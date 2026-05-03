import Foundation

protocol NetworkManagerProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

final class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()

    private let baseURL = "https://api.themoviedb.org/3"
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            throw NetworkError.unknown("Invalid URL")
        }
        components.queryItems = endpoint.parameters.map { key, value in
            URLQueryItem(name: key, value: "\(value)")
        }
        guard let url = components.url else {
            throw NetworkError.unknown("Invalid URL")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.noInternet
        } catch {
            throw NetworkError.unknown(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.unknown("Invalid response")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw NetworkError.serverError(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}
