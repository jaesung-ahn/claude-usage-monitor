import Foundation
import UsageCore

/// 사용량 조회 상태.
enum LoadState: Equatable {
    case idle
    case ok
    case needsAuth
    case rateLimited
    case failed
}

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var reading: UsageReading?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var loadState: LoadState = .idle

    /// 변경되면 타이머를 다시 잡아야 하므로 관찰 가능해야 한다.
    @Published var syncInterval: SyncInterval {
        didSet { defaults.set(syncInterval.rawValue, forKey: Self.syncIntervalKey) }
    }

    let strings: Strings
    let thresholds: Thresholds

    private let client: UsageProviding
    private let defaults: UserDefaults

    private static let syncIntervalKey = "syncIntervalSeconds"

    init(
        client: UsageProviding = UsageClient(tokenStore: TokenStore()),
        thresholds: Thresholds = .default,
        defaults: UserDefaults = .standard
    ) {
        self.client = client
        self.thresholds = thresholds
        self.defaults = defaults
        self.strings = Self.loadStrings()

        // 저장된 적이 없으면 0이 나온다. from(seconds:)이 기본값으로 되돌린다.
        self.syncInterval = SyncInterval.from(
            seconds: defaults.integer(forKey: Self.syncIntervalKey)
        )
    }

    /// 실패해도 마지막 성공 값을 지우지 않는다. 오래된 값이라도 없는 것보다 낫다.
    func refresh(now: Date = Date()) async {
        do {
            reading = try await client.fetch(now: now)
            lastUpdated = now
            loadState = .ok
        } catch UsageClientError.noToken, UsageClientError.unauthorized {
            loadState = .needsAuth
        } catch UsageClientError.rateLimited {
            loadState = .rateLimited
        } catch {
            loadState = .failed
        }
    }

    /// 상태 줄에 띄울 안내. 정상이면 표시하지 않는다.
    var notice: String? {
        switch loadState {
        case .idle, .ok: return nil
        case .needsAuth: return strings("status.needsAuth")
        case .rateLimited: return strings("status.rateLimited")
        case .failed: return strings("status.apiFailed")
        }
    }

    private static func loadStrings() -> Strings {
        guard
            let url = Paths.locale("ko"),
            let strings = try? Strings(contentsOf: url)
        else {
            // 문자열 파일을 못 찾으면 키가 그대로 보인다. 조용히 빈 화면이 되는 것보다 낫다.
            return Strings(table: [:])
        }
        return strings
    }
}
