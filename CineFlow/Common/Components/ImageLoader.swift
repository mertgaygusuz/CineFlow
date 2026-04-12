import UIKit
import Kingfisher

// MARK: - Protocol (abstraction over Kingfisher)
protocol ImageLoaderProtocol {
    func loadImage(into imageView: UIImageView, url: URL?, placeholder: UIImage?)
    func cancelLoading(for imageView: UIImageView)
}

// MARK: - Implementation
final class ImageLoader: ImageLoaderProtocol {
    static let shared = ImageLoader()
    private init() {}

    func loadImage(into imageView: UIImageView, url: URL?, placeholder: UIImage? = nil) {
        imageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [.transition(.fade(0.25)), .cacheOriginalImage]
        )
    }

    func cancelLoading(for imageView: UIImageView) {
        imageView.kf.cancelDownloadTask()
    }
}
