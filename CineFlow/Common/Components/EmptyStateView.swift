import UIKit
import SnapKit

final class EmptyStateView: UIView {
    private let iconImageView  = UIImageView()
    private let titleLabel     = UILabel()
    private let subtitleLabel  = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .darkBackground

        iconImageView.contentMode    = .scaleAspectFit
        iconImageView.tintColor      = .subtitleGray

        titleLabel.font              = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor         = .white
        titleLabel.textAlignment     = .center

        subtitleLabel.font           = .systemFont(ofSize: 14)
        subtitleLabel.textColor      = .subtitleGray
        subtitleLabel.textAlignment  = .center
        subtitleLabel.numberOfLines  = 0

        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, subtitleLabel])
        stack.axis      = .vertical
        stack.spacing   = 12
        stack.alignment = .center

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(32)
        }
        iconImageView.snp.makeConstraints { $0.size.equalTo(72) }
    }

    func configure(image: UIImage?, title: String, subtitle: String) {
        iconImageView.image = image
        titleLabel.text     = title
        subtitleLabel.text  = subtitle
    }
}
