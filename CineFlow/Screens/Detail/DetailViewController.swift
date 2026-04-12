import UIKit
import SnapKit

final class DetailViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: DetailViewModel

    private let scrollView   = UIScrollView()
    private let contentView  = UIView()

    private let backdropImageView = UIImageView()
    private let ratingLabel       = UILabel()
    private let starImageView     = UIImageView(image: UIImage(systemName: "star.fill"))
    private let dotLabel          = UILabel()
    private let releaseDateLabel  = UILabel()
    private let imdbButton        = UIButton(type: .system)
    private let titleLabel        = UILabel()
    private let overviewLabel     = UILabel()
    private let loadingView       = LoadingView()

    // MARK: - Init
    init(movieId: Int, movie: Movie? = nil) {
        self.viewModel = DetailViewModel(movieId: movieId, movie: movie)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupFavoriteButton()
        bindViewModel()
        viewModel.loadDetail()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .darkBackground
        navigationController?.navigationBar.tintColor = .white

        // ScrollView
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(view)
        }

        // Backdrop
        backdropImageView.contentMode   = .scaleAspectFill
        backdropImageView.clipsToBounds = true
        backdropImageView.backgroundColor = .cardBackground
        contentView.addSubview(backdropImageView)
        backdropImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(UIScreen.main.bounds.width * 9 / 16)
        }

        // IMDB Button
        imdbButton.setTitle("IMDb", for: .normal)
        imdbButton.setTitleColor(.black, for: .normal)
        imdbButton.titleLabel?.font  = .systemFont(ofSize: 13, weight: .bold)
        imdbButton.backgroundColor   = UIColor(red: 245/255, green: 197/255, blue: 24/255, alpha: 1)
        imdbButton.layer.cornerRadius = 4
        imdbButton.contentEdgeInsets  = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
        imdbButton.setContentHuggingPriority(.required, for: .horizontal)
        imdbButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        imdbButton.addTarget(self, action: #selector(imdbTapped), for: .touchUpInside)

        // Rating row
        starImageView.tintColor   = .systemYellow
        starImageView.contentMode = .scaleAspectFit

        ratingLabel.font      = .systemFont(ofSize: 14, weight: .medium)
        ratingLabel.textColor = .white

        dotLabel.text      = "•"
        dotLabel.textColor = .subtitleGray
        dotLabel.font      = .systemFont(ofSize: 14)

        releaseDateLabel.font      = .systemFont(ofSize: 14)
        releaseDateLabel.textColor = .subtitleGray

        let metaStack = UIStackView(arrangedSubviews: [imdbButton, starImageView, ratingLabel, dotLabel, releaseDateLabel])
        metaStack.axis      = .horizontal
        metaStack.spacing   = 8
        metaStack.alignment = .center
        starImageView.snp.makeConstraints { $0.size.equalTo(16) }

        // Title
        titleLabel.font         = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor    = .white
        titleLabel.numberOfLines = 0

        // Overview
        overviewLabel.font         = .systemFont(ofSize: 14)
        overviewLabel.textColor    = .subtitleGray
        overviewLabel.numberOfLines = 0

        let mainStack = UIStackView(arrangedSubviews: [metaStack, titleLabel, overviewLabel])
        mainStack.axis    = .vertical
        mainStack.spacing = 16

        contentView.addSubview(mainStack)
        mainStack.snp.makeConstraints {
            $0.top.equalTo(backdropImageView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(32)
        }

        // Loading
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupFavoriteButton() {
        let image = UIImage(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
        let btn   = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(favoriteTapped))
        btn.tintColor = .primaryRed
        navigationItem.rightBarButtonItem = btn
    }

    // MARK: - Binding
    private func bindViewModel() {
        viewModel.didUpdateDetail = { [weak self] detail in
            self?.populateUI(with: detail)
        }
        viewModel.isLoading = { [weak self] loading in
            loading ? self?.loadingView.startAnimating() : self?.loadingView.stopAnimating()
        }
        viewModel.didReceiveError = { [weak self] message in
            let alert = UIAlertController(title: "Hata", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
                self?.navigationController?.popViewController(animated: true)
            })
            self?.present(alert, animated: true)
        }
        viewModel.didUpdateFavoriteStatus = { [weak self] isFav in
            self?.navigationItem.rightBarButtonItem?.image = UIImage(systemName: isFav ? "heart.fill" : "heart")
        }
    }

    private func populateUI(with detail: MovieDetail) {
        title                 = detail.title
        titleLabel.text       = detail.title
        overviewLabel.text    = detail.overview
        ratingLabel.text      = String(format: "%.1f/10", detail.voteAverage)
        releaseDateLabel.text = detail.releaseDate?.formattedDate ?? ""
        ImageLoader.shared.loadImage(into: backdropImageView, url: detail.backdropURL ?? detail.posterURL)
    }

    // MARK: - Actions
    @objc private func favoriteTapped() { viewModel.toggleFavorite() }

    @objc private func imdbTapped() {
        guard let url = viewModel.imdbURL else { return }
        UIApplication.shared.open(url)
    }
}
