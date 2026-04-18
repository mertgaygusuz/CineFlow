import XCTest
@testable import CineFlow

@MainActor
final class DetailViewModelTests: XCTestCase {

    private var sut: DetailViewModel!
    private var mock: MockNetworkManager!
    private let stubMovie = Movie.stub(id: 42)

    override func setUp() async throws {
        try await super.setUp()
        mock = MockNetworkManager()
        sut  = DetailViewModel(movieId: 42, movie: stubMovie, networkManager: mock)
    }

    override func tearDown() async throws {
        FavoritesManager.shared.removeFavorite(stubMovie)
        sut  = nil
        mock = nil
        try await super.tearDown()
    }

    // MARK: - loadAll

    func test_loadAll_success_callsDidUpdateDetail() async {
        let detail  = MovieDetail.stub(id: 42)
        let credits = CreditsResponse(cast: [CastMember.stub()])
        let videos  = VideosResponse(results: [Video.stub()])

        mock.enqueue(Result<MovieDetail, NetworkError>.success(detail))
        mock.enqueue(Result<CreditsResponse, NetworkError>.success(credits))
        mock.enqueue(Result<VideosResponse, NetworkError>.success(videos))

        let detailExp  = expectation(description: "detail updated")
        let creditsExp = expectation(description: "credits updated")
        let trailerExp = expectation(description: "trailer updated")

        sut.didUpdateDetail  = { _ in detailExp.fulfill() }
        sut.didUpdateCredits = { cast in
            XCTAssertEqual(cast.count, 1)
            creditsExp.fulfill()
        }
        sut.didUpdateTrailer = { video in
            XCTAssertNotNil(video)
            trailerExp.fulfill()
        }

        sut.loadAll()

        await fulfillment(of: [detailExp, creditsExp, trailerExp], timeout: 1)
    }

    func test_loadAll_detailFailure_callsDidReceiveError() async {
        mock.enqueue(Result<MovieDetail, NetworkError>.failure(.noInternet))
        mock.enqueue(Result<CreditsResponse, NetworkError>.failure(.noInternet))
        mock.enqueue(Result<VideosResponse, NetworkError>.failure(.noInternet))

        let exp = expectation(description: "error received")
        sut.didReceiveError = { message in
            XCTAssertFalse(message.isEmpty)
            exp.fulfill()
        }

        sut.loadAll()

        await fulfillment(of: [exp], timeout: 1)
    }

    // MARK: - toggleFavorite

    func test_toggleFavorite_addsToFavorites() async {
        let exp = expectation(description: "favorite added")
        sut.didUpdateFavoriteStatus = { isFav in
            XCTAssertTrue(isFav)
            exp.fulfill()
        }

        sut.toggleFavorite()

        await fulfillment(of: [exp], timeout: 1)
        XCTAssertTrue(FavoritesManager.shared.isFavorite(stubMovie))
    }

    func test_toggleFavorite_removeFromFavorites() async {
        FavoritesManager.shared.toggleFavorite(stubMovie)

        let exp = expectation(description: "favorite removed")
        sut.didUpdateFavoriteStatus = { isFav in
            XCTAssertFalse(isFav)
            exp.fulfill()
        }

        sut.toggleFavorite()

        await fulfillment(of: [exp], timeout: 1)
        XCTAssertFalse(FavoritesManager.shared.isFavorite(stubMovie))
    }

    func test_isFavorite_reflectsCurrentState() async {
        XCTAssertFalse(sut.isFavorite)
        FavoritesManager.shared.toggleFavorite(stubMovie)
        let sutWithFav = DetailViewModel(movieId: 42, movie: stubMovie, networkManager: mock)
        XCTAssertTrue(sutWithFav.isFavorite)
    }
}
