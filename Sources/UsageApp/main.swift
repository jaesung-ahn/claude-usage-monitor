import AppKit

// 최상위 코드는 nonisolated이므로 메인 액터 격리를 명시한다.
// NSApplication.delegate가 weak 참조라 delegate는 run()이 블록하는 동안 스택에 남아야 한다.
MainActor.assumeIsolated {
    guard SingleInstance.claim() else { exit(0) }

    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    NSApplication.shared.setActivationPolicy(.accessory)
    NSApplication.shared.run()
}
