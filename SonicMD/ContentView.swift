import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var engine: AcousticEngine
    @AppStorage("termsAccepted") private var termsAccepted = false
    @State private var showTerms = false
    @State private var showHistory = false
    @State private var showGuide = false

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
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Guida rapida", systemImage: "questionmark.circle") {
                            showGuide = true
                        }
                        Button("Termini e sicurezza", systemImage: "shield") {
                            showTerms = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
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

            SessionStore.shared.add(
                before: before,
                after: newValue,
                delta: delta
            )
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Text("ACOUSTIC HEALTH SYSTEM")
                .font(.caption2.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(.secondary)

            Text("Speaker Health")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("Analizza, pulisci e verifica la risposta del tuo iPhone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)

                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 12)

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

                statusPill(
                    icon: "speaker.wave.2.fill",
                    text: "Speaker",
                    color: .cyan
                )
            }
        }
        .padding(.top, 6)
    }

    private var quickStatus: some View {
        HStack(spacing: 10) {
            metricCard(
                title: "PRIMA",
                value: engine.beforeIndex.map(String.init) ?? "—",
                icon: "circle.dashed"
            )

            metricCard(
                title: "DOPO",
                value: engine.afterIndex.map(String.init) ?? "—",
                icon: "checkmark.circle"
            )

            metricCard(
                title: "DELTA",
                value: engine.deltaPercent.map { String(format: "%+.1f%%", $0) } ?? "—",
                icon: "arrow.up.right"
            )
        }
    }

    private var mainActions: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Smart Scan")
                            .font(.title3.bold())

                        Text("Misura la risposta locale e crea un riferimento.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "waveform.path.ecg")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                ProgressView(value: engine.progress)
                    .tint(.blue)

                Text(engine.status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    Task {
                        await engine.measure(reference: engine.beforeBands.isEmpty)
                    }
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
                Task {
                    await engine.fullCycle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Guided Clean")
                            .font(.headline)
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
                LinearGradient(
                    colors: [.blue, .indigo],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .shadow(color: .blue.opacity(0.18), radius: 20, y: 10)
            .disabled(engine.isRunning)
        }
    }

    private var rescueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rescue Modes")
                    .font(.title2.bold())
                Spacer()
                Text("MANUALE")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                rescueCard(
                    title: "Water",
                    subtitle: "Basse frequenze",
                    icon: "drop.fill",
                    tint: .cyan
                ) {
                    Task { await engine.waterRescue() }
                }

                rescueCard(
                    title: "Dust",
                    subtitle: "Impulsi rapidi",
                    icon: "sparkles",
                    tint: .orange
                ) {
                    Task { await engine.dustRescue() }
                }
            }

            rescueCard(
                title: "Adaptive Clean",
                subtitle: "Pattern dinamico multi-frequenza",
                icon: "waveform.path",
                tint: .purple
            ) {
                Task { await engine.adaptiveClean() }
            }
        }
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Acoustic Insights", systemImage: "chart.xyaxis.line")
                    .font(.headline)
                Spacer()
                Text("LOCAL")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            Divider()

            insightRow(
                icon: "mic.fill",
                title: "Elaborazione",
                value: "Sul dispositivo"
            )

            insightRow(
                icon: "shield.checkered",
                title: "Diagnosi",
                value: "Comparativa"
            )

            insightRow(
                icon: "waveform",
                title: "Bande di test",
                value: "8 frequenze"
            )
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Text("Sonic MD")
                .font(.footnote.weight(.semibold))

            Text("Misurazione acustica comparativa. Non sostituisce assistenza tecnica o diagnostica certificata.")
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

    private var scoreCaption: String {
        engine.beforeIndex == nil ? "NESSUN RIFERIMENTO" : "RESPONSE INDEX"
    }

    private func statusPill(
        icon: String,
        text: String,
        color: Color
    ) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(color.opacity(0.10), in: Capsule())
            .foregroundStyle(color)
    }

    private func metricCard(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold())
                .contentTransition(.numericText())

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func rescueCard(
        title: String,
        subtitle: String,
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
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "play.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(engine.isRunning)
    }

    private func insightRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .font(.subheadline)
    }
}
