import SwiftUI
import AVKit

#if canImport(UIKit)
import UIKit

public struct PlayerViewRepresentable: UIViewRepresentable {
    public let player: AVPlayer
    public let aspectMode: AspectMode
    
    public init(player: AVPlayer, aspectMode: AspectMode = .fit) {
        self.player = player
        self.aspectMode = aspectMode
    }
    
    public func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = (aspectMode == .fill) ? .resizeAspectFill : .resizeAspect
        view.backgroundColor = .black
        return view
    }
    
    public func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
        let targetGravity: AVLayerVideoGravity = (aspectMode == .fill) ? .resizeAspectFill : .resizeAspect
        if uiView.playerLayer.videoGravity != targetGravity {
            uiView.playerLayer.videoGravity = targetGravity
        }
    }
}

public class PlayerUIView: UIView {
    public override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    public var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
#endif

#if canImport(KSPlayer)
import KSPlayer

public struct KSPlayerRepresentable: UIViewRepresentable {
    public let url: URL
    public let aspectMode: AspectMode
    
    public init(url: URL, aspectMode: AspectMode = .fit) {
        self.url = url
        self.aspectMode = aspectMode
    }
    
    public func makeUIView(context: Context) -> KSVideoPlayerView {
        let options = KSOptions()
        KSOptions.secondPlayerType = KSMEPlayer.self
        let playerView = KSVideoPlayerView(url: url, options: options)
        playerView.contentMode = (aspectMode == .fill) ? .scaleAspectFill : .scaleAspectFit
        return playerView
    }
    
    public func updateUIView(_ uiView: KSVideoPlayerView, context: Context) {
        if uiView.url != url {
            uiView.set(url: url)
        }
        uiView.contentMode = (aspectMode == .fill) ? .scaleAspectFill : .scaleAspectFit
    }
}
#endif

public struct DedicatedPlayerView: View {
    @ObservedObject var playerManager = DedicatedPlayerManager.shared
    @State private var showAudioMenu: Bool = false
    
    public init() {}
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Absolute Solid Black Background
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                // 1. Universal In-App Video Rendering Layer
                #if canImport(KSPlayer)
                if let streamUrl = playerManager.resolvedStreamURL {
                    KSPlayerRepresentable(url: streamUrl, aspectMode: playerManager.aspectMode)
                        .edgesIgnoringSafeArea(.all)
                }
                #else
                if let p = playerManager.player {
                    #if canImport(UIKit)
                    PlayerViewRepresentable(player: p, aspectMode: playerManager.aspectMode)
                        .edgesIgnoringSafeArea(.all)
                    #else
                    VideoPlayer(player: p)
                        .edgesIgnoringSafeArea(.all)
                    #endif
                }
                #endif
                
                // 2. Gesture Handling Layer (Double-tap Seek & Single-tap Controls)
                HStack(spacing: 0) {
                    // Left 50% - Rewind 10s on Double Tap
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            playerManager.triggerDoubleTapSeek(side: .left)
                        }
                        .onTapGesture(count: 1) {
                            playerManager.handleScreenTap()
                        }
                    
                    // Right 50% - Fast-Forward 10s on Double Tap
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            playerManager.triggerDoubleTapSeek(side: .right)
                        }
                        .onTapGesture(count: 1) {
                            playerManager.handleScreenTap()
                        }
                }
                .edgesIgnoringSafeArea(.all)
                
                // 3. Double-Tap Seek Ripple Animation Layer
                if let ripple = playerManager.rippleState {
                    HStack {
                        if ripple.side == .left {
                            HStack(spacing: 8) {
                                Image(systemName: "gobackward.10")
                                    .font(.system(size: 32, weight: .semibold))
                                Text("10 seconds")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.65))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                            )
                            .padding(.leading, 40)
                            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                            Spacer()
                        } else {
                            Spacer()
                            HStack(spacing: 8) {
                                Text("10 seconds")
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "goforward.10")
                                    .font(.system(size: 32, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.65))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                            )
                            .padding(.trailing, 40)
                            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                        }
                    }
                    .allowsHitTesting(false)
                }
                
                // 4. Buffering Indicator
                if playerManager.isBuffering && playerManager.playbackError == nil {
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: NetflixTheme.brandRed))
                            .scaleEffect(1.6)
                        
                        Text("Connecting to High-Speed Stream...")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 4)
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.65).cornerRadius(12))
                }
                
                // 5. Playback Error & Recovery Screen (100% In-App)
                if let errorMsg = playerManager.playbackError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(NetflixTheme.brandRed)
                        
                        Text("Stream Playback Alert")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(errorMsg)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "CCCCCC"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 24)
                        
                        // In-App Action Buttons
                        VStack(spacing: 10) {
                            Button(action: {
                                playerManager.playSampleStream()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 13))
                                    Text("▶ Play Test Video (Verify In-App Player)")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "4ADE80"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "1A2E1A"))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "2E7D32"), lineWidth: 1))
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    playerManager.retryPlayback()
                                }) {
                                    Text("🔄 Retry Stream")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(NetflixTheme.brandRed)
                                        .cornerRadius(6)
                                }
                                
                                Button(action: {
                                    playerManager.close()
                                }) {
                                    Text("✕ Close Player")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color(hex: "333333"))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: 440)
                    .background(Color(hex: "181818").cornerRadius(14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "333333"), lineWidth: 1))
                    .shadow(color: .black.opacity(0.8), radius: 25)
                    .padding(.horizontal, 20)
                }
                
                // 6. Netflix On-Screen Interactive Controls
                if playerManager.showControls && !playerManager.isLocked {
                    NetflixPlayerControls(
                        showAudioMenu: $showAudioMenu,
                        onClose: {
                            playerManager.close()
                        }
                    )
                    .transition(.opacity)
                }
                
                // 7. Screen Locked State Floating Unlock Pill
                if playerManager.isLocked && playerManager.showLockControlsHint {
                    VStack {
                        Spacer()
                        Button(action: {
                            playerManager.toggleScreenLock()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Screen Locked • Tap to Unlock")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "1F1F1F").opacity(0.92))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1.5))
                            )
                            .shadow(color: .black.opacity(0.8), radius: 16)
                        }
                        .padding(.bottom, 48)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                
                // 8. In-Player Episodes Sheet Drawer (Slide up / modal)
                if playerManager.showEpisodesSheet {
                    Color.black.opacity(0.65)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            playerManager.showEpisodesSheet = false
                        }
                    
                    VStack {
                        Spacer()
                        PlayerEpisodesSheet(onClose: {
                            playerManager.showEpisodesSheet = false
                        })
                        .frame(maxHeight: proxy.size.height * 0.85)
                    }
                    .transition(.move(edge: .bottom))
                }
                
                // 9. Audio & Subtitles Menu Overlay
                if showAudioMenu {
                    Color.black.opacity(0.65)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showAudioMenu = false
                        }
                    
                    AudioSubtitleMenu(onClose: {
                        showAudioMenu = false
                    })
                    .transition(.scale)
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: playerManager.showControls)
        .animation(.easeInOut(duration: 0.22), value: playerManager.isLocked)
        .animation(.easeInOut(duration: 0.22), value: playerManager.showLockControlsHint)
        .animation(.easeInOut(duration: 0.22), value: playerManager.rippleState != nil)
        .animation(.easeInOut(duration: 0.25), value: playerManager.showEpisodesSheet)
        .animation(.easeInOut(duration: 0.22), value: showAudioMenu)
        .animation(.easeInOut(duration: 0.22), value: playerManager.playbackError != nil)
    }
}
