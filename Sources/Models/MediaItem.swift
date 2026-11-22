import Foundation

public enum MediaType: String, Codable, Hashable {
    case movie = "movie"
    case series = "series"
}

public struct MediaItem: Identifiable, Codable, Hashable {
    public let id: String
    public let type: MediaType
    public let title: String
    public let year: Int?
    public let quality: String?
    public let category: String
    public let tags: [String]?
    public let poster: String?
    public let backdrop: String?
    public let streamUrl: String?
    public let overview: String?
    public let totalSeasons: Int?
    public let totalEpisodes: Int?
    
    public init(
        id: String,
        type: MediaType,
        title: String,
        year: Int? = nil,
        quality: String? = nil,
        category: String = "General",
        tags: [String]? = nil,
        poster: String? = nil,
        backdrop: String? = nil,
        streamUrl: String? = nil,
        overview: String? = nil,
        totalSeasons: Int? = nil,
        totalEpisodes: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.year = year
        self.quality = quality
        self.category = category
        self.tags = tags
        self.poster = poster
        self.backdrop = backdrop
        self.streamUrl = streamUrl
        self.overview = overview
        self.totalSeasons = totalSeasons
        self.totalEpisodes = totalEpisodes
    }
    
    public var isDualAudio: Bool {
        guard let tags = tags else { return false }
        return tags.contains(where: { $0.localizedCaseInsensitiveContains("dual") })
    }
    
    public var is4K: Bool {
        quality?.localizedCaseInsensitiveContains("4k") == true || quality?.localizedCaseInsensitiveContains("2160") == true
    }
    
    public var is1080p: Bool {
        quality?.localizedCaseInsensitiveContains("1080") == true
    }
    
    public var displayQuality: String {
        if is4K { return "4K Ultra HD" }
        if is1080p { return "1080p HD" }
        return quality ?? "HD"
    }
    
    public var displayYear: String {
        if let y = year, y > 1900 { return "\(y)" }
        return "2026"
    }
    
    public var posterURL: URL? {
        guard let p = poster, !p.isEmpty else { return nil }
        return URL(string: p)
    }
    
    public var backdropURL: URL? {
        if let b = backdrop, !b.isEmpty {
            return URL(string: b)
        }
        return posterURL
    }
}
