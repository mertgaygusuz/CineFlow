enum NetworkError: Error {
    case serverError(Int)
    case decodingError
    case noInternet
    case unknown(String)

    var message: String {
        switch self {
        case .serverError(let code): return "error.server".localized(with: code)
        case .decodingError:         return "error.decode".localized
        case .noInternet:            return "error.internet".localized
        case .unknown(let msg):      return msg
        }
    }
}
