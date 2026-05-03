import SwiftUI
import UIKit

enum DetailScreen {
    static func make(movieId: Int, movie: Movie? = nil) -> UIViewController {
        let host = UIHostingController(rootView: DetailView(movieId: movieId, movie: movie))
        host.hidesBottomBarWhenPushed = true
        return host
    }
}
