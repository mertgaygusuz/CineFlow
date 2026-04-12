import Foundation

final class HomeViewModel {

    // MARK: - Bindings
    var didUpdateNowPlaying: (([Movie]) -> Void)?
    var didUpdateUpcoming:   (([Movie]) -> Void)?
    var didReceiveError:     ((String)  -> Void)?
    var isLoading:           ((Bool)    -> Void)?

    // MARK: - State
    private(set) var nowPlayingMovies: [Movie] = []
    private(set) var upcomingMovies:   [Movie] = []

    private var currentPage   = 1
    private var totalPages    = 1
    private var isFetchingMore = false

    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }

    // MARK: - Public

    func loadInitialData() {
        isLoading?(true)
        currentPage = 1

        let group = DispatchGroup()

        group.enter()
        fetchNowPlaying { group.leave() }

        group.enter()
        fetchUpcoming(page: 1, reset: true) { group.leave() }

        group.notify(queue: .main) { [weak self] in
            self?.isLoading?(false)
        }
    }

    func fetchNextPage() {
        guard !isFetchingMore, currentPage < totalPages else { return }
        isFetchingMore = true
        currentPage += 1
        fetchUpcoming(page: currentPage, reset: false) { [weak self] in
            self?.isFetchingMore = false
        }
    }

    // MARK: - Private

    private func fetchNowPlaying(completion: @escaping () -> Void) {
        networkManager.request(.nowPlaying(page: 1)) { [weak self] (result: Result<MovieResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.nowPlayingMovies = response.results
                    self?.didUpdateNowPlaying?(response.results)
                case .failure(let error):
                    self?.didReceiveError?(error.message)
                }
                completion()
            }
        }
    }

    private func fetchUpcoming(page: Int, reset: Bool, completion: @escaping () -> Void) {
        networkManager.request(.upcoming(page: page)) { [weak self] (result: Result<MovieResponse, NetworkError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.totalPages = response.totalPages
                    if reset {
                        self?.upcomingMovies = response.results
                    } else {
                        self?.upcomingMovies.append(contentsOf: response.results)
                    }
                    self?.didUpdateUpcoming?(self?.upcomingMovies ?? [])
                case .failure(let error):
                    self?.didReceiveError?(error.message)
                }
                completion()
            }
        }
    }
}
