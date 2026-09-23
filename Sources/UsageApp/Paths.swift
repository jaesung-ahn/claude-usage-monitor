import Foundation

enum Paths {
    /// `locales/ko.json`은 저장소 루트에 둔다.
    /// 번들에 복사된 것을 먼저 찾고, 개발 중 실행에서는 실행 파일 상위를 거슬러 올라가 찾는다.
    static func locale(_ code: String) -> URL? {
        if let bundled = Bundle.main.url(
            forResource: code,
            withExtension: "json",
            subdirectory: "locales"
        ) {
            return bundled
        }

        var directory = Bundle.main.bundleURL
        for _ in 0..<6 {
            directory = directory.deletingLastPathComponent()
            let candidate = directory
                .appendingPathComponent("locales")
                .appendingPathComponent("\(code).json")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}
