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
        NetworkGuardView {
            ZStack(alignment: .top) {
                Color(hex: "141414")
                    .edgesIgnoringSafeArea(.all)
                
                // 1. Main Home Feed
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
                HomeFlixNavbarView(
                    selectedTab: $selectedTab,
                    onSearchTap: {
                        activeSheet = .search
                    },
                    onPreferencesTap: {
                        activeSheet = .preferences
                    }
                )
                
                // 3. Fullscreen Dedicated Universal Player Overlay (Pure SwiftUI Z-Stack: Zero UIKit Modal Glitch)
                if playerManager.isPresented {
                    DedicatedPlayerView()
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(999)
                        .transition(.opacity)
                }
            }
            // Unified Bulletproof Sheet Presentation
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
            .animation(.easeInOut(duration: 0.25), value: playerManager.isPresented)
        }
    }
}
