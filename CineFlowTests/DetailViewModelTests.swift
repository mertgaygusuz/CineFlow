import XCTest
import SwiftData
@testable import CineFlow

@MainActor
final class DetailViewModelTests: XCTestCase {

    private var sut: DetailViewModel!
    private var mock: MockNetworkManager!
    private var favoritesManager: FavoritesManager!
    private let stubMovie = Movie.stub(id: 42)

    override func setUp() async throws {
        try await super.setUp()
        mock = MockNetworkManager()
        let container = try ModelContainer(
            for: FavoriteMovie.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        favoritesManager = FavoritesManager(container: container)
        sut = DetailViewModel(
            movieId: 42,
            movie: stubMovie,
            networkManager: mock,
            favoritesManager: favoritesManager
        )
    }

    override func tearDown() async throws {
        sut = nil
        mock = nil
        favoritesManager = nil
        try await super.tearDown()
    }

    // MARK: - loadAll

    func test_loadAll_success_publishesDetailCreditsTrailer() async {
        let detail  = MovieDetail.stub(id: 42)
        let credits = CreditsResponse(cast: [CastMember.stub()])
        let videos  = VideosResponse(results: [Video.stub()])

        mock.enqueue(Result<MovieDetail, NetworkError>.success(detail))
        mock.enqueue(Result<CreditsResponse, NetworkError>.success(credits))
        mock.enqueue(Result<VideosResponse, NetworkError>.success(videos))

        await sut.loadAll()

        XCTAssertEqual(sut.detail?.id, 42)
        XCTAssertEqual(sut.cast.count, 1)
        XCTAssertNotNil(sut.trailer)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadAll_detailFailure_setsErrorMessage() async {
        mock.enqueue(Result<MovieDetail, NetworkError>.failure(.noInternet))
        mock.enqueue(Result<CreditsResponse, NetworkError>.failure(.noInternet))
        mock.enqueue(Result<VideosResponse, NetworkError>.failure(.noInternet))

        await sut.loadAll()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertNil(sut.detail)
    }

    // MARK: - toggleFavorite

    func test_toggleFavorite_addsToFavorites() {
        XCTAssertFalse(sut.isFavorite)
        sut.toggleFavorite()
        XCTAssertTrue(sut.isFavorite)
        XCTAssertTrue(favoritesManager.isFavorite(stubMovie))
    }

    func test_toggleFavorite_removesFromFavorites() {
        favoritesManager.toggleFavorite(stubMovie)
        let vm = DetailViewModel(
            movieId: 42, movie: stubMovie,
            networkManager: mock, favoritesManager: favoritesManager
        )
        XCTAssertTrue(vm.isFavorite)

        vm.toggleFavorite()

        XCTAssertFalse(vm.isFavorite)
        XCTAssertFalse(favoritesManager.isFavorite(stubMovie))
    }

    func test_isFavorite_reflectsInitialState() {
        XCTAssertFalse(sut.isFavorite)
        favoritesManager.toggleFavorite(stubMovie)
        let vm = DetailViewModel(
            movieId: 42, movie: stubMovie,
            networkManager: mock, favoritesManager: favoritesManager
        )
        XCTAssertTrue(vm.isFavorite)
    }
}
