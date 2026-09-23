import Combine
import SwiftUI
import UsageCore

struct PopoverView: View {
    @ObservedObject var state: AppState

    @State private var now = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// `now`가 1초마다 바뀌므로 대기가 끝나면 버튼이 저절로 다시 켜진다.
    private var canRefresh: Bool { _ = now; return state.canRefresh }

    private var icon: String {
        switch state.loadState {
        case .needsAuth: return "person.crop.circle.badge.exclamationmark"
        case .rateLimited: return "hourglass"
        case .failed: return "exclamationmark.triangle"
        case .idle, .ok: return "arrow.clockwise"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.cardSpacing) {
            header

            if let reading = state.reading {
                cards(for: reading)
            } else {
                emptyState
            }

            settings
            footer
        }
        .padding(14)
        .frame(width: Theme.popoverWidth)
        .background(Theme.surface)
        .onReceive(tick) { now = $0 }
    }

    private var header: some View {
        HStack {
            Text(state.strings("app.name"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.title)

            Spacer()

            Button {
                Task { await state.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(canRefresh ? Theme.label : Theme.muted)
            }
            .buttonStyle(.plain)
            .disabled(!canRefresh)
            .help(state.strings("action.refresh"))
        }
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func cards(for reading: UsageReading) -> some View {
        if let session = reading.session {
            card(title: state.strings("pool.session"), pool: session)
        }
        if let weekly = reading.weeklyAll {
            card(title: state.strings("pool.weeklyAll"), pool: weekly)
        }
        // 값이 nil인 풀은 행 자체를 만들지 않는다. 0%로 표시하면 사용량이 없는 것처럼 보인다.
        ForEach(reading.weeklyScoped, id: \.name) { pool in
            card(title: state.strings("pool.weeklyScoped", ["name": pool.name]), pool: pool)
        }
    }

    private func card(title: String, pool: Pool) -> some View {
        PoolCard(
            title: title,
            pool: pool,
            level: state.thresholds.level(for: pool.percent),
            now: now,
            strings: state.strings
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.muted)
            Text(state.emptyStateMessage(at: now))
                .font(.system(size: 12))
                .foregroundStyle(Theme.label)
                .fixedSize(horizontal: false, vertical: true)
            if let retry = state.retryMessage(at: now) {
                Text(retry)
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
    }

    private var settings: some View {
        HStack {
            Text(state.strings("settings.syncInterval"))
                .font(.system(size: 11))
                .foregroundStyle(Theme.label)

            Spacer()

            Picker("", selection: $state.syncInterval) {
                ForEach(SyncInterval.allCases, id: \.self) { interval in
                    Text(state.strings(interval.labelKey)).tag(interval)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 84)
            .font(.system(size: 11))
        }
        .padding(.horizontal, 2)
        .padding(.top, 2)
    }

    private var footer: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 1) {
                if let updated = state.lastUpdated {
                    Text(state.strings("status.lastSync", ["time": Format.clock.string(from: updated)]))
                }
                if let notice = state.notice {
                    Text(notice).foregroundStyle(Theme.color(for: .warning))
                }
                if state.reading != nil, let retry = state.retryMessage(at: now) {
                    Text(retry).monospacedDigit()
                }
            }
            .font(.system(size: 10))
            .foregroundStyle(Theme.muted)

            Spacer()

            Button(state.strings("action.quit")) {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 10))
            .foregroundStyle(Theme.muted)
        }
        .padding(.top, 2)
    }
}

private struct PoolCard: View {
    let title: String
    let pool: Pool
    let level: UsageLevel
    let now: Date
    let strings: Strings

    private var accent: Color { Theme.color(for: level) }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.label)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(pool.percent))")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.fill(for: level))
                Text("%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }

            UsageBar(percent: pool.percent, level: level)

            if let countdown = countdown(resetsAt: pool.resetsAt, now: now) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        countdown.isStale
                            ? strings("reset.soon")
                            : strings("reset.countdown", [
                                "time": formatCountdown(countdown, style: .popover)
                              ])
                    )
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.countdown)

                    if let resetsAt = pool.resetsAt {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9, weight: .semibold))
                            Text(Format.resetPoint.string(from: resetsAt))
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(Theme.muted)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .fill(Theme.cardFill(for: level))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .strokeBorder(accent.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct UsageBar: View {
    let percent: Double
    let level: UsageLevel

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                Capsule()
                    .fill(Theme.fill(for: level))
                    .frame(width: geometry.size.width * min(max(percent, 0), 100) / 100)
                    .shadow(color: Theme.color(for: level).opacity(0.5), radius: 4, y: 0)
            }
        }
        .frame(height: 8)
    }
}

private enum Format {
    static let clock = formatter("a h:mm")
    static let resetPoint = formatter("M/d(E) a h시")

    private static func formatter(_ template: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = template
        return formatter
    }
}
