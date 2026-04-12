import Foundation

final class FavoritesManager {
    static let shared = FavoritesManager()
    private init() {}

    private let key = "cf_favorites"

    var favorites: [Movie] {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let movies = try? JSONDecoder().decode([Movie].self, from: data)
            else { return [] }
            return movies
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }

    func isFavorite(_ movie: Movie) -> Bool {
        favorites.contains { $0.id == movie.id }
    }

    func toggleFavorite(_ movie: Movie) {
        if isFavorite(movie) {
            favorites = favorites.filter { $0.id != movie.id }
        } else {
            favorites.append(movie)
        }
    }

    func removeFavorite(_ movie: Movie) {
        favorites = favorites.filter { $0.id != movie.id }
    }
}
