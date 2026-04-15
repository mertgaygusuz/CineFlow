import Foundation

struct CreditsResponse: Codable {
    let cast: [CastMember]
}

struct CastMember: Codable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }

    var profileURL: URL? {
        profilePath.flatMap { URL(string: "https://image.tmdb.org/t/p/w185\($0)") }
    }
}
