import Foundation

@MainActor
final class DetailViewModel {

    // MARK: - Bindings
    var didUpdateDetail:         ((MovieDetail)   -> Void)?
    var didUpdateCredits:        (([CastMember])  -> Void)?
    var didUpdateTrailer:        ((Video?)        -> Void)?
    var didReceiveError:         ((String)        -> Void)?
    var isLoading:               ((Bool)          -> Void)?
    var didUpdateFavoriteStatus: ((Bool)          -> Void)?

    // MARK: - State
    private(set) var movieDetail: MovieDetail?

    private let movieId:          Int
    private let movieSnapshot:    Movie?
    private let networkManager:   NetworkManagerProtocol
    private let favoritesManager: FavoritesManager

    // MARK: - Init
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
    }

    // MARK: - Computed
    var isFavorite: Bool {
        movieSnapshot.map { favoritesManager.isFavorite($0) } ?? false
    }

    // MARK: - Public
    func loadAll() {
        isLoading?(true)

        Task { [weak self] in
            guard let self else { return }

            async let detailResult: MovieDetail       = networkManager.request(.movieDetail(id: movieId))
            async let creditsResult: CreditsResponse  = networkManager.request(.credits(id: movieId))
            async let videosResult: VideosResponse    = networkManager.request(.videos(id: movieId))

            do {
                let detail = try await detailResult
                movieDetail = detail
                didUpdateDetail?(detail)
            } catch let error as NetworkError {
                didReceiveError?(error.message)
            } catch {
                didReceiveError?(error.localizedDescription)
            }

            if let credits = try? await creditsResult {
                didUpdateCredits?(Array(credits.cast.prefix(15)))
            }

            if let videos = try? await videosResult {
                let trailer = videos.results.first { $0.isYouTubeTrailer }
                didUpdateTrailer?(trailer)
            }

            isLoading?(false)
        }
    }

    func toggleFavorite() {
        guard let movie = movieSnapshot else { return }
        favoritesManager.toggleFavorite(movie)
        didUpdateFavoriteStatus?(favoritesManager.isFavorite(movie))
    }

    var imdbURL: URL? { movieDetail?.imdbURL }
}
