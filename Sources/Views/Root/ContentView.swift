import SwiftUI

public enum ActiveSheet: Identifiable {
    case detail(MediaItem)
    case search
    case preferences
    
    public var id: String {
        switch self {
        case .detail(let item): return "detail_\(item.id)"
        case .search: return "search"
        case .preferences: return "preferences"
        }
    }
}

public struct ContentView: View {
    @State private var selectedTab: String = "home"
    @State private var activeSheet: ActiveSheet? = nil
    
    @ObservedObject private var playerManager = DedicatedPlayerManager.shared
    @ObservedObject private var catalogStore = CatalogStore.shared
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "141414").edgesIgnoringSafeArea(.all)
            
            // 1. Home Feed View
            HomeFeedView(
                selectedTab: $selectedTab,
                onSelectItem: { item in
                    activeSheet = .detail(item)
                },
                onPlayItem: { item in
                    playerManager.play(item: item)
                }
            )
            
            // 2. Translucent Floating Navbar
            NetflixNavbarView(
                selectedTab: $selectedTab,
                onSearchTap: {
                    activeSheet = .search
                },
                onPreferencesTap: {
                    activeSheet = .preferences
                }
            )
        }
        // Unified Bulletproof Sheet Presentation (Zero collision / Zero bug)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .detail(let item):
                DetailSheetView(
                    item: item,
                    onClose: {
                        activeSheet = nil
                    },
                    onPlay: { mediaItem, seasonNum, episode in
                        activeSheet = nil
                        playerManager.play(item: mediaItem, seasonNumber: seasonNum, episode: episode)
                    }
                )
            case .search:
                SearchModalView(
                    onClose: {
                        activeSheet = nil
                    },
                    onSelectItem: { item in
                        activeSheet = .detail(item)
                    }
                )
            case .preferences:
                TastePreferencesSheet(
                    onClose: {
                        activeSheet = nil
                    }
                )
            }
        }
        // Dedicated Fullscreen Universal Player
        .fullScreenCover(isPresented: $playerManager.isPresented) {
            DedicatedPlayerView()
        }
    }
}
