import AppKit

/// 같은 앱이 이미 실행 중인지 확인한다.
///
/// 메뉴바 앱은 중복 실행에 의미가 없다. 두 번 뜨면 메뉴바 아이템이 두 개 생기고,
/// 각자 따로 폴링하므로 요청 수도 두 배가 된다.
enum SingleInstance {
    /// 이미 실행 중이면 그 인스턴스를 앞으로 꺼내고 `false`를 반환한다.
    static func claim() -> Bool {
        guard let identifier = Bundle.main.bundleIdentifier else { return true }

        let others = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }

        guard let existing = others.first else { return true }

        // 사용자가 한 번 더 열었다면 기존 것을 보고 싶다는 뜻이다.
        existing.activate()
        return false
    }
}
