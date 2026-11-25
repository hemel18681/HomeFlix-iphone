import SwiftUI

public struct AudioSubtitleMenu: View {
    @ObservedObject var playerManager = DedicatedPlayerManager.shared
    let onClose: () -> Void
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .foregroundColor(HomeFlixTheme.brandRed)
                    Text("Audio & Subtitles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color(hex: "2A2A2A")))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Audio & Subtitle Selectors
            HStack(alignment: .top, spacing: 30) {
                // Audio Tracks (Dual Audio)
                VStack(alignment: .leading, spacing: 12) {
                    Text("AUDIO STREAM")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1.2)
                        .foregroundColor(HomeFlixTheme.textMuted)
                    
                    if playerManager.audioTracks.isEmpty {
                        Text("Default Audio")
                            .font(.system(size: 13))
                            .foregroundColor(HomeFlixTheme.textSecondary)
                    } else {
                        ForEach(playerManager.audioTracks, id: \.self) { track in
                            Button(action: {
                                playerManager.selectAudioTrack(track)
                            }) {
                                HStack(spacing: 8) {
                                    if playerManager.selectedAudioTrack == track {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(HomeFlixTheme.brandRed)
                                    } else {
                                        Color.clear.frame(width: 12, height: 12)
                                    }
                                    Text(track)
                                        .font(.system(size: 14, weight: playerManager.selectedAudioTrack == track ? .bold : .regular))
                                        .foregroundColor(playerManager.selectedAudioTrack == track ? .white : HomeFlixTheme.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Subtitles
                VStack(alignment: .leading, spacing: 12) {
                    Text("SUBTITLES")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1.2)
                        .foregroundColor(HomeFlixTheme.textMuted)
                    
                    ForEach(playerManager.subtitleTracks, id: \.self) { sub in
                        Button(action: {
                            playerManager.selectSubtitleTrack(sub)
                        }) {
                            HStack(spacing: 8) {
                                if playerManager.selectedSubtitleTrack == sub {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(HomeFlixTheme.brandRed)
                                } else {
                                    Color.clear.frame(width: 12, height: 12)
                                }
                                Text(sub)
                                    .font(.system(size: 14, weight: playerManager.selectedSubtitleTrack == sub ? .bold : .regular))
                                    .foregroundColor(playerManager.selectedSubtitleTrack == sub ? .white : HomeFlixTheme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            
            // In-App Audio Engine Info
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12))
                    .foregroundColor(HomeFlixTheme.brandRed)
                Text("Dolby Digital 5.1 & Multi-Track Hardware Decoding Active")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(HomeFlixTheme.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 440)
        .background(Color(hex: "1A1A1A").cornerRadius(14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "333333"), lineWidth: 1))
        .shadow(color: .black.opacity(0.8), radius: 25)
    }
}
