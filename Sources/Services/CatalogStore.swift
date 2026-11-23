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
    
    private var searchIndex: [MediaItem] = []
    
    public init() {
        loadCatalog()
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
    
    // Personalized row generation matching the web app algorithm
    public func getPersonalizedRows(selectedPreferences: [String]) -> [CategoryRow] {
        guard !selectedPreferences.isEmpty else { return curatedRows }
        
        var result: [CategoryRow] = []
        var processedRowIds = Set<String>()
        
        // Top 10 rows stay pinned at the top
        let top10Rows = curatedRows.filter { $0.isTop10 == true }
        result.append(contentsOf: top10Rows)
        top10Rows.forEach { processedRowIds.insert($0.id) }
        
        // Prioritize rows corresponding to active taste preferences
        for prefId in selectedPreferences {
            guard let config = TastePreference.all.first(where: { $0.id == prefId }) else { continue }
            for targetRowId in config.rowIds {
                guard !processedRowIds.contains(targetRowId) else { continue }
                if let originalRow = curatedRows.first(where: { $0.id == targetRowId }) {
                    var boostedRow = originalRow
                    boostedRow.title = config.personalizedTitle
                    result.append(boostedRow)
                    processedRowIds.insert(targetRowId)
                }
            }
        }
        
        // Append all remaining rows
        for row in curatedRows {
            if !processedRowIds.contains(row.id) {
                result.append(row)
                processedRowIds.insert(row.id)
            }
        }
        
        return result
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
