import Foundation

final class DetailViewModel {

    // MARK: - Bindings
    var didUpdateDetail:       ((MovieDetail) -> Void)?
    var didReceiveError:       ((String)      -> Void)?
    var isLoading:             ((Bool)        -> Void)?
    var didUpdateFavoriteStatus: ((Bool)      -> Void)?

    // MARK: - State
    private(set) var movieDetail: MovieDetail?

    private let movieId:         Int
    private let movieSnapshot:   Movie?
    private let networkManager:  NetworkManagerProtocol
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
    func loadDetail() {
        isLoading?(true)
        networkManager.request(.movieDetail(id: movieId)) { [weak self] (result: Result<MovieDetail, NetworkError>) in
            DispatchQueue.main.async {
                self?.isLoading?(false)
                switch result {
                case .success(let detail):
                    self?.movieDetail = detail
                    self?.didUpdateDetail?(detail)
                case .failure(let error):
                    self?.didReceiveError?(error.message)
                }
            }
        }
    }

    func toggleFavorite() {
        guard let movie = movieSnapshot else { return }
        favoritesManager.toggleFavorite(movie)
        didUpdateFavoriteStatus?(favoritesManager.isFavorite(movie))
    }

    var imdbURL: URL? { movieDetail?.imdbURL }
}
