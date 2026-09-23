import Foundation

/// 요청을 언제 보낼 수 있는지 판정한다.
///
/// 두 가지를 막는다.
/// - 수동 새로고침 연타. 버튼에 제한이 없으면 클릭 수만큼 요청이 나간다
/// - 429 이후의 즉시 재시도. 제한에 걸린 상태에서 계속 두드리면 더 오래 막힌다
public struct RequestGate: Equatable, Sendable {
    /// 수동 요청 사이의 최소 간격.
    public let minimumInterval: TimeInterval
    /// 429를 처음 받았을 때의 대기 시간.
    public let baseCooldown: TimeInterval
    /// 연속으로 맞아도 이 이상은 기다리지 않는다.
    public let maximumCooldown: TimeInterval

    private var lastAttempt: Date?
    private var blockedUntil: Date?
    private var consecutiveRateLimits: Int = 0

    public init(
        minimumInterval: TimeInterval = 5,
        baseCooldown: TimeInterval = 60,
        maximumCooldown: TimeInterval = 900
    ) {
        self.minimumInterval = minimumInterval
        self.baseCooldown = baseCooldown
        self.maximumCooldown = maximumCooldown
    }

    public func canRequest(at now: Date) -> Bool {
        remainingCooldown(at: now) == 0
    }

    /// 남은 대기 시간. 0이면 요청할 수 있다.
    public func remainingCooldown(at now: Date) -> TimeInterval {
        let byBlock = blockedUntil.map { $0.timeIntervalSince(now) } ?? 0
        let byInterval = lastAttempt.map { minimumInterval - now.timeIntervalSince($0) } ?? 0
        return max(0, max(byBlock, byInterval))
    }

    public mutating func recordAttempt(at now: Date) {
        lastAttempt = now
    }

    /// 성공하면 누적된 대기를 모두 푼다.
    public mutating func recordSuccess() {
        blockedUntil = nil
        consecutiveRateLimits = 0
    }

    /// 서버가 `Retry-After`를 주면 그 값을 따르고, 없으면 연속 횟수만큼 배로 늘린다.
    public mutating func recordRateLimited(at now: Date, retryAfter: TimeInterval? = nil) {
        consecutiveRateLimits += 1

        let cooldown: TimeInterval
        if let retryAfter, retryAfter > 0 {
            cooldown = min(retryAfter, maximumCooldown)
        } else {
            let doubled = baseCooldown * pow(2, Double(consecutiveRateLimits - 1))
            cooldown = min(doubled, maximumCooldown)
        }

        blockedUntil = now.addingTimeInterval(cooldown)
    }
}
