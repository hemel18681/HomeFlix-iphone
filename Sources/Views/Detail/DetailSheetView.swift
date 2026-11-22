import SwiftUI

public struct DetailSheetView: View {
    let initialItem: MediaItem
    let onClose: () -> Void
    let onPlay: (MediaItem, Int?, Episode?) -> Void
    
    @State private var currentItem: MediaItem
    @ObservedObject private var catalogStore = CatalogStore.shared
    @ObservedObject private var watchlistStore = WatchlistStore.shared
    
    public init(
        item: MediaItem,
        onClose: @escaping () -> Void,
        onPlay: @escaping (MediaItem, Int?, Episode?) -> Void
    ) {
        self.initialItem = item
        self._currentItem = State(initialValue: item)
        self.onClose = onClose
        self.onPlay = onPlay
    }
    
    private var seriesDetail: SeriesDetail? {
        catalogStore.getSeriesDetail(for: currentItem.id)
    }
    
    private var moreLikeThis: [MediaItem] {
        catalogStore.getMoreLikeThis(for: currentItem)
    }
    
    private var isWatchlisted: Bool {
        watchlistStore.isInWatchlist(currentItem.id)
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // 1. Top Backdrop with Close Button
                ZStack(alignment: .topTrailing) {
                    AsyncImageView(
                        url: currentItem.backdropURL,
                        aspectRatio: 16.0 / 9.0,
                        contentMode: .fill
                    )
                    .overlay(
                        LinearGradient(
                            colors: [.clear, NetflixTheme.background.opacity(0.9), NetflixTheme.background],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
                    
                    // Close button
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .padding(16)
                }
                
                // 2. Title & Metadata Badges
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentItem.title)
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(currentItem.displayYear)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(NetflixTheme.textSecondary)
                        
                        Text(currentItem.displayQuality)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(3)
                            .foregroundColor(.white)
                        
                        if currentItem.isDualAudio {
                            Text("DUAL AUDIO 5.1")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(NetflixTheme.brandRed)
                                .cornerRadius(3)
                                .foregroundColor(.white)
                        }
                        
                        if let seasons = currentItem.totalSeasons, seasons > 0 {
                            Text("\(seasons) Season\(seasons > 1 ? "s" : "")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(NetflixTheme.textSecondary)
                        }
                    }
                    
                    // Action Buttons (Play & My List)
                    HStack(spacing: 12) {
                        Button(action: {
                            if currentItem.type == .series, let s = seriesDetail?.seasons.first, let ep = s.episodes.first {
                                onPlay(currentItem, s.seasonNumber, ep)
                            } else {
                                onPlay(currentItem, nil, nil)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Play")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(4)
                        }
                        
                        Button(action: {
                            watchlistStore.toggleWatchlist(item: currentItem)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: isWatchlisted ? "checkmark" : "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(isWatchlisted ? "In List" : "My List")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(width: 60)
                        }
                        
                        Button(action: {
                            watchlistStore.setLike(id: currentItem.id, isLiked: true)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "hand.thumbsup")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Rate")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(width: 60)
                        }
                    }
                    .padding(.top, 4)
                    
                    // Overview Synopsis
                    if let overview = currentItem.overview, !overview.isEmpty {
                        Text(overview)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "CCCCCC"))
                            .lineSpacing(4)
                            .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 16)
                
                // 3. Episodes List (if series)
                if currentItem.type == .series, let detail = seriesDetail {
                    EpisodeListView(
                        seriesDetail: detail,
                        currentItem: currentItem,
                        onPlayEpisode: { ep, seasonNum in
                            onPlay(currentItem, seasonNum, ep)
                        }
                    )
                }
                
                // 4. More Like This Grid
                if !moreLikeThis.isEmpty {
                    MoreLikeThisGridView(
                        items: moreLikeThis,
                        onSelectItem: { newItem in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentItem = newItem
                            }
                        }
                    )
                }
                
                Color.clear.frame(height: 40)
            }
        }
        .background(NetflixTheme.background)
    }
}
