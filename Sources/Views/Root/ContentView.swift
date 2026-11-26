import SwiftUI

public struct ContentView: View {
    @State private var selectedTab: String = "home"
    @State private var isSearchPresented: Bool = false
    @State private var activeDetailItem: MediaItem? = nil
    @State private var showPreferences: Bool = false
    @State private var isPlayerPresented: Bool = false
    
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
                        activeDetailItem = item
                    },
                    onPlayItem: { item in
                        DedicatedPlayerManager.shared.play(item: item)
                    }
                )
                
                // 2. Translucent Floating Navbar (hidden when search is open)
                if !isSearchPresented {
                    HomeFlixNavbarView(
                        selectedTab: $selectedTab,
                        onSearchTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSearchPresented = true
                            }
                        },
                        onPreferencesTap: {
                            showPreferences = true
                        }
                    )
                    .transition(.opacity)
                }
                
                // 3. Search Panel Fullscreen View (State Preserved across playback!)
                if isSearchPresented {
                    SearchModalView(
                        onClose: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSearchPresented = false
                            }
                        },
                        onSelectItem: { item in
                            activeDetailItem = item
                        }
                    )
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(50)
                    .transition(.opacity)
                }
                
                // 4. Fullscreen Dedicated Universal Player Overlay (Pure SwiftUI Z-Stack)
                if isPlayerPresented {
                    DedicatedPlayerView()
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(999)
                        .transition(.opacity)
                }
            }
            // Detail Sheet (Works over both HomeFeed and SearchModalView!)
            .sheet(item: $activeDetailItem) { item in
                DetailSheetView(
                    item: item,
                    onClose: {
                        activeDetailItem = nil
                    },
                    onPlay: { mediaItem, seasonNum, episode in
                        #if canImport(UIKit)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        #endif
                        activeDetailItem = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            DedicatedPlayerManager.shared.play(item: mediaItem, seasonNumber: seasonNum, episode: episode)
                        }
                    }
                )
            }
            .sheet(isPresented: $showPreferences) {
                TastePreferencesSheet(
                    onClose: {
                        showPreferences = false
                    }
                )
            }
            .animation(.easeInOut(duration: 0.25), value: isPlayerPresented)
            .animation(.easeInOut(duration: 0.2), value: isSearchPresented)
            .onReceive(DedicatedPlayerManager.shared.$isPresented) { presented in
                isPlayerPresented = presented
            }
        }
    }
}
