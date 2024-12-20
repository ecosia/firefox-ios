@testable import Ecosia
import XCTest

final class TreesProjectionTests: XCTestCase {
    private var treesProjection: TreesProjection!

    override func setUp() {
        treesProjection = TreesProjection.shared
    }

    func testTreesAt() {
        let date = Date()
        Statistics.shared.treesPlanted = 10
        Statistics.shared.treesPlantedLastUpdated = date.addingTimeInterval(-100)
        Statistics.shared.timePerTree = 2
        XCTAssertEqual(Int(100/2 + 10-1), treesProjection.treesAt(date))
    }

    func testTimerIsActive() {
        let timePerTree = 0.1
        Statistics.shared.timePerTree = timePerTree

        let exp = XCTestExpectation(description: "Wait for timer")
        let projection = TreesProjection()
        var receivedCount: Int?
        projection.subscribe(self) { count in
            receivedCount = count
            exp.fulfill()
        }
        wait(for: [exp], timeout: timePerTree)

        XCTAssertNotNil(receivedCount)
    }
}
