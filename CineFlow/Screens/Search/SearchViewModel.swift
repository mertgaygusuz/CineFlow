import Foundation

final class SearchViewModel {

    // MARK: - Bindings
    var didUpdateResults: (([Movie]) -> Void)?
    var didReceiveError:  ((String)  -> Void)?
    var isLoading:        ((Bool)    -> Void)?

    // MARK: - State
    private(set) var movies: [Movie] = []

    private var currentQuery   = ""
    private var currentPage    = 1
    private var totalPages     = 1
    private var isFetchingMore = false

    private let networkManager: NetworkManagerProtocol

    // MARK: - Init
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }

    // MARK: - Public
    func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed != currentQuery else { return }
        currentQuery = trimmed
        currentPage  = 1
        movies       = []

        guard !trimmed.isEmpty else {
            didUpdateResults?([])
            return
        }

        isLoading?(true)
        fetch(query: trimmed, page: 1, reset: true)
    }

    func fetchNextPage() {
        guard !isFetchingMore, currentPage < totalPages, !currentQuery.isEmpty else { return }
        isFetchingMore = true
        currentPage   += 1
        fetch(query: currentQuery, page: currentPage, reset: false)
    }

    // MARK: - Private
    private func fetch(query: String, page: Int, reset: Bool) {
        networkManager.request(.search(query: query, page: page)) { [weak self] (result: Result<MovieResponse, NetworkError>) in
            DispatchQueue.main.async {
                self?.isLoading?(false)
                self?.isFetchingMore = false
                switch result {
                case .success(let response):
                    self?.totalPages = response.totalPages
                    if reset {
                        self?.movies = response.results
                    } else {
                        self?.movies.append(contentsOf: response.results)
                    }
                    self?.didUpdateResults?(self?.movies ?? [])
                case .failure(let error):
                    self?.didReceiveError?(error.message)
                }
            }
        }
    }
}
