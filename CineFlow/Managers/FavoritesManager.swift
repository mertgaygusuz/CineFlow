import Foundation
import SwiftData

@MainActor
final class FavoritesManager {
    static let shared: FavoritesManager = {
        do {
            let container = try ModelContainer(for: FavoriteMovie.self)
            return FavoritesManager(container: container)
        } catch {
            fatalError("Failed to initialise SwiftData container: \(error)")
        }
    }()

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
        migrateFromUserDefaultsIfNeeded()
    }

    var favorites: [Movie] {
        let descriptor = FetchDescriptor<FavoriteMovie>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        let stored = (try? context.fetch(descriptor)) ?? []
        return stored.map(\.asMovie)
    }

    func isFavorite(_ movie: Movie) -> Bool {
        fetch(id: movie.id) != nil
    }

    func toggleFavorite(_ movie: Movie) {
        if let existing = fetch(id: movie.id) {
            context.delete(existing)
        } else {
            context.insert(FavoriteMovie(movie: movie))
        }
        try? context.save()
    }

    func removeFavorite(_ movie: Movie) {
        guard let existing = fetch(id: movie.id) else { return }
        context.delete(existing)
        try? context.save()
    }

    private func fetch(id: Int) -> FavoriteMovie? {
        var descriptor = FetchDescriptor<FavoriteMovie>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    // MARK: - One-time migration from the old UserDefaults format
    private func migrateFromUserDefaultsIfNeeded() {
        let key = "cf_favorites"
        guard let data = UserDefaults.standard.data(forKey: key),
              let movies = try? JSONDecoder().decode([Movie].self, from: data),
              !movies.isEmpty else { return }
        for movie in movies where fetch(id: movie.id) == nil {
            context.insert(FavoriteMovie(movie: movie))
        }
        try? context.save()
        UserDefaults.standard.removeObject(forKey: key)
    }
}
