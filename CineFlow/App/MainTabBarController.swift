import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        styleTabBar()
    }

    private func setupTabs() {
        let home      = makeNav(root: HomeViewController(),      title: "tab.home".localized,      icon: "house",           selectedIcon: "house.fill")
        let search    = makeNav(root: SearchViewController(),    title: "tab.search".localized,    icon: "magnifyingglass", selectedIcon: "magnifyingglass")
        let favorites = makeNav(root: FavoritesViewController(), title: "tab.favorites".localized, icon: "heart",           selectedIcon: "heart.fill")

        viewControllers = [home, search, favorites]
    }

    private func makeNav(root: UIViewController, title: String, icon: String, selectedIcon: String) -> UINavigationController {
        root.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: icon),
            selectedImage: UIImage(systemName: selectedIcon)
        )

        let nav = UINavigationController(rootViewController: root)

        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor          = .darkBackground
            appearance.titleTextAttributes      = [.foregroundColor: UIColor.white]
            nav.navigationBar.standardAppearance   = appearance
            nav.navigationBar.scrollEdgeAppearance = appearance
            nav.navigationBar.compactAppearance    = appearance
        } else {
            nav.navigationBar.barTintColor        = .darkBackground
            nav.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        }

        nav.navigationBar.tintColor     = .white
        nav.navigationBar.isTranslucent = false
        return nav
    }

    private func styleTabBar() {
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .darkBackground

            let item = UITabBarItemAppearance()
            item.normal.iconColor           = .subtitleGray
            item.normal.titleTextAttributes = [.foregroundColor: UIColor.subtitleGray]
            item.selected.iconColor           = .primaryRed
            item.selected.titleTextAttributes = [.foregroundColor: UIColor.primaryRed]

            appearance.stackedLayoutAppearance       = item
            appearance.inlineLayoutAppearance        = item
            appearance.compactInlineLayoutAppearance = item

            tabBar.standardAppearance   = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.barTintColor            = .darkBackground
            tabBar.tintColor               = .primaryRed
            tabBar.unselectedItemTintColor = .subtitleGray
            tabBar.isTranslucent           = false
        }
    }
}
