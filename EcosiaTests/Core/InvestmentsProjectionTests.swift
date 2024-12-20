@testable import Ecosia
import XCTest

final class InvestmentsProjectionTests: XCTestCase {
    private var investmentsProjection: InvestmentsProjection!

    override func setUp() {
        investmentsProjection = InvestmentsProjection.shared
    }

    func testTotalInvestedAt() {
        let date = Date()
        Statistics.shared.totalInvestments = 123456789
        Statistics.shared.totalInvestmentsLastUpdated = date.addingTimeInterval(-100)
        Statistics.shared.investmentPerSecond = 0.5
        XCTAssertEqual(Int(100*0.5 + 123456789), investmentsProjection.totalInvestedAt(date))
    }

    func testTimerIsActive() {
        let investmentPerSecond = 1.0
        Statistics.shared.investmentPerSecond = investmentPerSecond

        let exp = XCTestExpectation(description: "Wait for timer")
        let projection = InvestmentsProjection()
        var receivedAmount: Int?
        projection.subscribe(self) { amount in
            receivedAmount = amount
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)

        XCTAssertNotNil(receivedAmount)
    }
}
