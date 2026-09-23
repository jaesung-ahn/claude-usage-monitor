import Foundation
import UsageCore

/// 사용량을 가져오는 경로.
///
/// `AppState`가 구체 타입에 묶이지 않게 하는 이음매다. 앱 계층 테스트를 붙일 때 이 지점에
/// 대역을 넣는다.
protocol UsageProviding {
    func fetch(now: Date) async throws -> UsageReading
}

extension UsageClient: UsageProviding {}
