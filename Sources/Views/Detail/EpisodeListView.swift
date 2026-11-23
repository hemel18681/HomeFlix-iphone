import SwiftUI

public struct EpisodeListView: View {
    let seriesDetail: SeriesDetail
    let currentItem: MediaItem
    let onPlayEpisode: (Episode, Int) -> Void
    
    @State private var selectedSeasonIndex: Int = 0
    @ObservedObject private var watchlistStore = WatchlistStore.shared
    
    public init(
        seriesDetail: SeriesDetail,
        currentItem: MediaItem,
        onPlayEpisode: @escaping (Episode, Int) -> Void
    ) {
        self.seriesDetail = seriesDetail
        self.currentItem = currentItem
        self.onPlayEpisode = onPlayEpisode
    }
    
    private var currentSeason: Season? {
        guard !seriesDetail.seasons.isEmpty else { return nil }
        let idx = min(selectedSeasonIndex, seriesDetail.seasons.count - 1)
        return seriesDetail.seasons[idx]
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Season Selector
            HStack {
                Text("Episodes")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if seriesDetail.seasons.count > 1 {
                    Menu {
                        ForEach(Array(seriesDetail.seasons.enumerated()), id: \.element.id) { index, season in
                            Button(season.seasonName) {
                                selectedSeasonIndex = index
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(currentSeason?.seasonName ?? "Season 1")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(HomeFlixTheme.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "262626"))
                        .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Episode Rows
            if let season = currentSeason {
                LazyVStack(spacing: 8) {
                    ForEach(season.episodes) { ep in
                        let epKey = "\(currentItem.id)_s\(season.seasonNumber)_e\(ep.episodeNumber)"
                        let epProgress = watchlistStore.getProgress(epKey)
                        
                        Button(action: {
                            onPlayEpisode(ep, season.seasonNumber)
                        }) {
                            HStack(spacing: 12) {
                                // Episode Thumbnail / Number Box
                                ZStack {
                                    Rectangle()
                                        .fill(Color(hex: "222222"))
                                        .frame(width: 80, height: 48)
                                        .cornerRadius(4)
                                    
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    
                                    // Progress bar at bottom of ep box
                                    if let p = epProgress, p.percent > 0 {
                                        VStack {
                                            Spacer()
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Rectangle().fill(Color.white.opacity(0.3)).frame(height: 2)
                                                    Rectangle().fill(HomeFlixTheme.brandRed).frame(width: geo.size.width * CGFloat(p.percent / 100.0), height: 2)
                                                }
                                            }
                                            .frame(height: 2)
                                        }
                                    }
                                }
                                
                                // Episode Metadata
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(ep.episodeNumber). \(ep.title)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    if let size = ep.fileSize, !size.isEmpty {
                                        Text(size)
                                            .font(.system(size: 11, weight: .regular))
                                            .foregroundColor(HomeFlixTheme.textMuted)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.down.to.line")
                                    .font(.system(size: 13))
                                    .foregroundColor(HomeFlixTheme.textSecondary)
                                    .padding(.trailing, 8)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "1A1A1A"))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
