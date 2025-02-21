// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Storage
// Ecosia: Import Core
import Core

/// Each scene has it's own scene coordinator, which is the root coordinator for a scene.
class SceneCoordinator: BaseCoordinator, LaunchCoordinatorDelegate, LaunchFinishedLoadingDelegate {
    var window: UIWindow?
    let windowUUID: WindowUUID
    private let screenshotService: ScreenshotService
    private let sceneContainer: SceneContainer
    private let windowManager: WindowManager

    init(scene: UIScene,
         sceneSetupHelper: SceneSetupHelper = SceneSetupHelper(),
         screenshotService: ScreenshotService = ScreenshotService(),
         sceneContainer: SceneContainer = SceneContainer(),
         windowManager: WindowManager = AppContainer.shared.resolve()) {
        self.window = sceneSetupHelper.configureWindowFor(scene, screenshotServiceDelegate: screenshotService)
        self.screenshotService = screenshotService
        self.sceneContainer = sceneContainer
        self.windowManager = windowManager
        self.windowUUID = windowManager.nextAvailableWindowUUID()

        let navigationController = sceneSetupHelper.createNavigationController()
        let router = DefaultRouter(navigationController: navigationController)
        super.init(router: router)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    func start() {
        router.setRootViewController(sceneContainer, hideBar: true)

        let launchScreenVC = LaunchScreenViewController(coordinator: self)
        router.push(launchScreenVC, animated: false)
    }

    override func canHandle(route: Route) -> Bool {
        switch route {
        case .action(action: .showIntroOnboarding):
            return canShowIntroOnboarding()
        default:
            return false
        }
    }

    override func handle(route: Route) {
        switch route {
        case .action(action: .showIntroOnboarding):
            showIntroOnboardingIfNeeded()
        default:
            break
        }
    }

    private func canShowIntroOnboarding() -> Bool {
        let profile: Profile = AppContainer.shared.resolve()
        let introManager = IntroScreenManager(prefs: profile.prefs)
        let launchType = LaunchType.intro(manager: introManager)
        return launchType.canLaunch(fromType: .SceneCoordinator)
    }

    private func showIntroOnboardingIfNeeded() {
        let profile: Profile = AppContainer.shared.resolve()
        let introManager = IntroScreenManager(prefs: profile.prefs)
        let launchType = LaunchType.intro(manager: introManager)
        // Ecosia: custom onboarding
        // if launchType.canLaunch(fromType: .SceneCoordinator) {
        if launchType.canLaunch(fromType: .SceneCoordinator),
           User.shared.firstTime {
            startLaunch(with: launchType)
        }
    }

    // MARK: - LaunchFinishedLoadingDelegate

    func launchWith(launchType: LaunchType) {
        guard launchType.canLaunch(fromType: .SceneCoordinator) else {
            startBrowser(with: launchType)
            return
        }

        startLaunch(with: launchType)
    }

    func launchBrowser() {
        startBrowser(with: nil)
    }

    // MARK: - Helper methods

    private func startLaunch(with launchType: LaunchType) {
        logger.log("Launching with launchtype \(launchType)",
                   level: .info,
                   category: .coordinator)

        let launchCoordinator = LaunchCoordinator(router: router)
        launchCoordinator.parentCoordinator = self
        add(child: launchCoordinator)
        launchCoordinator.start(with: launchType)
    }

    private func startBrowser(with launchType: LaunchType?) {
        guard !childCoordinators.contains(where: { $0 is BrowserCoordinator }) else { return }

        logger.log("Starting browser with launchtype \(String(describing: launchType))",
                   level: .info,
                   category: .coordinator)

        let browserCoordinator = BrowserCoordinator(router: router,
                                                    screenshotService: screenshotService,
                                                    tabManager: createWindowTabManager(for: windowUUID))
        add(child: browserCoordinator)
        browserCoordinator.start(with: launchType)

        if let savedRoute {
            browserCoordinator.findAndHandle(route: savedRoute)
        }
    }

    private func createWindowTabManager(for windowUUID: WindowUUID) -> TabManager {
        let profile: Profile = AppContainer.shared.resolve()
        let imageStore = defaultDiskImageStoreForSceneTabManager()
        return TabManagerImplementation(profile: profile, imageStore: imageStore, uuid: windowUUID)
    }

    private func defaultDiskImageStoreForSceneTabManager() -> DefaultDiskImageStore {
        let profile: Profile = AppContainer.shared.resolve()
        // TODO: [FXIOS-7885] Once iPad multi-window enabled each TabManager will likely share same default image store.
        return DefaultDiskImageStore(files: profile.files,
                                     namespace: "TabManagerScreenshots",
                                     quality: UIConstants.ScreenshotQuality)
    }

    // MARK: - LaunchCoordinatorDelegate

    func didFinishLaunch(from coordinator: LaunchCoordinator) {
        router.dismiss(animated: true)
        remove(child: coordinator)
        startBrowser(with: nil)
    }
}
