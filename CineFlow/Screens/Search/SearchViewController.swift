import UIKit
import SnapKit

final class SearchViewController: UIViewController {

    // MARK: - Properties
    private let viewModel = SearchViewModel()

    private let searchController = UISearchController(searchResultsController: nil)
    private var debounceTimer: Timer?

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .darkBackground
        tv.separatorStyle  = .none
        tv.dataSource      = self
        tv.delegate        = self
        tv.register(MovieListCell.self, forCellReuseIdentifier: MovieListCell.reuseID)
        return tv
    }()

    private let emptyStateView = EmptyStateView()
    private let loadingView    = LoadingView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "tab.search".localized
        view.backgroundColor = .darkBackground

        searchController.searchResultsUpdater              = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder             = "search.placeholder".localized
        searchController.searchBar.tintColor               = .white   // cancel (X) butonu
        searchController.searchBar.searchTextField.textColor       = .white
        searchController.searchBar.searchTextField.tintColor       = .primaryRed  // cursor
        searchController.searchBar.searchTextField.leftView?.tintColor = .subtitleGray
        searchController.searchBar.searchTextField.clearButtonMode = .never
        navigationItem.searchController                    = searchController
        navigationItem.hidesSearchBarWhenScrolling         = false
        definesPresentationContext                         = true

        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        showEmptyState(isSearching: false)
        view.addSubview(emptyStateView)
        emptyStateView.snp.makeConstraints { $0.edges.equalToSuperview() }

        loadingView.isHidden = true
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Binding
    private func bindViewModel() {
        viewModel.didUpdateResults = { [weak self] movies in
            self?.tableView.reloadData()
            let query = self?.searchController.searchBar.text ?? ""
            self?.emptyStateView.isHidden = !movies.isEmpty
            if movies.isEmpty { self?.showEmptyState(isSearching: !query.isEmpty) }
        }
        viewModel.isLoading = { [weak self] loading in
            self?.loadingView.isHidden = !loading
            loading ? self?.loadingView.startAnimating() : self?.loadingView.stopAnimating()
        }
        viewModel.didReceiveError = { [weak self] message in
            let alert = UIAlertController(title: "common.error".localized, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func showEmptyState(isSearching: Bool) {
        if isSearching {
            emptyStateView.configure(image: UIImage(systemName: "film.slash"),
                                     title: "search.empty.title".localized,
                                     subtitle: "search.empty.subtitle".localized)
        } else {
            emptyStateView.configure(image: UIImage(systemName: "magnifyingglass"),
                                     title: "search.initial.title".localized,
                                     subtitle: "search.initial.subtitle".localized)
        }
    }
}

// MARK: - UISearchResultsUpdating
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        debounceTimer?.invalidate()
        let query = searchController.searchBar.text ?? ""
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.viewModel.search(query: query)
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.movies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MovieListCell.reuseID, for: indexPath) as! MovieListCell
        cell.configure(with: viewModel.movies[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 119 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let movie = viewModel.movies[indexPath.row]
        navigationController?.pushViewController(DetailScreen.make(movieId: movie.id, movie: movie), animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.movies.count - 3 {
            viewModel.fetchNextPage()
        }
    }
}
