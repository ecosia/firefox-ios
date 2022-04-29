/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class LogoCell: UICollectionViewCell, Themeable {

    private weak var logo: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        let logo = UIImageView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.clipsToBounds = true
        logo.contentMode = .scaleAspectFit
        contentView.addSubview(logo)
        self.logo = logo

        let bottom = logo.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -22)
        bottom.priority = .defaultHigh
        bottom.isActive = true

        let height = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        logo.topAnchor.constraint(equalTo: contentView.topAnchor, constant: (height/10)).isActive = true
        logo.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        logo.widthAnchor.constraint(equalToConstant: 144).isActive = true
        applyTheme()
    }

    func applyTheme() {
        logo.image = UIImage(themed: "ecosiaLogo")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
