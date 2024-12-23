// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class OpenFiftyTabsDebugOption: HiddenSetting {
    override var accessibilityIdentifier: String? { return "OpenFiftyTabsOption.Setting" }
    private weak var settingsDelegate: DebugSettingsDelegate?

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        /* Ecosia: Update Debug message
        return NSAttributedString(
            string: "Open 50 `mozilla.org` tabs ⚠️",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
        */
        return NSAttributedString(
            string: "Open 50 `ecosia.org` tabs ⚠️", 
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )

    }

    override func onClick(_ navigationController: UINavigationController?) {
        /* Ecosia: Update on click action
        settingsDelegate?.pressedOpenFiftyTabs()
        */
        // TODO Ecosia Upgrade: Do we need to upgate this using `settingsDelegate` too? (that's new, we used to only change the URL)
        guard let url = URL(string: "https://www.ecosia.org") else { return }
        let object = OpenTabNotificationObject(type: .debugOption(50, url))
        NotificationCenter.default.post(name: .OpenTabNotification, object: object)
    }
}
