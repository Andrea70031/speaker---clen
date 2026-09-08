import SwiftUI
import GoogleMobileAds

@main
struct SonicMDApp: App {
    @StateObject private var engine = AcousticEngine()

    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .safeAreaInset(edge: .bottom) {
                    AdMobBannerView()
                        .frame(height: 60)
                        .background(.ultraThinMaterial)
                }
        }
    }
}
