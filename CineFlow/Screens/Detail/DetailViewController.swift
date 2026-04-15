import UIKit
import SnapKit

final class DetailViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: DetailViewModel

    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    // Backdrop
    private let backdropImageView = UIImageView()

    // Meta row
    private let ratingLabel      = UILabel()
    private let starImageView    = UIImageView(image: UIImage(systemName: "star.fill"))
    private let dotLabel         = UILabel()
    private let releaseDateLabel = UILabel()
    private let imdbButton       = UIButton(type: .system)

    // Info
    private let titleLabel    = UILabel()
    private let overviewLabel = UILabel()

    // Trailer section
    private let trailerSection      = UIStackView()
    private let trailerHeaderLabel  = UILabel()
    private let trailerThumbView    = UIView()
    private let trailerImageView    = UIImageView()
    private let playIconView        = UIImageView()
    private var trailerVideo: Video?

    // Cast section
    private let castSection     = UIStackView()
    private let castHeaderLabel = UILabel()
    private var castMembers: [CastMember] = []
    private lazy var castCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection       = .horizontal
        layout.itemSize              = CGSize(width: 90, height: 145)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset          = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor               = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(CastCell.self, forCellWithReuseIdentifier: CastCell.identifier)
        cv.dataSource = self
        return cv
    }()

    private let loadingView = LoadingView()

    // MARK: - Init
    init(movieId: Int, movie: Movie? = nil) {
        self.viewModel = DetailViewModel(movieId: movieId, movie: movie)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupFavoriteButton()
        bindViewModel()
        viewModel.loadAll()
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

        // Page stack (all content below backdrop)
        let pageStack = UIStackView()
        pageStack.axis    = .vertical
        pageStack.spacing = 24
        pageStack.isLayoutMarginsRelativeArrangement = true
        pageStack.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 32, right: 16)

        contentView.addSubview(pageStack)
        pageStack.snp.makeConstraints {
            $0.top.equalTo(backdropImageView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        // --- Info section ---
        setupImdbButton()

        starImageView.tintColor   = .systemYellow
        starImageView.contentMode = .scaleAspectFit
        starImageView.snp.makeConstraints { $0.size.equalTo(16) }

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

        titleLabel.font          = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor     = .white
        titleLabel.numberOfLines = 0

        overviewLabel.font          = .systemFont(ofSize: 14)
        overviewLabel.textColor     = .subtitleGray
        overviewLabel.numberOfLines = 0

        let infoStack = UIStackView(arrangedSubviews: [metaStack, titleLabel, overviewLabel])
        infoStack.axis    = .vertical
        infoStack.spacing = 16

        pageStack.addArrangedSubview(infoStack)

        // --- Trailer section ---
        setupTrailerSection()
        pageStack.addArrangedSubview(trailerSection)

        // --- Cast section ---
        setupCastSection()
        pageStack.addArrangedSubview(castSection)

        // Loading overlay
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupImdbButton() {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor(red: 245/255, green: 197/255, blue: 24/255, alpha: 1)
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8)
        config.attributedTitle = AttributedString(
            "IMDb",
            attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 13, weight: .bold)])
        )
        config.cornerStyle = .fixed
        imdbButton.configuration = config
        imdbButton.layer.cornerRadius = 4
        imdbButton.clipsToBounds = true
        imdbButton.setContentHuggingPriority(.required, for: .horizontal)
        imdbButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        imdbButton.addTarget(self, action: #selector(imdbTapped), for: .touchUpInside)
    }

    private func setupTrailerSection() {
        trailerSection.axis    = .vertical
        trailerSection.spacing = 12
        trailerSection.isHidden = true

        trailerHeaderLabel.text      = "detail.trailer".localized
        trailerHeaderLabel.font      = .systemFont(ofSize: 17, weight: .bold)
        trailerHeaderLabel.textColor = .white

        // Thumbnail container
        trailerThumbView.backgroundColor   = .cardBackground
        trailerThumbView.layer.cornerRadius = 10
        trailerThumbView.clipsToBounds      = true

        trailerImageView.contentMode   = .scaleAspectFill
        trailerImageView.clipsToBounds = true
        trailerThumbView.addSubview(trailerImageView)
        trailerImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Play icon overlay
        let overlayView = UIView()
        overlayView.backgroundColor    = UIColor.black.withAlphaComponent(0.45)
        overlayView.layer.cornerRadius = 30
        trailerThumbView.addSubview(overlayView)
        overlayView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(60)
        }

        playIconView.image     = UIImage(systemName: "play.fill")
        playIconView.tintColor = .white
        playIconView.contentMode = .scaleAspectFit
        overlayView.addSubview(playIconView)
        playIconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(26)
        }

        // Aspect ratio 16:9
        trailerThumbView.snp.makeConstraints {
            $0.height.equalTo(trailerThumbView.snp.width).multipliedBy(9.0 / 16.0)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(trailerTapped))
        trailerThumbView.addGestureRecognizer(tapGesture)
        trailerThumbView.isUserInteractionEnabled = true

        trailerSection.addArrangedSubview(trailerHeaderLabel)
        trailerSection.addArrangedSubview(trailerThumbView)
    }

    private func setupCastSection() {
        castSection.axis    = .vertical
        castSection.spacing = 12
        castSection.isHidden = true

        castHeaderLabel.text      = "detail.cast".localized
        castHeaderLabel.font      = .systemFont(ofSize: 17, weight: .bold)
        castHeaderLabel.textColor = .white

        castCollectionView.snp.makeConstraints {
            $0.height.equalTo(145)
        }

        castSection.addArrangedSubview(castHeaderLabel)
        castSection.addArrangedSubview(castCollectionView)
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
            self?.populateInfo(with: detail)
        }
        viewModel.didUpdateTrailer = { [weak self] video in
            guard let video = video else { return }
            self?.trailerVideo = video
            self?.populateTrailer(video: video)
        }
        viewModel.didUpdateCredits = { [weak self] cast in
            guard !cast.isEmpty else { return }
            self?.castMembers = cast
            self?.castCollectionView.reloadData()
            self?.castSection.isHidden = false
        }
        viewModel.isLoading = { [weak self] loading in
            loading ? self?.loadingView.startAnimating() : self?.loadingView.stopAnimating()
        }
        viewModel.didReceiveError = { [weak self] message in
            let alert = UIAlertController(title: "common.error".localized, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default) { _ in
                self?.navigationController?.popViewController(animated: true)
            })
            self?.present(alert, animated: true)
        }
        viewModel.didUpdateFavoriteStatus = { [weak self] isFav in
            self?.navigationItem.rightBarButtonItem?.image = UIImage(systemName: isFav ? "heart.fill" : "heart")
        }
    }

    private func populateInfo(with detail: MovieDetail) {
        title                 = detail.title
        titleLabel.text       = detail.title
        overviewLabel.text    = detail.overview
        ratingLabel.text      = String(format: "%.1f/10", detail.voteAverage)
        releaseDateLabel.text = detail.releaseDate?.formattedDate ?? ""
        ImageLoader.shared.loadImage(into: backdropImageView, url: detail.backdropURL ?? detail.posterURL)
    }

    private func populateTrailer(video: Video) {
        ImageLoader.shared.loadImage(into: trailerImageView, url: video.thumbnailURL)
        UIView.animate(withDuration: 0.3) {
            self.trailerSection.isHidden = false
        }
    }

    // MARK: - Actions
    @objc private func favoriteTapped() { viewModel.toggleFavorite() }

    @objc private func imdbTapped() {
        guard let url = viewModel.imdbURL else { return }
        UIApplication.shared.open(url)
    }

    @objc private func trailerTapped() {
        guard let url = trailerVideo?.youtubeURL else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - UICollectionViewDataSource
extension DetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        castMembers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CastCell.identifier, for: indexPath) as! CastCell
        cell.configure(with: castMembers[indexPath.item])
        return cell
    }
}
