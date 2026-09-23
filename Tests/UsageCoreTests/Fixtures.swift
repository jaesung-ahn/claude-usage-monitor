import Foundation

/// 테스트가 읽는 실제 응답 표본. 경로는 패키지 루트 기준으로 해석한다.
enum Fixtures {
    static let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // UsageCoreTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // 패키지 루트

    static let root = packageRoot
        .appendingPathComponent("Tests")
        .appendingPathComponent("Fixtures")

    static func json(_ name: String) throws -> [String: Any] {
        let data = try Data(contentsOf: root.appendingPathComponent(name))
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "Fixtures", code: 1)
        }
        return object
    }
}
