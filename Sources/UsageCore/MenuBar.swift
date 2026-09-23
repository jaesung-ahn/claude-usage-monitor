import Foundation

/// 메뉴바에 표시할 항목 하나.
///
/// 표시 문구는 `labelKey`로만 넘긴다. 한국어를 코드에 넣지 않는다.
public struct MenuBarItem: Equatable, Sendable {
    public let labelKey: String
    public let percent: Double?
    public let level: UsageLevel?

    public init(labelKey: String, percent: Double?, level: UsageLevel?) {
        self.labelKey = labelKey
        self.percent = percent
        self.level = level
    }
}

/// 메뉴바에 무엇을 어떤 순서로 보여줄지 결정한다.
///
/// 5시간과 7일은 독립적으로 적용되며 하나만 한도에 닿아도 그 범위에서 막힌다.
/// 따라서 한쪽만 보여주면 다른 쪽이 한도에 근접해도 안전해 보이는 상태가 만들어진다.
/// 둘 다 표시한다.
///
/// 모델별 주간 풀은 넣지 않는다. 개수가 정해져 있지 않아 메뉴바 폭을 예측할 수 없다.
/// 팝오버에서 확인한다.
public func menuBarItems(
    reading: UsageReading?,
    thresholds: Thresholds
) -> [MenuBarItem] {
    [
        item(labelKey: "menubar.session", pool: reading?.session, thresholds: thresholds),
        item(labelKey: "menubar.weekly", pool: reading?.weeklyAll, thresholds: thresholds),
    ]
}

private func item(labelKey: String, pool: Pool?, thresholds: Thresholds) -> MenuBarItem {
    // 값이 없으면 0%가 아니라 없음으로 둔다. 표시 계층이 자리표시자를 쓴다.
    guard let pool else {
        return MenuBarItem(labelKey: labelKey, percent: nil, level: nil)
    }
    return MenuBarItem(
        labelKey: labelKey,
        percent: pool.percent,
        level: thresholds.level(for: pool.percent)
    )
}
