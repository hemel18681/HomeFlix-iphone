import Foundation
import SwiftUI
import Combine

@MainActor
public final class WatchlistStore: ObservableObject {
    public static let shared = WatchlistStore()
    
    @Published public private(set) var watchlist: Set<String> = []
    @Published public private(set) var watchlistItemMap: [String: MediaItem] = [:]
    @Published public private(set) var history: [String: WatchProgress] = [:]
    @Published public private(set) var preferences: [String] = ["action", "anime", "hollywood-1080p"]
    @Published public private(set) var likes: [String: Bool] = [:]
    
    private let watchlistKey = "homeflix_user_watchlist"
    private let preferencesKey = "homeflix_user_preferences"
    private let historyKey = "homeflix_user_history"
    private let likesKey = "homeflix_user_likes"
    private let itemMapKey = "homeflix_user_watchlist_items"
    
    public init() {
        loadState()
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        
        // Watchlist IDs
        if let savedList = defaults.array(forKey: watchlistKey) as? [String] {
            self.watchlist = Set(savedList)
        }
        
        // Watchlist Item Details
        if let data = defaults.data(forKey: itemMapKey),
           let decoded = try? JSONDecoder().decode([String: MediaItem].self, from: data) {
            self.watchlistItemMap = decoded
        }
        
        // Preferences
        if let savedPrefs = defaults.array(forKey: preferencesKey) as? [String], !savedPrefs.isEmpty {
            self.preferences = savedPrefs
        }
        
        // History
        if let data = defaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([String: WatchProgress].self, from: data) {
            self.history = decoded
        }
        
        // Likes
        if let savedLikes = defaults.dictionary(forKey: likesKey) as? [String: Bool] {
            self.likes = savedLikes
        }
    }
    
    // Watchlist
    public func toggleWatchlist(item: MediaItem) {
        if watchlist.contains(item.id) {
            watchlist.remove(item.id)
            watchlistItemMap.removeValue(forKey: item.id)
        } else {
            watchlist.insert(item.id)
            watchlistItemMap[item.id] = item
        }
        saveWatchlist()
    }
    
    public func isInWatchlist(_ id: String) -> Bool {
        watchlist.contains(id)
    }
    
    public var mylistItems: [MediaItem] {
        Array(watchlistItemMap.values).sorted { $0.title < $1.title }
    }
    
    private func saveWatchlist() {
        let defaults = UserDefaults.standard
        defaults.set(Array(watchlist), forKey: watchlistKey)
        if let encoded = try? JSONEncoder().encode(watchlistItemMap) {
            defaults.set(encoded, forKey: itemMapKey)
        }
    }
    
    // Taste Preferences
    public func setPreferences(_ prefs: [String]) {
        self.preferences = prefs
        UserDefaults.standard.set(prefs, forKey: preferencesKey)
    }
    
    public func togglePreference(_ prefId: String) {
        if preferences.contains(prefId) {
            preferences.removeAll { $0 == prefId }
        } else {
            preferences.append(prefId)
        }
        UserDefaults.standard.set(preferences, forKey: preferencesKey)
    }
    
    // History & Continue Watching
    public func updateProgress(
        mediaId: String,
        title: String,
        type: String,
        poster: String?,
        seasonNumber: Int?,
        episodeNumber: Int?,
        currentTime: Double,
        duration: Double
    ) {
        guard duration > 0 else { return }
        let percent = min(100.0, max(0.0, (currentTime / duration) * 100.0))
        
        let progress = WatchProgress(
            mediaId: mediaId,
            title: title,
            type: type,
            poster: poster,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            currentTime: currentTime,
            duration: duration,
            percent: percent,
            updatedAt: Date().timeIntervalSince1970
        )
        
        history[mediaId] = progress
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    public func getProgress(_ id: String) -> WatchProgress? {
        history[id]
    }
    
    public var continueWatchingItems: [MediaItem] {
        history.values
            .filter { $0.percent > 1 && $0.percent < 95 }
            .sorted { $0.updatedAt > $1.updatedAt }
            .map { h in
                MediaItem(
                    id: h.mediaId,
                    type: h.type == "series" ? .series : .movie,
                    title: h.title,
                    category: "In Progress",
                    poster: h.poster,
                    backdrop: h.poster
                )
            }
    }
    
    // Likes
    public func setLike(id: String, isLiked: Bool) {
        likes[id] = isLiked
        UserDefaults.standard.set(likes, forKey: likesKey)
    }
}
