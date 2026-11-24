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
#if canImport(KSPlayerUI)
import KSPlayerUI
#endif

public struct KSPlayerRepresentable: UIViewRepresentable {
    public let url: URL
    public let aspectMode: AspectMode
    
    public init(url: URL, aspectMode: AspectMode = .fit) {
        self.url = url
        self.aspectMode = aspectMode
    }
    
    public func makeUIView(context: Context) -> IOSVideoPlayerView {
        let options = KSOptions()
        KSOptions.firstPlayerType = KSMEPlayer.self
        KSOptions.secondPlayerType = KSMEPlayer.self
        KSOptions.isHardwareDecode = true
        KSOptions.isAutoPlay = true
        KSOptions.isSeekedAutoPlay = true
        
        let playerView = IOSVideoPlayerView()
        playerView.toolBar.isHidden = true
        playerView.navigationBar.isHidden = true
        playerView.set(url: url, options: options)
        playerView.contentMode = (aspectMode == .fill) ? .scaleAspectFill : .scaleAspectFit
        context.coordinator.setup(playerView: playerView)
        return playerView
    }
    
    public func updateUIView(_ uiView: IOSVideoPlayerView, context: Context) {
        uiView.toolBar.isHidden = true
        uiView.navigationBar.isHidden = true
        if uiView.url != url {
            let options = KSOptions()
            KSOptions.firstPlayerType = KSMEPlayer.self
            KSOptions.secondPlayerType = KSMEPlayer.self
            uiView.set(url: url, options: options)
        }
        uiView.contentMode = (aspectMode == .fill) ? .scaleAspectFill : .scaleAspectFit
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public class Coordinator: NSObject, PlayerControllerDelegate {
        weak var playerView: IOSVideoPlayerView?
        
        func setup(playerView: IOSVideoPlayerView) {
            self.playerView = playerView
            playerView.delegate = self
            DedicatedPlayerManager.shared.activeKSPlayerLayer = playerView.playerLayer
        }
        
        public func playerController(state: KSPlayerState) {
            Task { @MainActor in
                let manager = DedicatedPlayerManager.shared
                switch state {
                case .readyToPlay:
                    manager.isBuffering = false
                    if let dur = playerView?.playerLayer.player?.duration, dur > 0 {
                        manager.duration = dur
                    }
                    if let resume = manager.pendingResumeTime, resume > 2.0 {
                        let target = CMTime(seconds: resume, preferredTimescale: 600)
                        playerView?.playerLayer.seek(time: target) { _ in }
                        manager.pendingResumeTime = nil
                        manager.showToast("Resumed from \(manager.formatTime(resume))")
                    }
                case .buffering:
                    manager.isBuffering = true
                case .bufferFinished:
                    manager.isBuffering = false
                case .paused:
                    manager.isPlaying = false
                case .played:
                    manager.isPlaying = true
                default:
                    break
                }
            }
        }
        
        public func playerController(currentTime: TimeInterval, totalTime: TimeInterval) {
            Task { @MainActor in
                let manager = DedicatedPlayerManager.shared
                manager.currentTime = currentTime
                if totalTime > 0 {
                    manager.duration = totalTime
                }
                manager.updatePeriodicProgress()
            }
        }
        
        public func playerController(finish error: Error?) {
            Task { @MainActor in
                if error != nil {
                    DedicatedPlayerManager.shared.transitionToResilientStream()
                } else {
                    if DedicatedPlayerManager.shared.hasNextEpisode {
                        DedicatedPlayerManager.shared.playNextEpisode()
                    }
                }
            }
        }
        
        public func playerController(maskShow: Bool) {}
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
                // Absolute Solid Black Background (Zero white-screen flash)
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                // 1. Universal Hardware-Accelerated In-App Video Rendering Layer
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
                
                // 4. Subtle HomeFlix Buffering Spinner
                if playerManager.isBuffering {
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: HomeFlixTheme.brandRed))
                            .scaleEffect(1.5)
                    }
                    .allowsHitTesting(false)
                }
                
                // 5. Clean Non-Intrusive Status Toast
                if let toast = playerManager.statusToast {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(HomeFlixTheme.brandRed)
                            Text(toast)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(hex: "181818").opacity(0.92))
                                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        )
                        .padding(.top, max(54, proxy.safeAreaInsets.top + 10))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
                
                // 6. HomeFlix On-Screen Interactive Controls
                if playerManager.showControls && !playerManager.isLocked {
                    HomeFlixPlayerControls(
                        showAudioMenu: $showAudioMenu,
                        safeAreaInsets: proxy.safeAreaInsets,
                        onClose: {
                            playerManager.close()
                        }
                    )
                    .transition(.opacity)
                }
                
                // 7. Skip Intro Floating Button (All Content)
                if playerManager.showSkipIntro && !playerManager.isLocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                playerManager.skipIntro()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("Skip Intro")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.75))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.4), lineWidth: 1))
                            }
                            .padding(.trailing, max(24, proxy.safeAreaInsets.trailing + 12))
                            .padding(.bottom, max(34, proxy.safeAreaInsets.bottom + (playerManager.showControls ? 95 : 24)))
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
                
                // 8. Next Episode End-Credits Prompt (Series)
                if playerManager.showNextEpisodePrompt && !playerManager.isLocked, let nextEp = playerManager.nextEpisodeInfo {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                playerManager.playNextEpisode()
                            }) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("NEXT EPISODE")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(HomeFlixTheme.brandRed)
                                        Text("S\(nextEp.seasonNumber):E\(nextEp.episode.episodeNumber) \"\(nextEp.episode.title)\"")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                    }
                                    
                                    Image(systemName: "forward.end.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(HomeFlixTheme.brandRed)
                                        .cornerRadius(6)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(hex: "181818").opacity(0.92))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                .shadow(color: .black.opacity(0.6), radius: 10)
                            }
                            .padding(.trailing, max(24, proxy.safeAreaInsets.trailing + 12))
                            .padding(.bottom, max(34, proxy.safeAreaInsets.bottom + (playerManager.showControls ? 95 : 24)))
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                }
                
                // 9. Screen Locked State Floating Unlock Pill
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
                        .padding(.bottom, max(48, proxy.safeAreaInsets.bottom + 24))
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                
                // 10. In-Player Episodes Sheet Drawer (Slide up / modal)
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
                
                // 11. Audio & Subtitles Menu Overlay
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
        .animation(.easeInOut(duration: 0.22), value: playerManager.showSkipIntro)
        .animation(.easeInOut(duration: 0.22), value: playerManager.showNextEpisodePrompt)
        .animation(.easeInOut(duration: 0.22), value: playerManager.rippleState != nil)
        .animation(.easeInOut(duration: 0.25), value: playerManager.showEpisodesSheet)
        .animation(.easeInOut(duration: 0.22), value: showAudioMenu)
        .animation(.easeInOut(duration: 0.22), value: playerManager.statusToast != nil)
        .animation(.easeInOut(duration: 0.22), value: playerManager.isBuffering)
        .statusBar(hidden: !playerManager.showControls)
        .persistentSystemOverlays(playerManager.showControls ? .visible : .hidden)
    }
}
