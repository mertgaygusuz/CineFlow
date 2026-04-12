import UIKit
import SnapKit

final class HomeViewController: UIViewController {

    // MARK: - Properties
    private let viewModel = HomeViewModel()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor  = .darkBackground
        tv.separatorStyle   = .none
        tv.dataSource       = self
        tv.delegate         = self
        tv.refreshControl   = refreshControl
        tv.register(MovieListCell.self, forCellReuseIdentifier: MovieListCell.reuseID)
        return tv
    }()

    private let sliderView     = NowPlayingSliderView()
    private let refreshControl = UIRefreshControl()
    private let loadingView    = LoadingView()
    private let emptyStateView = EmptyStateView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.loadInitialData()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "CineFlow"
        view.backgroundColor = .darkBackground

        let sliderHeight = UIScreen.main.bounds.width * (9.0 / 16.0)
        sliderView.delegate = self
        sliderView.frame    = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: sliderHeight)
        tableView.tableHeaderView = sliderView

        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }

        emptyStateView.configure(image: UIImage(systemName: "film"),
                                 title: "Film Bulunamadı",
                                 subtitle: "Yaklaşan filmler yüklenemedi.")
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        emptyStateView.snp.makeConstraints { $0.edges.equalToSuperview() }

        refreshControl.tintColor = .primaryRed
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }

    // MARK: - Binding
    private func bindViewModel() {
        viewModel.didUpdateNowPlaying = { [weak self] movies in
            self?.sliderView.configure(with: movies)
        }
        viewModel.didUpdateUpcoming = { [weak self] movies in
            self?.tableView.reloadData()
            self?.emptyStateView.isHidden = !movies.isEmpty
        }
        viewModel.isLoading = { [weak self] loading in
            loading ? self?.loadingView.startAnimating() : self?.loadingView.stopAnimating()
            if !loading { self?.refreshControl.endRefreshing() }
        }
        viewModel.didReceiveError = { [weak self] msg in
            self?.showErrorAlert(msg)
        }
    }

    @objc private func handleRefresh() { viewModel.loadInitialData() }

    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension HomeViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.upcomingMovies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MovieListCell.reuseID, for: indexPath) as! MovieListCell
        cell.configure(with: viewModel.upcomingMovies[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 119 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let movie = viewModel.upcomingMovies[indexPath.row]
        navigationController?.pushViewController(DetailViewController(movieId: movie.id, movie: movie), animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.upcomingMovies.count - 3 {
            viewModel.fetchNextPage()
        }
    }
}

// MARK: - NowPlayingSliderViewDelegate
extension HomeViewController: NowPlayingSliderViewDelegate {
    func sliderView(_ sliderView: NowPlayingSliderView, didSelectMovie movie: Movie) {
        navigationController?.pushViewController(DetailViewController(movieId: movie.id, movie: movie), animated: true)
    }
}
