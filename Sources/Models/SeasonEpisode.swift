import Foundation

public struct Episode: Identifiable, Codable, Hashable {
    public var id: String { "\(episodeNumber)_\(fileName)" }
    public let episodeNumber: Int
    public let title: String
    public let fileName: String
    public let streamUrl: String
    public let fileSize: String?
    public let duration: Double?
    
    public init(
        episodeNumber: Int,
        title: String,
        fileName: String,
        streamUrl: String,
        fileSize: String? = nil,
        duration: Double? = nil
    ) {
        self.episodeNumber = episodeNumber
        self.title = title
        self.fileName = fileName
        self.streamUrl = streamUrl
        self.fileSize = fileSize
        self.duration = duration
    }
}

public struct Season: Identifiable, Codable, Hashable {
    public var id: Int { seasonNumber }
    public let seasonNumber: Int
    public let seasonName: String
    public let episodes: [Episode]
    
    public init(seasonNumber: Int, seasonName: String, episodes: [Episode]) {
        self.seasonNumber = seasonNumber
        self.seasonName = seasonName
        self.episodes = episodes
    }
}

public struct SeriesDetail: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let totalSeasons: Int?
    public let totalEpisodes: Int?
    public let seasons: [Season]
    
    public init(
        id: String,
        title: String,
        totalSeasons: Int?,
        totalEpisodes: Int?,
        seasons: [Season]
    ) {
        self.id = id
        self.title = title
        self.totalSeasons = totalSeasons
        self.totalEpisodes = totalEpisodes
        self.seasons = seasons
    }
}
