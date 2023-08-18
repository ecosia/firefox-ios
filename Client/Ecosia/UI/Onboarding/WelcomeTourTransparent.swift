/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class WelcomeTourTransparent: UIView, NotificationThemeable {

    private weak var stack: UIStackView!

    lazy var currencyNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        return formatter
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        updateAccessibilitySettings()
    }

    required init?(coder: NSCoder) {  nil }

    func setup() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .leading
        stack.spacing = 8
        addSubview(stack)
        self.stack = stack

        stack.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stack.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        stack.topAnchor.constraint(equalTo: topAnchor, constant: 54).isActive = true
        let height = heightAnchor.constraint(equalToConstant: 200)
        height.priority = .init(rawValue: 500)
        height.isActive = true
        
        addMonthView(toStack: stack)
        
        let report = FinancialReports.shared.latestReport
        if let totalIncome = currencyNumberFormatter.string(from: .init(value: report.totalIncome)) {
            let income = WelcomeTourRow(image: "financialReports", title: totalIncome, text: .localized(.totalIncome))
            stack.addArrangedSubview(income)
        }
        let treesFinanced = String(report.numberOfTreesFinanced)
        let trees = WelcomeTourRow(image: "treesUpdate", title: treesFinanced, text: .localized(.treesFinanced))
        stack.addArrangedSubview(trees)
    }

    func applyTheme() {
        stack.arrangedSubviews.forEach { view in
            (view as? NotificationThemeable)?.applyTheme()
        }
    }
    
    func updateAccessibilitySettings() {
        isAccessibilityElement = false
        shouldGroupAccessibilityChildren = true
    }
    
    func addMonthView(toStack parentStack: UIStackView) {
        let monthView = UIView()
        monthView.translatesAutoresizingMaskIntoConstraints = false
        monthView.backgroundColor = .theme.ecosia.primaryHighlight.withAlphaComponent(0.5)
        parentStack.addArrangedSubview(monthView)
        
        let containerStack = UIStackView()
        containerStack.axis = .horizontal
        containerStack.alignment = .center
        containerStack.spacing = 4
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        monthView.addSubview(containerStack)
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = FinancialReports.shared.localizedMonthAndYear
        label.textColor = .theme.ecosia.secondaryBrand
        label.font = .preferredFont(forTextStyle: .footnote)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        containerStack.addArrangedSubview(label)
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(named: "chevronDown")?.withRenderingMode(.alwaysTemplate)
        imageView.image = image
        imageView.tintColor = .theme.ecosia.secondaryBrand
        imageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        containerStack.addArrangedSubview(imageView)
        
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: monthView.topAnchor, constant: 8),
            containerStack.bottomAnchor.constraint(equalTo: monthView.bottomAnchor, constant: -8),
            containerStack.leadingAnchor.constraint(equalTo: monthView.leadingAnchor, constant: 12),
            containerStack.trailingAnchor.constraint(equalTo: monthView.trailingAnchor, constant: -12)
        ])
        
        // Force layout to calculate the frame before setting corner radius
        monthView.layoutIfNeeded()
        monthView.layer.cornerRadius = monthView.frame.height/2
        
        // Adding view for extra spacing on parent stack below this specific view
        parentStack.addArrangedSubview(UIView(frame: .init(width: 0, height: 8)))
    }
}
