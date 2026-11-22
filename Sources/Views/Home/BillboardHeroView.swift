import SwiftUI

public struct BillboardHeroView: View {
    let item: MediaItem?
    let onPlay: (MediaItem) -> Void
    let onMoreInfo: (MediaItem) -> Void
    
    @State private var isMuted: Bool = true
    
    public init(
        item: MediaItem?,
        onPlay: @escaping (MediaItem) -> Void,
        onMoreInfo: @escaping (MediaItem) -> Void
    ) {
        self.item = item
        self.onPlay = onPlay
        self.onMoreInfo = onMoreInfo
    }
    
    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 1. Hero Backdrop Image
            if let heroItem = item {
                AsyncImageView(
                    url: heroItem.backdropURL,
                    aspectRatio: 16.0 / 10.0,
                    contentMode: .fill
                )
            } else {
                Rectangle()
                    .fill(Color(hex: "181818"))
                    .aspectRatio(16.0 / 10.0, contentMode: .fit)
            }
            
            // 2. Triple Vignette Gradients
            NetflixTheme.heroTopGradient
            NetflixTheme.heroLeftGradient
            NetflixTheme.heroBottomGradient
            
            // 3. Hero Metadata & Action Buttons
            if let hero = item {
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()
                    
                    // Top 10 Badge & Quality
                    HStack(spacing: 6) {
                        HStack(spacing: 3) {
                            Text("TOP")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.white)
                            Text("10")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(NetflixTheme.brandRed)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(3)
                        
                        Text(hero.displayQuality)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(3)
                            .foregroundColor(.white)
                        
                        if hero.isDualAudio {
                            Text("DUAL AUDIO 5.1")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(NetflixTheme.brandRed)
                                .cornerRadius(3)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Title
                    Text(hero.title)
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                    
                    // Overview
                    if let overview = hero.overview, !overview.isEmpty {
                        Text(overview)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "CCCCCC"))
                            .lineLimit(2)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    }
                    
                    // Buttons
                    HStack(spacing: 12) {
                        // Play Button
                        Button(action: {
                            onPlay(hero)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Play")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 9)
                            .background(Color.white)
                            .cornerRadius(4)
                        }
                        
                        // More Info Button
                        Button(action: {
                            onMoreInfo(hero)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("More Info")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        // Mute / Unmute Button
                        Button(action: {
                            isMuted.toggle()
                        }) {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                                .background(Circle().fill(Color.black.opacity(0.4)))
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16.0 / 10.0, contentMode: .fit)
    }
}
