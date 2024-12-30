// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

struct MockUNNotificationSettings: AnalyticsUNNotificationSettingsProtocol {
    var authorizationStatus: UNAuthorizationStatus
}

class MockAnalyticsUserNotificationCenter: AnalyticsUserNotificationCenterProtocol {
    private let mockSettings: AnalyticsUNNotificationSettingsProtocol

    init(mockSettings: AnalyticsUNNotificationSettingsProtocol) {
        self.mockSettings = mockSettings
    }

    func getNotificationSettingsProtocol(completionHandler: @escaping (AnalyticsUNNotificationSettingsProtocol) -> Void) {
        completionHandler(mockSettings)
    }
}
