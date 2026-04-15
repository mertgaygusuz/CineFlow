@testable import CineFlow

extension Movie {
    static func stub(id: Int = 1) -> Movie {
        Movie(
            id: id,
            title: "Test Movie \(id)",
            overview: "Overview for movie \(id)",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2024-01-01",
            voteAverage: 7.5
        )
    }
}

extension MovieDetail {
    static func stub(id: Int = 1) -> MovieDetail {
        MovieDetail(
            id: id,
            title: "Test Movie \(id)",
            overview: "Overview for movie \(id)",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2024-01-01",
            voteAverage: 7.5,
            imdbId: "tt1234567",
            runtime: 120,
            genres: [Genre(id: 28, name: "Action")]
        )
    }
}

extension CastMember {
    static func stub() -> CastMember {
        CastMember(id: 1, name: "Actor Name", character: "Character", profilePath: nil)
    }
}

extension Video {
    static func stub() -> Video {
        Video(id: "v1", key: "abc123", name: "Official Trailer", site: "YouTube", type: "Trailer")
    }
}

extension MovieResponse {
    static func stub(results: [Movie] = [], page: Int = 1, totalPages: Int = 1) -> MovieResponse {
        MovieResponse(page: page, results: results, totalPages: totalPages, totalResults: results.count)
    }
}
