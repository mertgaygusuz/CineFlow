import Foundation
import SwiftData

@Model
final class FavoriteMovie {
    @Attribute(.unique) var id: Int
    var title: String
    var overview: String
    var posterPath: String?
    var backdropPath: String?
    var releaseDate: String?
    var voteAverage: Double
    var addedAt: Date

    init(movie: Movie, addedAt: Date = .now) {
        self.id            = movie.id
        self.title         = movie.title
        self.overview      = movie.overview
        self.posterPath    = movie.posterPath
        self.backdropPath  = movie.backdropPath
        self.releaseDate   = movie.releaseDate
        self.voteAverage   = movie.voteAverage
        self.addedAt       = addedAt
    }

    var asMovie: Movie {
        Movie(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage
        )
    }
}
