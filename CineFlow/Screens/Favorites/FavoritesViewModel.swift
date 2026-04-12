import Foundation

final class FavoritesViewModel {

    // MARK: - Bindings
    var didUpdateFavorites: (([Movie]) -> Void)?

    // MARK: - State
    private(set) var favorites: [Movie] = []

    private let favoritesManager: FavoritesManager

    // MARK: - Init
    init(favoritesManager: FavoritesManager = .shared) {
        self.favoritesManager = favoritesManager
    }

    // MARK: - Public
    func loadFavorites() {
        favorites = favoritesManager.favorites
        didUpdateFavorites?(favorites)
    }

    func removeFavorite(at index: Int) {
        guard index < favorites.count else { return }
        favoritesManager.removeFavorite(favorites[index])
        favorites = favoritesManager.favorites
        didUpdateFavorites?(favorites)
    }
}
