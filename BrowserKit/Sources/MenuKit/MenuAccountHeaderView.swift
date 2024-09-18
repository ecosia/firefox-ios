// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

final class MenuAccountHeaderView: UIView, ThemeApplicable {
    // MARK: - UI Elements

    // MARK: - Properties

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupView() {
        NSLayoutConstraint.activate([
        ])
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer3
    }
}
