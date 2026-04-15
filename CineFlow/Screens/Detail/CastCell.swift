import UIKit
import SnapKit

final class CastCell: UICollectionViewCell {
    static let identifier = "CastCell"

    private let imageView      = UIImageView()
    private let nameLabel      = UILabel()
    private let characterLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        imageView.contentMode    = .scaleAspectFill
        imageView.clipsToBounds  = true
        imageView.layer.cornerRadius = 40
        imageView.backgroundColor = .cardBackground

        nameLabel.font          = .systemFont(ofSize: 11, weight: .semibold)
        nameLabel.textColor     = .white
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2

        characterLabel.font          = .systemFont(ofSize: 10)
        characterLabel.textColor     = .subtitleGray
        characterLabel.textAlignment = .center
        characterLabel.numberOfLines = 2

        [imageView, nameLabel, characterLabel].forEach { contentView.addSubview($0) }

        imageView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.width.height.equalTo(80)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview()
        }
        characterLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview()
        }
    }

    func configure(with member: CastMember) {
        nameLabel.text      = member.name
        characterLabel.text = member.character
        if let url = member.profileURL {
            ImageLoader.shared.loadImage(into: imageView, url: url)
        } else {
            imageView.image           = UIImage(systemName: "person.fill")
            imageView.tintColor       = .subtitleGray
            imageView.backgroundColor = .cardBackground
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ImageLoader.shared.cancelLoading(for: imageView)
        imageView.image = nil
    }
}
