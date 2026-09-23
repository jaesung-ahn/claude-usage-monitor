import XCTest
@testable import UsageCore

final class RequestGateTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    func testFirstRequestIsAllowed() {
        XCTAssertTrue(RequestGate().canRequest(at: now))
    }

    func testRapidRepeatIsBlocked() {
        var gate = RequestGate(minimumInterval: 5)
        gate.recordAttempt(at: now)

        XCTAssertFalse(gate.canRequest(at: now.addingTimeInterval(1)), "연타를 막는다")
        XCTAssertTrue(gate.canRequest(at: now.addingTimeInterval(5)))
    }

    func testRateLimitBlocksForBaseCooldown() {
        var gate = RequestGate(baseCooldown: 60)
        gate.recordRateLimited(at: now)

        XCTAssertEqual(gate.remainingCooldown(at: now), 60)
        XCTAssertFalse(gate.canRequest(at: now.addingTimeInterval(59)))
        XCTAssertTrue(gate.canRequest(at: now.addingTimeInterval(60)))
    }

    func testConsecutiveRateLimitsDouble() {
        var gate = RequestGate(baseCooldown: 60, maximumCooldown: 900)

        gate.recordRateLimited(at: now)
        XCTAssertEqual(gate.remainingCooldown(at: now), 60)

        gate.recordRateLimited(at: now)
        XCTAssertEqual(gate.remainingCooldown(at: now), 120)

        gate.recordRateLimited(at: now)
        XCTAssertEqual(gate.remainingCooldown(at: now), 240)
    }

    func testCooldownIsCapped() {
        var gate = RequestGate(baseCooldown: 60, maximumCooldown: 300)
        for _ in 0..<10 { gate.recordRateLimited(at: now) }

        XCTAssertEqual(gate.remainingCooldown(at: now), 300)
    }

    func testRetryAfterHeaderWins() {
        var gate = RequestGate(baseCooldown: 60)
        gate.recordRateLimited(at: now, retryAfter: 30)

        XCTAssertEqual(gate.remainingCooldown(at: now), 30, "서버가 준 값을 따른다")
    }

    func testRetryAfterIsAlsoCapped() {
        var gate = RequestGate(maximumCooldown: 300)
        gate.recordRateLimited(at: now, retryAfter: 100_000)

        XCTAssertEqual(gate.remainingCooldown(at: now), 300)
    }

    func testSuccessClearsBackoff() {
        var gate = RequestGate(baseCooldown: 60)
        gate.recordRateLimited(at: now)
        gate.recordRateLimited(at: now)
        gate.recordSuccess()

        XCTAssertTrue(gate.canRequest(at: now))

        // 누적 횟수도 초기화되어 다음 429는 다시 기본값부터 시작한다
        gate.recordRateLimited(at: now)
        XCTAssertEqual(gate.remainingCooldown(at: now), 60)
    }

    func testLongerOfTheTwoConstraintsApplies() {
        var gate = RequestGate(minimumInterval: 5, baseCooldown: 60)
        gate.recordAttempt(at: now)
        gate.recordRateLimited(at: now)

        XCTAssertEqual(gate.remainingCooldown(at: now), 60, "더 긴 제약이 이긴다")
    }
}
