import XCTest
@testable import UsageCore

final class ThresholdsTests: XCTestCase {
    func testBoundariesAreInclusive() {
        let t = Thresholds.default
        XCTAssertEqual(t.level(for: 85), .danger)
        XCTAssertEqual(t.level(for: 60), .warning)
        XCTAssertEqual(t.level(for: 59.9), .safe)
    }

    func testFractionalValuesAreNotTruncated() {
        let t = Thresholds.default
        XCTAssertEqual(t.level(for: 84.9), .warning)
        XCTAssertEqual(t.level(for: 85.1), .danger)
    }

    func testInvalidCombinationsAreRejected() {
        XCTAssertNil(Thresholds(warning: 90, danger: 80), "warning이 danger보다 크면 거부한다")
        XCTAssertNil(Thresholds(warning: 70, danger: 70), "같으면 거부한다")
        XCTAssertNil(Thresholds(warning: 0, danger: 85), "허용 범위를 벗어나면 거부한다")
        XCTAssertNil(Thresholds(warning: 60, danger: 100), "허용 범위를 벗어나면 거부한다")
    }

    func testValidCombinationIsAccepted() {
        XCTAssertNotNil(Thresholds(warning: 50, danger: 90))
    }
}
