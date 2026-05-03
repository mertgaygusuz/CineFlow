import WidgetKit
import SwiftUI

// MARK: - Entry

struct WidgetItem {
    let id: Int
    let title: String
    let voteAverage: Double
    let posterData: Data?
    let backdropData: Data?
}

struct MovieEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let items: [WidgetItem]
}

// MARK: - Provider

struct Provider: AppIntentTimelineProvider {

    private let network: NetworkManagerProtocol = NetworkManager.shared

    func placeholder(in context: Context) -> MovieEntry {
        MovieEntry(date: .now, configuration: ConfigurationAppIntent(), items: Self.placeholderItems)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> MovieEntry {
        let items = (try? await fetch(configuration.category)) ?? Self.placeholderItems
        return MovieEntry(date: .now, configuration: configuration, items: items)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<MovieEntry> {
        let items = (try? await fetch(configuration.category)) ?? []
        let entry = MovieEntry(date: .now, configuration: configuration, items: items)
        let next  = Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? .now.addingTimeInterval(6 * 3600)
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func fetch(_ category: MovieCategory) async throws -> [WidgetItem] {
        let endpoint: APIEndpoint = category == .nowPlaying
            ? .nowPlaying(page: 1)
            : .upcoming(page: 1)
        let response: MovieResponse = try await network.request(endpoint)

        return await withTaskGroup(of: WidgetItem.self) { group in
            for movie in response.results.prefix(6) {
                group.addTask {
                    async let poster   = Self.downloadImage(Self.thumbURL(for: movie.posterPath))
                    async let backdrop = Self.downloadImage(Self.backdropURL(for: movie.backdropPath))
                    return WidgetItem(
                        id: movie.id,
                        title: movie.title,
                        voteAverage: movie.voteAverage,
                        posterData: await poster,
                        backdropData: await backdrop
                    )
                }
            }
            var collected: [WidgetItem] = []
            for await item in group { collected.append(item) }
            // Preserve original API order
            let order = Dictionary(uniqueKeysWithValues: response.results.enumerated().map { ($1.id, $0) })
            return collected.sorted { (order[$0.id] ?? 0) < (order[$1.id] ?? 0) }
        }
    }

    private static func thumbURL(for path: String?) -> URL? {
        path.flatMap { URL(string: "https://image.tmdb.org/t/p/w185\($0)") }
    }

    private static func backdropURL(for path: String?) -> URL? {
        path.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
    }

    private static func downloadImage(_ url: URL?) async -> Data? {
        guard let url else { return nil }
        return try? await URLSession.shared.data(from: url).0
    }

    static let placeholderItems: [WidgetItem] = (1...6).map {
        WidgetItem(id: $0, title: "Loading…", voteAverage: 0, posterData: nil, backdropData: nil)
    }
}

// MARK: - Brand colors

private extension Color {
    static let cfBackground = Color(red: 18/255, green: 18/255, blue: 18/255)
    static let cfCard       = Color(red: 30/255, green: 30/255, blue: 30/255)
    static let cfRed        = Color(red: 229/255, green: 9/255,  blue: 20/255)
    static let cfMuted      = Color(red: 170/255, green: 170/255, blue: 170/255)
}

// MARK: - View

struct CineFlowWidgetEntryView: View {
    var entry: MovieEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:  smallView
            case .systemMedium: mediumView
            default:            largeView
            }
        }
        .containerBackground(for: .widget) {
            Color.cfBackground
        }
    }

    // MARK: Small — hero backdrop with title overlay
    @ViewBuilder
    private var smallView: some View {
        if let item = entry.items.first {
            Link(destination: deepLink(id: item.id)) {
                ZStack(alignment: .bottomLeading) {
                    backdrop(for: item)
                    LinearGradient(
                        colors: [.black.opacity(0.0), .black.opacity(0.85)],
                        startPoint: .top, endPoint: .bottom
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        categoryPill
                        Spacer(minLength: 0)
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        ratingRow(item.voteAverage)
                    }
                    .padding(10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        } else {
            emptyState
        }
    }

    // MARK: Medium — 3 rows with poster thumbs, compact
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entry.items.prefix(3).enumerated()), id: \.element.id) { index, item in
                Link(destination: deepLink(id: item.id)) {
                    row(for: item, posterSize: CGSize(width: 28, height: 42))
                }
                if index < min(2, entry.items.count - 1) {
                    Divider().background(Color.white.opacity(0.08))
                }
            }
            if entry.items.isEmpty { emptyState }
        }
    }

    // MARK: Large — header + 5 rows
    private var largeView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                categoryPill
                Spacer()
                Image(systemName: "film.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.cfRed)
            }
            .padding(.bottom, 2)
            ForEach(Array(entry.items.prefix(5).enumerated()), id: \.element.id) { index, item in
                Link(destination: deepLink(id: item.id)) {
                    row(for: item, posterSize: CGSize(width: 36, height: 54))
                }
                if index < min(4, entry.items.count - 1) {
                    Divider().background(Color.white.opacity(0.08))
                }
            }
            if entry.items.isEmpty { emptyState }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Building blocks

    private var categoryPill: some View {
        Text(entry.configuration.category == .nowPlaying ? "NOW PLAYING" : "UPCOMING")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.cfRed)
            .clipShape(Capsule())
    }

    private func row(for item: WidgetItem, posterSize: CGSize) -> some View {
        HStack(spacing: 8) {
            poster(for: item, size: posterSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                ratingRow(item.voteAverage)
            }
            Spacer(minLength: 0)
        }
    }

    private func ratingRow(_ value: Double) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 9))
                .foregroundStyle(.yellow)
            Text(String(format: "%.1f", value))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.cfMuted)
        }
    }

    @ViewBuilder
    private func backdrop(for item: WidgetItem) -> some View {
        if let data = item.backdropData ?? item.posterData,
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color.cfCard
        }
    }

    @ViewBuilder
    private func poster(for item: WidgetItem, size: CGSize) -> some View {
        Group {
            if let data = item.posterData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.cfCard
                    Image(systemName: "film")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.cfMuted)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var emptyState: some View {
        Text("No movies")
            .font(.caption)
            .foregroundStyle(Color.cfMuted)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func deepLink(id: Int) -> URL {
        URL(string: "cineflow://movie/\(id)") ?? URL(string: "cineflow://")!
    }
}

// MARK: - Widget

struct CineFlowWidget: Widget {
    let kind: String = "CineFlowWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            CineFlowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("CineFlow")
        .description("Now playing or upcoming movies, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    CineFlowWidget()
} timeline: {
    MovieEntry(date: .now, configuration: ConfigurationAppIntent(), items: Provider.placeholderItems)
}

#Preview(as: .systemMedium) {
    CineFlowWidget()
} timeline: {
    MovieEntry(date: .now, configuration: ConfigurationAppIntent(), items: Provider.placeholderItems)
}

#Preview(as: .systemLarge) {
    CineFlowWidget()
} timeline: {
    MovieEntry(date: .now, configuration: ConfigurationAppIntent(), items: Provider.placeholderItems)
}
