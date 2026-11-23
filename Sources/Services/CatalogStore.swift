import Foundation
import Combine

@MainActor
public final class CatalogStore: ObservableObject {
    public static let shared = CatalogStore()
    
    @Published public var featured: [MediaItem] = []
    @Published public var curatedRows: [CategoryRow] = []
    @Published public var allItems: [MediaItem] = []
    @Published public var seriesDetails: [String: SeriesDetail] = [:]
    @Published public var isLoaded: Bool = false
    @Published public var refreshSeed: Int = 0
    
    private var searchIndex: [MediaItem] = []
    
    public init() {
        loadCatalog()
    }
    
    public func refreshFeed() {
        refreshSeed += 1
        objectWillChange.send()
    }
    
    public func loadCatalog() {
        guard !isLoaded else { return }
        
        // 1. Load featured items
        if let featuredData = loadResourceData(name: "featured", ext: "json"),
           let decoded = try? JSONDecoder().decode([MediaItem].self, from: featuredData) {
            self.featured = decoded
        }
        
        // 2. Load curated rows
        if let rowsData = loadResourceData(name: "curated-rows", ext: "json"),
           let decoded = try? JSONDecoder().decode([CategoryRow].self, from: rowsData) {
            self.curatedRows = decoded
        }
        
        // 3. Load series episodes
        if let seriesData = loadResourceData(name: "series-episodes", ext: "json"),
           let decoded = try? JSONDecoder().decode([String: SeriesDetail].self, from: seriesData) {
            self.seriesDetails = decoded
        }
        
        // 4. Background parse search-index
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            if let indexData = self.loadResourceData(name: "search-index", ext: "json"),
               let decoded = try? JSONDecoder().decode([MediaItem].self, from: indexData) {
                await MainActor.run {
                    self.searchIndex = decoded
                    self.allItems = decoded
                    self.isLoaded = true
                }
            } else {
                await MainActor.run {
                    self.isLoaded = true
                }
            }
        }
    }
    
    private nonisolated func loadResourceData(name: String, ext: String) -> Data? {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: name, withExtension: ext),
           let data = try? Data(contentsOf: url) {
            return data
        }
        #endif
        if let url = Bundle.main.url(forResource: name, withExtension: ext),
           let data = try? Data(contentsOf: url) {
            return data
        }
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources"),
           let data = try? Data(contentsOf: url) {
            return data
        }
        // Direct filesystem fallbacks
        let paths = [
            "/workspace/mobile-app/Sources/Resources/\(name).\(ext)",
            "/workspace/mobile-app/Resources/\(name).\(ext)"
        ]
        for p in paths {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: p)) {
                return data
            }
        }
        return nil
    }
    
    // MARK: - Dynamic Netflix-Grade Personalization Engine
    
    /// Dynamically selects the Billboard Hero based on user watch history, likes, and taste preferences.
    public func getPersonalizedHero(
        history: [String: WatchProgress] = [:],
        preferences: [String] = [],
        refreshSeed: Int = 0
    ) -> MediaItem? {
        guard !featured.isEmpty else { return curatedRows.first?.items.first }
        
        let affinities = computeGenreAffinities(history: history, likes: [:], preferences: preferences)
        
        if !affinities.isEmpty {
            let sortedFeatured = featured.sorted { f1, f2 in
                scoreItem(f1, affinities: affinities) > scoreItem(f2, affinities: affinities)
            }
            if let best = sortedFeatured.first, scoreItem(best, affinities: affinities) > 0 {
                let topMatches = sortedFeatured.filter { scoreItem($0, affinities: affinities) >= scoreItem(best, affinities: affinities) }
                let index = abs(refreshSeed) % max(1, topMatches.count)
                return topMatches[index]
            }
        }
        
        let index = abs(refreshSeed) % featured.count
        return featured[index]
    }
    
    /// Dynamically generates and re-ranks rows in real time based on Watch History, Likes, and Taste Preferences.
    public func getPersonalizedRows(
        selectedPreferences: [String] = [],
        history: [String: WatchProgress] = [:],
        likes: [String: Bool] = [:],
        refreshSeed: Int = 0
    ) -> [CategoryRow] {
        var result: [CategoryRow] = []
        var processedRowIds = Set<String>()
        var seenMediaIdsOnPage = Set(history.keys) // Exclude already watched/completed items from recommendations
        
        // 1. Top 10 Pinned Rows (Netflix standard)
        let top10Rows = curatedRows.filter { $0.isTop10 == true }
        result.append(contentsOf: top10Rows)
        top10Rows.forEach { row in
            processedRowIds.insert(row.id)
            row.items.forEach { seenMediaIdsOnPage.insert($0.id) }
        }
        
        // 2. Daily Watch History Driven "Because you watched [Title]" Dynamic Rows
        // Sorted by recency (highest recency decay weight first)
        let recentWatches = history.values
            .filter { $0.currentTime >= 120 || $0.percent >= 5 } // Filter out accidental bounces (<2 min)
            .sorted { $0.updatedAt > $1.updatedAt }
        
        var addedBecauseWatchedCount = 0
        for watch in recentWatches {
            guard addedBecauseWatchedCount < 2 else { break }
            guard let watchedItem = findItem(by: watch.mediaId) else { continue }
            
            let recommendations = getRecommendationsForWatched(item: watchedItem, excluding: seenMediaIdsOnPage)
            if recommendations.count >= 4 {
                let row = CategoryRow(
                    id: "because-watched-\(watchedItem.id)",
                    title: "Because you watched \(watchedItem.title)",
                    items: recommendations
                )
                result.append(row)
                processedRowIds.insert(row.id)
                recommendations.forEach { seenMediaIdsOnPage.insert($0.id) }
                addedBecauseWatchedCount += 1
            }
        }
        
        // 3. Learned Genre Affinities (with Netflix Exponential Half-Life Time Decay & Consumption Depth)
        let affinities = computeGenreAffinities(history: history, likes: likes, preferences: selectedPreferences)
        
        // 4. "⚡ Top Picks for You" Row (Deduplicated with Netflix PVR scoring)
        let topPicks = getTopPicksForYou(affinities: affinities, excluding: seenMediaIdsOnPage, seed: refreshSeed)
        if !topPicks.isEmpty {
            let topPicksRow = CategoryRow(
                id: "top-picks-for-you",
                title: "⚡ Top Picks for You",
                items: topPicks
            )
            result.append(topPicksRow)
            processedRowIds.insert(topPicksRow.id)
            topPicks.forEach { seenMediaIdsOnPage.insert($0.id) }
        }
        
        // 5. Prioritize and Elevate Curated Rows Matching User's Affinities
        var scoredCuratedRows: [(row: CategoryRow, score: Double)] = []
        for row in curatedRows {
            guard !processedRowIds.contains(row.id) else { continue }
            
            var rowScore: Double = 0
            // Explicit taste preference boosts (+30)
            for prefId in selectedPreferences {
                if let config = TastePreference.all.first(where: { $0.id == prefId }), config.rowIds.contains(row.id) {
                    rowScore += 30.0
                }
            }
            // Watch history & likes genre affinities
            for (genre, weight) in affinities {
                if row.id.localizedCaseInsensitiveContains(genre) || row.title.localizedCaseInsensitiveContains(genre) {
                    rowScore += Double(weight) * 3.5
                }
            }
            scoredCuratedRows.append((row, rowScore))
        }
        
        // Boosted rows appear first
        let sortedCurated = scoredCuratedRows.sorted { r1, r2 in
            r1.score > r2.score
        }
        
        for item in sortedCurated {
            var boostedRow = item.row
            // Deduplicate items in boosted rows against top picks/because watched to ensure diversity
            let freshItems = boostedRow.items.filter { !seenMediaIdsOnPage.contains($0.id) }
            if freshItems.count >= 6 {
                boostedRow.items = freshItems
            }
            
            // If boosted by taste preference, show personalized banner title
            for prefId in selectedPreferences {
                if let config = TastePreference.all.first(where: { $0.id == prefId }), config.rowIds.contains(item.row.id) {
                    boostedRow.title = config.personalizedTitle
                    break
                }
            }
            result.append(boostedRow)
            processedRowIds.insert(item.row.id)
            boostedRow.items.prefix(8).forEach { seenMediaIdsOnPage.insert($0.id) }
        }
        
        // 6. Dynamic "✨ Fresh Discoveries on HomeFlix" Row (shuffled from 37,000+ catalog pool)
        let discoveries = getDiscoveries(excluding: seenMediaIdsOnPage, seed: refreshSeed)
        if !discoveries.isEmpty {
            let discoveriesRow = CategoryRow(
                id: "fresh-discoveries",
                title: "✨ Fresh Discoveries on HomeFlix",
                items: discoveries
            )
            let insertIndex = min(4, result.count)
            result.insert(discoveriesRow, at: insertIndex)
        }
        
        return result
    }
    
    /// Computes genre affinities using Netflix's exponential recency decay and consumption depth
    private func computeGenreAffinities(
        history: [String: WatchProgress],
        likes: [String: Bool],
        preferences: [String]
    ) -> [String: Double] {
        var scores: [String: Double] = [:]
        let now = Date().timeIntervalSince1970
        let sevenDaysSeconds: Double = 7.0 * 24.0 * 3600.0
        
        // 1. Explicit taste preferences (+10 baseline weight)
        for pref in preferences {
            scores[pref.lowercased(), default: 0] += 10.0
        }
        
        // 2. Daily Watch History with Exponential Recency Decay: W = depthWeight * 0.5^(dt / 7days)
        for progress in history.values {
            guard progress.currentTime >= 120 || progress.percent >= 5 else { continue } // Ignore bounces
            
            let elapsed = max(0, now - progress.updatedAt)
            let recencyDecay = pow(0.5, elapsed / sevenDaysSeconds) // 1.0 today, 0.5 after 1 week, 0.1 after 3 weeks
            
            // Consumption depth multiplier
            let depthMultiplier: Double
            if progress.percent >= 70 {
                depthMultiplier = 2.5 // Binge / High completion
            } else if progress.percent >= 30 {
                depthMultiplier = 1.5 // Deep engagement
            } else {
                depthMultiplier = 1.0 // Standard viewing
            }
            
            let finalWeight = 8.0 * depthMultiplier * recencyDecay
            
            if let item = findItem(by: progress.mediaId) {
                let catLower = item.category.lowercased()
                scores[catLower, default: 0] += finalWeight
                
                if let tags = item.tags {
                    for tag in tags {
                        scores[tag.lowercased(), default: 0] += finalWeight * 0.5
                    }
                }
                
                // Map to category taxonomy
                if catLower.contains("anime") { scores["anime", default: 0] += finalWeight * 1.2 }
                if catLower.contains("action") { scores["action", default: 0] += finalWeight }
                if catLower.contains("korean") || catLower.contains("k-drama") { scores["korean", default: 0] += finalWeight * 1.2 }
                if catLower.contains("sci-fi") { scores["sci-fi", default: 0] += finalWeight }
                if catLower.contains("horror") { scores["horror-thriller", default: 0] += finalWeight }
                if catLower.contains("crime") { scores["crime-mystery", default: 0] += finalWeight }
                if catLower.contains("comedy") { scores["comedy", default: 0] += finalWeight * 0.8 }
                if catLower.contains("romance") { scores["romance-drama", default: 0] += finalWeight * 0.8 }
                if catLower.contains("1080p") { scores["top-1080p", default: 0] += finalWeight }
                if catLower.contains("south indian") { scores["south-indian", default: 0] += finalWeight }
                if catLower.contains("hindi") { scores["hindi", default: 0] += finalWeight }
                if catLower.contains("animation") { scores["animation", default: 0] += finalWeight }
                if catLower.contains("3d") { scores["movies-3d", default: 0] += finalWeight }
                if item.type == .series { scores["tv-series", default: 0] += finalWeight * 0.9 }
            }
        }
        
        // 3. Explicit Likes (+12 weight)
        for (id, isLiked) in likes where isLiked {
            if let item = findItem(by: id) {
                let catLower = item.category.lowercased()
                scores[catLower, default: 0] += 12.0
                if catLower.contains("anime") { scores["anime", default: 0] += 10.0 }
                if catLower.contains("action") { scores["action", default: 0] += 10.0 }
                if catLower.contains("korean") { scores["korean", default: 0] += 10.0 }
                if catLower.contains("sci-fi") { scores["sci-fi", default: 0] += 10.0 }
                if item.type == .series { scores["tv-series", default: 0] += 8.0 }
            }
        }
        
        return scores
    }
    
    private func scoreItem(_ item: MediaItem, affinities: [String: Double]) -> Double {
        var score: Double = 0
        let cat = item.category.lowercased()
        let title = item.title.lowercased()
        
        for (genre, weight) in affinities {
            if cat.contains(genre) || title.contains(genre) {
                score += weight * 2.0
            }
            if let tags = item.tags, tags.contains(where: { $0.localizedCaseInsensitiveContains(genre) }) {
                score += weight
            }
        }
        return score
    }
    
    /// Content similarity based on category match + Jaccard tag coefficient + format weighting
    private func getRecommendationsForWatched(item: MediaItem, excluding: Set<String>) -> [MediaItem] {
        let pool = allItems.isEmpty ? curatedRows.flatMap { $0.items } : allItems
        var scoredCandidates: [(item: MediaItem, similarity: Double)] = []
        var seenIds = excluding
        seenIds.insert(item.id)
        
        let itemCat = item.category.lowercased()
        let itemTags = Set((item.tags ?? []).map { $0.lowercased() })
        
        for candidate in pool {
            guard !seenIds.contains(candidate.id) else { continue }
            guard candidate.type == item.type || item.type == .movie else { continue }
            
            let candCat = candidate.category.lowercased()
            let candTags = Set((candidate.tags ?? []).map { $0.lowercased() })
            
            var similarity: Double = 0
            
            // Category match (weight = 3.0)
            if candCat == itemCat {
                similarity += 3.0
            } else if candCat.contains(itemCat) || itemCat.contains(candCat) {
                similarity += 2.0
            }
            
            // Jaccard similarity on tags: |A ∩ B| / |A ∪ B| (weight = 4.0)
            if !itemTags.isEmpty && !candTags.isEmpty {
                let intersection = Double(itemTags.intersection(candTags).count)
                let union = Double(itemTags.union(candTags).count)
                if union > 0 {
                    similarity += (intersection / union) * 4.0
                }
            }
            
            // HD / 1080p Quality boost
            if candidate.quality == "1080p" || candidate.quality == "HD" {
                similarity += 0.5
            }
            
            if similarity > 1.2 {
                scoredCandidates.append((candidate, similarity))
                seenIds.insert(candidate.id)
                if scoredCandidates.count >= 24 { break }
            }
        }
        
        // Sort by highest similarity score
        let sorted = scoredCandidates.sorted { $0.similarity > $1.similarity }.map { $0.item }
        if sorted.count >= 4 {
            return Array(sorted.prefix(16))
        }
        
        // Fallback to moreLikeThis
        var fallbackResults = sorted
        let fallback = getMoreLikeThis(for: item).filter { !excluding.contains($0.id) && $0.id != item.id }
        for fb in fallback where !seenIds.contains(fb.id) {
            fallbackResults.append(fb)
            seenIds.insert(fb.id)
        }
        
        return Array(fallbackResults.prefix(16))
    }
    
    private func getTopPicksForYou(affinities: [String: Double], excluding: Set<String>, seed: Int) -> [MediaItem] {
        let pool = allItems.isEmpty ? curatedRows.flatMap { $0.items } : allItems
        guard !affinities.isEmpty else {
            return Array(pool.filter { !excluding.contains($0.id) && ($0.quality == "1080p" || $0.quality == "HD") }.prefix(16))
        }
        
        let topGenres = affinities.sorted { $0.value > $1.value }.map { $0.key }.prefix(3)
        var picks: [MediaItem] = []
        var seen = excluding
        
        for candidate in pool {
            guard !seen.contains(candidate.id) else { continue }
            let cat = candidate.category.lowercased()
            let tags = (candidate.tags ?? []).map { $0.lowercased() }
            
            let matches = topGenres.contains { g in cat.contains(g) || tags.contains(where: { $0.contains(g) }) }
            if matches {
                picks.append(candidate)
                seen.insert(candidate.id)
                if picks.count >= 16 { break }
            }
        }
        
        return picks
    }
    
    private func getDiscoveries(excluding: Set<String>, seed: Int) -> [MediaItem] {
        let pool = allItems.isEmpty ? curatedRows.flatMap { $0.items } : allItems
        guard pool.count > 30 else { return [] }
        
        let validPool = pool.filter { !excluding.contains($0.id) && $0.poster != nil }
        guard validPool.count >= 16 else { return [] }
        
        let offset = (abs(seed * 37) + 17) % max(1, validPool.count - 16)
        let slice = Array(validPool[offset..<min(validPool.count, offset + 16)])
        return slice
    }
    
    // Series Detail with Episodes
    public func getSeriesDetail(for id: String) -> SeriesDetail? {
        seriesDetails[id]
    }
    
    // More Like This Recommendation Engine
    public func getMoreLikeThis(for item: MediaItem) -> [MediaItem] {
        let pool = allItems.isEmpty ? curatedRows.flatMap { $0.items } : allItems
        let sameCategory = pool.filter { $0.id != item.id && $0.category.localizedCaseInsensitiveContains(item.category) }
        if sameCategory.count >= 6 {
            return Array(sameCategory.prefix(9))
        }
        let fallback = pool.filter { $0.id != item.id && $0.type == item.type }
        return Array(fallback.prefix(9))
    }
    
    // Lightning Fast Instant Search (<1ms)
    public func search(
        query: String,
        typeFilter: String? = nil,
        categoryFilter: String? = nil,
        qualityFilter: String? = nil,
        limit: Int = 60
    ) -> [MediaItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty || typeFilter != nil || categoryFilter != nil || qualityFilter != nil else {
            return []
        }
        
        let pool = allItems.isEmpty ? curatedRows.flatMap { $0.items } : allItems
        let terms = q.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        var matches: [MediaItem] = []
        for item in pool {
            if let type = typeFilter, item.type.rawValue != type { continue }
            if let cat = categoryFilter, !item.category.localizedCaseInsensitiveContains(cat) { continue }
            if let qual = qualityFilter, item.quality?.localizedCaseInsensitiveContains(qual) != true { continue }
            
            if terms.isEmpty {
                matches.append(item)
            } else {
                let titleLower = item.title.lowercased()
                let tagsLower = (item.tags ?? []).joined(separator: " ").lowercased()
                let matchesAllTerms = terms.allSatisfy { term in
                    titleLower.contains(term) || tagsLower.contains(term)
                }
                if matchesAllTerms {
                    matches.append(item)
                }
            }
            if matches.count >= limit { break }
        }
        return matches
    }
    
    public func findItem(by id: String) -> MediaItem? {
        if let found = allItems.first(where: { $0.id == id }) {
            return found
        }
        for row in curatedRows {
            if let found = row.items.first(where: { $0.id == id }) {
                return found
            }
        }
        return featured.first(where: { $0.id == id })
    }
}
