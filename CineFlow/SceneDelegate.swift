import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()

        if let url = connectionOptions.urlContexts.first?.url {
            handle(url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handle(url)
    }

    // MARK: - Deep links
    // cineflow://movie/<id>
    private func handle(_ url: URL) {
        guard url.scheme == "cineflow", url.host == "movie" else { return }
        let idString = url.lastPathComponent
        guard let movieId = Int(idString) else { return }

        guard let tab = window?.rootViewController as? UITabBarController,
              let nav = tab.selectedViewController as? UINavigationController else { return }

        nav.popToRootViewController(animated: false)
        nav.pushViewController(DetailScreen.make(movieId: movieId), animated: true)
    }
}
