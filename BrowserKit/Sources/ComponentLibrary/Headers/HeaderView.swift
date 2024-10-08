// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SiteImageView

public final class HeaderView: UIView, ThemeApplicable {
    private struct UX {
        static let headerLinesLimit: Int = 2
        static let siteDomainLabelsVerticalSpacing: CGFloat = 12
        static let largeFaviconImageSize: CGFloat = 48
        static let favIconImageSize: CGFloat = 32
        static let smallFaviconImageSize: CGFloat = 20
        static let maskFaviconImageSize: CGFloat = 32
        static let horizontalMargin: CGFloat = 16
        static let headerLabelDistance: CGFloat = 2
        static let separatorHeight: CGFloat = 1
        static let closeButtonSize: CGFloat = 30
    }

    public var closeButtonCallback: (() -> Void)?
    public var mainButtonCallback: (() -> Void)?

    private lazy var headerLabelsContainer: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = UX.headerLabelDistance
    }

    private var favicon: FaviconImageView = .build { favicon in
        favicon.manuallySetImage(
            UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysTemplate) ?? UIImage())
    }

    private let titleLabel: UILabel = .build { label in
        label.numberOfLines = UX.headerLinesLimit
        label.adjustsFontForContentSizeCategory = true
    }

    private let subtitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.numberOfLines = 2
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
    }

    private lazy var mainButton: UIButton = .build { button in
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(self.mainButtonTapped), for: .touchUpInside)
    }

    private var iconMask: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let horizontalLine: UIView = .build()

    private var viewConstraints: [NSLayoutConstraint] = []

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        headerLabelsContainer.addArrangedSubview(titleLabel)
        headerLabelsContainer.addArrangedSubview(subtitleLabel)
        addSubviews(mainButton, iconMask, favicon, headerLabelsContainer, closeButton, horizontalLine)
    }

    private func updateLayout(isAccessibilityCategory: Bool, isWebsiteIcon: Bool) {
        removeConstraints(constraints)
        favicon.removeConstraints(favicon.constraints)
        closeButton.removeConstraints(closeButton.constraints)
        iconMask.removeConstraints(iconMask.constraints)
        viewConstraints.removeAll()
        viewConstraints.append(contentsOf: [
            favicon.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: UX.horizontalMargin
            ),

            headerLabelsContainer.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.leadingAnchor.constraint(
                equalTo: favicon.trailingAnchor,
                constant: UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.trailingAnchor.constraint(
                equalTo: closeButton.leadingAnchor,
                constant: -UX.horizontalMargin
            ),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalMargin),

            horizontalLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: UX.separatorHeight),

            iconMask.centerXAnchor.constraint(equalTo: favicon.centerXAnchor),
            iconMask.centerYAnchor.constraint(equalTo: favicon.centerYAnchor),

            mainButton.leadingAnchor.constraint(equalTo: iconMask.leadingAnchor),
            mainButton.trailingAnchor.constraint(equalTo: headerLabelsContainer.trailingAnchor),
            mainButton.topAnchor.constraint(equalTo: headerLabelsContainer.topAnchor),
            mainButton.bottomAnchor.constraint(equalTo: headerLabelsContainer.bottomAnchor)
        ])
        let favIconSizes = isAccessibilityCategory ? UX.largeFaviconImageSize :
        isWebsiteIcon ? UX.favIconImageSize: UX.smallFaviconImageSize
        viewConstraints.append(favicon.heightAnchor.constraint(equalToConstant: favIconSizes))
        viewConstraints.append(favicon.widthAnchor.constraint(equalToConstant: favIconSizes))

        let closeButtonSizes = isAccessibilityCategory ? UX.largeFaviconImageSize : UX.closeButtonSize
        viewConstraints.append(closeButton.heightAnchor.constraint(equalToConstant: closeButtonSizes))
        viewConstraints.append(closeButton.widthAnchor.constraint(equalToConstant: closeButtonSizes))
        closeButton.layer.cornerRadius = 0.5 * closeButtonSizes

        let maskButtonSizes = isAccessibilityCategory ? UX.largeFaviconImageSize : UX.maskFaviconImageSize
        viewConstraints.append(iconMask.heightAnchor.constraint(equalToConstant: maskButtonSizes))
        viewConstraints.append(iconMask.widthAnchor.constraint(equalToConstant: maskButtonSizes))
        iconMask.layer.cornerRadius = 0.5 * maskButtonSizes

        if isAccessibilityCategory {
            viewConstraints.append(favicon.topAnchor.constraint(equalTo: headerLabelsContainer.topAnchor))
            viewConstraints.append(closeButton.topAnchor.constraint(equalTo: headerLabelsContainer.topAnchor))
        } else {
            viewConstraints.append(favicon.centerYAnchor.constraint(equalTo: centerYAnchor))
            viewConstraints.append(closeButton.centerYAnchor.constraint(equalTo: centerYAnchor))
        }
        NSLayoutConstraint.activate(viewConstraints)
    }

    public func setupAccessibility(closeButtonA11yLabel: String,
                                   closeButtonA11yId: String,
                                   mainButtonA11yLabel: String? = nil,
                                   mainButtonA11yId: String? = nil) {
        let closeButtonViewModel = CloseButtonViewModel(a11yLabel: closeButtonA11yLabel,
                                                        a11yIdentifier: closeButtonA11yId)
        closeButton.configure(viewModel: closeButtonViewModel)
        if let mainButtonA11yLabel, let mainButtonA11yId {
            titleLabel.isAccessibilityElement = false
            subtitleLabel.isAccessibilityElement = false
            mainButton.accessibilityIdentifier = mainButtonA11yId
            mainButton.accessibilityLabel = mainButtonA11yLabel
        } else {
            mainButton.isAccessibilityElement = false
        }
    }

    public func setupDetails(subtitle: String, title: String, icon: FaviconImageViewModel) {
        titleLabel.font = FXFontStyles.Regular.headline.scaledFont()
        favicon.setFavicon(icon)
        subtitleLabel.text = subtitle
        titleLabel.text = title
    }

    public func setupDetails(subtitle: String, title: String, icon: UIImage?) {
        titleLabel.font = FXFontStyles.Regular.body.scaledFont()
        if let icon { favicon.manuallySetImage(icon) }
        subtitleLabel.text = subtitle
        titleLabel.text = title
    }

    public func setIconTheme(with theme: Theme) {
        iconMask.backgroundColor = theme.colors.layer2
        favicon.tintColor = theme.colors.iconSecondary
    }

    func setTitle(with text: String) {
        titleLabel.text = text
    }

    public func adjustLayout(isWebsiteIcon: Bool = false) {
        updateLayout(isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory,
                     isWebsiteIcon: isWebsiteIcon)
    }

    public func updateHeaderLineView(isHidden: Bool) {
        if (isHidden && !horizontalLine.isHidden) || (!isHidden && horizontalLine.isHidden) {
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.horizontalLine.isHidden = isHidden
            }
        }
    }

    @objc
    func closeButtonTapped() {
        closeButtonCallback?()
    }

    @objc
    func mainButtonTapped() {
        mainButtonCallback?()
    }

    public func applyTheme(theme: Theme) {
        let buttonImage = UIImage(named: StandardImageIdentifiers.Medium.cross)?
            .withTintColor(theme.colors.iconSecondary)
        subtitleLabel.textColor = theme.colors.textSecondary
        titleLabel.textColor = theme.colors.textPrimary
        self.tintColor = theme.colors.layer2
        closeButton.setImage(buttonImage, for: .normal)
        closeButton.backgroundColor = theme.colors.layer2
        horizontalLine.backgroundColor = theme.colors.borderPrimary
    }
}
