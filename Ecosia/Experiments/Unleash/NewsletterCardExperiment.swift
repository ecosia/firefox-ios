// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct NewsletterCardExperiment {
    private init() {}

    public static var isEnabled: Bool {
        Unleash.isEnabled(.newsletterCard)
    }

    public static var shouldShowCard: Bool {
        isEnabled && !isDismissed
    }

    /// Send onboarding card view analytics event, but just the first time it's called.
    public static func trackExperimentImpression() {
        let trackExperimentImpressionKey = "newsletterCardExperimentImpression"
        guard !UserDefaults.standard.bool(forKey: trackExperimentImpressionKey) else {
            return
        }
        Analytics.shared.newsletterCardExperiment(action: .view)
        UserDefaults.standard.setValue(true, forKey: trackExperimentImpressionKey)
    }

    // MARK: Dismissed
    private static let dismissedKey = "newsletterCardExperimentDismissed"

    public static var isDismissed: Bool {
        UserDefaults.standard.bool(forKey: dismissedKey)
    }

    public static func setDismissed() {
        UserDefaults.standard.set(true, forKey: dismissedKey)
    }

    /// Should only be used in Debug!
    public static func unsetDismissed() {
        UserDefaults.standard.removeObject(forKey: dismissedKey)
    }
}
