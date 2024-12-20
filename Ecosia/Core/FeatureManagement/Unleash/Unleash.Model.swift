import Foundation

extension Unleash {
    public struct Model: Codable {
        public var id = UUID()
        var toggles = Set<Toggle>()
        var updated = Date(timeIntervalSince1970: 0)
        var appVersion: String = ""
        var deviceRegion: String = ""
        public var etag: String = ""

        public subscript(_ name: Toggle.Name) -> Toggle? {
            toggles.first { $0.name == name.rawValue }
        }
    }

    public struct Toggle: Codable, Hashable {
        public enum Name: String {
            case apnConsent = "mob_ios_apn_consent_on_launch_rollout"
            case brazeIntegration = "mob_ios_braze_integration"
            case configTest = "mob_ios_staging_config"
            case seedCounterNTP = "mob_ios_seed_counter_ntp"
            case newsletterCard = "mob_ios_newsletter_card"
        }

        public let name: String
        public let enabled: Bool
        public let variant: Variant

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }

        public func hash(into: inout Hasher) {
            into.combine(name)
        }
    }

    public struct Variant: Codable {
        public let name: String
        public let enabled: Bool
        public let payload: Payload?
    }

    public struct Payload: Codable {
        public let type, value: String
    }

    struct FeatureResponse: Codable {
        let toggles: [Toggle]
    }
}
