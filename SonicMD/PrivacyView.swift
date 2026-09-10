import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    private let privacyURL = URL(string: "https://oneassistantai.com/sonic-md/privacy")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Privacy").font(.largeTitle.bold())
                    Text("Sonic MD elabora localmente sul dispositivo le funzioni acustiche principali e non richiede un account.")

                    section(
                        title: "Microfono",
                        text: "Il microfono viene usato durante Smart Scan e le verifiche acustiche. I campioni audio vengono elaborati in memoria sul dispositivo e non vengono caricati o inviati a server esterni."
                    )
                    section(
                        title: "Cronologia",
                        text: "La cronologia delle sessioni contiene soltanto data, indice prima/dopo e variazione percentuale. È salvata localmente sul dispositivo e può essere cancellata dalla schermata Cronologia."
                    )
                    section(
                        title: "Pubblicità e servizi di terze parti",
                        text: "Sonic MD utilizza Google AdMob per mostrare annunci. Google e i suoi partner possono trattare dati tecnici, identificativi del dispositivo, posizione approssimativa, dati di utilizzo, pubblicitari, prestazioni e diagnostica secondo le scelte privacy dell'utente e la normativa applicabile."
                    )
                    section(
                        title: "Consenso e scelte privacy",
                        text: "Quando richiesto, Sonic MD mostra il modulo di consenso Google UMP prima di richiedere annunci. Le scelte relative alla pubblicità possono essere modificate tramite l'opzione privacy mostrata nell'app quando prevista."
                    )
                    section(
                        title: "Conservazione e cancellazione",
                        text: "I dati audio e la cronologia locale non vengono conservati sui server di Sonic MD. I dati locali restano sul dispositivo finché non vengono cancellati dall'utente o finché l'app non viene rimossa."
                    )

                    Link(destination: privacyURL) {
                        Label("Apri la Privacy Policy online", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text("Ultimo aggiornamento: 10 settembre 2026")
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
