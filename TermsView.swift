import SwiftUI

struct TermsView: View {
    let requiredAcceptance: Bool
    let onAccept: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var accepted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Termini di utilizzo e sicurezza")
                        .font(.largeTitle.bold())

                    Text("Sonic MD genera segnali audio e utilizza il microfono per confrontare la risposta acustica locale.")
                    Text("Le funzioni di pulizia non garantiscono la rimozione di acqua, polvere o altri contaminanti.")
                    Text("Non tenere il dispositivo vicino all’orecchio. Interrompi in caso di distorsioni o vibrazioni anomale.")
                    Text("Gli indici sono comparativi e non costituiscono una diagnosi hardware certificata.")
                    Text("L’audio del microfono viene elaborato localmente in questa build.")

                    if requiredAcceptance {
                        Toggle(
                            "Ho letto e accetto i Termini e le indicazioni di sicurezza.",
                            isOn: $accepted
                        )

                        Button("Accetta e continua") {
                            onAccept()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!accepted)
                    }
                }
                .padding()
            }
            .toolbar {
                if !requiredAcceptance {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Chiudi") { dismiss() }
                    }
                }
            }
        }
        .interactiveDismissDisabled(requiredAcceptance)
    }
}
