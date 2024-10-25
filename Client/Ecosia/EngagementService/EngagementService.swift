import Foundation
import Core

final class ClientEngagementService {
    
    private init() {}
    
    static let shared = ClientEngagementService()
    private let service  = EngagementService(provider: Braze())
    private var parameters: [String: Any] = [:]
    private(set) var notificationAuthorizationStatus: UNAuthorizationStatus?
    
    var identifier: String? {
        parameters["id"] as? String
    }
    
    func initialize(parameters: [String: Any]) async {
        do {
            try service.initialize(parameters: parameters)
            self.parameters = parameters
            await retrieveUserCurrentNotificationAuthStatus()
        } catch {
            debugPrint(error)
        }
    }
    
    func registerDeviceToken(_ deviceToken: Data) {
        service.registerDeviceToken(deviceToken)
    }
    
    func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate,
                           completionHandler: @escaping (Bool, Swift.Error?) -> Void) {
        service.provider.requestAPNConsent(notificationCenterDelegate: notificationCenterDelegate, 
                                           completionHandler: completionHandler)
    }
    
    func requestAPNConsent(notificationCenterDelegate: UNUserNotificationCenterDelegate) async throws -> Bool {
        try await service.requestAPNConsent(notificationCenterDelegate: notificationCenterDelegate)
    }
    
    public func refreshAPNRegistrationIfNeeded(notificationCenterDelegate: UNUserNotificationCenterDelegate) async {
        await service.refreshAPNRegistrationIfNeeded(notificationCenterDelegate: notificationCenterDelegate)
    }
}

// MARK: - Helpers

extension ClientEngagementService {
    
    func initializeAndRefreshNotificationRegistration(notificationCenterDelegate: UNUserNotificationCenterDelegate) async {
        await initialize(parameters: ["id": User.shared.analyticsId.uuidString])
        await refreshAPNRegistrationIfNeeded(notificationCenterDelegate: notificationCenterDelegate)
    }
    
    func retrieveUserCurrentNotificationAuthStatus() async {
        let notificationCenter = UNUserNotificationCenter.current()
        let currentSettings = await notificationCenter.notificationSettings()
        notificationAuthorizationStatus = currentSettings.authorizationStatus
    }
}
