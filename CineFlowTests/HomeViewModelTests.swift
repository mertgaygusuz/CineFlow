import XCTest
@testable import CineFlow

final class HomeViewModelTests: XCTestCase {

    private var sut: HomeViewModel!
    private var mock: MockNetworkManager!

    override func setUp() {
        super.setUp()
        mock = MockNetworkManager()
        sut  = HomeViewModel(networkManager: mock)
    }

    override func tearDown() {
        sut  = nil
        mock = nil
        super.tearDown()
    }

    // MARK: - loadInitialData

    func test_loadInitialData_success_updatesNowPlayingAndUpcoming() {
        let nowPlayingMovies = [Movie.stub(id: 1), Movie.stub(id: 2)]
        let upcomingMovies   = [Movie.stub(id: 3), Movie.stub(id: 4)]

        mock.enqueue(Result<MovieResponse, NetworkError>.success(
            .stub(results: nowPlayingMovies, page: 1, totalPages: 1)
        ))
        mock.enqueue(Result<MovieResponse, NetworkError>.success(
            .stub(results: upcomingMovies, page: 1, totalPages: 3)
        ))

        let nowPlayingExp = expectation(description: "nowPlaying updated")
        let upcomingExp   = expectation(description: "upcoming updated")

        sut.didUpdateNowPlaying = { movies in
            XCTAssertEqual(movies.count, 2)
            nowPlayingExp.fulfill()
        }
        sut.didUpdateUpcoming = { movies in
            XCTAssertEqual(movies.count, 2)
            upcomingExp.fulfill()
        }

        sut.loadInitialData()

        waitForExpectations(timeout: 1)
    }

    func test_loadInitialData_networkFailure_callsDidReceiveError() {
        mock.enqueue(Result<MovieResponse, NetworkError>.failure(.noInternet))
        mock.enqueue(Result<MovieResponse, NetworkError>.failure(.noInternet))

        let exp = expectation(description: "error received")
        sut.didReceiveError = { message in
            XCTAssertFalse(message.isEmpty)
            exp.fulfill()
        }

        sut.loadInitialData()

        waitForExpectations(timeout: 1)
    }

    func test_loadInitialData_resetsUpcomingMovies() {
        let firstLoad = MovieResponse.stub(results: [Movie.stub(id: 1), Movie.stub(id: 2)], page: 1, totalPages: 1)
        mock.enqueue(Result<MovieResponse, NetworkError>.success(.stub()))
        mock.enqueue(Result<MovieResponse, NetworkError>.success(firstLoad))
        sut.loadInitialData()

        let secondLoad = MovieResponse.stub(results: [Movie.stub(id: 99)], page: 1, totalPages: 1)
        mock.enqueue(Result<MovieResponse, NetworkError>.success(.stub()))
        mock.enqueue(Result<MovieResponse, NetworkError>.success(secondLoad))

        let exp = expectation(description: "upcoming reset on reload")
        sut.didUpdateUpcoming = { movies in
            XCTAssertEqual(movies.count, 1)
            exp.fulfill()
        }

        sut.loadInitialData()

        waitForExpectations(timeout: 1)
    }

    // MARK: - fetchNextPage

    func test_fetchNextPage_appendsToExistingMovies() {
        let page1 = MovieResponse.stub(results: [Movie.stub(id: 1), Movie.stub(id: 2)], page: 1, totalPages: 2)
        let page2 = MovieResponse.stub(results: [Movie.stub(id: 3)], page: 2, totalPages: 2)

        mock.enqueue(Result<MovieResponse, NetworkError>.success(.stub()))
        mock.enqueue(Result<MovieResponse, NetworkError>.success(page1))
        sut.loadInitialData()

        mock.enqueue(Result<MovieResponse, NetworkError>.success(page2))

        let exp = expectation(description: "page 2 appended")
        sut.didUpdateUpcoming = { movies in
            if movies.count == 3 { exp.fulfill() }
        }

        sut.fetchNextPage()

        waitForExpectations(timeout: 1)
    }

    func test_fetchNextPage_onLastPage_doesNotFetch() {
        mock.enqueue(Result<MovieResponse, NetworkError>.success(.stub()))
        mock.enqueue(Result<MovieResponse, NetworkError>.success(
            .stub(results: [Movie.stub(id: 1)], page: 1, totalPages: 1)
        ))
        sut.loadInitialData()

        var callCount = 0
        sut.didUpdateUpcoming = { _ in callCount += 1 }

        sut.fetchNextPage()

        XCTAssertEqual(callCount, 0)
    }
}
