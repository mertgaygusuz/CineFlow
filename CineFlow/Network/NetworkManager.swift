import Foundation
import Alamofire

// MARK: - Protocol
protocol NetworkManagerProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

// MARK: - Implementation
final class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "https://api.themoviedb.org/3"

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let url = baseURL + endpoint.path
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, parameters: endpoint.parameters)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        if let statusCode = response.response?.statusCode {
                            continuation.resume(throwing: NetworkError.serverError(statusCode))
                        } else if let urlError = error.underlyingError as? URLError,
                                  urlError.code == .notConnectedToInternet {
                            continuation.resume(throwing: NetworkError.noInternet)
                        } else {
                            continuation.resume(throwing: NetworkError.unknown(error.localizedDescription))
                        }
                    }
                }
        }
    }
}
