// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public final class MenuDetailView: UIView,
                                   MenuTableViewDataDelegate {
    private struct UX {
        static let headerHeight: CGFloat = 70
    }

    // MARK: - UI Elements
    private var tableView: MenuTableView = .build()
    private var detailHeaderView: MenuSubmenuHeaderView = .build()

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
        backgroundColor = .clear
        addSubview(detailHeaderView)
        addSubview(tableView)

        NSLayoutConstraint.activate([
            detailHeaderView.topAnchor.constraint(equalTo: self.topAnchor),
            detailHeaderView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            detailHeaderView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            detailHeaderView.heightAnchor.constraint(equalToConstant: UX.headerHeight),

            tableView.topAnchor.constraint(equalTo: detailHeaderView.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    // MARK: - Interface
    public func reloadTableView(with data: [MenuSection]) {
        tableView.reloadTableView(with: data)
    }

    public func setupHeaderNavigation(from delegate: MainMenuDetailNavigationHandler) {
        detailHeaderView.navigationDelegate = delegate
    }
}
