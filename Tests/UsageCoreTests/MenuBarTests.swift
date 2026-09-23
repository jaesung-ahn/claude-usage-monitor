import XCTest
@testable import UsageCore

final class MenuBarTests: XCTestCase {
    private func reading(session: Double?, weekly: Double?) -> UsageReading {
        UsageReading(
            observedAt: Date(timeIntervalSince1970: 1_790_000_000),
            session: session.map { Pool(name: "session", percent: $0, resetsAt: nil) },
            weeklyAll: weekly.map { Pool(name: "weeklyAll", percent: $0, resetsAt: nil) },
            weeklyScoped: [Pool(name: "Fable", percent: 23, resetsAt: nil)]
        )
    }

    func testShowsBothWindowsInOrder() {
        let items = menuBarItems(reading: reading(session: 30, weekly: 18), thresholds: .default)

        XCTAssertEqual(items.map(\.labelKey), ["menubar.session", "menubar.weekly"])
        XCTAssertEqual(items.map(\.percent), [30, 18])
    }

    func testEachItemGetsItsOwnLevel() {
        // 5시간이 안전해도 7일이 위험하면 그 사실이 드러나야 한다.
        let items = menuBarItems(reading: reading(session: 10, weekly: 90), thresholds: .default)

        XCTAssertEqual(items[0].level, .safe)
        XCTAssertEqual(items[1].level, .danger)
    }

    func testScopedPoolsAreNotShown() {
        let items = menuBarItems(reading: reading(session: 30, weekly: 18), thresholds: .default)
        XCTAssertEqual(items.count, 2, "개수가 정해지지 않아 메뉴바 폭을 예측할 수 없다")
    }

    func testMissingReadingKeepsSlots() {
        let items = menuBarItems(reading: nil, thresholds: .default)

        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items.allSatisfy { $0.percent == nil && $0.level == nil })
    }

    func testMissingPoolIsNilNotZero() {
        let items = menuBarItems(reading: reading(session: nil, weekly: 18), thresholds: .default)

        XCTAssertNil(items[0].percent, "값 없음과 0%는 다른 상태다")
        XCTAssertEqual(items[1].percent, 18)
    }
}
