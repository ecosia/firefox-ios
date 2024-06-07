// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class LocationView: UIView, UITextFieldDelegate, ThemeApplicable {
    // MARK: - Properties
    private enum UX {
        static let horizontalSpace: CGFloat = 8
        static let gradientViewWidth: CGFloat = 40
        static let searchEngineImageViewCornerRadius: CGFloat = 4
        static let lockIconImageViewSize = CGSize(width: 20, height: 20)
        static let searchEngineImageViewSize = CGSize(width: 24, height: 24)
    }

    private var urlAbsolutePath: String?
    private var searchTerm: String?
    private var notifyTextChanged: (() -> Void)?
    private var onTapLockIcon: (() -> Void)?
    private var locationViewDelegate: LocationViewDelegate?

    private var isURLTextFieldEmpty: Bool {
        urlTextField.text?.isEmpty == true
    }

    private var doesURLTextFieldExceedViewWidth: Bool {
        guard let text = urlTextField.text, let font = urlTextField.font else {
            return false
        }
        let locationViewWidth = frame.width - (UX.horizontalSpace * 2)
        let fontAttributes = [NSAttributedString.Key.font: font]
        let urlTextFieldWidth = text.size(withAttributes: fontAttributes).width
        return urlTextFieldWidth >= locationViewWidth
    }

    private var dotWidth: CGFloat {
        guard let font = urlTextField.font else { return 0 }
        let fontAttributes = [NSAttributedString.Key.font: font]
        let width = "...".size(withAttributes: fontAttributes).width
        return CGFloat(width)
    }

    private lazy var urlTextFieldSubdomainColor: UIColor = .clear
    private lazy var gradientLayer = CAGradientLayer()
    private lazy var gradientView: UIView = .build()

    private var clearButtonWidthConstraint: NSLayoutConstraint?
    private var urlTextFieldLeadingConstraint: NSLayoutConstraint?

    private lazy var iconContainerStackView: UIStackView = .build { view in
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
    }

    private lazy var searchEngineContentView: UIView = .build()

    private lazy var searchEngineImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = UX.searchEngineImageViewCornerRadius
        imageView.isAccessibilityElement = true
    }

    private lazy var lockIconButton: UIButton = .build { button in
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(self.didTapLockIcon), for: .touchUpInside)
    }

    private lazy var urlTextField: LocationTextField = .build { [self] urlTextField in
        urlTextField.backgroundColor = .clear
        urlTextField.font = FXFontStyles.Regular.body.scaledFont()
        urlTextField.adjustsFontForContentSizeCategory = true
        urlTextField.delegate = self
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
        setupGradientLayer()

        urlTextField.addTarget(self, action: #selector(LocationView.textDidChange), for: .editingChanged)
        notifyTextChanged = { [self] in
            guard urlTextField.isEditing else { return }

            urlTextField.text = urlTextField.text?.lowercased()
            urlAbsolutePath = urlTextField.text
            locationViewDelegate?.locationViewDidEnterText(urlTextField.text ?? "")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return urlTextField.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return urlTextField.resignFirstResponder()
    }

    func configure(_ state: LocationViewState, delegate: LocationViewDelegate) {
        searchEngineImageView.image = state.searchEngineImage
        configureLockIconButton(state)
        configureURLTextField(state)
        configureA11y(state)
        formatAndTruncateURLTextField()
        updateIconContainer()
        locationViewDelegate = delegate
        searchTerm = state.searchTerm
    }

    // MARK: - Layout
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        DispatchQueue.main.async { [self] in
            formatAndTruncateURLTextField()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradient()
        updateURLTextFieldLeadingConstraintBasedOnState()
    }

    private func setupLayout() {
        addSubviews(urlTextField, iconContainerStackView, gradientView)
        searchEngineContentView.addSubview(searchEngineImageView)
        iconContainerStackView.addArrangedSubview(searchEngineContentView)

        urlTextFieldLeadingConstraint = urlTextField.leadingAnchor.constraint(
            equalTo: iconContainerStackView.trailingAnchor)
        urlTextFieldLeadingConstraint?.isActive = true

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: urlTextField.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: urlTextField.bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: iconContainerStackView.trailingAnchor),
            gradientView.widthAnchor.constraint(equalToConstant: UX.gradientViewWidth),

            urlTextField.topAnchor.constraint(equalTo: topAnchor),
            urlTextField.bottomAnchor.constraint(equalTo: bottomAnchor),
            urlTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalSpace),

            searchEngineImageView.heightAnchor.constraint(equalToConstant: UX.searchEngineImageViewSize.height),
            searchEngineImageView.widthAnchor.constraint(equalToConstant: UX.searchEngineImageViewSize.width),
            searchEngineImageView.leadingAnchor.constraint(equalTo: searchEngineContentView.leadingAnchor),
            searchEngineImageView.trailingAnchor.constraint(equalTo: searchEngineContentView.trailingAnchor),
            searchEngineImageView.topAnchor.constraint(greaterThanOrEqualTo: searchEngineContentView.topAnchor),
            searchEngineImageView.bottomAnchor.constraint(lessThanOrEqualTo: searchEngineContentView.bottomAnchor),
            searchEngineImageView.centerXAnchor.constraint(equalTo: searchEngineContentView.centerXAnchor),
            searchEngineImageView.centerYAnchor.constraint(equalTo: searchEngineContentView.centerYAnchor),

            lockIconButton.heightAnchor.constraint(equalToConstant: UX.lockIconImageViewSize.height),
            lockIconButton.widthAnchor.constraint(equalToConstant: UX.lockIconImageViewSize.width),

            iconContainerStackView.topAnchor.constraint(equalTo: topAnchor),
            iconContainerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            iconContainerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalSpace),
        ])
    }

    private func setupGradientLayer() {
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientView.layer.addSublayer(gradientLayer)
    }

    private func updateGradient() {
        let showGradientForLongURL = doesURLTextFieldExceedViewWidth && !urlTextField.isFirstResponder
        gradientView.isHidden = !showGradientForLongURL
        gradientLayer.frame = gradientView.bounds
    }

    private func updateURLTextFieldLeadingConstraintBasedOnState() {
        let isTextFieldFocused = urlTextField.isFirstResponder
        let shouldAdjustForOverflow = doesURLTextFieldExceedViewWidth && !isTextFieldFocused
        let shouldAdjustForNonEmpty = !isURLTextFieldEmpty && !isTextFieldFocused

        // hide the leading "..." by moving them behind the lock icon
        if shouldAdjustForOverflow {
            updateURLTextFieldLeadingConstraint(constant: -dotWidth)
        } else if shouldAdjustForNonEmpty {
            updateURLTextFieldLeadingConstraint()
        } else {
            updateURLTextFieldLeadingConstraint(constant: UX.horizontalSpace)
        }
    }

    private func updateURLTextFieldLeadingConstraint(constant: CGFloat = 0) {
        urlTextFieldLeadingConstraint?.constant = constant
    }

    private func removeContainerIcons() {
        iconContainerStackView.removeAllArrangedViews()
    }

    private func updateIconContainer() {
        guard !urlTextField.isEditing else {
            updateUIForSearchEngineDisplay()
            return
        }

        if isURLTextFieldEmpty {
            updateUIForSearchEngineDisplay()
        } else {
            updateUIForLockIconDisplay()
        }
    }

    private func updateUIForSearchEngineDisplay() {
        removeContainerIcons()
        iconContainerStackView.addArrangedSubview(searchEngineContentView)
        urlTextFieldLeadingConstraint?.constant = UX.horizontalSpace
        updateURLTextFieldLeadingConstraint(constant: UX.horizontalSpace)
        updateGradient()
    }

    private func updateUIForLockIconDisplay() {
        removeContainerIcons()
        iconContainerStackView.addArrangedSubview(lockIconButton)
        urlTextFieldLeadingConstraint?.constant = 0
        updateGradient()
    }

    // MARK: - `urlTextField` Configuration
    private func configureURLTextField(_ state: LocationViewState) {
        urlTextField.resignFirstResponder()
        urlTextField.text = state.url?.absoluteString
        urlTextField.placeholder = state.urlTextFieldPlaceholder
        urlAbsolutePath = urlTextField.text
    }

    private func formatAndTruncateURLTextField() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingHead

        let urlString = urlAbsolutePath ?? ""
        let (subdomain, normalizedHost) = URL.getSubdomainAndHost(from: urlString)

        let attributedString = NSMutableAttributedString(string: normalizedHost)

        if let subdomain {
            let range = NSRange(location: 0, length: subdomain.count)
            attributedString.addAttribute(.foregroundColor, value: urlTextFieldSubdomainColor, range: range)
        }
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(
                location: 0,
                length: attributedString.length
            )
        )
        urlTextField.attributedText = attributedString
    }

    // MARK: - `lockIconButton` Configuration
    private func configureLockIconButton(_ state: LocationViewState) {
        let lockImage = UIImage(named: state.lockIconImageName)?.withRenderingMode(.alwaysTemplate)
        lockIconButton.setImage(lockImage, for: .normal)
        onTapLockIcon = state.onTapLockIcon
    }

    // MARK: - Selectors
    @objc
    func textDidChange(_ textField: UITextField) {
        notifyTextChanged?()
    }

    @objc
    private func didTapLockIcon() {
        onTapLockIcon?()
    }

    // MARK: - UITextFieldDelegate
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        updateUIForSearchEngineDisplay()

        DispatchQueue.main.async { [self] in
            // `attributedText` property is set to nil to remove all formatting and truncation set before.
            textField.attributedText = nil
            textField.text = searchTerm != nil ? searchTerm : urlAbsolutePath
            textField.selectAll(nil)
        }
        locationViewDelegate?.locationViewDidBeginEditing(textField.text ?? "")
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        if isURLTextFieldEmpty {
            updateGradient()
        } else {
            updateUIForLockIconDisplay()
        }
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let searchText = textField.text?.lowercased(), !searchText.isEmpty else { return false }

        locationViewDelegate?.locationViewShouldSearchFor(searchText)
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Accessibility
    private func configureA11y(_ state: LocationViewState) {
        lockIconButton.accessibilityIdentifier = state.lockIconButtonA11yId
        lockIconButton.accessibilityLabel = state.lockIconButtonA11yLabel

        searchEngineImageView.accessibilityIdentifier = state.searchEngineImageViewA11yId
        searchEngineImageView.accessibilityLabel = state.searchEngineImageViewA11yLabel
        searchEngineImageView.largeContentTitle = state.searchEngineImageViewA11yLabel
        searchEngineImageView.largeContentImage = nil

        urlTextField.accessibilityIdentifier = state.urlTextFieldA11yId
        urlTextField.accessibilityLabel = state.urlTextFieldA11yLabel
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        urlTextFieldSubdomainColor = colors.textSecondary
        gradientLayer.colors = colors.layerGradientURL.cgColors.reversed()
        searchEngineImageView.backgroundColor = colors.iconPrimary
        lockIconButton.tintColor = colors.iconPrimary
        lockIconButton.backgroundColor = colors.layerSearch
        urlTextField.applyTheme(theme: theme)
    }
}
