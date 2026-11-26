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

public class HomeFlixPlayerOptions: KSOptions {
    public override init() {
        super.init()
        hardwareDecode = true
        asynchronousDecompression = false
        autoRotate = false
        autoSelectEmbedSubtitle = true
        preferredForwardBufferDuration = 3.0
        maxBufferDuration = 30.0
        isSecondOpen = true
        isAccurateSeek = false
        isSeekImageSubtitle = true
        
        // Clean LAN/BDIX HTTP streaming parameters (avoid multiple_requests & artificial buffer_size)
        formatContextOptions["reconnect"] = 1
        formatContextOptions["reconnect_streamed"] = 1
        formatContextOptions["reconnect_delay_max"] = 5
        decoderOptions["threads"] = "auto"
        decoderOptions["refcounted_frames"] = "1"
    }
    
    // Provide generous decoded frame queue headroom (64 frames ~= 2.7s buffer) so CADisplayLink never starves
    open override func videoFrameMaxCount(fps: Float, naturalSize: CGSize, isLive: Bool) -> UInt8 {
        return 64
    }
    
    open override func videoClockSync(main: KSClock, nextVideoTime: TimeInterval, fps: Double, frameCount: Int) -> (Double, ClockProcessType) {
        let desire = main.getTime() - videoDelay
        let diff = nextVideoTime - desire
        let effectiveFps = (fps >= 10.0 && fps <= 120.0) ? fps : 24.0
        let frameDuration = 1.0 / effectiveFps
        
        // 1. Hold frame if ahead of audio clock by more than half a frame duration
        if diff >= (frameDuration / 2.0) {
            return (diff, .remain)
        }
        
        // 2. Smooth sync tolerance: only drop frames if lagging behind by over 1.0s AND multiple frames queued
        if diff < -1.0 {
            if diff < -3.5 {
                return (diff, .flush)
            } else if frameCount > 3 {
                return (diff, .dropNextFrame)
            }
        }
        
        // 3. Smooth presentation
        return (diff, .next)
    }
}

public class KSPlayerContainerView: UIView {
    public var playerLayer: KSPlayerLayer? {
        didSet {
            attachVideoViewIfNeeded()
        }
    }
    
    private weak var currentVideoView: UIView?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        isUserInteractionEnabled = false
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let videoView = currentVideoView {
            if videoView.frame != bounds {
                videoView.frame = bounds
            }
        } else {
            attachVideoViewIfNeeded()
        }
    }
    
    public func attachVideoViewIfNeeded() {
        guard let layer = playerLayer, let videoView = layer.player.view else { return }
        if videoView.superview !== self {
            subviews.forEach { $0.removeFromSuperview() }
            videoView.frame = bounds
            videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            videoView.isUserInteractionEnabled = false
            addSubview(videoView)
            currentVideoView = videoView
        } else if videoView.frame != bounds {
            videoView.frame = bounds
        }
        if bounds.width > 0 && bounds.height > 0 {
            videoView.setNeedsLayout()
            videoView.layoutIfNeeded()
        }
    }
}

public struct KSPlayerRepresentable: UIViewRepresentable {
    public let url: URL
    public let aspectMode: AspectMode
    
