import UIKit
import SnapKit

protocol NowPlayingSliderViewDelegate: AnyObject {
    func sliderView(_ sliderView: NowPlayingSliderView, didSelectMovie movie: Movie)
}

final class NowPlayingSliderView: UIView {
    weak var delegate: NowPlayingSliderViewDelegate?

    private var movies:        [Movie] = []
    private var autoScrollTimer: Timer?
    private var currentIndex = 0

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection  = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate   = self
        cv.register(NowPlayingSliderCell.self, forCellWithReuseIdentifier: NowPlayingSliderCell.reuseID)
        return cv
    }()

    private let pageControl = UIPageControl()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }

        pageControl.currentPageIndicatorTintColor = .primaryRed
        pageControl.pageIndicatorTintColor        = UIColor.white.withAlphaComponent(0.35)
        addSubview(pageControl)
        pageControl.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(10)
            $0.centerX.equalToSuperview()
        }
    }

    func configure(with movies: [Movie]) {
        self.movies = movies
        pageControl.numberOfPages = movies.count
        collectionView.reloadData()
        startAutoScroll()
    }

    private func startAutoScroll() {
        autoScrollTimer?.invalidate()
        guard movies.count > 1 else { return }
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            self?.scrollToNext()
        }
    }

    private func scrollToNext() {
        guard !movies.isEmpty else { return }
        currentIndex = (currentIndex + 1) % movies.count
        collectionView.scrollToItem(
            at: IndexPath(item: currentIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
        pageControl.currentPage = currentIndex
    }

    deinit { autoScrollTimer?.invalidate() }
}

// MARK: - UICollectionView DataSource & Delegate
extension NowPlayingSliderView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        movies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NowPlayingSliderCell.reuseID,
            for: indexPath
        ) as! NowPlayingSliderCell
        cell.configure(with: movies[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.sliderView(self, didSelectMovie: movies[indexPath.item])
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / max(scrollView.bounds.width, 1))
        currentIndex            = page
        pageControl.currentPage = page
    }
}
