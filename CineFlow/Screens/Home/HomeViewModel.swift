import Foundation

@MainActor
final class HomeViewModel {

    // MARK: - Bindings
    var didUpdateNowPlaying: (([Movie]) -> Void)?
    var didUpdateUpcoming:   (([Movie]) -> Void)?
    var didReceiveError:     ((String)  -> Void)?
    var isLoading:           ((Bool)    -> Void)?

    // MARK: - State
    private(set) var nowPlayingMovies: [Movie] = []
    private(set) var upcomingMovies:   [Movie] = []

    private var currentPage    = 1
    private var totalPages     = 1
    private var isFetchingMore = false

    private let networkManager: NetworkManagerProtocol

    init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }

    // MARK: - Public

    func loadInitialData() {
        isLoading?(true)
        currentPage = 1

        Task { [weak self] in
            guard let self else { return }

            async let nowPlayingResult: MovieResponse = networkManager.request(.nowPlaying(page: 1))
            async let upcomingResult: MovieResponse   = networkManager.request(.upcoming(page: 1))

            do {
                let response = try await nowPlayingResult
                nowPlayingMovies = response.results
                didUpdateNowPlaying?(response.results)
            } catch let error as NetworkError {
                didReceiveError?(error.message)
            } catch {
                didReceiveError?(error.localizedDescription)
            }

            do {
                let response = try await upcomingResult
                totalPages     = response.totalPages
                upcomingMovies = response.results
                didUpdateUpcoming?(upcomingMovies)
            } catch let error as NetworkError {
                didReceiveError?(error.message)
            } catch {
                didReceiveError?(error.localizedDescription)
            }

            isLoading?(false)
        }
    }

    func fetchNextPage() {
        guard !isFetchingMore, currentPage < totalPages else { return }
        isFetchingMore = true
        currentPage   += 1

        Task { [weak self] in
            guard let self else { return }
            defer { isFetchingMore = false }

            do {
                let response: MovieResponse = try await networkManager.request(.upcoming(page: currentPage))
                totalPages = response.totalPages
                upcomingMovies.append(contentsOf: response.results)
                didUpdateUpcoming?(upcomingMovies)
            } catch let error as NetworkError {
                didReceiveError?(error.message)
            } catch {
                didReceiveError?(error.localizedDescription)
            }
        }
    }
}
