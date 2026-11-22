import SwiftUI

public struct NetflixPlayerControls: View {
    @ObservedObject var playerManager = DedicatedPlayerManager.shared
    @Binding var showAudioMenu: Bool
    let onClose: () -> Void
    
    public init(showAudioMenu: Binding<Bool>, onClose: @escaping () -> Void) {
        self._showAudioMenu = showAudioMenu
        self.onClose = onClose
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "00:00" }
        let s = Int(seconds)
        let hrs = s / 3600
        let mins = (s % 3600) / 60
        let secs = s % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
    
    public var body: some View {
        ZStack {
            // Dark gradient overlays
            LinearGradient(colors: [Color.black.opacity(0.85), .clear], startPoint: .top, endPoint: .center)
                .allowsHitTesting(false)
            LinearGradient(colors: [.clear, Color.black.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                .allowsHitTesting(false)
            
            VStack {
                // TOP BAR
                HStack(spacing: 16) {
                    Button(action: onClose) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(playerManager.currentTitle)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(playerManager.activeItem?.category ?? "Streaming")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(NetflixTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Audio & Subtitles
                    Button(action: {
                        showAudioMenu.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "captions.bubble")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Audio")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // CENTER PLAYBACK CONTROLS
                HStack(spacing: 48) {
                    // Rewind 10s
                    Button(action: {
                        playerManager.seek(by: -10)
                    }) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.white)
                    }
                    
                    // Circular Play/Pause
                    Button(action: {
                        playerManager.togglePlayPause()
                    }) {
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
                    }
                    
                    // Forward 10s
                    Button(action: {
                        playerManager.seek(by: 10)
                    }) {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // BOTTOM SCRUB BAR & CONTROLS
                VStack(spacing: 8) {
                    // Scrub Slider
                    HStack(spacing: 12) {
                        Text(formatTime(playerManager.currentTime))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Slider(
                            value: Binding(
                                get: { playerManager.currentTime },
                                set: { playerManager.seek(to: $0) }
                            ),
                            in: 0...max(1.0, playerManager.duration)
                        )
                        .accentColor(NetflixTheme.brandRed)
                        
                        Text(formatTime(playerManager.duration))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(NetflixTheme.textSecondary)
                    }
                    
                    // Speed and Landscape buttons
                    HStack {
                        // Speed Menu
                        Menu {
                            Button("0.75x") { playerManager.setSpeed(0.75) }
                            Button("1.0x (Normal)") { playerManager.setSpeed(1.0) }
                            Button("1.25x") { playerManager.setSpeed(1.25) }
                            Button("1.5x") { playerManager.setSpeed(1.5) }
                        } label: {
                            Text("Speed (\(String(format: "%.2g", playerManager.playbackSpeed))x)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        // Landscape Lock
                        Button(action: {
                            playerManager.isForceLandscape.toggle()
                        }) {
                            Image(systemName: playerManager.isForceLandscape ? "lock.rotation.open" : "lock.rotation")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
