import Foundation

public struct CategoryRow: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var isTop10: Bool?
    public var items: [MediaItem]
    
    public init(id: String, title: String, isTop10: Bool? = false, items: [MediaItem]) {
        self.id = id
        self.title = title
        self.isTop10 = isTop10
        self.items = items
    }
}
