import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    private let privacyURL = URL(string: "https://andrea70031.github.io/speaker---clen/privacy.html")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Privacy").font(.largeTitle.bold())
                    Text("Sonic MD è progettata per funzionare localmente sul dispositivo.")

                    section(
                        title: "Microfono",
                        text: "Il microfono viene usato durante Smart Scan e le verifiche acustiche. I campioni audio vengono elaborati in memoria sul dispositivo e non vengono caricati o inviati a server esterni."
                    )
                    section(
                        title: "Cronologia",
                        text: "La cronologia delle sessioni contiene soltanto data, indice prima/dopo e variazione percentuale. È salvata localmente sul dispositivo e può essere cancellata dalla schermata Cronologia."
                    )
                    section(
                        title: "Account, pubblicità e tracciamento",
                        text: "La versione 1.0 non richiede account, non contiene pubblicità, non usa tracker e non integra SDK di analytics di terze parti."
                    )
                    section(
                        title: "Conservazione e cancellazione",
                        text: "I dati locali restano sul dispositivo finché non vengono cancellati dall'utente o finché l'app non viene rimossa. Sonic MD non conserva copie server dei dati."
                    )

                    Link(destination: privacyURL) {
                        Label("Apri la Privacy Policy online", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text("Ultimo aggiornamento: 8 settembre 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func section(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(text).foregroundStyle(.secondary)
        }
    }
}
