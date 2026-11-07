import SwiftUI
import UIKit
import AVFoundation
import MediaPlayer
import Combine

struct ContentView: View {
    @EnvironmentObject private var engine: AcousticEngine
    @AppStorage("termsAccepted") private var termsAccepted = false
    @State private var showTerms = false
    @State private var showHistory = false
    @State private var showGuide = false
    @State private var showPrivacy = false
    @State private var showVolumeRequirement = false
    @State private var pendingAudioAction: AudioAction?
    @State private var volumePreviouslyConfirmed = false

    private var audioBusy: Bool { engine.isRunning || engine.isAutoWorkflow }

    var body: some View {
        NavigationStack {
            ZStack {
                SonicAuroraBackdrop()

                ScrollView {
                    VStack(spacing: 26) {
                        hero
                        quickStatus
                        mainActions
                        if audioBusy { stopButton }
                        if !engine.autoConclusion.isEmpty { autoResultCard }
                        rescueSection
                        volumeReminder
                        insightsCard
                        footer
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Sonic MD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("Cronologia")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Guida rapida", systemImage: "questionmark.circle") {
                            showGuide = true
                        }
                        Button("Privacy", systemImage: "hand.raised") {
                            showPrivacy = true
                        }
                        Button("Termini e sicurezza", systemImage: "shield") {
                            showTerms = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Altre opzioni")
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsView(requiredAcceptance: !termsAccepted) {
                termsAccepted = true
                showTerms = false
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showGuide) {
            QuickGuideView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyView()
        }
        .sheet(isPresented: $showVolumeRequirement) {
            VolumeRequirementSheet(
                onReady: {
                    // The sheet has checked the active audio session and the
                    // user has explicitly confirmed the volume when unreadable.
                    volumePreviouslyConfirmed = true
                    showVolumeRequirement = false
                    runPendingAudioAction()
                },
                onCancel: {
                    pendingAudioAction = nil
                    showVolumeRequirement = false
                }
            )
        }
        .alert("Microfono necessario", isPresented: $engine.microphonePermissionDenied) {
            Button("Annulla", role: .cancel) { }
            Button("Apri Impostazioni") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        } message: {
            Text("Sonic MD usa il microfono solo per misurazioni acustiche locali. Abilita l'accesso al microfono per utilizzare Smart Scan e Guided Clean.")
        }
        .sensoryFeedback(.success, trigger: engine.afterIndex)
        .onAppear {
            if !termsAccepted {
                showTerms = true
            }
        }
        .onChange(of: engine.afterIndex) { _, newValue in
            guard let newValue,
                  let before = engine.beforeIndex,
                  let delta = engine.deltaPercent
            else { return }

            SessionStore.shared.add(before: before, after: newValue, delta: delta)
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(audioBusy ? Color.cyan : Color.green)
                    .frame(width: 7, height: 7)
                Text(audioBusy ? "SESSIONE ATTIVA" : "SONIC / ACOUSTIC LAB")
                    .tracking(2)
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .sonicGlassCapsule(tint: .cyan)

            Text("Speaker Health")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .tracking(-1.5)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text("Il suono, sotto controllo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.cyan.opacity(0.46), .indigo.opacity(0.22), .clear],
                            center: .center,
                            startRadius: 26,
                            endRadius: 153
                        )
                    )
                    .frame(width: 298, height: 298)
                    .blur(radius: 22)

                Circle()
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    .frame(width: 264, height: 264)

                Circle()
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
                    .frame(width: 242, height: 242)

                Circle()
                    .fill(Color.clear)
                    .frame(width: 218, height: 218)
                    .sonicGlassCircle()

                Circle()
                    .stroke(Color.primary.opacity(0.07), lineWidth: 11)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: max(
                        0.035,
                        min(1, audioBusy ? engine.progress : (engine.beforeIndex == nil ? 0.04 : 1))
                    ))
                    .stroke(
                        AngularGradient(
                            colors: [.mint, .cyan, .blue, .indigo, .cyan],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 11, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth(duration: 0.45), value: engine.progress)

                VStack(spacing: 7) {
                    Image(systemName: audioBusy ? "waveform" : "waveform.path")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.cyan)
                        .symbolEffect(.variableColor.iterative, options: .repeating, isActive: audioBusy)

                    Text(scoreText)
                        .font(.system(size: 62, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text(scoreCaption)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .tracking(1.2)
                }
            }
            .frame(height: 292)
            .accessibilityElement(children: .combine)

            HStack(spacing: 10) {
                statusPill(
                    icon: audioBusy ? "waveform" : "checkmark.seal.fill",
                    text: audioBusy ? "Analisi in corso" : "Sistema pronto",
                    color: audioBusy ? .cyan : .green
                )
                statusPill(icon: "speaker.wave.2.fill", text: "iPhone Speaker", color: .blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var quickStatus: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 8) { metricRow }
            } else {
                metricRow
            }
        }
    }

    private var metricRow: some View {
        HStack(spacing: 10) {
            metricCard(title: "PRIMA", value: engine.beforeIndex.map(String.init) ?? "—", icon: "circle.dashed")
            metricCard(title: "DOPO", value: engine.afterIndex.map(String.init) ?? "—", icon: "checkmark.circle")
            metricCard(
                title: "DELTA",
                value: engine.deltaPercent.map { String(format: "%+.1f%%", $0) } ?? "—",
                icon: "arrow.up.right"
            )
        }
    }

    private var volumeReminder: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "speaker.wave.3.fill")
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 38, height: 38)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text("VOLUME CONSIGLIATO")
                    .font(.caption.weight(.bold))
                    .tracking(0.9)
                    .foregroundStyle(.orange)

                Text("Per le funzioni audio usa un volume moderato (circa 50–70%). Scollega cuffie e Bluetooth; non avvicinare il telefono all'orecchio.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .sonicGlass(cornerRadius: 22)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.orange.opacity(0.18), lineWidth: 1)
        }
    }

