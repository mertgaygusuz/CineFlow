import UIKit
import SnapKit

final class MovieListCell: UITableViewCell {
    static let reuseID = "MovieListCell"

    private let posterImageView = UIImageView()
    private let titleLabel      = UILabel()
    private let overviewLabel   = UILabel()
    private let dateLabel       = UILabel()
    private let chevron         = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let separator       = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor  = .darkBackground
        selectionStyle   = .none

        posterImageView.contentMode   = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.layer.cornerRadius = 8
        posterImageView.backgroundColor = .cardBackground

        titleLabel.font         = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor    = .white
        titleLabel.numberOfLines = 2

        overviewLabel.font         = .systemFont(ofSize: 12)
        overviewLabel.textColor    = .subtitleGray
        overviewLabel.numberOfLines = 2

        dateLabel.font      = .systemFont(ofSize: 11)
        dateLabel.textColor = .subtitleGray

        chevron.tintColor   = .subtitleGray
        chevron.contentMode = .scaleAspectFit

        separator.backgroundColor = .cardBackground

        let textStack = UIStackView(arrangedSubviews: [titleLabel, overviewLabel, dateLabel])
        textStack.axis    = .vertical
        textStack.spacing = 4

        contentView.addSubview(posterImageView)
        contentView.addSubview(textStack)
        contentView.addSubview(chevron)
        contentView.addSubview(separator)

        posterImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview().inset(12)
            $0.width.equalTo(70)
            $0.height.greaterThanOrEqualTo(90)
        }

        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(14)
        }

        textStack.snp.makeConstraints {
            $0.leading.equalTo(posterImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(chevron.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }

        separator.snp.makeConstraints {
            $0.leading.equalTo(textStack)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }

    func configure(with movie: Movie) {
        titleLabel.text    = movie.title
        overviewLabel.text = movie.overview
        dateLabel.text     = movie.releaseDate?.formattedDate ?? ""
        ImageLoader.shared.loadImage(into: posterImageView, url: movie.posterURL)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ImageLoader.shared.cancelLoading(for: posterImageView)
        posterImageView.image = nil
    }
}
