enum NetworkError: Error {
    case serverError(Int)
    case decodingError
    case noInternet
    case unknown(String)

    var message: String {
        switch self {
        case .serverError(let code): return "Server error: \(code)"
        case .decodingError:         return "Failed to decode response."
        case .noInternet:            return "No internet connection."
        case .unknown(let msg):      return msg
        }
    }
}
