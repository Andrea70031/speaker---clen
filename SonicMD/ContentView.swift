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

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color.blue.opacity(0.05),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        hero
                        quickStatus
                        volumeReminder
                        mainActions
                        rescueSection
                        insightsCard
                        footer
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
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
        VStack(spacing: 14) {
            Text("ACOUSTIC RESPONSE SYSTEM")
                .font(.caption2.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(.secondary)

            Text("Speaker Health")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("Analizza, pulisci e confronta la risposta acustica del tuo iPhone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ZStack {
                Circle().fill(.ultraThinMaterial)
                Circle().stroke(Color.primary.opacity(0.06), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: max(engine.progress, engine.beforeIndex == nil ? 0.04 : 1))
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .blue, .indigo, .purple, .cyan],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.35), value: engine.progress)

                VStack(spacing: 5) {
                    Text(scoreText)
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    Text(scoreCaption)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.8)
                }
            }
            .frame(width: 218, height: 218)
            .shadow(color: .blue.opacity(0.12), radius: 26, y: 12)

            HStack(spacing: 8) {
                statusPill(
                    icon: engine.isRunning ? "waveform" : "checkmark.circle.fill",
                    text: engine.isRunning ? "Analisi in corso" : "Sistema pronto",
                    color: engine.isRunning ? .blue : .green
                )
                statusPill(icon: "speaker.wave.2.fill", text: "Speaker", color: .cyan)
            }
        }
        .padding(.top, 6)
    }

    private var quickStatus: some View {
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
                Text("VOLUME AL MASSIMO")
                    .font(.caption.weight(.bold))
                    .tracking(0.9)
                    .foregroundStyle(.orange)

                Text("Prima di ogni funzione, porta il volume dell’iPhone al massimo per rendere efficaci i segnali acustici.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.orange.opacity(0.18), lineWidth: 1)
        }
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
                .disabled(engine.isRunning)
            }
            .padding(18)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))

            Button {
                requestAudioAction(.guidedClean)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles").font(.title2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Guided Clean").font(.headline)
                        Text("Scan → Adaptive Clean → verifica")
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
                LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .shadow(color: .blue.opacity(0.18), radius: 20, y: 10)
            .disabled(engine.isRunning)
        }
    }

    private var rescueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rescue Modes").font(.title2.bold())
                Spacer()
                Text("MANUALE").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                rescueCard(title: "Water", subtitle: "Basse frequenze", icon: "drop.fill", tint: .cyan) {
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(color.opacity(0.10), in: Capsule())
            .foregroundStyle(color)
    }

    private func metricCard(title: LocalizedStringKey, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold()).contentTransition(.numericText())
            Text(title).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(engine.isRunning)
    }

    private func requestAudioAction(_ action: AudioAction) {
        let currentVolume = AVAudioSession.sharedInstance().outputVolume

        if currentVolume >= 0.99 {
            runAudioAction(action)
        } else {
            pendingAudioAction = action
            showVolumeRequirement = true
        }
    }

    private func runPendingAudioAction() {
        guard let action = pendingAudioAction else { return }
        pendingAudioAction = nil
        runAudioAction(action)
    }

    private func runAudioAction(_ action: AudioAction) {
        switch action {
        case .smartScan(let reference):
            Task { await engine.measure(reference: reference) }
        case .guidedClean:
            Task { await engine.fullCycle() }
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

private enum AudioAction {
    case smartScan(reference: Bool)
    case guidedClean
    case waterRescue
    case dustRescue
    case adaptiveClean
}

private struct VolumeRequirementSheet: View {
    let onReady: () -> Void
    let onCancel: () -> Void

    @State private var volume = AVAudioSession.sharedInstance().outputVolume
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    private var isReady: Bool {
        volume >= 0.99
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill((isReady ? Color.green : Color.orange).opacity(0.12))
                    .frame(width: 76, height: 76)

                Image(systemName: isReady ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(isReady ? .green : .orange)
            }

            VStack(spacing: 8) {
                Text(isReady ? "Volume pronto" : "Alza il volume al massimo")
                    .font(.title2.bold())

                Text("Sonic MD usa segnali acustici per questa funzione. Porta il volume dell’iPhone al massimo prima di continuare.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                HStack {
                    Label("Volume iPhone", systemImage: "speaker.wave.2")
                    Spacer()
                    Text("\(Int((volume * 100).rounded()))%")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(isReady ? .green : .orange)
                }

                SystemVolumeControl()
                    .frame(height: 34)
            }

            Text("Non avvicinare l’iPhone all’orecchio durante i segnali.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Annulla", role: .cancel) {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    onReady()
                } label: {
                    Label("Avvia funzione", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isReady)
            }
        }
        .padding(24)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
        .onReceive(timer) { _ in
            volume = AVAudioSession.sharedInstance().outputVolume
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

