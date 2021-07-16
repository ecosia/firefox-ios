/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class EmptyCell: UICollectionViewCell, Themeable {
    func applyTheme() {
        contentView.backgroundColor = UIColor.theme.ecosia.primaryBackground
        contentView.backgroundColor = .systemRed
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
