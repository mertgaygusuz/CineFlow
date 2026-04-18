import Foundation

@MainActor
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
        Task { [weak self] in
            guard let self else { return }

            do {
                let response: MovieResponse = try await networkManager.request(.search(query: query, page: page))
                totalPages = response.totalPages
                if reset {
                    movies = response.results
                } else {
                    movies.append(contentsOf: response.results)
                }
                didUpdateResults?(movies)
            } catch let error as NetworkError {
                didReceiveError?(error.message)
            } catch {
                didReceiveError?(error.localizedDescription)
            }
            isLoading?(false)
            isFetchingMore = false
        }
    }
}