    private var stopButton: some View {
        Button(role: .destructive) {
            engine.stop()
        } label: {
            Label("Interrompi sessione", systemImage: "stop.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .controlSize(.large)
    }

    private var autoResultCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Risultato Auto Clean", systemImage: "chart.bar.xaxis")
                .font(.headline)
            Text(engine.autoConclusion)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("La variazione dipende anche dall'ambiente, dal volume e dalla posizione del dispositivo.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .sonicGlass(cornerRadius: 22)
    }

    private var mainActions: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Smart Scan").font(.title3.bold())
                        Text("Misura la risposta locale e crea un riferimento comparativo.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "waveform.path.ecg")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                ProgressView(value: engine.progress).tint(.blue)
                Text(engine.status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    requestAudioAction(.smartScan(reference: engine.beforeBands.isEmpty))
                } label: {
                    Label(
                        engine.beforeBands.isEmpty ? "Avvia Smart Scan" : "Verifica risultato",
                        systemImage: engine.beforeBands.isEmpty ? "scope" : "checkmark.seal.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(audioBusy)
            }
            .padding(18)
            .sonicGlass(cornerRadius: 26)

            Button {
                requestAudioAction(.autoClean)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles").font(.title2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sonic Auto Clean").font(.headline)
                        Text("Un tocco: misura → pulizia → verifica")
                            .font(.caption)
                            .opacity(0.82)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding(18)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: [.cyan, .blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .shadow(color: .blue.opacity(0.18), radius: 20, y: 10)
            .disabled(audioBusy)
        }
    }

    private var rescueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Modalità pulizia").font(.title2.bold())
                Spacer()
                Text("MANUALE").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                rescueCard(title: "Water Plus", subtitle: "2 cicli con pause protette", icon: "drop.fill", tint: .cyan) {
                    requestAudioAction(.waterRescue)
                }
                rescueCard(title: "Dust", subtitle: "Impulsi rapidi", icon: "sparkles", tint: .orange) {
                    requestAudioAction(.dustRescue)
                }
            }

            rescueCard(
                title: "Adaptive Clean",
                subtitle: "Pattern dinamico multi-frequenza",
                icon: "waveform.path",
                tint: .purple
            ) {
                requestAudioAction(.adaptiveClean)
            }
        }
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Acoustic Insights", systemImage: "chart.xyaxis.line").font(.headline)
                Spacer()
                Text("LOCAL").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            }
            Divider()
            insightRow(icon: "mic.fill", title: "Elaborazione", value: "Sul dispositivo")
            insightRow(icon: "shield.checkered", title: "Misurazione", value: "Comparativa")
            insightRow(icon: "waveform", title: "Bande di test", value: "8 frequenze")
        }
        .padding(18)
        .sonicGlass(cornerRadius: 24)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Text("Sonic MD").font(.footnote.weight(.semibold))
            Text("Indice acustico comparativo. Non sostituisce assistenza tecnica o diagnostica certificata.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }

    private var scoreText: String {
        if let after = engine.afterIndex { return String(after) }
        if let before = engine.beforeIndex { return String(before) }
        return "—"
    }

    private var scoreCaption: LocalizedStringKey {
        engine.beforeIndex == nil
            ? LocalizedStringKey("NESSUN RIFERIMENTO")
            : LocalizedStringKey("RESPONSE INDEX")
    }

    private func statusPill(icon: String, text: LocalizedStringKey, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .sonicGlassCapsule(tint: color)
    }

    private func metricCard(title: LocalizedStringKey, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 1)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.cyan)
            }
            Text(value)
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .sonicGlass(cornerRadius: 22)
    }

    private func rescueCard(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "play.fill").font(.caption).foregroundStyle(.secondary)
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .sonicGlass(cornerRadius: 20)
        }
        .buttonStyle(.plain)
        .disabled(audioBusy)
    }

    private func requestAudioAction(_ action: AudioAction) {
        guard !audioBusy else { return }

        let session = AVAudioSession.sharedInstance()
        // outputVolume may report an initial 0 before a media session is
        // activated. Never trust that snapshot to block the user.
        let detectedVolume = session.outputVolume
        let isSpeaker = session.currentRoute.outputs.contains {
            $0.portType == .builtInSpeaker
        }

        if volumePreviouslyConfirmed && isSpeaker &&
            detectedVolume >= 0.35 && detectedVolume <= 0.85 {
            runAudioAction(action)
        } else {
            pendingAudioAction = action
            showVolumeRequirement = true
        }
    }

    private func runPendingAudioAction() {
        guard let action = pendingAudioAction else { return }
        pendingAudioAction = nil
        // The sheet validates volume on the active playback route. Actual
        // speaker route is checked again in AcousticEngine.prepare().
        runAudioAction(action)
    }

    private func runAudioAction(_ action: AudioAction) {
        switch action {
        case .smartScan(let reference):
            Task { await engine.measure(reference: reference) }
        case .autoClean:
            Task { await engine.autoClean() }
        case .waterRescue:
            Task { await engine.waterRescue() }
        case .dustRescue:
            Task { await engine.dustRescue() }
        case .adaptiveClean:
            Task { await engine.adaptiveClean() }
        }
    }

    private func insightRow(icon: String, title: LocalizedStringKey, value: LocalizedStringKey) -> some View {
        HStack {
            Label(title, systemImage: icon).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold))
        }
        .font(.subheadline)
    }
}

