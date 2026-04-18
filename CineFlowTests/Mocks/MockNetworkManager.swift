@testable import CineFlow

final class MockNetworkManager: NetworkManagerProtocol {
    private var queue: [Any] = []
    private(set) var requestCount = 0

    func enqueue<T>(_ result: Result<T, NetworkError>) {
        queue.append(result)
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        requestCount += 1
        guard !queue.isEmpty, let result = queue.removeFirst() as? Result<T, NetworkError> else {
            throw NetworkError.unknown("No mock response enqueued")
        }
        switch result {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
