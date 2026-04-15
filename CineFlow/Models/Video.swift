import Foundation

struct VideosResponse: Codable {
    let results: [Video]
}

struct Video: Codable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String

    var isYouTubeTrailer: Bool {
        site == "YouTube" && type == "Trailer"
    }

    var youtubeURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(key)")
    }

    var thumbnailURL: URL? {
        URL(string: "https://img.youtube.com/vi/\(key)/hqdefault.jpg")
    }
}
