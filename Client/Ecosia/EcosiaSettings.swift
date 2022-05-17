/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import Shared

private var disclosureIndicator: UIImageView {
    let config = UIImage.SymbolConfiguration(pointSize: 16)
    let disclosureIndicator = UIImageView(image: .init(systemName: "chevron.right", withConfiguration: config))
    disclosureIndicator.contentMode = .center
    disclosureIndicator.tintColor = UIColor.theme.tableView.accessoryViewTint
    disclosureIndicator.sizeToFit()
    return disclosureIndicator
}

class SearchAreaSetting: Setting {
    override var accessoryView: UIImageView? { return disclosureIndicator }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString { return NSAttributedString(string: Markets.current ?? "") }

    override var accessibilityIdentifier: String? { return .localized(.searchRegion) }

    init(settings: SettingsTableViewController) {
        super.init(title: NSAttributedString(string: .localized(.searchRegion), attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(MarketsController(style: .insetGrouped), animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        cell.detailTextLabel?.numberOfLines = 2
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.minimumScaleFactor = 0.8
        cell.detailTextLabel?.allowsDefaultTighteningForTruncation = true
        cell.textLabel?.numberOfLines = 2
    }
}

class SafeSearchSettings: Setting {
    override var accessoryView: UIImageView? { return disclosureIndicator }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString { return NSAttributedString(string: FilterController.current ?? "") }

    override var accessibilityIdentifier: String? { return .localized(.searchRegion) }

    init(settings: SettingsTableViewController) {
        super.init(title: NSAttributedString(string: .localized(.safeSearch), attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(FilterController(), animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        cell.detailTextLabel?.numberOfLines = 2
        cell.textLabel?.numberOfLines = 2
    }
}

class AutoCompleteSettings: BoolSetting {
    convenience init(prefs: Prefs) {
        self.init(prefs: prefs, prefKey: "", defaultValue: true,
                titleText: .localized(.autocomplete),
                statusText: .localized(.shownUnderSearchField), settingDidChange: { value in

                    User.shared.autoComplete = value

                })
    }

    override func displayBool(_ control: UISwitch) {
        control.isOn = User.shared.autoComplete
    }

    override func writeBool(_ control: UISwitch) {
        User.shared.autoComplete = control.isOn
    }
}

class PersonalSearchSettings: BoolSetting {
    convenience init(prefs: Prefs) {
        self.init(prefs: prefs, prefKey: "", defaultValue: false,
                titleText: .localized(.personalizedResults),
                statusText: .localized(.relevantResults), settingDidChange: { value in

                    User.shared.personalized = value

                })
    }

    override func displayBool(_ control: UISwitch) {
        control.isOn = User.shared.personalized ?? false
    }

    override func writeBool(_ control: UISwitch) {
        User.shared.personalized = control.isOn
    }
}

class EcosiaPrivacyPolicySetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .localized(.privacy), attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var url: URL? {
        return Environment.current.privacy
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
        Analytics.shared.navigation(.open, label: .privacy)
    }
}

class EcosiaSendFeedbackSetting: Setting {
    private var device: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    private var mailURL: String {
        """
        mailto:iosapp@ecosia.org?subject=\
        iOS%20App%20Feedback%20-\
        %20Version_\(Bundle.version)\
        %20iOS_\(UIDevice.current.systemVersion)\
        %20\(device)
        """
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: .localized(.sendFeedback), attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        _ = URL(string: mailURL).map {
            UIApplication.shared.open($0, options: [:], completionHandler: nil)
        }
        Analytics.shared.navigation(.open, label: .sendFeedback)
    }
}

class EcosiaTermsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .localized(.terms), attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var url: URL? {
        return Environment.current.terms
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
        Analytics.shared.navigation(.open, label: .terms)
    }
}
