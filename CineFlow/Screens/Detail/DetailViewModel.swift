import Foundation
import Combine

@MainActor
final class DetailViewModel: ObservableObject {

    @Published private(set) var detail: MovieDetail?
    @Published private(set) var cast: [CastMember] = []
    @Published private(set) var trailer: Video?
    @Published private(set) var isLoading = false
    @Published private(set) var isFavorite = false
    @Published var errorMessage: String?

    let movieId: Int
    private let movieSnapshot: Movie?
    private let networkManager: NetworkManagerProtocol
    private let favoritesManager: FavoritesManager

    init(
        movieId: Int,
        movie: Movie? = nil,
        networkManager: NetworkManagerProtocol = NetworkManager.shared,
        favoritesManager: FavoritesManager = .shared
    ) {
        self.movieId          = movieId
        self.movieSnapshot    = movie
        self.networkManager   = networkManager
        self.favoritesManager = favoritesManager
        self.isFavorite       = movie.map { favoritesManager.isFavorite($0) } ?? false
    }

    var imdbURL: URL? { detail?.imdbURL }

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }

        async let detailResult: MovieDetail      = networkManager.request(.movieDetail(id: movieId))
        async let creditsResult: CreditsResponse = networkManager.request(.credits(id: movieId))
        async let videosResult: VideosResponse   = networkManager.request(.videos(id: movieId))

        do {
            detail = try await detailResult
        } catch let error as NetworkError {
            errorMessage = error.message
            return
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        if let credits = try? await creditsResult {
            cast = Array(credits.cast.prefix(15))
        }
        if let videos = try? await videosResult {
            trailer = videos.results.first { $0.isYouTubeTrailer }
        }
    }

    func toggleFavorite() {
        guard let movie = movieSnapshot else { return }
        favoritesManager.toggleFavorite(movie)
        isFavorite = favoritesManager.isFavorite(movie)
    }
}
