import SwiftUI

public struct AudioSubtitleMenu: View {
    @ObservedObject var playerManager = DedicatedPlayerManager.shared
    let onClose: () -> Void
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Audio & Subtitles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            HStack(alignment: .top, spacing: 30) {
                // Audio Tracks
                VStack(alignment: .leading, spacing: 12) {
                    Text("AUDIO")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(NetflixTheme.textMuted)
                    
                    ForEach(playerManager.audioTracks, id: \.self) { track in
                        Button(action: {
                            playerManager.selectedAudioTrack = track
                        }) {
                            HStack(spacing: 8) {
                                if playerManager.selectedAudioTrack == track {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Color.clear.frame(width: 12, height: 12)
                                }
                                Text(track)
                                    .font(.system(size: 14, weight: playerManager.selectedAudioTrack == track ? .bold : .regular))
                                    .foregroundColor(playerManager.selectedAudioTrack == track ? .white : NetflixTheme.textSecondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Subtitles
                VStack(alignment: .leading, spacing: 12) {
                    Text("SUBTITLES")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(NetflixTheme.textMuted)
                    
                    ForEach(playerManager.subtitleTracks, id: \.self) { sub in
                        Button(action: {
                            playerManager.selectedSubtitleTrack = sub
                        }) {
                            HStack(spacing: 8) {
                                if playerManager.selectedSubtitleTrack == sub {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Color.clear.frame(width: 12, height: 12)
                                }
                                Text(sub)
                                    .font(.system(size: 14, weight: playerManager.selectedSubtitleTrack == sub ? .bold : .regular))
                                    .foregroundColor(playerManager.selectedSubtitleTrack == sub ? .white : NetflixTheme.textSecondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            
            // External Player Fallbacks
            VStack(alignment: .leading, spacing: 8) {
                Text("EXTERNAL PLAYER ENGINE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(NetflixTheme.textMuted)
                
                HStack(spacing: 10) {
                    ForEach(ExternalPlayerApp.allCases) { app in
                        Button(action: {
                            playerManager.openExternal(app)
                        }) {
                            Text(app.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(hex: "262626"))
                                .cornerRadius(4)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 420)
        .background(Color(hex: "1F1F1F").cornerRadius(12))
        .shadow(radius: 20)
    }
}
