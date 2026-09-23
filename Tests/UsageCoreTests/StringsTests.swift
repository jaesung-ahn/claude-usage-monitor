import XCTest
@testable import UsageCore

final class StringsTests: XCTestCase {
    func testLoadsSharedLocaleFile() throws {
        let url = Fixtures.packageRoot.appendingPathComponent("locales/ko.json")
        let strings = try Strings(contentsOf: url)
        XCTAssertEqual(strings("pool.session"), "5시간 사용률")
    }

    func testSubstitutesPlaceholders() {
        let strings = Strings(table: ["pool.weeklyScoped": "{name} (주간)"])
        XCTAssertEqual(strings("pool.weeklyScoped", ["name": "Fable"]), "Fable (주간)")
    }

    func testMissingKeyReturnsKey() {
        let strings = Strings(table: [:])
        XCTAssertEqual(strings("unknown.key"), "unknown.key", "누락을 UI에서 알아챌 수 있어야 한다")
    }
}
