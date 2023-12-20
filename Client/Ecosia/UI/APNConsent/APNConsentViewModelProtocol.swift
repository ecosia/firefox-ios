// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - APNConsentViewModelProtocol

/// Protocol defining the properties required for an APN consent view model.
protocol APNConsentViewModelProtocol {
    var listItems: [APNConsentListItem] { get }
    var title: String { get }
    var image: UIImage? { get }
    var ctaAllowButtonTitle: String { get }
    var skipButtonTitle: String { get }
}

extension APNConsentViewModelProtocol {
    
    // MARK: Default values for optional properties
    
    /// Default implementation for the CTA (Call to Action) allow button title.
    var ctaAllowButtonTitle: String {
        .localized(.apnConsentCTAAllowButtonTitle)
    }
    
    /// Default implementation for the skip button title.
    var skipButtonTitle: String {
        .localized(.apnConsentSkipButtonTitle)
    }
}
