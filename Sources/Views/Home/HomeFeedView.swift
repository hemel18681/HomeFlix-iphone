import SwiftUI

public struct HomeFeedView: View {
    @ObservedObject var catalogStore = CatalogStore.shared
    @ObservedObject var watchlistStore = WatchlistStore.shared
    @Binding var selectedTab: String
    
    let onSelectItem: (MediaItem) -> Void
    let onPlayItem: (MediaItem) -> Void
    
    public init(
        selectedTab: Binding<String>,
        onSelectItem: @escaping (MediaItem) -> Void,
        onPlayItem: @escaping (MediaItem) -> Void
    ) {
        self._selectedTab = selectedTab
        self.onSelectItem = onSelectItem
        self.onPlayItem = onPlayItem
    }
    
    private var displayedRows: [CategoryRow] {
        let baseRows = catalogStore.getPersonalizedRows(selectedPreferences: watchlistStore.preferences)
        
        switch selectedTab {
        case "series":
            return baseRows.filter { row in
                row.id.contains("tv") || row.id.contains("korean") || row.items.contains { $0.type == .series }
            }
        case "movies":
            return baseRows.filter { row in
                row.id.contains("movie") || row.id.contains("1080p") || row.items.contains { $0.type == .movie }
            }
        case "anime":
            return baseRows.filter { row in
                row.id.contains("anime") || row.id.contains("animation")
            }
        default:
            return baseRows
        }
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // 1. Billboard Hero (on Home tab)
                if selectedTab == "home" || selectedTab == "movies" {
                    BillboardHeroView(
                        item: catalogStore.featured.first,
                        onPlay: onPlayItem,
                        onMoreInfo: onSelectItem
                    )
                }
                
                // 2. Continue Watching Row (if user has active history)
                if !watchlistStore.continueWatchingItems.isEmpty && (selectedTab == "home" || selectedTab == "mylist") {
                    ContentRowView(
                        row: CategoryRow(
                            id: "continue-watching",
                            title: "▶ Continue Watching for You",
                            items: watchlistStore.continueWatchingItems
                        ),
                        onSelect: onSelectItem
                    )
                }
                
                // 3. My List Row (if user has watchlist items)
                if !watchlistStore.mylistItems.isEmpty && (selectedTab == "home" || selectedTab == "mylist") {
                    ContentRowView(
                        row: CategoryRow(
                            id: "my-list",
                            title: "✓ My List",
                            items: watchlistStore.mylistItems
                        ),
                        onSelect: onSelectItem
                    )
                }
                
                // 4. Personalized Curated Rows
                ForEach(displayedRows) { row in
                    ContentRowView(row: row, onSelect: onSelectItem)
                }
                
                // Bottom Padding for smooth scrolling
                Color.clear.frame(height: 80)
            }
        }
        .background(NetflixTheme.background)
        .refreshable {
            catalogStore.loadCatalog()
        }
    }
}
