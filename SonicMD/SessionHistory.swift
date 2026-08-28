import SwiftUI

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let before: Int
    let after: Int
    let delta: Double
}

@MainActor
final class SessionStore: ObservableObject {
    static let shared = SessionStore()

    @Published private(set) var records: [SessionRecord] = []

    private let key = "sonicmd.sessionHistory"

    private init() {
        load()
    }

    func add(before: Int, after: Int, delta: Double) {
        let record = SessionRecord(
            id: UUID(),
            date: Date(),
            before: before,
            after: after,
            delta: delta
        )

        records.insert(record, at: 0)

        if records.count > 20 {
            records = Array(records.prefix(20))
        }

        save()
    }

    func clear() {
        records = []
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data)
        else {
            records = []
            return
        }

        records = decoded
    }
}

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = SessionStore.shared

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    ContentUnavailableView(
                        "Nessuna sessione",
                        systemImage: "waveform.path.ecg",
                        description: Text("Le sessioni complete appariranno qui.")
                    )
                } else {
                    List {
                        ForEach(store.records) { record in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(record.date, format: .dateTime.day().month().hour().minute())
                                        .font(.headline)

                                    Spacer()

                                    Text(String(format: "%+.1f%%", record.delta))
                                        .font(.subheadline.bold())
                                        .foregroundStyle(record.delta >= 0 ? .green : .orange)
                                }

                                HStack(spacing: 16) {
                                    Label("\(record.before)", systemImage: "circle.dashed")
                                    Label("\(record.after)", systemImage: "checkmark.circle")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Cronologia")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !store.records.isEmpty {
                        Button("Svuota", role: .destructive) {
                            store.clear()
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
}
