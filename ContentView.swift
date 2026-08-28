import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var engine: AcousticEngine
    @AppStorage("termsAccepted") private var termsAccepted = false
    @State private var showTerms = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("ACOUSTIC SYSTEM")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text("Speaker Health")
                        .font(.system(size: 38, weight: .bold, design: .rounded))

                    ZStack {
                        Circle().stroke(.quaternary, lineWidth: 10)

                        Circle()
                            .trim(from: 0, to: engine.progress)
                            .stroke(
                                AngularGradient(
                                    colors: [.blue, .cyan, .purple, .blue],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        VStack {
                            Text("\(engine.afterIndex ?? engine.beforeIndex ?? 0)")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                            Text("RESPONSE INDEX")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 210, height: 210)

                    VStack(spacing: 14) {
                        HStack {
                            metric("PRIMA", engine.beforeIndex.map(String.init) ?? "â")
                            metric("DOPO", engine.afterIndex.map(String.init) ?? "â")
                            metric("VARIAZIONE", engine.deltaPercent.map { String(format: "%+.1f%%", $0) } ?? "â")
                        }

                        ProgressView(value: engine.progress)

                        Text(engine.status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            Task { await engine.measure(reference: engine.beforeBands.isEmpty) }
                        } label: {
                            Text(engine.beforeBands.isEmpty ? "Misura risposta" : "Misura di verifica")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(engine.isRunning)

                        Button {
                            Task { await engine.fullCycle() }
                        } label: {
                            Text("Ciclo completo: misura â pulizia â verifica")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(engine.isRunning)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rescue").font(.title2.bold())
                        Button("Water Rescue") { Task { await engine.waterRescue() } }
                            .buttonStyle(.bordered).controlSize(.large)
                        Button("Dust Rescue") { Task { await engine.dustRescue() } }
                            .buttonStyle(.bordered).controlSize(.large)
                        Button("Adaptive Clean") { Task { await engine.adaptiveClean() } }
                            .buttonStyle(.borderedProminent).controlSize(.large)
                    }

                    Text("Misura locale comparativa. Non sostituisce una diagnosi hardware.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sonic MD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Termini") { showTerms = true }
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsView(requiredAcceptance: !termsAccepted) {
                termsAccepted = true
                showTerms = false
            }
        }
        .onAppear {
            if !termsAccepted { showTerms = true }
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }
}
