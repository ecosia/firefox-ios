/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class EcosiaNavigation: UINavigationController, Themeable {

    convenience init(delegate: EcosiaHomeDelegate?, referrals: Referrals) {
        self.init(rootViewController: EcosiaHome(delegate: delegate, referrals: referrals))
        modalPresentationCapturesStatusBarAppearance = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.prefersLargeTitles = true
        NotificationCenter.default.addObserver(self, selector: #selector(displayThemeChanged), name: .DisplayThemeChanged, object: nil)
        applyTheme()
    }

    func applyTheme() {
        viewControllers.forEach { ($0 as? Themeable)?.applyTheme() }

        navigationBar.backgroundColor = UIColor.theme.ecosia.modalBackground
        navigationBar.tintColor = UIColor.theme.ecosia.primaryBrand
        navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.theme.ecosia.secondaryBrand
        ]
        navigationBar.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.theme.ecosia.secondaryBrand
        ]
    }

    @objc private func displayThemeChanged(notification: Notification) {
        applyTheme()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return ThemeManager.instance.current.isDark ? .lightContent : .darkContent
        } else {
            return ThemeManager.instance.current.isDark ? .lightContent : .default
        }
    }
}
