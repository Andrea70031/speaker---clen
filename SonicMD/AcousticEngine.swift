import Foundation
import AVFoundation
import Accelerate

@MainActor
final class AcousticEngine: ObservableObject {
    @Published var isRunning = false
    @Published var status = NSLocalizedString("Pronto", comment: "")
    @Published var progress: Double = 0
    @Published var beforeIndex: Int?
    @Published var afterIndex: Int?
    @Published var deltaPercent: Double?
    @Published var beforeBands: [Float] = []
    @Published var afterBands: [Float] = []
    @Published var microphonePermissionDenied = false
    @Published var isAutoWorkflow = false
    @Published var isMeasuring = false
    @Published var completedCycles = 0
    @Published var lastCleanSucceeded = false
    @Published var autoConclusion = ""

    private var stopRequested = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let session = AVAudioSession.sharedInstance()
    private var rmsSamples: [Float] = []
    private var tapInstalled = false

    private let testFrequencies: [Double] = [180, 260, 380, 550, 800, 1150, 1650, 2400]

    func prepare(requiresMicrophone: Bool = true) async throws {
        if requiresMicrophone {
            let granted = await requestMicrophonePermission()
            microphonePermissionDenied = !granted
            guard granted else { throw AcousticError.microphoneDenied }
        }

        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setActive(true)
        try? session.overrideOutputAudioPort(.speaker)

        // Never route rescue tones to headphones, AirPods or an external audio device.
        guard session.currentRoute.outputs.contains(where: { $0.portType == .builtInSpeaker }) else {
            throw AcousticError.externalAudioRoute
        }

        if requiresMicrophone {
            let inputFormat = engine.inputNode.outputFormat(forBus: 0)
            guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
                throw AcousticError.audioInputUnavailable
            }
        }

        if !engine.attachedNodes.contains(player) {
            engine.attach(player)
        }

        if engine.outputConnectionPoints(for: player, outputBus: 0).isEmpty {
            let mixerFormat = engine.mainMixerNode.outputFormat(forBus: 0)
            guard mixerFormat.sampleRate > 0, mixerFormat.channelCount > 0 else {
                throw AcousticError.audioOutputUnavailable
            }
            engine.connect(player, to: engine.mainMixerNode, format: mixerFormat)
        }

        if requiresMicrophone && !tapInstalled {
            try installMicrophoneTap()
        }

        if !engine.isRunning {
            engine.prepare()
            try engine.start()
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        }

