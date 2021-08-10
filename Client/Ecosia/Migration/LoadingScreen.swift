/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import UIKit
import Core

final class LoadingScreen: UIViewController {
    private weak var profile: Profile!
    private weak var tabManager: TabManager!
    private weak var progress: UIProgressView!
    
    required init?(coder: NSCoder) { nil }
    init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.theme.ecosia.primaryBackground

        let logo = UIImageView(image: UIImage(themed: "ecosiaLogo"))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.clipsToBounds = true
        logo.contentMode = .center
        view.addSubview(logo)
        
        let progress = UIProgressView()
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progressTintColor = UIColor.theme.ecosia.primaryBrand
        view.addSubview(progress)
        self.progress = progress
        
        let message = UILabel()
        message.translatesAutoresizingMaskIntoConstraints = false
        message.text = .localized(.sitTightWeAre)
        message.font = .preferredFont(forTextStyle: .footnote)
        message.numberOfLines = 0
        message.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        message.textColor = UIColor.theme.ecosia.primaryText
        message.textAlignment = .center
        view.addSubview(message)
        
        logo.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logo.bottomAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        progress.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        progress.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 24).isActive = true
        progress.widthAnchor.constraint(equalToConstant: 173).isActive = true
        progress.heightAnchor.constraint(equalToConstant: 3).isActive = true
        
        message.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        message.topAnchor.constraint(equalTo: progress.bottomAnchor, constant: 25).isActive = true
        message.widthAnchor.constraint(lessThanOrEqualToConstant: 280).isActive = true
        
        migrate()
    }

    private func migrate() {
        if User.shared.migrated != true {
            migrateHistory()
        } else if User.shared.migratedFavorites != true {
            migrateFavorites()
            progress.isHidden = true
        } else {
            dismiss(animated: true)
        }
    }

    private var backgroundTaskID: UIBackgroundTaskIdentifier?
    private func migrateHistory() {
        guard !skip() else { return }

        NSSetUncaughtExceptionHandler { exception in
            EcosiaImport.Exception(reason: exception.reason ?? "Unknown").save()
        }

        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "Migration", expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID!)
            self.backgroundTaskID = .invalid
            // force shutting down profile to avoid crash by system
            self.profile._shutdown(force: true)
        })

        let ecosiaImport = EcosiaImport(profile: profile)
        ecosiaImport.migrateHistory(progress: { [weak self] progress in
            self?.progress.setProgress(.init(progress), animated: true)
        }){ [weak self] result in
            if case .succeeded = result {
                Analytics.shared.migration(true)
                self?.cleanUp()
                self?.dismiss(animated: true)
            } else {
                Analytics.shared.migration(false)
                self?.showError()
            }
            
            Core.User.shared.migrated = true
            Core.User.shared.migratedFavorites = true
            NSSetUncaughtExceptionHandler(nil)

            if let id = self?.backgroundTaskID {
                UIApplication.shared.endBackgroundTask(id)
            }

            if UIApplication.shared.applicationState != .active {
                self?.profile._shutdown(force: true)
            }
        }
    }

    private func migrateFavorites() {
        guard !skip() else { return }

        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "Migration", expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID!)
            self.backgroundTaskID = .invalid
            // force shutting down profile to avoid crash by system
            if UIApplication.shared.applicationState != .active {
                self.profile._shutdown(force: true)
            }
        })

        let ecosiaImport = EcosiaImport(profile: profile)
        ecosiaImport.migrateFavourites { [weak self] result in
            switch result {
            case .succeeded:
                self?.dismiss(animated: true)
            case .failed:
                self?.showError()
            }
            Core.User.shared.migratedFavorites = true
            Core.User.shared.migrated = true

            if let id = self?.backgroundTaskID {
                UIApplication.shared.endBackgroundTask(id)
            }

            if UIApplication.shared.applicationState != .active {
                self?.profile._shutdown(force: true)
            }
        }
    }

    private func skip() -> Bool {
        if let exception = EcosiaImport.Exception.load() {
            Analytics.shared.migrationError(in: .exception, message: exception.reason)
            Core.User.shared.migratedFavorites = true
            Core.User.shared.migrated = true
            EcosiaImport.Exception.clear()
            cleanUp()

            DispatchQueue.main.async { [weak self] in
                self?.showError()
            }
            return true
        }
        return false
    }
    
    private func showError() {
        let alert = UIAlertController(title: .localized(.weHitAGlitch),
                                      message: .localized(.weAreMomentarilyUnable),
                                      preferredStyle: .alert)
        alert.addAction(.init(title: .localized(.continueMessage), style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func cleanUp() {
        History().deleteAll()
        Tabs().clear()
    }
}
