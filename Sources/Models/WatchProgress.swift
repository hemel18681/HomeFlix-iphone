import Foundation

public struct WatchProgress: Identifiable, Codable, Hashable {
    public var id: String { mediaId }
    public let mediaId: String
    public let title: String
    public let type: String
    public let poster: String?
    public let seasonNumber: Int?
    public let episodeNumber: Int?
    public var currentTime: Double
    public var duration: Double
    public var percent: Double
    public var updatedAt: Double
    
    public init(
        mediaId: String,
        title: String,
        type: String,
        poster: String? = nil,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        currentTime: Double = 0,
        duration: Double = 0,
        percent: Double = 0,
        updatedAt: Double = Date().timeIntervalSince1970
    ) {
        self.mediaId = mediaId
        self.title = title
        self.type = type
        self.poster = poster
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.currentTime = currentTime
        self.duration = duration
        self.percent = percent
        self.updatedAt = updatedAt
    }
    
    public var remainingTimeFormatted: String {
        let remaining = max(0, duration - currentTime)
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(max(1, minutes))m left"
        }
    }
    
    public var episodeInfoFormatted: String? {
        guard let s = seasonNumber, let e = episodeNumber else { return nil }
        return "S\(s):E\(e)"
    }
}
