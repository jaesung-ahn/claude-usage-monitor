import Foundation

/// 표시 문자열 조회.
///
/// 문자열을 코드에 넣지 않는 이유는 언어를 추가할 때 전수 수정이 필요해지기 때문이다.
public struct Strings: Sendable {
    private let table: [String: String]

    public init(table: [String: String]) {
        self.table = table
    }

    public init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        guard let table = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
            throw StringsError.malformed
        }
        self.table = table
    }

    /// 키가 없으면 키 자체를 반환한다. 빈 문자열을 반환하면 UI에서 누락을 알아채기 어렵다.
    public func callAsFunction(_ key: String, _ arguments: [String: String] = [:]) -> String {
        var value = table[key] ?? key
        for (name, replacement) in arguments {
            value = value.replacingOccurrences(of: "{\(name)}", with: replacement)
        }
        return value
    }
}

public enum StringsError: Error {
    case malformed
}
