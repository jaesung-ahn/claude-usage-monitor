import Foundation

public enum UsageLevel: String, Equatable, Sendable {
    case safe
    case warning
    case danger
}

/// 사용률을 세 단계로 분류하는 기준.
///
/// 검증을 통과하지 못한 값은 받지 않는다. 조용히 보정하면 사용자가 입력한 값과
/// 다른 값이 적용된 이유를 알 수 없다. 호출자가 `.default`로 되돌린다.
public struct Thresholds: Equatable, Sendable {
    public static let `default` = Thresholds(unchecked: (warning: 60, danger: 85))

    public let warning: Double
    public let danger: Double

    private init(unchecked v: (warning: Double, danger: Double)) {
        self.warning = v.warning
        self.danger = v.danger
    }

    public init?(warning: Double, danger: Double) {
        guard (1...98).contains(warning), (2...99).contains(danger), warning < danger else {
            return nil
        }
        self.warning = warning
        self.danger = danger
    }

    /// 비교는 실수로 한다. 정수로 내림한 뒤 비교하면 경계에서 한 단계 늦게 반응한다.
    public func level(for percent: Double) -> UsageLevel {
        if percent >= danger { return .danger }
        if percent >= warning { return .warning }
        return .safe
    }
}
