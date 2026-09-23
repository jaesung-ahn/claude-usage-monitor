import SwiftUI
import UsageCore

/// 팝오버 전반의 색과 간격.
///
/// 팝오버 기본 재질은 반투명이라 뒤 배경에 따라 대비가 무너진다.
/// 불투명한 다크 서피스를 직접 깔고, 그 위에서 고정 팔레트를 쓴다.
enum Theme {
    static let cardCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 14
    static let cardSpacing: CGFloat = 10
    static let popoverWidth: CGFloat = 300

    static let surface = Color(red: 0.067, green: 0.075, blue: 0.106)
    static let track = Color.white.opacity(0.10)

    static let title = Color.white.opacity(0.95)
    static let label = Color.white.opacity(0.58)
    static let muted = Color.white.opacity(0.40)

    /// 카운트다운은 사용률 색과 구분되어야 한다. 남은 시간은 경고가 아니라 정보다.
    static let countdown = Color(red: 0.70, green: 0.63, blue: 1.0)

    static func color(for level: UsageLevel) -> Color {
        switch level {
        case .safe: return Color(red: 0.23, green: 0.87, blue: 0.56)
        case .warning: return Color(red: 1.0, green: 0.73, blue: 0.25)
        case .danger: return Color(red: 1.0, green: 0.44, blue: 0.44)
        }
    }

    /// 막대와 숫자에 쓰는 그라디언트. 단색보다 색이 살아난다.
    static func fill(for level: UsageLevel) -> LinearGradient {
        let base = color(for: level)
        return LinearGradient(
            colors: [base.opacity(0.75), base],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// 카드 배경에 해당 단계의 색을 옅게 깐다.
    static func cardFill(for level: UsageLevel) -> LinearGradient {
        let base = color(for: level)
        return LinearGradient(
            colors: [base.opacity(0.13), base.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
