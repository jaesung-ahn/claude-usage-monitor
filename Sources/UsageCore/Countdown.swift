import Foundation

/// 리셋까지 남은 시간.
///
/// `isStale`은 리셋 시각이 이미 지났다는 뜻이다. 데이터가 갱신되지 않았다는 신호이므로
/// 호출자는 사용률 값을 그대로 신뢰하지 않아야 한다.
public struct Countdown: Equatable, Sendable {
    public let remaining: TimeInterval
    public let isStale: Bool
}

/// 리셋 시각이 없으면 카운트다운을 만들지 않는다.
public func countdown(resetsAt: Date?, now: Date) -> Countdown? {
    guard let resetsAt else { return nil }
    let raw = resetsAt.timeIntervalSince(now)
    return Countdown(remaining: max(0, raw), isStale: raw < 0)
}

public enum CountdownStyle: Equatable, Sendable {
    /// 팝오버. 초까지 표시하고 1초마다 갱신한다.
    case popover
    /// 메뉴바. 초를 표시하지 않는다. 1초마다 상태 아이템을 다시 그리는 비용이
    /// 표시 가치보다 크다.
    case menuBar
}

public func formatCountdown(_ countdown: Countdown, style: CountdownStyle) -> String {
    let total = Int(countdown.remaining)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60

    switch style {
    case .popover:
        return "\(hours)h \(minutes)m \(seconds)s"
    case .menuBar:
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
