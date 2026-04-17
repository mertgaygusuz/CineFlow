import XCTest
@testable import CineFlow

final class SearchViewModelTests: XCTestCase {

    private var sut: SearchViewModel!
    private var mock: MockNetworkManager!

    override func setUp() {
        super.setUp()
        mock = MockNetworkManager()
        sut  = SearchViewModel(networkManager: mock)
    }

    override func tearDown() {
        sut.didUpdateResults = nil
        sut.didReceiveError  = nil
        sut.isLoading        = nil
        sut  = nil
        mock = nil
        super.tearDown()
    }

    // MARK: - search

    func test_search_withValidQuery_updatesResults() {
        let movies = [Movie.stub(id: 1), Movie.stub(id: 2), Movie.stub(id: 3)]
        mock.enqueue(Result<MovieResponse, NetworkError>.success(
            .stub(results: movies, page: 1, totalPages: 1)
        ))

        let exp = expectation(description: "results updated")
        sut.didUpdateResults = { result in
            XCTAssertEqual(result.count, 3)
            exp.fulfill()
        }

        sut.search(query: "Inception")

        waitForExpectations(timeout: 1)
    }

    func test_search_withEmptyQuery_returnsEmptyResultsWithoutNetworkCall() {
        let exp = expectation(description: "empty results")
        sut.didUpdateResults = { result in
            XCTAssertTrue(result.isEmpty)
            exp.fulfill()
        }

        sut.search(query: "   ")

        waitForExpectations(timeout: 1)
    }

    func test_search_withSameQueryTwice_doesNotMakeSecondNetworkCall() {
        mock.enqueue(Result<MovieResponse, NetworkError>.success(
            .stub(results: [Movie.stub(id: 1)], page: 1, totalPages: 1)
        ))

        var callCount = 0
        sut.didUpdateResults = { _ in callCount += 1 }

        sut.search(query: "Batman")
        sut.search(query: "Batman")

        XCTAssertEqual(callCount, 1)
    }

    func test_search_networkFailure_callsDidReceiveError() {
        mock.enqueue(Result<MovieResponse, NetworkError>.failure(.serverError(500)))

        let exp = expectation(description: "error received")
        sut.didReceiveError = { message in
            XCTAssertFalse(message.isEmpty)
            exp.fulfill()
        }

        sut.search(query: "Interstellar")

        waitForExpectations(timeout: 1)
    }

    func test_search_newQuery_resetsPreviousResults() {
        mock.enqueue(Result<MovieResponse, NetworkError>.success(
            .stub(results: [Movie.stub(id: 1), Movie.stub(id: 2)], page: 1, totalPages: 1)
        ))
        let firstExp = expectation(description: "first search done")
        sut.didUpdateResults = { _ in firstExp.fulfill() }
        sut.search(query: "Marvel")
        wait(for: [firstExp], timeout: 1)

        mock.enqueue(Result<MovieResponse, NetworkError>.success(
            .stub(results: [Movie.stub(id: 99)], page: 1, totalPages: 1)
        ))

        let exp = expectation(description: "results reset")
        sut.didUpdateResults = { movies in
            XCTAssertEqual(movies.count, 1)
            exp.fulfill()
        }

        sut.search(query: "DC")
        waitForExpectations(timeout: 1)
    }

    // MARK: - fetchNextPage

    func test_fetchNextPage_withMorePages_appendsResults() {
        let page1 = MovieResponse.stub(results: [Movie.stub(id: 1)], page: 1, totalPages: 2)
        let page2 = MovieResponse.stub(results: [Movie.stub(id: 2), Movie.stub(id: 3)], page: 2, totalPages: 2)

        mock.enqueue(Result<MovieResponse, NetworkError>.success(page1))
        let firstExp = expectation(description: "first page loaded")
        sut.didUpdateResults = { _ in firstExp.fulfill() }
        sut.search(query: "Marvel")
        wait(for: [firstExp], timeout: 1)

        mock.enqueue(Result<MovieResponse, NetworkError>.success(page2))

        let exp = expectation(description: "page 2 appended")
        sut.didUpdateResults = { movies in
            if movies.count == 3 { exp.fulfill() }
        }

        sut.fetchNextPage()
        waitForExpectations(timeout: 1)
    }

    func test_fetchNextPage_onLastPage_doesNotFetch() {
        mock.enqueue(Result<MovieResponse, NetworkError>.success(
            .stub(results: [Movie.stub(id: 1)], page: 1, totalPages: 1)
        ))
        let firstExp = expectation(description: "search done")
        sut.didUpdateResults = { _ in firstExp.fulfill() }
        sut.search(query: "DC")
        wait(for: [firstExp], timeout: 1)

        var callCount = 0
        sut.didUpdateResults = { _ in callCount += 1 }

        sut.fetchNextPage()

        XCTAssertEqual(callCount, 0)
    }
}
