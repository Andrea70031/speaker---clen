import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency

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
            await finalizePrivacyAndAdsState()
            return
        }

        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required

        do {
            // This is the GDPR/Google consent form. It is not a substitute for Apple's ATT prompt.
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }

        await finalizePrivacyAndAdsState()
    }

    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }

        await finalizePrivacyAndAdsState()
    }

    private func finalizePrivacyAndAdsState() async {
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required

        guard ConsentInformation.shared.canRequestAds else {
            canRequestAds = false
            return
        }

        // ATT is the only permission request used for Apple-defined tracking.
        // If the user denies ATT, AdMob can still request ads without IDFA.
        await requestTrackingAuthorizationIfNeeded()

        canRequestAds = true

        guard !mobileAdsStarted else { return }
        mobileAdsStarted = true
        MobileAds.shared.start()
    }

    private func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        // Allow any UMP sheet to finish dismissing before presenting the system ATT alert.
        try? await Task.sleep(for: .milliseconds(450))

        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { _ in
                continuation.resume()
            }
        }
    }
}
