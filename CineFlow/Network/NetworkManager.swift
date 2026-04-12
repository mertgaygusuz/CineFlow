import Foundation
import Alamofire

// MARK: - Protocol (abstraction over Alamofire)
protocol NetworkManagerProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint, completion: @escaping (Result<T, NetworkError>) -> Void)
}

// MARK: - Implementation
final class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "https://api.themoviedb.org/3"

    func request<T: Decodable>(_ endpoint: APIEndpoint, completion: @escaping (Result<T, NetworkError>) -> Void) {
        let url = baseURL + endpoint.path
        AF.request(url, parameters: endpoint.parameters)
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        completion(.failure(.serverError(statusCode)))
                    } else if let urlError = error.underlyingError as? URLError,
                              urlError.code == .notConnectedToInternet {
                        completion(.failure(.noInternet))
                    } else {
                        completion(.failure(.unknown(error.localizedDescription)))
                    }
                }
            }
    }
}
