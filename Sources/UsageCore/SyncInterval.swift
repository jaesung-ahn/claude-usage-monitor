import Foundation

/// 사용량 조회 주기.
///
/// 조회 엔드포인트라 호출에 토큰이 들지 않는다. 제약은 요청 빈도 제한뿐이므로
/// 자유 입력 대신 정해진 선택지를 둔다. 오입력으로 429를 부르는 경로를 없앤다.
public enum SyncInterval: Int, CaseIterable, Sendable {
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600

    public static let `default` = SyncInterval.fiveMinutes

    public var seconds: TimeInterval { TimeInterval(rawValue) }

    /// `locales`의 키. 표시 문구를 코드에 넣지 않는다.
    public var labelKey: String { "sync.\(rawValue)" }

    /// 저장된 값이 선택지에 없으면 기본값으로 되돌린다.
    /// 앱 버전이 바뀌며 선택지가 줄어도 안전하게 동작해야 한다.
    public static func from(seconds: Int) -> SyncInterval {
        SyncInterval(rawValue: seconds) ?? .default
    }
}