// Native Liquid Glass on iOS 26, with a material fallback on iOS 17–25.
// Centralizing the treatment keeps the app functional on older supported devices.
private extension View {
    @ViewBuilder
    func sonicGlassCircle() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: Circle())
        } else {
            self.background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.09), lineWidth: 1))
        }
    }

    @ViewBuilder
    func sonicGlassCapsule(tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(tint.opacity(0.13)), in: Capsule())
        } else {
            self.background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(tint.opacity(0.16), lineWidth: 0.8))
        }
    }

    @ViewBuilder
    func sonicGlass(cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.thinMaterial, in: shape)
                .overlay(shape.strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.7))
        }
    }
}

private enum AudioAction {
    case smartScan(reference: Bool)
    case autoClean
    case waterRescue
    case dustRescue
    case adaptiveClean
}

private struct VolumeRequirementSheet: View {
    let onReady: () -> Void
    let onCancel: () -> Void

    @State private var volume: Float?
    @State private var sessionReady = false
    @State private var speakerConnected = true
    @State private var manuallyConfirmed = false
    @State private var sessionError: String?
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    // A reported 0 can mean either silence or that iOS has not supplied a
    // reliable reading yet. Do not display a misleading "0%" in this case.
    private var measuredVolume: Float? {
        guard let volume, volume > 0.001 else { return nil }
        return volume
    }

