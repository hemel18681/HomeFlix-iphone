import SwiftUI

public struct PlayerEpisodesSheet: View {
    @ObservedObject var playerManager = DedicatedPlayerManager.shared
    @ObservedObject var catalogStore = CatalogStore.shared
    let onClose: () -> Void
    
    @State private var selectedSeasonIndex: Int = 0
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    private var seriesDetail: SeriesDetail? {
        guard let item = playerManager.activeItem, item.type == .series else { return nil }
        return catalogStore.getSeriesDetail(for: item.id)
    }
    
    private var currentSeason: Season? {
        guard let detail = seriesDetail, !detail.seasons.isEmpty else { return nil }
        let idx = min(selectedSeasonIndex, detail.seasons.count - 1)
        return detail.seasons[idx]
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Episodes")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Season Dropdown if multiple seasons
                if let detail = seriesDetail, detail.seasons.count > 1 {
                    Menu {
                        ForEach(Array(detail.seasons.enumerated()), id: \.element.id) { index, season in
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
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(NetflixTheme.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "2A2A2A"))
                        .cornerRadius(6)
                    }
                }
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color(hex: "2A2A2A")))
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(Color(hex: "333333"))
            
            // Episode List
            if let season = currentSeason {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 10) {
                        ForEach(season.episodes) { ep in
                            let isPlaying = playerManager.activeEpisode?.episodeNumber == ep.episodeNumber &&
                                            (playerManager.activeSeasonNumber ?? 1) == season.seasonNumber
                            
                            Button(action: {
                                if let item = playerManager.activeItem {
                                    playerManager.play(item: item, seasonNumber: season.seasonNumber, episode: ep)
                                    onClose()
                                }
                            }) {
                                HStack(spacing: 14) {
                                    // Thumbnail / Episode Index Box
                                    ZStack {
                                        Rectangle()
                                            .fill(isPlaying ? Color(hex: "2A1414") : Color(hex: "222222"))
                                            .frame(width: 88, height: 52)
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(isPlaying ? NetflixTheme.brandRed : Color.clear, lineWidth: 1.5)
                                            )
                                        
                                        if isPlaying {
                                            Image(systemName: "speaker.wave.3.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(NetflixTheme.brandRed)
                                        } else {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    // Title & Info
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("\(ep.episodeNumber). \(ep.title)")
                                            .font(.system(size: 14, weight: isPlaying ? .bold : .semibold))
                                            .foregroundColor(isPlaying ? NetflixTheme.brandRed : .white)
                                            .lineLimit(1)
                                        
                                        if let size = ep.fileSize, !size.isEmpty {
                                            Text(size)
                                                .font(.system(size: 11))
                                                .foregroundColor(NetflixTheme.textMuted)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if isPlaying {
                                        Text("PLAYING")
                                            .font(.system(size: 9, weight: .black))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(NetflixTheme.brandRed)
                                            .cornerRadius(3)
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isPlaying ? Color(hex: "201818") : Color(hex: "181818"))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "film")
                        .font(.system(size: 32))
                        .foregroundColor(NetflixTheme.textMuted)
                    Text("No episode data available for this title.")
                        .font(.system(size: 13))
                        .foregroundColor(NetflixTheme.textSecondary)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: 540)
        .background(Color(hex: "161616").cornerRadius(16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "333333"), lineWidth: 1))
        .shadow(color: .black.opacity(0.85), radius: 30)
        .onAppear {
            if let detail = seriesDetail, let activeSeason = playerManager.activeSeasonNumber {
                if let idx = detail.seasons.firstIndex(where: { $0.seasonNumber == activeSeason }) {
                    selectedSeasonIndex = idx
                }
            }
        }
    }
}
