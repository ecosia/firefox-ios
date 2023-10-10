// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NTPCustomizationCell: UICollectionViewCell, NotificationThemeable, ReusableCell {
    struct UX {
        static let buttonHeight: CGFloat = 40
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 12
        static let imageTitlePadding: CGFloat = 4
    }
    
    weak var delegate: NTPCustomizationCellDelegate?
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.localized(.customizeHomepage), for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.setImage(.init(named: ImageIdentifiers.settings)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.setInsets(forContentPadding: .init(top: UX.verticalInset, left: UX.horizontalInset, bottom: UX.verticalInset, right: UX.horizontalInset),
                         imageTitlePadding: UX.imageTitlePadding)
        button.addTarget(self, action: #selector(touchButtonAction), for: .touchUpInside)
        button.clipsToBounds = true
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        applyTheme()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        applyTheme()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.layer.cornerRadius = button.frame.height/2
    }
    
    private func setup() {
        contentView.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
            button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func applyTheme() {
        button.imageView?.tintColor = .theme.ecosia.secondaryButtonContent
        button.setTitleColor(.theme.ecosia.secondaryButtonContent, for: .normal)
        button.setBackgroundColor(.theme.ecosia.secondaryButtonBackground, forState: .normal)
        button.setBackgroundColor(.theme.ecosia.activeTransparentBackground, forState: .highlighted)
    }
    
    @objc func touchButtonAction() {
        delegate?.openNTPCustomizationSettings()
    }
}
