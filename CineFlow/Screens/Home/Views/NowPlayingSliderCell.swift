import UIKit
import SnapKit

final class NowPlayingSliderCell: UICollectionViewCell {
    static let reuseID = "NowPlayingSliderCell"

    private let backdropImageView = UIImageView()
    private let gradientLayer     = CAGradientLayer()
    private let titleLabel        = UILabel()
    private let overviewLabel     = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
    }

    private func setup() {
        backdropImageView.contentMode  = .scaleAspectFill
        backdropImageView.clipsToBounds = true
        contentView.addSubview(backdropImageView)
        backdropImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        gradientLayer.colors    = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.85).cgColor]
        gradientLayer.locations = [0.35, 1.0]
        backdropImageView.layer.addSublayer(gradientLayer)

        titleLabel.font          = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor     = .white
        titleLabel.numberOfLines = 2

        overviewLabel.font         = .systemFont(ofSize: 12)
        overviewLabel.textColor    = UIColor.white.withAlphaComponent(0.75)
        overviewLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [titleLabel, overviewLabel])
        stack.axis    = .vertical
        stack.spacing = 6
        contentView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(40) // page control için boşluk
        }
    }

    func configure(with movie: Movie) {
        titleLabel.text    = movie.title
        overviewLabel.text = movie.overview
        ImageLoader.shared.loadImage(into: backdropImageView, url: movie.backdropURL ?? movie.posterURL)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ImageLoader.shared.cancelLoading(for: backdropImageView)
        backdropImageView.image = nil
    }
}
