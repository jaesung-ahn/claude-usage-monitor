import Foundation
import Security

/// Claude Code가 로그인 시 저장해 둔 OAuth 토큰을 읽는다.
///
/// 별도의 API 키를 만들지 않고, 내장 `/usage`가 쓰는 것과 같은 토큰을 재사용한다.
/// 토큰은 메모리에만 두고 로그나 파일로 내보내지 않는다.
final class TokenStore {
    private let credentialsFile: URL
    private let service = "Claude Code-credentials"

    private var cached: String?
    private var keychainDeniedUntil: Date?
    private var reads = 0

    /// Keychain은 최초 접근 시 권한 창을 띄운다. 거부당한 뒤 매 폴링마다 다시 물으면
    /// 창이 반복해서 뜨므로 쿨다운을 둔다.
    private let denialCooldown: TimeInterval = 600

    init(credentialsFile: URL = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/.credentials.json")) {
        self.credentialsFile = credentialsFile
    }

    func accessToken(now: Date = Date()) -> String? {
        reads += 1

        if let cached {
            Log.auth.debug("token: cache hit (read #\(self.reads, privacy: .public))")
            return cached
        }

        if let token = readFromFile() {
            Log.auth.info("token: read from file (read #\(self.reads, privacy: .public))")
            cached = token
            return token
        }

        if let deniedUntil = keychainDeniedUntil, now < deniedUntil {
            Log.auth.info("token: keychain in cooldown")
            return nil
        }

        Log.auth.info("token: querying keychain (read #\(self.reads, privacy: .public))")
        guard let token = readFromKeychain() else {
            Log.auth.error("token: keychain query failed")
            keychainDeniedUntil = now.addingTimeInterval(denialCooldown)
            return nil
        }

        Log.auth.info("token: read from keychain")
        cached = token
        return token
    }

    /// 401을 받으면 캐시를 버린다. Claude Code가 토큰을 갱신했을 수 있다.
    func invalidate() {
        cached = nil
        keychainDeniedUntil = nil
    }

    private func readFromFile() -> String? {
        guard let data = try? Data(contentsOf: credentialsFile) else { return nil }
        return Self.accessToken(fromJSON: data)
    }

    private func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }

        return Self.accessToken(fromJSON: data)
    }

    /// 자격증명은 `claudeAiOauth` 아래에 있거나 최상위에 있다. 둘 다 받는다.
    static func accessToken(fromJSON data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let root = object as? [String: Any]
        else { return nil }

        let container = (root["claudeAiOauth"] as? [String: Any]) ?? root
        guard let token = container["accessToken"] as? String, !token.isEmpty else { return nil }
        return token
    }
}
