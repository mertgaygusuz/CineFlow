import UIKit
import SnapKit

final class FavoritesViewController: UIViewController {

    private let viewModel = FavoritesViewModel()

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadFavorites()
    }

    private func setupUI() {
        title = "tab.favorites".localized
        view.backgroundColor = .darkBackground

        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        emptyStateView.configure(image: UIImage(systemName: "heart.slash"),
                                 title: "favorites.empty.title".localized,
                                 subtitle: "favorites.empty.subtitle".localized)
        view.addSubview(emptyStateView)
        emptyStateView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func bindViewModel() {
        viewModel.didUpdateFavorites = { [weak self] movies in
            self?.tableView.reloadData()
            self?.emptyStateView.isHidden = !movies.isEmpty
        }
    }
}

extension FavoritesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.favorites.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: MovieListCell.reuseID, for: indexPath) as! MovieListCell
        cell.configure(with: viewModel.favorites[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 119 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let movie = viewModel.favorites[indexPath.row]
        navigationController?.pushViewController(DetailScreen.make(movieId: movie.id, movie: movie), animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete { viewModel.removeFavorite(at: indexPath.row) }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "common.delete".localized
    }
}
