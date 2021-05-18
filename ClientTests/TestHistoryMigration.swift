/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import Client
import Foundation
import Storage
import Core

class TestHistoryMigration: TestHistory {

    func testEcosiaImportHistory() {
        let url = URL(string:"https://ecosia.org")!

        withTestProfile { profile in
            let items = [(Date(), Core.Page(url: url, title: "Ecosia"))]
            EcosiaHistory.migrate(items, to: profile) { _ in }
            self.checkVisits(profile.history, url: url.absoluteString)
        }
    }

    func testEcosiaHistoryPrepare() {
        let urls = [URL(string:"https://apple.com")!,
                    URL(string:"https://ecosia.org")!,
                    URL(string:"https://ecosia.org/blog")!,
                    URL(string:"https://ecosia.org/blog")!]

        let items = urls.map { (Date(), Core.Page(url: $0, title: "Ecosia")) }
        let data = EcosiaHistory.prepare(history: items)
        XCTAssert(data.domains["apple.com"] == 1)
        XCTAssert(data.domains["ecosia.org"] == 2)
        XCTAssert(data.domains.count == 2)
        XCTAssert(data.sites[0].1 == 1)
        XCTAssert(data.sites[1].1 == 2)
        XCTAssert(data.sites[2].1 == 2)

        XCTAssert(data.sites.count == 3)
        XCTAssert(data.visits.count == 4)
    }

    func testImportFailureDescription() {
        let singleFailure = EcosiaImport.Failure(reasons: ["Reason 1"])
        XCTAssertEqual(singleFailure.description, "Reason 1")

        let fourFailures = EcosiaImport.Failure(reasons: ["Reason 1", "Reason 2", "Reason 3", "Reason 4"])
        let cappedDescription = fourFailures.description
        XCTAssertEqual(cappedDescription, "Reason 1 / Reason 2 / Reason 3")
    }

}
