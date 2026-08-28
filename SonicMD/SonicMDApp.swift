import SwiftUI

@main
struct SonicMDApp: App {
    @StateObject private var engine = AcousticEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
        }
    }
}