    public init(url: URL, aspectMode: AspectMode = .fit) {
        self.url = url
        self.aspectMode = aspectMode
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public func makeUIView(context: Context) -> KSPlayerContainerView {
        let container = KSPlayerContainerView()
        
        KSOptions.firstPlayerType = KSMEPlayer.self
        KSOptions.secondPlayerType = KSMEPlayer.self
        KSOptions.hardwareDecode = true
        KSOptions.asynchronousDecompression = false
        KSOptions.preferredFrame = false
        KSOptions.preferredForwardBufferDuration = 3.0
        
        let options = HomeFlixPlayerOptions()
        
        let layer = KSPlayerLayer(url: url, isAutoPlay: true, options: options, delegate: context.coordinator)
        layer.player.contentMode = (aspectMode == .fill) ? .scaleAspectFill : .scaleAspectFit
        
        container.playerLayer = layer
        container.attachVideoViewIfNeeded()
        context.coordinator.setup(layer: layer, container: container)
        
        layer.play()
        
        return container
    }
    
    public func updateUIView(_ uiView: KSPlayerContainerView, context: Context) {
        if uiView.playerLayer?.url != url {
            KSOptions.firstPlayerType = KSMEPlayer.self
            KSOptions.secondPlayerType = KSMEPlayer.self
            KSOptions.hardwareDecode = true
            KSOptions.asynchronousDecompression = false
            KSOptions.preferredFrame = false
            KSOptions.preferredForwardBufferDuration = 3.0
            
            let options = HomeFlixPlayerOptions()
            
            let layer = KSPlayerLayer(url: url, isAutoPlay: true, options: options, delegate: context.coordinator)
            layer.player.contentMode = (aspectMode == .fill) ? .scaleAspectFill : .scaleAspectFit
            
            uiView.playerLayer = layer
            uiView.attachVideoViewIfNeeded()
            context.coordinator.setup(layer: layer, container: uiView)
            
            layer.play()
        }
        let targetMode: UIView.ContentMode = (aspectMode == .fill) ? .scaleAspectFill : .scaleAspectFit
        if uiView.playerLayer?.player.contentMode != targetMode {
            uiView.playerLayer?.player.contentMode = targetMode
        }
    }
    
    public static func dismantleUIView(_ uiView: KSPlayerContainerView, coordinator: Coordinator) {
        uiView.playerLayer?.delegate = nil
        uiView.playerLayer?.pause()
        uiView.playerLayer = nil
        coordinator.cleanup()
    }
    
    public class Coordinator: NSObject, KSPlayerLayerDelegate {
        weak var playerLayer: KSPlayerLayer?
        weak var container: KSPlayerContainerView?
        private var lastUpdateTime: TimeInterval = 0
        
        func setup(layer: KSPlayerLayer, container: KSPlayerContainerView) {
            self.playerLayer = layer
            self.container = container
            DedicatedPlayerManager.shared.activeKSPlayerView = container
            DedicatedPlayerManager.shared.activeKSPlayerLayer = layer
        }
        
        func cleanup() {
            playerLayer?.delegate = nil
            playerLayer = nil
            container = nil
            if DedicatedPlayerManager.shared.activeKSPlayerLayer != nil {
                DedicatedPlayerManager.shared.activeKSPlayerLayer = nil
                DedicatedPlayerManager.shared.activeKSPlayerView = nil
            }
        }
        
        public func player(layer: KSPlayerLayer, state: KSPlayerState) {
            Task { @MainActor in
                let manager = DedicatedPlayerManager.shared
                container?.attachVideoViewIfNeeded()
                switch state {
                case .readyToPlay:
                    manager.isBuffering = false
                    manager.isPlaying = true
                    container?.attachVideoViewIfNeeded()
                    layer.player.playbackRate = manager.playbackSpeed
                    if manager.isPlaying && !layer.player.isPlaying {
                        layer.play()
                    }
                    manager.refreshKSPlayerTracks(layer: layer)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak layer] in
                        guard let layer = layer else { return }
                        DedicatedPlayerManager.shared.refreshKSPlayerTracks(layer: layer)
                    }
                    if layer.player.duration > 0 {
                        manager.duration = layer.player.duration
                    }
                    if let resume = manager.pendingResumeTime, resume > 2.0 {
                        layer.seek(time: resume, autoPlay: true) { _ in }
                        manager.pendingResumeTime = nil
                        manager.showToast("Resumed from \(manager.formatTime(resume))")
                    }
                case .buffering:
                    manager.isBuffering = true
                case .bufferFinished:
                    manager.isBuffering = false
                case .paused:
                    manager.isPlaying = false
                case .playedToTheEnd:
                    manager.isPlaying = false
                    if manager.hasNextEpisode {
                        manager.playNextEpisode()
                    }
                case .error:
                    manager.isBuffering = false
                    manager.showToast("Stream Error: Playback failed")
                default:
                    break
                }
            }
        }
        
        public func player(layer: KSPlayerLayer, currentTime: TimeInterval, totalTime: TimeInterval) {
            _ = DedicatedPlayerManager.shared.subtitleModel.subtitle(currentTime: currentTime)
            guard abs(currentTime - lastUpdateTime) >= 0.5 || currentTime == 0 || currentTime >= totalTime else { return }
            lastUpdateTime = currentTime
            Task { @MainActor in
                let manager = DedicatedPlayerManager.shared
                manager.currentTime = currentTime
                if totalTime > 0 {
                    manager.duration = totalTime
                }
                manager.isBuffering = false
                manager.updatePeriodicProgress()
            }
        }
        
