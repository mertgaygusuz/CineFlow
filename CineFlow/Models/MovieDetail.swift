import Foundation

struct MovieDetail: Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let imdbId: String?
    let runtime: Int?
    let genres: [Genre]?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres
        case posterPath   = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate  = "release_date"
        case voteAverage  = "vote_average"
        case imdbId       = "imdb_id"
    }

    var posterURL: URL? {
        posterPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
    }

    var backdropURL: URL? {
        backdropPath.flatMap { URL(string: "https://image.tmdb.org/t/p/w780\($0)") }
    }

    var imdbURL: URL? {
        imdbId.flatMap { URL(string: "https://www.imdb.com/title/\($0)") }
    }
}

struct Genre: Codable {
    let id: Int
    let name: String
}
