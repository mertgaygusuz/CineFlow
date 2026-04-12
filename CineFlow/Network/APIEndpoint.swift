import Foundation

enum APIEndpoint {
    case nowPlaying(page: Int)
    case upcoming(page: Int)
    case movieDetail(id: Int)
    case search(query: String, page: Int)

    var path: String {
        switch self {
        case .nowPlaying:          return "/movie/now_playing"
        case .upcoming:            return "/movie/upcoming"
        case .movieDetail(let id): return "/movie/\(id)"
        case .search:              return "/search/movie"
        }
    }

    var parameters: [String: Any] {
        var params: [String: Any] = [
            "api_key": AppConstants.apiKey,
            "language": "en-US"
        ]
        switch self {
        case .nowPlaying(let page):
            params["page"] = page
        case .upcoming(let page):
            params["page"] = page
        case .movieDetail:
            break
        case .search(let query, let page):
            params["query"] = query
            params["page"] = page
        }
        return params
    }
}
