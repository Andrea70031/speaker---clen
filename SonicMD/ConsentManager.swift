import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform

@MainActor
final class ConsentManager: ObservableObject {
    @Published private(set) var canRequestAds = false
    @Published private(set) var privacyOptionsRequired = false
    @Published private(set) var lastErrorMessage: String?

    private var mobileAdsStarted = false

    func gatherConsent() async {
        let parameters = RequestParameters()

        let requestError: Error? = await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                continuation.resume(returning: error)
            }
        }

        if let requestError {
            lastErrorMessage = requestError.localizedDescription
            refreshAdState()
            return
        }

        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required

        do {
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }

        refreshAdState()
    }

    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }

        refreshAdState()
    }

    private func refreshAdState() {
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        canRequestAds = ConsentInformation.shared.canRequestAds

        guard canRequestAds, !mobileAdsStarted else { return }
        mobileAdsStarted = true
        MobileAds.shared.start()
    }
}
