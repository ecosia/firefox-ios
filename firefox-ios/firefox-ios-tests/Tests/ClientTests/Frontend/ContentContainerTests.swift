// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit
import XCTest
@testable import Client

final class ContentContainerTests: XCTestCase {
    private var profile: MockProfile!
    private var overlayModeManager: MockOverlayModeManager!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())
        self.profile = MockProfile()
        self.overlayModeManager = MockOverlayModeManager()
    }

    override func tearDown() {
        super.tearDown()
        self.profile = nil
        self.overlayModeManager = nil
        AppContainer.shared.reset()
    }

    // MARK: - canAddHomepage

    func testCanAddHomepage() {
        let subject = ContentContainer(frame: .zero)
        let homepage = createHomepage()

        XCTAssertTrue(subject.canAdd(content: homepage))
    }

    func testCanAddHomepageOnceOnly() {
        let subject = ContentContainer(frame: .zero)
        let homepage = createHomepage()

        subject.add(content: homepage)
        XCTAssertFalse(subject.canAdd(content: homepage))
    }

    // MARK: - canAddNewHomepage

    func testCanAddNewHomepage() {
        let subject = ContentContainer(frame: .zero)
        let homepage = NewHomepageViewController(windowUUID: .XCTestDefaultUUID)

        XCTAssertTrue(subject.canAdd(content: homepage))
    }

    func testCanAddNewHomepageOnceOnly() {
        let subject = ContentContainer(frame: .zero)
        let homepage = NewHomepageViewController(windowUUID: .XCTestDefaultUUID)

        subject.add(content: homepage)
        XCTAssertFalse(subject.canAdd(content: homepage))
    }

    // MARK: - canAddPrivateHomepage

    func testCanAddPrivateHomepage() {
        let subject = ContentContainer(frame: .zero)
        let privateHomepage = PrivateHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: overlayModeManager
        )

        XCTAssertTrue(subject.canAdd(content: privateHomepage))
    }

    func testCanAddPrivateHomepageOnceOnly() {
        let subject = ContentContainer(frame: .zero)
        let privateHomepage = PrivateHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: overlayModeManager
        )

        subject.add(content: privateHomepage)
        XCTAssertFalse(subject.canAdd(content: privateHomepage))
    }

    // MARK: - Webview

    func testCanAddWebview() {
        let subject = ContentContainer(frame: .zero)
        let webview = WebviewViewController(webView: WKWebView())

        XCTAssertTrue(subject.canAdd(content: webview))
    }

    func testCanAddWebviewOnceOnly() {
        let subject = ContentContainer(frame: .zero)
        let webview = WebviewViewController(webView: WKWebView())

        subject.add(content: webview)
        XCTAssertFalse(subject.canAdd(content: webview))
    }

    // MARK: - hasHomepage

    func testHasHomepage_trueWhenHomepage() {
        let subject = ContentContainer(frame: .zero)
        let homepage = createHomepage()
        subject.add(content: homepage)

        XCTAssertTrue(subject.hasHomepage)
    }

    func testHasHomepage_falseWhenNil() {
        let subject = ContentContainer(frame: .zero)
        XCTAssertFalse(subject.hasHomepage)
    }

    func testHasHomepage_falseWhenWebview() {
        let subject = ContentContainer(frame: .zero)
        let webview = WebviewViewController(webView: WKWebView())
        subject.add(content: webview)

        XCTAssertFalse(subject.hasHomepage)
    }

    // MARK: - hasNewHomepage

    func testHasNewHomepage_returnsTrueWhenAdded() {
        let subject = ContentContainer(frame: .zero)
        let homepage = NewHomepageViewController(windowUUID: .XCTestDefaultUUID)
        subject.add(content: homepage)

        XCTAssertTrue(subject.hasNewHomepage)
    }

    func testHasNewHomepage_returnsFalseWhenNil() {
        let subject = ContentContainer(frame: .zero)
        XCTAssertFalse(subject.hasNewHomepage)
    }

    func testHasNewHomepage_returnsFalseWhenWebview() {
        let subject = ContentContainer(frame: .zero)
        let webview = WebviewViewController(webView: WKWebView())
        subject.add(content: webview)

        XCTAssertFalse(subject.hasNewHomepage)
    }

    // MARK: - hasPrivateHomepage

    func testHasPrivateHomepage_returnsTrueWhenAdded() {
        let subject = ContentContainer(frame: .zero)
        let privateHomepage = PrivateHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: overlayModeManager
        )
        subject.add(content: privateHomepage)

        XCTAssertTrue(subject.hasPrivateHomepage)
    }

    func testHasPrivateHomepage_returnsFalseWhenNil() {
        let subject = ContentContainer(frame: .zero)
        XCTAssertFalse(subject.hasPrivateHomepage)
    }

    func testHasPrivateHomepage_returnsFalseWhenWebview() {
        let subject = ContentContainer(frame: .zero)
        let webview = WebviewViewController(webView: WKWebView())
        subject.add(content: webview)

        XCTAssertFalse(subject.hasPrivateHomepage)
    }

    // MARK: - contentView

    func testContentView_notContent_viewIsNil() {
        let subject = ContentContainer(frame: .zero)
        XCTAssertNil(subject.contentView)
    }

    func testContentView_hasContentHomepage_viewIsNotNil() {
        let subject = ContentContainer(frame: .zero)
        let homepage = createHomepage()
        subject.add(content: homepage)
        XCTAssertNotNil(subject.contentView)
    }

    func testContentView_hasContentNewHomepage_viewIsNotNil() {
        let subject = ContentContainer(frame: .zero)
        let homepage = NewHomepageViewController(windowUUID: .XCTestDefaultUUID)
        subject.add(content: homepage)
        XCTAssertNotNil(subject.contentView)
    }

    func testContentView_hasContentPrivateHomepage_viewIsNotNil() {
        let subject = ContentContainer(frame: .zero)
        let privateHomepage = PrivateHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: overlayModeManager
        )
        subject.add(content: privateHomepage)
        XCTAssertNotNil(subject.contentView)
    }

    // MARK: update method

    func test_update_hasHomepage_returnsTrue() {
        let subject = ContentContainer(frame: .zero)
        let homepage = createHomepage()
        subject.update(content: homepage)
        XCTAssertTrue(subject.hasHomepage)
        XCTAssertFalse(subject.hasNewHomepage)
        XCTAssertFalse(subject.hasPrivateHomepage)
        XCTAssertFalse(subject.hasWebView)
    }

    func test_update_hasNewHomepage_returnsTrue() {
        let subject = ContentContainer(frame: .zero)
        let homepage = NewHomepageViewController(windowUUID: .XCTestDefaultUUID)
        subject.update(content: homepage)
        XCTAssertTrue(subject.hasNewHomepage)
        XCTAssertFalse(subject.hasHomepage)
        XCTAssertFalse(subject.hasPrivateHomepage)
        XCTAssertFalse(subject.hasWebView)
    }

    func test_update_hasNewPrivateHomepage_returnsTrue() {
        let subject = ContentContainer(frame: .zero)
        let privateHomepage = PrivateHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: overlayModeManager
        )
        subject.update(content: privateHomepage)
        XCTAssertTrue(subject.hasPrivateHomepage)
        XCTAssertFalse(subject.hasHomepage)
        XCTAssertFalse(subject.hasNewHomepage)
        XCTAssertFalse(subject.hasWebView)
    }

    func test_update_hasWebView_returnsTrue() {
        let subject = ContentContainer(frame: .zero)
        let webview = WebviewViewController(webView: WKWebView())
        subject.update(content: webview)
        XCTAssertTrue(subject.hasWebView)
        XCTAssertFalse(subject.hasHomepage)
        XCTAssertFalse(subject.hasNewHomepage)
        XCTAssertFalse(subject.hasPrivateHomepage)
    }

    private func createHomepage() -> HomepageViewController {
        return HomepageViewController(profile: profile,
                                      toastContainer: UIView(),
                                      tabManager: MockTabManager(),
                                      overlayManager: overlayModeManager)
    }
}
