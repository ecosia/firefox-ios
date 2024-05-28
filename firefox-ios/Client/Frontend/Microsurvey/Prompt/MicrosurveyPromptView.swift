// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import ComponentLibrary
import Redux

/*
 |----------------|
 | [Logo] Title X |
 |----------------|
 |    [Button]    |
 |----------------|
 */

class MicrosurveyPromptView: UIView, ThemeApplicable, Notifiable {
    private struct UX {
        static let headerStackSpacing: CGFloat = 8
        static let stackSpacing: CGFloat = 17
        static let closeButtonSize = CGSize(width: 30, height: 30)
        static let logoSize = CGSize(width: 24, height: 24)
        static let logoLargeSize = CGSize(width: 48, height: 48)
        static let padding = NSDirectionalEdgeInsets(
            top: 14,
            leading: 16,
            bottom: -12,
            trailing: -16
        )
        static let mediumPadding = NSDirectionalEdgeInsets(
            top: 16,
            leading: 66,
            bottom: -16,
            trailing: -66
        )
        static let largePadding = NSDirectionalEdgeInsets(
            top: 22,
            leading: 258,
            bottom: -22,
            trailing: -258
        )
    }

    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var logoWidthConstraint: NSLayoutConstraint?
    private var logoHeightConstraint: NSLayoutConstraint?

    private let windowUUID: WindowUUID
    var notificationCenter: NotificationProtocol

    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        imageView.contentMode = .scaleAspectFit
    }

    private var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
    }

    private lazy var closeButton: UIButton = .build { button in
        button.accessibilityLabel = .Microsurvey.Prompt.CloseButtonAccessibilityLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.Microsurvey.Prompt.closeButton
        button.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        button.addTarget(self, action: #selector(self.closeMicroSurvey), for: .touchUpInside)
    }

    private lazy var headerView: UIStackView = .build { stack in
        stack.distribution = .fillProportionally
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = UX.headerStackSpacing
    }

    private lazy var surveyButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.openMicroSurvey), for: .touchUpInside)
    }

    private lazy var toastView: UIStackView = .build { stack in
        stack.spacing = UX.stackSpacing
        stack.distribution = .fillProportionally
        stack.axis = .vertical
    }

    @objc
    func closeMicroSurvey() {
        store.dispatch(
            MicrosurveyPromptAction(windowUUID: windowUUID, actionType: MicrosurveyPromptActionType.closePrompt)
        )
    }

    @objc
    func openMicroSurvey() {
        store.dispatch(
            MicrosurveyPromptAction(windowUUID: windowUUID, actionType: MicrosurveyPromptActionType.continueToSurvey)
        )
    }

    init(
        state: MicrosurveyPromptState,
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        super.init(frame: .zero)
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        configure(with: state)
        setupView()
    }

    private func configure(with state: MicrosurveyPromptState) {
        titleLabel.text = state.model?.promptTitle
        // TODO: FXIOS-8990 - Mobile Messaging Structure - Should use MicrosurveyModel instead of State
        let roundedButtonViewModel = PrimaryRoundedButtonViewModel(
            title: state.model?.promptButtonLabel ?? "",
            a11yIdentifier: AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton
        )
        surveyButton.configure(viewModel: roundedButtonViewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        headerView.addArrangedSubview(logoImage)
        headerView.addArrangedSubview(titleLabel)
        headerView.addArrangedSubview(closeButton)

        toastView.addArrangedSubview(headerView)
        toastView.addArrangedSubview(surveyButton)

        addSubview(toastView)
        leadingConstraint = toastView.leadingAnchor.constraint(equalTo: leadingAnchor)
        trailingConstraint = toastView.trailingAnchor.constraint(equalTo: trailingAnchor)
        logoWidthConstraint = logoImage.widthAnchor.constraint(equalToConstant: UX.logoSize.width)
        logoHeightConstraint = logoImage.heightAnchor.constraint(equalToConstant: UX.logoSize.height)

        leadingConstraint?.isActive = true
        trailingConstraint?.isActive = true
        logoWidthConstraint?.isActive = true
        logoHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            toastView.topAnchor.constraint(equalTo: topAnchor, constant: UX.padding.top),
            toastView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: UX.padding.bottom),
            titleLabel.heightAnchor.constraint(equalTo: headerView.heightAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),
        ])
    }

    override func updateConstraints() {
        super.updateConstraints()
        updatePadding()
    }

    private func updatePadding() {
        var paddingConstant: NSDirectionalEdgeInsets = UX.padding

        if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
            paddingConstant = UIWindow.isLandscape ? UX.largePadding : UX.mediumPadding
        } else if UIDevice.current.userInterfaceIdiom == .phone && UIWindow.isLandscape {
            paddingConstant = UX.mediumPadding
        }

        leadingConstraint?.constant = paddingConstant.leading
        trailingConstraint?.constant = paddingConstant.trailing
    }

    private func adjustIconSize() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        let logoSize = contentSizeCategory.isAccessibilityCategory ? UX.logoLargeSize : UX.logoSize
        logoWidthConstraint?.constant = logoSize.width
        logoHeightConstraint?.constant = logoSize.height
    }

    // MARK: ThemeApplicable
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
        closeButton.tintColor = theme.colors.textSecondary
        surveyButton.applyTheme(theme: theme)
    }

    // MARK: Notifiable
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustIconSize()
        default: break
        }
    }
}
