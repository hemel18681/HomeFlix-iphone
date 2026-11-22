import SwiftUI

public struct MediaCardView: View {
    let item: MediaItem
    var rank: Int? = nil
    var width: CGFloat = 160
    var isLandscape: Bool = true
    let onSelect: (MediaItem) -> Void
    
    @ObservedObject private var watchlistStore = WatchlistStore.shared
    @State private var isPressed: Bool = false
    
    public init(
        item: MediaItem,
        rank: Int? = nil,
        width: CGFloat = 160,
        isLandscape: Bool = true,
        onSelect: @escaping (MediaItem) -> Void
    ) {
        self.item = item
        self.rank = rank
        self.width = width
        self.isLandscape = isLandscape
        self.onSelect = onSelect
    }
    
    private var progress: WatchProgress? {
        watchlistStore.getProgress(item.id)
    }
    
    public var body: some View {
        Button(action: {
            onSelect(item)
        }) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    // Poster / Backdrop Image
                    AsyncImageView(
                        url: isLandscape ? item.backdropURL : item.posterURL,
                        aspectRatio: isLandscape ? (16.0 / 9.0) : (2.0 / 3.0),
                        contentMode: .fill
                    )
                    
                    // Card Bottom Gradient
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.85)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    
                    // Badges & Metadata
                    VStack(alignment: .leading, spacing: 4) {
                        Spacer()
                        
                        // Title
                        Text(item.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            if let q = item.quality, !q.isEmpty {
                                Text(q)
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1.5)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(2)
                                    .foregroundColor(.white)
                            }
                            
                            if item.isDualAudio {
                                Text("DUAL")
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1.5)
                                    .background(NetflixTheme.brandRed)
                                    .cornerRadius(2)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text(item.displayYear)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(NetflixTheme.textSecondary)
                        }
                    }
                    .padding(6)
                    
                    // Watch Progress Bar
                    if let p = progress, p.percent > 0 {
                        VStack {
                            Spacer()
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 3)
                                    Rectangle()
                                        .fill(NetflixTheme.brandRed)
                                        .frame(width: geo.size.width * CGFloat(p.percent / 100.0), height: 3)
                                }
                            }
                            .frame(height: 3)
                        }
                    }
                }
                .frame(width: width, height: isLandscape ? (width * 9.0 / 16.0) : (width * 1.5))
                .background(NetflixTheme.cardBackground)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(NetflixTheme.border, lineWidth: 0.5)
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
    }
}
