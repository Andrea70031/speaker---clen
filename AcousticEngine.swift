import Foundation
import AVFoundation
import Accelerate

@MainActor
final class AcousticEngine: ObservableObject {
    @Published var isRunning = false
    @Published var status = "Pronto"
    @Published var progress: Double = 0
    @Published var beforeIndex: Int?
    @Published var afterIndex: Int?
    @Published var deltaPercent: Double?
    @Published var beforeBands: [Float] = []
    @Published var afterBands: [Float] = []

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let session = AVAudioSession.sharedInstance()
    private var rmsSamples: [Float] = []
    private var tapInstalled = false

    private let testFrequencies: [Double] = [180, 260, 380, 550, 800, 1150, 1650, 2400]

    func prepare() async throws {
        let granted = await requestMicrophonePermission()
        guard granted else { throw AcousticError.microphoneDenied }

        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setActive(true)

        if !engine.attachedNodes.contains(player) {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)
        }

        if !tapInstalled {
            installMicrophoneTap()
        }

        if !engine.isRunning {
            try engine.start()
        }

        try? session.overrideOutputAudioPort(.speaker)
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

    private func installMicrophoneTap() {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self, let channel = buffer.floatChannelData?[0] else { return }

            var rms: Float = 0
            vDSP_rmsqv(channel, 1, &rms, vDSP_Length(buffer.frameLength))

            Task { @MainActor in
                if self.isRunning {
                    self.rmsSamples.append(rms)
                }
            }
        }

        tapInstalled = true
    }

    func measure(reference: Bool) async {
        guard !isRunning else { return }

        do {
            try await prepare()
            isRunning = true
            progress = 0
            status = reference ? "Misura inizialeâ¦" : "Misura di verificaâ¦"

            var bands: [Float] = []

            for (index, frequency) in testFrequencies.enumerated() {
                rmsSamples.removeAll(keepingCapacity: true)
                playTone(frequency: frequency, duration: 0.42, amplitude: 0.18)
                try await Task.sleep(for: .milliseconds(330))

                bands.append(max(robustAverage(rmsSamples), 0.000001))
                progress = Double(index + 1) / Double(testFrequencies.count)

                try await Task.sleep(for: .milliseconds(150))
            }

            let index = responseIndex(bands)

            if reference || beforeBands.isEmpty {
                beforeBands = bands
                beforeIndex = index
                afterBands = []
                afterIndex = nil
                deltaPercent = nil
                status = "Riferimento acquisito. Esegui una pulizia e poi verifica."
            } else {
                afterBands = bands
                afterIndex = index
                deltaPercent = improvement(from: beforeBands, to: afterBands)
                status = "Confronto completato."
            }

            isRunning = false
        } catch {
            isRunning = false
            status = error.localizedDescription
        }
    }

    func fullCycle() async {
        beforeBands = []
        afterBands = []
        beforeIndex = nil
        afterIndex = nil
        deltaPercent = nil

        await measure(reference: true)
        guard !beforeBands.isEmpty else { return }

        try? await Task.sleep(for: .milliseconds(700))
        await adaptiveClean()
        try? await Task.sleep(for: .milliseconds(1200))
        await measure(reference: false)
    }

    func waterRescue() async {
        await clean(name: "Water Rescue",
                    frequencies: [165,155,145,135,125,115,105,120,140,160],
                    toneMilliseconds: 250,
                    pauseMilliseconds: 65,
                    amplitude: 0.48)
    }

    func dustRescue() async {
        await clean(name: "Dust Rescue",
                    frequencies: [120,210,145,240,130,190,110,225,155,200,125,250],
                    toneMilliseconds: 115,
                    pauseMilliseconds: 30,
                    amplitude: 0.50)
    }

    func adaptiveClean() async {
        await clean(name: "Adaptive Clean",
                    frequencies: [110,140,180,220,250,205,165,125,235,150,195,115,245,175],
                    toneMilliseconds: 145,
                    pauseMilliseconds: 38,
                    amplitude: 0.50)
    }

    private func clean(
        name: String,
        frequencies: [Double],
        toneMilliseconds: Int,
        pauseMilliseconds: Int,
        amplitude: Float
    ) async {
        guard !isRunning else { return }

        do {
            try await prepare()
            isRunning = true
            progress = 0
            status = "\(name) in corsoâ¦"

            for (index, frequency) in frequencies.enumerated() {
                playTone(
                    frequency: frequency,
                    duration: Double(toneMilliseconds) / 1000.0,
                    amplitude: amplitude
                )

                progress = Double(index + 1) / Double(frequencies.count)

                try await Task.sleep(
                    for: .milliseconds(toneMilliseconds + pauseMilliseconds)
                )
            }

            isRunning = false
            status = "\(name) completato."
        } catch {
            isRunning = false
            status = error.localizedDescription
        }
    }

    private func playTone(
        frequency: Double,
        duration: Double,
        amplitude: Float
    ) {
        let sampleRate = 48_000.0
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        ),
        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else { return }

        buffer.frameLength = frameCount
        guard let samples = buffer.floatChannelData?[0] else { return }

        let attackFrames = max(1, Int(sampleRate * 0.015))
        let releaseFrames = max(1, Int(sampleRate * 0.040))

        for i in 0..<Int(frameCount) {
            let time = Double(i) / sampleRate
            var envelope: Float = 1

            if i < attackFrames {
                envelope = Float(i) / Float(attackFrames)
            } else if i > Int(frameCount) - releaseFrames {
                envelope = Float(Int(frameCount) - i) / Float(releaseFrames)
            }

            samples[i] =
                Float(sin(2.0 * Double.pi * frequency * time))
                * amplitude
                * max(0, envelope)
        }

        player.scheduleBuffer(buffer)
        if !player.isPlaying { player.play() }
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
}

enum AcousticError: LocalizedError {
    case microphoneDenied

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return "Permesso microfono negato. Abilitalo nelle Impostazioni di iOS."
        }
    }
}
