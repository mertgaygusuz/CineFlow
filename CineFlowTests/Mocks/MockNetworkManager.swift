@testable import CineFlow

final class MockNetworkManager: NetworkManagerProtocol {
    private var queue: [Any] = []

    func enqueue<T>(_ result: Result<T, NetworkError>) {
        queue.append(result)
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint, completion: @escaping (Result<T, NetworkError>) -> Void) {
        guard !queue.isEmpty, let result = queue.removeFirst() as? Result<T, NetworkError> else { return }
        completion(result)
    }
}
