/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

final class CircleButton: ToolbarButton {
    enum Config {
        case search
        case newTab
        
        var image: String {
            switch self {
            case .search: return "search"
            case .newTab: return "nav-add"
            }
        }
        var shouldHideCircle: Bool {
            switch self {
            case .search: return false
            case .newTab: return true
            }
        }
        var accessibilityLabel: String {
            switch self {
            case .search: return .TabToolbarSearchAccessibilityLabel
            case .newTab: return .TabToolbarNewTabAccessibilityLabel
            }
        }
    }

    let circle = UIView()
    var config: Config = .search {
        didSet {
            setup()
        }
    }
    private var margin: CGFloat = 8

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    convenience init(config: Config, margin: CGFloat = 8) {
        self.init(frame: .zero)
        self.config = config
        self.margin = margin
        setup()
    }

    private func setup() {
        setImage(UIImage(named: config.image), for: .normal)
        circle.isUserInteractionEnabled = false
        addSubview(circle)
        sendSubviewToBack(circle)
        applyTheme()
        accessibilityLabel = config.accessibilityLabel
        accessibilityIdentifier = AccessibilityIdentifiers.Ecosia.TabToolbar.circleButton
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let height = bounds.height - margin
        circle.bounds = .init(size: .init(width: height, height: height))
        circle.layer.cornerRadius = circle.bounds.height / 2
        circle.center = .init(x: bounds.width/2, y: bounds.height/2)
        circle.isHidden = config.shouldHideCircle
    }

    override func applyTheme() {
        circle.backgroundColor = UIColor.theme.ecosia.tertiaryBackground
        tintColor = config.shouldHideCircle ? .theme.ecosia.primaryText : .theme.ecosia.primaryButton
        selectedTintColor = UIColor.theme.ecosia.primaryButtonActive
        unselectedTintColor = tintColor
    }
}
