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
                    VStack(spacing: 0) {
                        if consentManager.privacyOptionsRequired {
                            Button {
                                Task { await consentManager.presentPrivacyOptions() }
                            } label: {
                                Label("Scelte privacy annunci", systemImage: "hand.raised")
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                            }
                            .buttonStyle(.plain)
                            .background(.ultraThinMaterial)
                        }

                        if consentManager.canRequestAds {
                            AdMobBannerView()
                                .frame(height: 60)
                                .background(.ultraThinMaterial)
                        }
                    }
                }
                .task {
                    await consentManager.gatherConsent()
                }
        }
    }
}
