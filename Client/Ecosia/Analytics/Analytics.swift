import Foundation
import SnowplowTracker
import Core

final class Analytics {
    static let shared = Analytics()
    private let tracker: TrackerController

    private init() {
        tracker = Snowplow
            .createTracker(namespace: "ios_sp",
                           network: .init(endpoint: Environment.current.snowplow),
                           configurations: [TrackerConfiguration()
                                                .appId(Bundle.version)
                                                .platformContext(true)
                                                .geoLocationContext(true),
                                            SubjectConfiguration()
                                                .userId(User.shared.analyticsId.uuidString)])
    }
    
    func install() {
        SPSelfDescribingJson(schema: "iglu:org.ecosia/ios_install_event/jsonschema/1-0-0", andData: ["app_v": Bundle.version] as NSObject).map { data in
            tracker.track(SPUnstructured.build {
                $0.setEventData(data)
            })
        }
    }
    
    func activity(_ action: Action.Activity) {
        tracker.track(Structured.build {
            $0.setCategory(Category.activity.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("inapp")
        })
    }

    func browser(_ action: Action.Browser, label: Label.Browser, property: Property? = nil) {
        tracker.track(Structured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel(label.rawValue)
            $0.setProperty(property?.rawValue)
        })
    }

    func navigation(_ action: Action, label: Label.Navigation) {
        tracker.track(Structured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel(label.rawValue)
        })
    }

    func navigationOpenNews(_ id: String) {
        tracker.track(Structured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel(Label.Navigation.news.rawValue)
            $0.setProperty(id)
        })
    }
    
    func navigationChangeMarket(_ new: String) {
        tracker.track(Structured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction("change")
            $0.setLabel("market")
            $0.setProperty(new)
        })
    }

    func deeplink() {
        tracker.track(Structured.build {
            $0.setCategory(Category.external.rawValue)
            $0.setAction(Action.receive.rawValue)
            $0.setLabel("deeplink")
        })
    }
    
    func defaultBrowser() {
        tracker.track(Structured.build {
            $0.setCategory(Category.external.rawValue)
            $0.setAction(Action.receive.rawValue)
            $0.setLabel("default_browser_deeplink")
        })
    }
    
    func reset() {
        User.shared.analyticsId = .init()
        
        guard let subject = SPSubject(platformContext: true, andGeoContext: true) else { return }
        subject.setUserId(User.shared.analyticsId.uuidString)
        tracker.setSubject(subject)
    }
    
    func defaultBrowser(_ action: Action.Promo) {
        tracker.track(Structured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("default_browser_promo")
            $0.setProperty("home")
        })
    }

    func defaultBrowserSettings() {
        tracker.track(Structured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel("default_browser_settings")
        })
    }

    func migration(_ success: Bool) {
        tracker.track(Structured.build({
            $0.setCategory(Category.migration.rawValue)
            $0.setAction(success ? Action.success.rawValue : Action.error.rawValue)
        }))
    }

    func migrationError(in migration: Migration, message: String) {
        tracker.track(Structured.build {
            $0.setCategory(Category.migration.rawValue)
            $0.setAction(Action.error.rawValue)
            $0.setLabel(migration.rawValue)
            $0.setProperty(message)
        })
    }

    func migrationRetryHistory(_ success: Bool) {
        tracker.track(Structured.build({
            $0.setCategory(Category.migration.rawValue)
            $0.setAction(Action.retry.rawValue)
            $0.setLabel(Migration.history.rawValue)
            $0.setProperty(success ? Action.success.rawValue : Action.error.rawValue)
        }))
    }
    
    func migrated(_ migration: Migration, in seconds: TimeInterval) {
        tracker.track(Structured.build({
            $0.setCategory(Category.migration.rawValue)
            $0.setAction(Action.completed.rawValue)
            $0.setLabel(migration.rawValue)
            $0.setValue(seconds * 1000)
        }))
    }
    
    func open(topSite: Property.TopSite) {
        tracker.track(Structured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel("top_sites")
            $0.setProperty(topSite.rawValue)
        })
    }
}
