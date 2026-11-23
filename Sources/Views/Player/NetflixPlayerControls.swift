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
    
    private var durationOrRemainingLabel: String {
        if playerManager.isRemainingTime {
            let remaining = max(0, playerManager.duration - playerManager.currentTime)
            return "-\(formatTime(remaining))"
        } else {
            return formatTime(playerManager.duration)
        }
    }
    
    public var body: some View {
        ZStack {
            // Dark Netflix Cinematic Vignette Gradients
            LinearGradient(
                colors: [Color.black.opacity(0.88), Color.black.opacity(0.4), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
            
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.4), Color.black.opacity(0.92)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                // 1. TOP BAR
                HStack(spacing: 14) {
                    // Back button
                    Button(action: onClose) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.black.opacity(0.55)))
                    }
                    
                    // Title and Series Metadata
                    VStack(alignment: .leading, spacing: 2) {
                        Text(playerManager.currentTitle)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Text(playerManager.activeItem?.category ?? "Streaming")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(NetflixTheme.textSecondary)
                            
                            if playerManager.isSampleMode {
                                Text("VERIFIED 1080P")
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "2E7D32"))
                                    .cornerRadius(3)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Aspect Mode Toggle (Fit vs Fill)
                    Button(action: {
                        playerManager.toggleAspectMode()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: playerManager.aspectMode == .fill ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                                .font(.system(size: 12, weight: .bold))
                            Text(playerManager.aspectMode.rawValue)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(6)
                    }
                    
                    // Screen Lock Button (Top Quick Lock)
                    Button(action: {
                        playerManager.toggleScreenLock()
                    }) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.55)))
                    }
                    
                    // Audio & Subtitles
                    Button(action: {
                        showAudioMenu.toggle()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "captions.bubble.fill")
                                .font(.system(size: 15, weight: .semibold))
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
                
                // 2. CENTER PLAYBACK CONTROLS
                if playerManager.playbackError == nil {
                    HStack(spacing: 52) {
                        // Rewind 10s
                        Button(action: {
                            playerManager.seek(by: -10)
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: "gobackward.10")
                                    .font(.system(size: 38, weight: .light))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 54, height: 54)
                        }
                        
                        // Circular Play/Pause Toggle
                        Button(action: {
                            playerManager.togglePlayPause()
                        }) {
                            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 38))
                                .foregroundColor(.white)
                                .frame(width: 76, height: 76)
                                .background(Circle().fill(Color.black.opacity(0.65)))
                                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
                                .shadow(color: .black.opacity(0.6), radius: 10)
                        }
                        
                        // Forward 10s
                        Button(action: {
                            playerManager.seek(by: 10)
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: "goforward.10")
                                    .font(.system(size: 38, weight: .light))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 54, height: 54)
                        }
                    }
                }
                
                Spacer()
                
                // 3. BOTTOM SCRUB BAR & MULTI-ACTION CONTROLS
                VStack(spacing: 10) {
                    // Netflix Scrub Timeline
                    HStack(spacing: 12) {
                        Text(formatTime(playerManager.currentTime))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Slider(
                            value: Binding(
                                get: { playerManager.currentTime },
                                set: { playerManager.seek(to: $0) }
                            ),
                            in: 0...max(1.0, playerManager.duration)
                        )
                        .tint(NetflixTheme.brandRed)
                        
                        // Tap to toggle total duration vs remaining time
                        Button(action: {
                            playerManager.toggleRemainingTime()
                        }) {
                            Text(durationOrRemainingLabel)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(NetflixTheme.textSecondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(4)
                        }
                    }
                    
                    // Netflix Bottom Actions Bar
                    HStack(spacing: 14) {
                        // Playback Speed Selector
                        Menu {
                            Button("0.5x") { playerManager.setSpeed(0.5) }
                            Button("0.75x") { playerManager.setSpeed(0.75) }
                            Button("1.0x (Normal)") { playerManager.setSpeed(1.0) }
                            Button("1.25x") { playerManager.setSpeed(1.25) }
                            Button("1.5x") { playerManager.setSpeed(1.5) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "gauge.medium")
                                    .font(.system(size: 11))
                                Text("Speed (\(String(format: "%.2g", playerManager.playbackSpeed))x)")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.16))
                            .cornerRadius(5)
                        }
                        
                        // Lock Screen button
                        Button(action: {
                            playerManager.toggleScreenLock()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 11))
                                Text("Lock")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.16))
                            .cornerRadius(5)
                        }
                        
                        // Episodes Drawer (Series only)
                        if playerManager.activeItem?.type == .series {
                            Button(action: {
                                playerManager.showEpisodesSheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "rectangle.grid.1x2.fill")
                                        .font(.system(size: 11))
                                    Text("Episodes")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.16))
                                .cornerRadius(5)
                            }
                            
                            // 1-Tap Next Episode Quick Jump (if available)
                            if playerManager.hasNextEpisode {
                                Button(action: {
                                    playerManager.playNextEpisode()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "forward.end.fill")
                                            .font(.system(size: 11))
                                        Text("Next Ep")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(NetflixTheme.brandRed)
                                    .cornerRadius(5)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Instant Verified Test Stream Mode Toggle
                        Button(action: {
                            if playerManager.isSampleMode {
                                playerManager.retryPlayback()
                            } else {
                                playerManager.playSampleStream()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: playerManager.isSampleMode ? "antenna.radiowaves.left.and.right" : "play.circle")
                                    .font(.system(size: 11))
                                Text(playerManager.isSampleMode ? "Switch to BDIX" : "Test Sample")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(playerManager.isSampleMode ? Color(hex: "4ADE80") : .white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(playerManager.isSampleMode ? Color(hex: "1F3D1F") : Color.white.opacity(0.16))
                            .cornerRadius(5)
                        }
                        
                        // Landscape / Portrait Lock
                        Button(action: {
                            playerManager.isForceLandscape.toggle()
                        }) {
                            Image(systemName: playerManager.isForceLandscape ? "lock.rotation.open" : "lock.rotation")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(6)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 22)
            }
        }
    }
}
