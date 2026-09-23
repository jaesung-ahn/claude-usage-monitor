import AppKit
import Combine
import SwiftUI
import UsageCore

/// 메뉴바 아이템과 팝오버.
///
/// 메뉴바 텍스트는 초를 표시하지 않는다. 1초마다 상태 아이템을 다시 그리는 비용이
/// 표시 가치보다 크다.
@MainActor
final class StatusItemController {
    private let state: AppState
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var cancellable: AnyCancellable?

    init(state: AppState) {
        self.state = state
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        popover.behavior = .transient
        // 팝오버 재질이 밝은 배경을 비치면 다크 팔레트의 대비가 무너진다.
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = NSHostingController(rootView: PopoverView(state: state))

        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        // 값이 바뀌면 스스로 다시 그린다. 갱신 경로마다 render를 부르면 빠뜨리기 쉽다.
        // @Published는 willSet에서 방출되므로 메인 런루프로 한 번 넘겨 갱신 후의 값을 읽는다.
        cancellable = state.$reading
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.render() }

        render()
    }

    /// 5시간과 7일을 함께 표시한다. 하나만 보여주면 다른 쪽이 한도에 근접해도
    /// 안전해 보이는 상태가 만들어진다.
    func render() {
        guard let button = statusItem.button else { return }
        button.image = nil
        button.imagePosition = .noImage
        button.attributedTitle = MenuBarLabel.attributedTitle(
            items: menuBarItems(reading: state.reading, thresholds: state.thresholds),
            strings: state.strings,
            placeholder: state.strings("menubar.placeholder")
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