        return await withCheckedContinuation { continuation in
            session.requestRecordPermission {
                continuation.resume(returning: $0)
            }
        }
    }

    private func installMicrophoneTap() throws {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw AcousticError.audioInputUnavailable
        }

        // Let AVAudioEngine use the input node's native hardware format.
        // Supplying a mismatched explicit format can trigger a CoreAudio assertion on-device.
        input.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            guard buffer.frameLength > 0,
                  let self,
                  let channel = buffer.floatChannelData?[0]
            else { return }

            var rms: Float = 0
            vDSP_rmsqv(channel, 1, &rms, vDSP_Length(buffer.frameLength))

            Task { @MainActor in
                if self.isMeasuring {
                    self.rmsSamples.append(rms)
                }
            }
        }

        tapInstalled = true
    }

    func measure(reference: Bool) async {
        guard !isRunning else { return }
        if !isAutoWorkflow { stopRequested = false }

        do {
            try await prepare()
            try checkCancellation()
            isRunning = true
            isMeasuring = true
            progress = 0
            status = reference
                ? NSLocalizedString("Misura iniziale…", comment: "")
                : NSLocalizedString("Misura di verifica…", comment: "")

            var bands: [Float] = []

            for (index, frequency) in testFrequencies.enumerated() {
                try checkCancellation()
                rmsSamples.removeAll(keepingCapacity: true)
                try playTone(frequency: frequency, duration: 0.42, amplitude: 0.18)
                try await Task.sleep(for: .milliseconds(440))
                try checkCancellation()

                bands.append(max(robustAverage(rmsSamples), 0.000001))
                progress = Double(index + 1) / Double(testFrequencies.count)
                try await Task.sleep(for: .milliseconds(120))
            }

            let index = responseIndex(bands)

            if reference || beforeBands.isEmpty {
                beforeBands = bands
                beforeIndex = index
                afterBands = []
                afterIndex = nil
                deltaPercent = nil
                status = NSLocalizedString("Riferimento acquisito. Esegui una pulizia e poi verifica.", comment: "")
            } else {
                afterBands = bands
                afterIndex = index
                deltaPercent = improvement(from: beforeBands, to: afterBands)
                status = NSLocalizedString("Confronto completato.", comment: "")
            }

            player.stop()
            isMeasuring = false
            isRunning = false
        } catch {
            handle(error)
        }
    }

    // Relative measurement only; no hardware or contamination diagnosis.
    func fullCycle() async { await autoClean() }

    func autoClean() async {
        guard !isRunning && !isAutoWorkflow else { return }
        isAutoWorkflow = true
        stopRequested = false
        completedCycles = 0
        autoConclusion = ""
        beforeBands = []
        afterBands = []
        beforeIndex = nil
        afterIndex = nil
        deltaPercent = nil

        status = NSLocalizedString("Auto Clean · 1/3: misurazione iniziale", comment: "")
        await measure(reference: true)
        guard !stopRequested, beforeIndex != nil else {
            isAutoWorkflow = false
            return
        }

        status = NSLocalizedString("Auto Clean · 2/3: pulizia bilanciata", comment: "")
        await adaptiveClean()
        guard !stopRequested, lastCleanSucceeded else {
            isAutoWorkflow = false
            return
        }
        completedCycles = 1

        try? await Task.sleep(for: .milliseconds(650))
        guard !stopRequested else {
            isAutoWorkflow = false
            return
        }

        status = NSLocalizedString("Auto Clean · 3/3: verifica finale", comment: "")
        await measure(reference: false)
        if !stopRequested, let delta = deltaPercent {
            if delta > 3 {
                autoConclusion = NSLocalizedString("La risposta misurata è aumentata rispetto al riferimento. Risultato indicativo.", comment: "")
            } else if delta < -3 {
                autoConclusion = NSLocalizedString("La risposta misurata è diminuita. Ripeti la misura in un ambiente silenzioso, senza aumentare il volume.", comment: "")
            } else {
                autoConclusion = NSLocalizedString("Differenza limitata: nessuna variazione affidabile rilevata. Non servono cicli automatici aggiuntivi.", comment: "")
            }
            status = NSLocalizedString("Auto Clean completato", comment: "")
        }
        isAutoWorkflow = false
    }

    func stop() {
        guard isRunning || isAutoWorkflow else { return }
        stopRequested = true
        player.stop()
        status = NSLocalizedString("Operazione interrotta.", comment: "")
    }

    private func checkCancellation() throws {
        if stopRequested || Task.isCancelled { throw AcousticError.cancelled }
        if !session.currentRoute.outputs.contains(where: { $0.portType == .builtInSpeaker }) {
            throw AcousticError.externalAudioRoute
        }
    }

    func waterRescue() async {
        await clean(
            name: NSLocalizedString("Water Rescue Plus", comment: ""),
            frequencies: [165, 150, 135, 120, 105, 125, 145, 160,
                          165, 150, 135, 120, 105, 125, 145, 160],
            toneMilliseconds: 270,
            pauseMilliseconds: 180,
            amplitude: 0.42
        )
    }

    func dustRescue() async {
        await clean(
            name: NSLocalizedString("Dust Rescue", comment: ""),
            frequencies: [120, 210, 145, 240, 130, 190, 110, 225, 155, 200, 125, 250],
            toneMilliseconds: 115,
            pauseMilliseconds: 30,
            amplitude: 0.50
        )
    }

    func adaptiveClean() async {
        await clean(
            name: NSLocalizedString("Adaptive Clean", comment: ""),
            frequencies: [110, 140, 180, 220, 250, 205, 165, 125, 235, 150, 195, 115, 245, 175],
            toneMilliseconds: 145,
            pauseMilliseconds: 38,
            amplitude: 0.50
        )
    }

    private func clean(
        name: String,
        frequencies: [Double],
        toneMilliseconds: Int,
        pauseMilliseconds: Int,
        amplitude: Float
    ) async {
        guard !isRunning else { return }
        if !isAutoWorkflow { stopRequested = false }
        lastCleanSucceeded = false

        do {
            try await prepare(requiresMicrophone: false)
            try checkCancellation()
            isRunning = true
            progress = 0
            status = String(
                format: NSLocalizedString("%@ in corso…", comment: ""),
                name
            )

            for (index, frequency) in frequencies.enumerated() {
                try checkCancellation()
                try playTone(
                    frequency: frequency,
                    duration: Double(toneMilliseconds) / 1000.0,
                    amplitude: amplitude
                )

                progress = Double(index + 1) / Double(frequencies.count)

                try await Task.sleep(
                    for: .milliseconds(toneMilliseconds + pauseMilliseconds)
                )
            }

            try checkCancellation()
            player.stop()
            isRunning = false
            lastCleanSucceeded = true
            status = String(
                format: NSLocalizedString("%@ completato.", comment: ""),
                name
            )
        } catch {
            handle(error)
        }
    }

    private func playTone(
        frequency: Double,
        duration: Double,
        amplitude: Float
    ) throws {
        let format = player.outputFormat(forBus: 0)
        guard format.sampleRate > 0,
              format.channelCount > 0,
              format.commonFormat == .pcmFormatFloat32
        else {
            throw AcousticError.audioOutputUnavailable
        }

        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(max(1, Int(duration * sampleRate)))

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else {
            throw AcousticError.audioOutputUnavailable
        }

        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData else {
            throw AcousticError.audioOutputUnavailable
        }

        let attackFrames = max(1, Int(sampleRate * 0.015))
        let releaseFrames = max(1, Int(sampleRate * 0.040))

        for channelIndex in 0..<Int(format.channelCount) {
            let samples = channelData[channelIndex]

            for i in 0..<Int(frameCount) {
                let time = Double(i) / sampleRate
                var envelope: Float = 1

                if i < attackFrames {
                    envelope = Float(i) / Float(attackFrames)
                } else if i > Int(frameCount) - releaseFrames {
                    envelope = Float(Int(frameCount) - i) / Float(releaseFrames)
                }

                samples[i] = Float(sin(2.0 * Double.pi * frequency * time))
                    * amplitude
                    * max(0, envelope)
            }
        }

        player.scheduleBuffer(buffer)
        if !player.isPlaying {
            player.play()
        }
    }

    private func robustAverage(_ values: [Float]) -> Float {
        guard !values.isEmpty else { return 0 }

        let sorted = values.sorted()
        let lower = Int(Double(sorted.count) * 0.20)
        let upper = max(lower + 1, Int(Double(sorted.count) * 0.80))
        let trimmed = sorted[lower..<min(upper, sorted.count)]

        return trimmed.reduce(0, +) / Float(trimmed.count)
    }

    private func responseIndex(_ bands: [Float]) -> Int {
        guard !bands.isEmpty else { return 0 }

        let decibels = bands.map {
            20 * log10(max($0, 0.000001))
        }

        let average = decibels.reduce(0, +) / Float(decibels.count)
        return Int(max(1, min(100, (average + 55) * 2.15)))
    }

    private func improvement(from before: [Float], to after: [Float]) -> Double {
        guard !before.isEmpty, before.count == after.count else { return 0 }

        let beforeAverage = before.reduce(0, +) / Float(before.count)
        let afterAverage = after.reduce(0, +) / Float(after.count)

        guard beforeAverage > 0 else { return 0 }
        return Double((afterAverage - beforeAverage) / beforeAverage * 100)
    }

    private func handle(_ error: Error) {
        player.stop()
        isMeasuring = false
        isRunning = false
        progress = 0

        if let acousticError = error as? AcousticError {
            switch acousticError {
            case .microphoneDenied:
                microphonePermissionDenied = true
            case .audioInputUnavailable, .audioOutputUnavailable, .externalAudioRoute, .cancelled:
                microphonePermissionDenied = false
            }
        }

        status = error.localizedDescription
    }
}

enum AcousticError: LocalizedError {
    case microphoneDenied
    case audioInputUnavailable
    case audioOutputUnavailable
    case externalAudioRoute
    case cancelled

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return NSLocalizedString("Permesso microfono negato. Abilitalo nelle Impostazioni di iOS.", comment: "")
        case .audioInputUnavailable:
            return NSLocalizedString("Ingresso microfono non disponibile. Scollega eventuali dispositivi audio e riprova.", comment: "")
        case .audioOutputUnavailable:
            return NSLocalizedString("Uscita audio non disponibile. Scollega eventuali dispositivi audio e riprova.", comment: "")
        case .externalAudioRoute:
            return NSLocalizedString("Per sicurezza scollega cuffie, Bluetooth e accessori audio prima di avviare i segnali.", comment: "")
        case .cancelled:
            return NSLocalizedString("Operazione interrotta.", comment: "")
        }
    }
}
