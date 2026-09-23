import XCTest
@testable import UsageCore

final class SyncIntervalTests: XCTestCase {
    func testDefaultIsFiveMinutes() {
        XCTAssertEqual(SyncInterval.default.seconds, 300)
    }

    func testChoicesAreOrderedAscending() {
        let seconds = SyncInterval.allCases.map(\.rawValue)
        XCTAssertEqual(seconds, seconds.sorted(), "선택지 순서가 UI 순서가 된다")
    }

    func testUnknownStoredValueFallsBackToDefault() {
        XCTAssertEqual(SyncInterval.from(seconds: 7), .default)
        XCTAssertEqual(SyncInterval.from(seconds: 0), .default)
    }

    func testKnownStoredValueIsRestored() {
        XCTAssertEqual(SyncInterval.from(seconds: 900), .fifteenMinutes)
    }

    func testLabelKeysAreUnique() {
        let keys = Set(SyncInterval.allCases.map(\.labelKey))
        XCTAssertEqual(keys.count, SyncInterval.allCases.count)
    }
}
