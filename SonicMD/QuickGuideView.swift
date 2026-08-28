import SwiftUI

struct QuickGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Come ottenere un confronto migliore")
                        .font(.largeTitle.bold())

                    guideStep(
                        number: "1",
                        title: "Togli la custodia",
                        text: "Per un confronto più stabile, usa il telefono senza custodie che coprono o modificano l'uscita audio."
                    )

                    guideStep(
                        number: "2",
                        title: "Ambiente silenzioso",
                        text: "Riduci musica, TV e conversazioni vicine durante le misure Prima e Dopo."
                    )

                    guideStep(
                        number: "3",
                        title: "Non spostare l'iPhone",
                        text: "Mantieni posizione e orientamento il più possibile identici tra le due misure."
                    )

                    guideStep(
                        number: "4",
                        title: "Usa Guided Clean",
                        text: "Per il test più semplice esegui il ciclo completo: Smart Scan, Adaptive Clean e verifica finale."
                    )

                    Text("I risultati sono comparativi e non costituiscono una diagnosi hardware certificata.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Guida rapida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }

    private func guideStep(
        number: String,
        title: String,
        text: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.headline)
                .frame(width: 34, height: 34)
                .background(.blue.opacity(0.12), in: Circle())
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