    private var isInRecommendedRange: Bool {
        guard let measuredVolume else { return false }
        return (0.35...0.85).contains(measuredVolume)
    }

    private var isReady: Bool {
        sessionReady && speakerConnected &&
            (isInRecommendedRange || (measuredVolume == nil && manuallyConfirmed))
    }

    private var volumeText: String {
        guard let measuredVolume else { return "—" }
        return "\(Int((measuredVolume * 100).rounded()))%"
    }

    private var volumeMessage: String {
        if !sessionReady { return "Preparazione del controllo volume…" }
        if !speakerConnected { return "Scollega cuffie, AirPods e dispositivi Bluetooth audio." }
        guard let measuredVolume else {
            return "iOS non restituisce una lettura affidabile. Regola il volume con il cursore o i tasti laterali, poi conferma manualmente."
        }
        if measuredVolume > 0.85 { return "Volume troppo alto: abbassalo per evitare suoni eccessivi." }
        if measuredVolume < 0.35 { return "Aumenta gradualmente il volume verso il 50–70%." }
        return "Volume nel range consentito. Puoi avviare la funzione."
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill((isReady ? Color.green : Color.orange).opacity(0.12))
                        .frame(width: 76, height: 76)

                    Image(systemName: isReady ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(isReady ? .green : .orange)
                }

                VStack(spacing: 8) {
                    Text(isReady ? "Volume pronto" : "Regola il volume")
                        .font(.title2.bold())
                    Text("Imposta un volume moderato (50–70% consigliato). Non serve il volume massimo.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    HStack {
                        Label("Volume iPhone", systemImage: "speaker.wave.2")
                        Spacer()
                        Text(volumeText)
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundStyle(isReady ? .green : .orange)
                    }
                    SystemVolumeControl()
                        .frame(height: 40)
                        .accessibilityLabel("Regola volume di sistema")
                    Text(volumeMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if sessionReady && measuredVolume == nil {
                        Toggle(isOn: $manuallyConfirmed) {
                            Text("Confermo di aver impostato manualmente un volume moderato (50–70%).")
                                .font(.footnote)
                        }
                        .tint(.cyan)
                    }
                    if let sessionError {
                        Text(sessionError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(18)
                .sonicGlass(cornerRadius: 22)

                Text("Tieni l'iPhone lontano dall'orecchio e interrompi la riproduzione in caso di vibrazioni o distorsioni anomale.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button("Annulla", role: .cancel, action: onCancel)
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                    Button(action: onReady) {
                        Label("Avvia funzione", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!isReady)
                }
            }
            .padding(24)
        }
        .presentationDetents([.height(550), .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
        .task { await activateVolumeSession() }
        .onReceive(timer) { _ in refreshVolume() }
    }

    @MainActor
    private func activateVolumeSession() async {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            // Allow the audio route and MPVolumeView to synchronize before
            // using outputVolume as a preflight indication.
            try? await Task.sleep(for: .milliseconds(350))
            sessionReady = true
            refreshVolume()
        } catch {
            sessionError = "Impossibile attivare il controllo volume: \(error.localizedDescription)"
            sessionReady = false
        }
    }

    @MainActor
    private func refreshVolume() {
        guard sessionReady else { return }
        let session = AVAudioSession.sharedInstance()
        volume = session.outputVolume
        speakerConnected = session.currentRoute.outputs.contains {
            $0.portType == .builtInSpeaker
        }
        // A new reliable measurement takes precedence over an earlier
        // manual acknowledgment.
        if let v = measuredVolume, !(0.35...0.85).contains(v) {
            manuallyConfirmed = false
        }
    }
}

private struct SystemVolumeControl: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.showsRouteButton = false
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) { }
}

