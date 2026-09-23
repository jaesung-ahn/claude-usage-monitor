import XCTest
@testable import UsageCore

final class CountdownTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    func testNilResetProducesNoCountdown() {
        XCTAssertNil(countdown(resetsAt: nil, now: now))
    }

    func testRemainingIsClampedAndMarkedStale() {
        let past = countdown(resetsAt: now.addingTimeInterval(-60), now: now)
        XCTAssertEqual(past?.remaining, 0)
        XCTAssertEqual(past?.isStale, true)
    }

    func testFutureResetIsNotStale() {
        let future = countdown(resetsAt: now.addingTimeInterval(3661), now: now)
        XCTAssertEqual(future?.remaining, 3661)
        XCTAssertEqual(future?.isStale, false)
    }

    func testPopoverShowsSeconds() {
        let c = Countdown(remaining: 3661, isStale: false)
        XCTAssertEqual(formatCountdown(c, style: .popover), "1h 1m 1s")
    }

    func testMenuBarOmitsSeconds() {
        XCTAssertEqual(
            formatCountdown(Countdown(remaining: 3661, isStale: false), style: .menuBar),
            "1h 1m"
        )
        XCTAssertEqual(
            formatCountdown(Countdown(remaining: 125, isStale: false), style: .menuBar),
            "2m"
        )
    }
}
