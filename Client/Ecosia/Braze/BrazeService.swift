// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import BrazeKit
import BrazeUI
import Core

final class BrazeService {
    private init() {}

    private var braze: Braze?
    private var userId: String {
        User.shared.analyticsId.uuidString
    }
    private(set) var notificationAuthorizationStatus: UNAuthorizationStatus?
    private static var apiKey = EnvironmentFetcher.valueFromMainBundleOrProcessInfo(forKey: "BRAZE_API_KEY") ?? ""
    static let shared = BrazeService()

    enum Error: Swift.Error {
        case invalidConfiguration
        case generic(description: String)
    }

    enum CustomEvent: String {
        case newsletterCardClick = "newsletter_card_click"
    }

    // TODO: Make `BrazeService` directly `UNUserNotificationCenterDelegate`
    func initialize(notificationCenterDelegate: UNUserNotificationCenterDelegate) async {
        do {
            try await initBraze(userId: userId)
            await refreshAPNRegistrationIfNeeded(notificationCenterDelegate: notificationCenterDelegate)
        } catch {
            debugPrint(error)
        }
    }

    func registerDeviceToken(_ deviceToken: Data) {
        braze?.notifications.register(deviceToken: deviceToken)
        Task.detached(priority: .medium) { [weak self] in
            await self?.updateID(self?.userId)
        }
    }

    func logCustomEvent(_ event: CustomEvent) {
        self.braze?.logCustomEvent(name: event.rawValue)
    }

    // MARK: - APN Consent

    func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate) async throws -> Bool {
        await UIApplication.shared.registerForRemoteNotifications()
        let notificationCenter = makeNotificationCenter(notificationCenterDelegate: notificationCenterDelegate)
        let granted = try await notificationCenter.requestAuthorization()
        await retrieveUserCurrentNotificationAuthStatus() // Make sure status is always updated
        return granted
    }

    func refreshAPNRegistrationIfNeeded(notificationCenterDelegate: UNUserNotificationCenterDelegate) async {
        let notificationCenter = UNUserNotificationCenter.current()
        let currentStatus = await notificationCenter.notificationSettings().authorizationStatus
        switch currentStatus {
        case .authorized, .ephemeral, .provisional:
            _ = try? await requestAPNConsent(notificationCenterDelegate: notificationCenterDelegate)
        default:
            break
        }
    }
}

extension BrazeService {
    // MARK: - Init Braze

    @MainActor
    private func initBraze(userId: String) throws {
        self.braze = Braze(configuration: try getBrazeConfiguration())
        let inAppMessageUI = BrazeInAppMessageUI()
        self.braze?.inAppMessagePresenter = inAppMessageUI
        Task.detached(priority: .medium) { [weak self] in
            await self?.updateID(self?.userId)
        }
    }
}

extension BrazeService {
    // MARK: - Notification Center

    private func makeNotificationCenter(notificationCenterDelegate: UNUserNotificationCenterDelegate) -> UNUserNotificationCenter {
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories(BrazeKit.Braze.Notifications.categories)
        center.delegate = notificationCenterDelegate
        return center
    }

    private func retrieveUserCurrentNotificationAuthStatus() async {
        let notificationCenter = UNUserNotificationCenter.current()
        let currentStatus = await notificationCenter.notificationSettings().authorizationStatus
        notificationAuthorizationStatus = currentStatus
    }
}

extension BrazeService {
    // MARK: - ID Update

    private func updateID(_ id: String?) async {
        guard let id else { return }
        #if MOZ_CHANNEL_FENNEC
        print("📣🆔 Braze Identifier Updating To: \(id)")
        #endif
        let brazeID = await braze?.user.id()
        guard id != brazeID else { return }
        braze?.changeUser(userId: id)
    }
}

extension BrazeService {
    // MARK: - Environment Configuration

    /// Retrieves the Braze configuration based on the provided parameters.
    ///
    /// - Parameters:
    ///   - apiKey: The Braze API key to be used for configuration.
    ///   - environment: The target environment for which the Braze configuration is requested.
    ///                  Defaults to the current environment.
    /// - Returns: A Braze configuration if the required parameters are present.
    /// - Throws: An `Error.invalidConfiguration` if the API key is empty.
    ///
    /// - Note: The `environment` parameter allows customization of the target environment.
    ///   If not provided, it defaults to the current environment.
    ///
    /// - Warning: Ensure that the provided API key is not empty to avoid invalid configurations.
    func getBrazeConfiguration(apiKey: String = BrazeService.apiKey,
                               environment: Environment = Environment.current) throws -> BrazeKit.Braze.Configuration {
        guard !apiKey.isEmpty else { throw Error.invalidConfiguration }

        let brazeConfiguration = BrazeKit.Braze.Configuration(apiKey: apiKey, endpoint: environment.urlProvider.brazeEndpoint)
        #if MOZ_CHANNEL_FENNEC
        brazeConfiguration.logger.level = .debug
        #endif
        return brazeConfiguration
    }
}
