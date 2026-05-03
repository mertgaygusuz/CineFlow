import WidgetKit
import AppIntents

enum MovieCategory: String, AppEnum {
    case nowPlaying
    case upcoming

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Category")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .nowPlaying: "Now Playing",
        .upcoming:   "Upcoming"
    ]
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Movie Category" }
    static var description: IntentDescription { "Pick which movies to display." }

    @Parameter(title: "Category", default: .nowPlaying)
    var category: MovieCategory
}