        public func player(layer: KSPlayerLayer, finish error: Error?) {
            Task { @MainActor in
                let manager = DedicatedPlayerManager.shared
                if let err = error {
                    manager.showToast("Stream Error: \(err.localizedDescription)")
                    manager.isBuffering = false
                } else {
                    if manager.hasNextEpisode {
                        manager.playNextEpisode()
                    }
                }
            }
        }
        
        public func player(layer: KSPlayerLayer, bufferedCount: Int, consumeTime: TimeInterval) {}
    }
}

public struct KSSubtitleOverlayView: View {
    @ObservedObject var subtitleModel: SubtitleModel
    
    public init(subtitleModel: SubtitleModel) {
        self.subtitleModel = subtitleModel
    }
    
    public var body: some View {
        VStack {
            Spacer()
            ForEach(subtitleModel.parts) { part in
                if let image = part.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 140)
                        .padding(.horizontal, 16)
                } else if let text = part.text, !text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(AttributedString(text))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                        .padding(.horizontal, 24)
                }
            }
        }
        .padding(.bottom, 28)
        .allowsHitTesting(false)
    }
}
#endif

public struct DedicatedPlayerView: View {
    @ObservedObject var playerManager = DedicatedPlayerManager.shared
    @State private var showAudioMenu: Bool = false
    
    public init() {}
    
    public var body: some View {
        GeometryReader { proxy in
            let isPhysicallyLandscape = proxy.size.width > proxy.size.height
            let needsVisualRotation = playerManager.isForceLandscape && !isPhysicallyLandscape
            let containerWidth = needsVisualRotation ? proxy.size.height : proxy.size.width
            let containerHeight = needsVisualRotation ? proxy.size.width : proxy.size.height
            let effectiveInsets = needsVisualRotation
                ? EdgeInsets(top: 16, leading: max(34, proxy.safeAreaInsets.top), bottom: 16, trailing: max(24, proxy.safeAreaInsets.bottom))
                : proxy.safeAreaInsets
            
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                playerLayers(containerWidth: containerWidth, containerHeight: containerHeight, insets: effectiveInsets)
                    .frame(width: containerWidth, height: containerHeight)
                    .rotationEffect(needsVisualRotation ? .degrees(90) : .zero)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
            .edgesIgnoringSafeArea(.all)
            .animation(.easeInOut(duration: 0.25), value: playerManager.isForceLandscape)
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
    
    @ViewBuilder
    private func playerLayers(containerWidth: CGFloat, containerHeight: CGFloat, insets: EdgeInsets) -> some View {
        ZStack {
            // Absolute Solid Black Background (Zero white-screen flash)
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // 1. Universal Hardware-Accelerated In-App Video Rendering Layer
            let currentUrl = playerManager.activeStreamURL ?? playerManager.resolvedStreamURL
            
            #if canImport(KSPlayer)
            if let streamUrl = currentUrl {
                KSPlayerRepresentable(url: streamUrl, aspectMode: playerManager.aspectMode)
                    .edgesIgnoringSafeArea(.all)
                    .id("ksplayer-\(streamUrl.absoluteString)")
                
                KSSubtitleOverlayView(subtitleModel: playerManager.subtitleModel)
                    .edgesIgnoringSafeArea(.all)
            }
            #else
            if let p = playerManager.player {
                #if canImport(UIKit)
                PlayerViewRepresentable(player: p, aspectMode: playerManager.aspectMode)
                    .edgesIgnoringSafeArea(.all)
                    .id("primary-player")
                #else
                VideoPlayer(player: p)
                    .edgesIgnoringSafeArea(.all)
                    .id("primary-player")
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
                    .padding(.top, max(54, insets.top + 10))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            
            // 6. HomeFlix On-Screen Interactive Controls
            if playerManager.showControls && !playerManager.isLocked {
                HomeFlixPlayerControls(
                    showAudioMenu: $showAudioMenu,
                    safeAreaInsets: insets,
                    isLandscape: containerWidth > containerHeight,
                    onClose: {
                        playerManager.close()
                    }
                )
                .transition(.opacity)
            }
            
            // 7. Next Episode End-Credits Prompt (Series)
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
                        .padding(.trailing, max(24, insets.trailing + 12))
                        .padding(.bottom, max(34, insets.bottom + (playerManager.showControls ? 95 : 24)))
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
                    .padding(.bottom, max(48, insets.bottom + 24))
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
                    .frame(maxHeight: containerHeight * 0.85)
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
}
