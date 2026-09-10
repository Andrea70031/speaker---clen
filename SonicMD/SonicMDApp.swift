import SwiftUI

@main
struct SonicMDApp: App {
    @StateObject private var engine = AcousticEngine()
    @StateObject private var consentManager = ConsentManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .environmentObject(consentManager)
                .safeAreaInset(edge: .bottom) {
                    if consentManager.canRequestAds {
                        AdMobBannerView()
                            .frame(height: 60)
                            .background(.ultraThinMaterial)
                    }
                }
                .task {
                    await consentManager.gatherConsent()
                }
        }
    }
}
