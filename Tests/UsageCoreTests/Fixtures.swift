import Foundation

/// 픽스처는 두 구현이 함께 읽는 자산이다. 경로는 패키지 루트 기준으로 해석한다.
enum Fixtures {
    static let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // UsageCoreTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // 패키지 루트

    static let root = packageRoot.appendingPathComponent("docs/spec/fixtures")

    static func json(_ name: String) throws -> [String: Any] {
        let data = try Data(contentsOf: root.appendingPathComponent(name))
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "Fixtures", code: 1)
        }
        return object
    }
}
