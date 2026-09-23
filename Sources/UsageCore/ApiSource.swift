import Foundation

/// OAuth usage 응답을 내부 모델로 정규화한다.
///
/// 상세는 docs/spec/usage-api.md 참조.
public enum ApiSource {
    private static let sessionKind = "session"
    private static let weeklyAllKind = "weekly_all"
    private static let weeklyScopedKind = "weekly_scoped"

    public static func normalize(json: [String: Any], observedAt: Date) -> UsageReading {
        if let limits = json["limits"] as? [[String: Any]], !limits.isEmpty {
            return fromLimits(limits, observedAt: observedAt)
        }
        return fromTopLevel(json, observedAt: observedAt)
    }

    /// `limits`가 있으면 그쪽이 권위를 갖는다.
    ///
    /// 신형 요금제에서는 top-level `seven_day_*` 키가 전부 `null`로 온다. 실측으로 확인했다.
    /// 둘을 병합하면 0%로 표시되는 행이 생긴다.
    private static func fromLimits(
        _ limits: [[String: Any]],
        observedAt: Date
    ) -> UsageReading {
        var session: Pool?
        var weeklyAll: Pool?
        var scoped: [Pool] = []

        for limit in limits {
            guard let percent = Parse.number(limit["percent"]) else { continue }
            let resetsAt = Parse.isoDate(limit["resets_at"])

            // 알 수 없는 kind는 무시한다. 새 종류가 추가되어도 파싱이 실패하지 않아야 한다.
            switch limit["kind"] as? String {
            case sessionKind:
                session = Pool(name: "session", percent: percent, resetsAt: resetsAt)
            case weeklyAllKind:
                weeklyAll = Pool(name: "weeklyAll", percent: percent, resetsAt: resetsAt)
            case weeklyScopedKind:
                // 이름이 없으면 행을 만들지 않는다. 무엇의 한도인지 알 수 없다.
                guard let name = modelName(from: limit["scope"]) else { continue }
                scoped.append(Pool(name: name, percent: percent, resetsAt: resetsAt))
            default:
                continue
            }
        }

        return UsageReading(
            observedAt: observedAt,
            session: session,
            weeklyAll: weeklyAll,
            // 응답 순서에 의존하면 행 순서가 동기화마다 바뀐다.
            weeklyScoped: scoped.sorted { $0.name < $1.name }
        )
    }

    private static func fromTopLevel(
        _ json: [String: Any],
        observedAt: Date
    ) -> UsageReading {
        let known: Set<String> = ["seven_day"]
        var scoped: [Pool] = []

        for (key, value) in json where key.hasPrefix("seven_day_") && !known.contains(key) {
            guard
                let dict = value as? [String: Any],
                let percent = Parse.number(dict["utilization"])
            else { continue }

            let slug = String(key.dropFirst("seven_day_".count))
            scoped.append(
                Pool(name: slug, percent: percent, resetsAt: Parse.isoDate(dict["resets_at"]))
            )
        }

        return UsageReading(
            observedAt: observedAt,
            session: pool(named: "session", from: json["five_hour"]),
            weeklyAll: pool(named: "weeklyAll", from: json["seven_day"]),
            weeklyScoped: scoped.sorted { $0.name < $1.name }
        )
    }

    private static func pool(named name: String, from value: Any?) -> Pool? {
        guard
            let dict = value as? [String: Any],
            let percent = Parse.number(dict["utilization"])
        else { return nil }

        return Pool(name: name, percent: percent, resetsAt: Parse.isoDate(dict["resets_at"]))
    }

    private static func modelName(from scope: Any?) -> String? {
        guard
            let scope = scope as? [String: Any],
            let model = scope["model"] as? [String: Any],
            let name = model["display_name"] as? String,
            !name.isEmpty
        else { return nil }
        return name
    }
}
