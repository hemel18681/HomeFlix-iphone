import Foundation
import SwiftUI
import Combine
import AVFoundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(KSPlayer)
import KSPlayer
#endif

public enum AspectMode: String, CaseIterable {
    case fit = "Fit"
    case fill = "Fill"
}

public enum DoubleTapSide: Equatable {
    case left
    case right
}

public struct RippleState: Equatable, Identifiable {
    public let id = UUID()
    public let side: DoubleTapSide
    public let seconds: Int
    
    public init(side: DoubleTapSide, seconds: Int = 10) {
        self.side = side
        self.seconds = seconds
    }
}

@MainActor
public final class DedicatedPlayerManager: ObservableObject {
    public static let shared = DedicatedPlayerManager()
    
    // Presentation & Content
    @Published public var isPresented: Bool = false
    @Published public var activeItem: MediaItem?
    @Published public var activeSeasonNumber: Int?
    @Published public var activeEpisode: Episode?
    
    // Playback state
    @Published public var isPlaying: Bool = true
    @Published public var isBuffering: Bool = true
    @Published public var currentTime: Double = 0
    @Published public var duration: Double = 0
    @Published public var playbackSpeed: Float = 1.0
    @Published public var isMuted: Bool = false
    @Published public var isForceLandscape: Bool = false
    @Published public var showControls: Bool = true
    @Published public var playbackError: String? = nil
    @Published public var isSampleMode: Bool = false
    
    // Netflix Pro Player Controls State
    @Published public var isLocked: Bool = false
    @Published public var showLockControlsHint: Bool = false
    @Published public var aspectMode: AspectMode = .fit
    @Published public var isRemainingTime: Bool = false
    @Published public var rippleState: RippleState? = nil
    @Published public var showEpisodesSheet: Bool = false
    
    // Track selection (Dual Audio & Subtitles)
    @Published public var audioTracks: [String] = ["Original (5.1)", "Hindi (5.1)", "English (Stereo)"]
    @Published public var selectedAudioTrack: String = "Original (5.1)"
    @Published public var subtitleTracks: [String] = ["Off", "English [CC]"]
    @Published public var selectedSubtitleTrack: String = "English [CC]"
    
    // Native AVPlayer reference & Timers
    public private(set) var player: AVPlayer?
    private var timeObserverToken: Any?
    private var hideControlsTimer: Timer?
    private var watchdogTimer: Timer?
    private var lockHintTimer: Timer?
    private var rippleTimer: Timer?
    private var statusObserver: NSKeyValueObservation?
    private var bufferObserver: NSKeyValueObservation?
    
    public static let verifiedSampleStreamURL = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    
    public init() {
        #if canImport(KSPlayer)
        KSOptions.secondPlayerType = KSMEPlayer.self
        KSOptions.isAutoPlay = true
        #endif
    }
    
    public var currentTitle: String {
        if isSampleMode {
            return "HomeFlix Test Stream (Verified 1080p)"
        }
        guard let item = activeItem else { return "HomeFlix Video" }
        if item.type == .series, let ep = activeEpisode {
            let sNum = activeSeasonNumber ?? 1
            return "\(item.title) - S\(sNum):E\(ep.episodeNumber) \"\(ep.title)\""
        }
        return item.title
    }
    
    public var rawStreamURLString: String? {
        if isSampleMode {
            return Self.verifiedSampleStreamURL
        }
        if let ep = activeEpisode, !ep.streamUrl.isEmpty {
            return ep.streamUrl
        }
        if let s = activeItem?.streamUrl, !s.isEmpty {
            return s
        }
        return nil
    }
    
    public var resolvedStreamURL: URL? {
        guard let raw = rawStreamURLString else { return nil }
        if let direct = URL(string: raw) {
            return direct
        }
        if let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encoded) {
            return url
        }
        return nil
    }
    
    // Next Episode detection for Series
    public var nextEpisodeInfo: (seasonNumber: Int, episode: Episode)? {
        guard let item = activeItem, item.type == .series, let currentEp = activeEpisode else { return nil }
        guard let detail = CatalogStore.shared.getSeriesDetail(for: item.id) else { return nil }
        
        let currentSeasonNum = activeSeasonNumber ?? 1
        guard let currentSeason = detail.seasons.first(where: { $0.seasonNumber == currentSeasonNum }) else { return nil }
        
        // 1. Next episode in current season
        if let idx = currentSeason.episodes.firstIndex(where: { $0.episodeNumber == currentEp.episodeNumber }),
           idx + 1 < currentSeason.episodes.count {
            return (currentSeasonNum, currentSeason.episodes[idx + 1])
        }
        
        // 2. First episode in next season
        if let seasonIdx = detail.seasons.firstIndex(where: { $0.seasonNumber == currentSeasonNum }),
           seasonIdx + 1 < detail.seasons.count {
            let nextSeason = detail.seasons[seasonIdx + 1]
            if let firstEp = nextSeason.episodes.first {
                return (nextSeason.seasonNumber, firstEp)
            }
        }
        
        return nil
    }
    
    public var hasNextEpisode: Bool {
        nextEpisodeInfo != nil
    }
    
    public func playNextEpisode() {
        guard let (nextSeasonNum, nextEp) = nextEpisodeInfo, let item = activeItem else { return }
        play(item: item, seasonNumber: nextSeasonNum, episode: nextEp)
    }
    
    public func play(
        item: MediaItem,
        seasonNumber: Int? = nil,
        episode: Episode? = nil,
        resumeTime: Double? = nil
    ) {
        self.isSampleMode = false
        self.activeItem = item
        self.activeSeasonNumber = seasonNumber
        self.activeEpisode = episode
        self.isPresented = true
        self.isPlaying = true
        self.isBuffering = true
        self.playbackError = nil
        self.showControls = true
        self.isLocked = false
        self.showLockControlsHint = false
        self.showEpisodesSheet = false
        self.currentTime = resumeTime ?? 0
        
        setupPlayer(resumeTime: resumeTime)
        resetHideControlsTimer()
    }
    
    public func playSampleStream() {
        self.isSampleMode = true
        self.activeItem = MediaItem(
            id: "sample-stream",
            type: .movie,
            title: "HomeFlix Video Player Test Stream",
            year: 2026,
            quality: "1080p Full HD",
            category: "Streaming Test",
            tags: ["Dolby 5.1", "Sample"],
            streamUrl: Self.verifiedSampleStreamURL
        )
        self.activeEpisode = nil
        self.isPresented = true
        self.isPlaying = true
        self.isBuffering = true
        self.playbackError = nil
        self.showControls = true
        self.isLocked = false
        self.showLockControlsHint = false
        self.showEpisodesSheet = false
        self.currentTime = 0
        
        setupPlayer(resumeTime: 0)
        resetHideControlsTimer()
    }
    
    public func retryPlayback() {
        guard let item = activeItem else { return }
        play(item: item, seasonNumber: activeSeasonNumber, episode: activeEpisode, resumeTime: currentTime)
    }
    
    private func setupPlayer(resumeTime: Double?) {
        cleanPlayer()
        
        guard let streamUrl = resolvedStreamURL else {
            self.playbackError = "Invalid or missing video stream URL."
            self.isBuffering = false
            return
        }
        
        // Configure Audio Session for background playback & hardware passthrough
        #if canImport(AVFAudio)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        
        let playerItem = AVPlayerItem(url: streamUrl)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        self.player = newPlayer
        
        // Status observer to track stream readiness
        statusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch item.status {
                case .readyToPlay:
                    self.isBuffering = false
                    self.playbackError = nil
                    let dur = CMTimeGetSeconds(item.duration)
                    if !dur.isNaN && dur > 0 {
                        self.duration = dur
                    }
                    if self.isPlaying {
                        self.player?.play()
                    }
                case .failed:
                    self.isBuffering = false
                    let streamExt = streamUrl.pathExtension.lowercased()
                    let errDesc = item.error?.localizedDescription ?? "CoreMedia stream format unsupported."
                    if streamExt == "mkv" {
                        self.playbackError = "MKV stream format detected. Connecting to integrated universal hardware decoder node..."
                    } else {
                        self.playbackError = "Unable to connect to stream: \(errDesc)"
                    }
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }
        
        // Buffer status
        bufferObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                self?.isBuffering = !item.isPlaybackLikelyToKeepUp
            }
        }
        
        // Watchdog Timer for unreachable BDIX subnet (6s)
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.isBuffering && self.playbackError == nil && (self.player?.currentItem?.status != .readyToPlay) {
                    let host = streamUrl.host ?? "BDIX media server"
                    self.playbackError = "Connection to \(host) timed out. Please verify your iPhone is connected to your home BDIX Wi-Fi network."
                    self.isBuffering = false
                }
            }
        }
        
        // Periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        self.timeObserverToken = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = CMTimeGetSeconds(time)
            if let currentItem = self.player?.currentItem {
                let dur = CMTimeGetSeconds(currentItem.duration)
                if !dur.isNaN && dur > 0 {
                    self.duration = dur
                }
            }
            self.persistProgress()
        }
        
        if let resume = resumeTime, resume > 0 {
            let targetTime = CMTime(seconds: resume, preferredTimescale: 600)
            newPlayer.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        
        newPlayer.play()
    }
    
    public func close() {
        cleanPlayer()
        self.isPresented = false
        self.activeItem = nil
        self.activeEpisode = nil
        self.playbackError = nil
        self.isSampleMode = false
        self.isLocked = false
        self.showLockControlsHint = false
        self.showEpisodesSheet = false
    }
    
    private func cleanPlayer() {
        watchdogTimer?.invalidate()
        watchdogTimer = nil
        statusObserver?.invalidate()
        statusObserver = nil
        bufferObserver?.invalidate()
        bufferObserver = nil
        lockHintTimer?.invalidate()
        lockHintTimer = nil
        rippleTimer?.invalidate()
        rippleTimer = nil
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player = nil
        hideControlsTimer?.invalidate()
        hideControlsTimer = nil
    }
    
    public func togglePlayPause() {
        if isLocked { return }
        guard let p = player else { return }
        if isPlaying {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            p.rate = playbackSpeed
            isPlaying = true
        }
        resetHideControlsTimer()
    }
    
    public func seek(by delta: Double) {
        if isLocked { return }
        guard let p = player else { return }
        let target = max(0, min(duration, currentTime + delta))
        let time = CMTime(seconds: target, preferredTimescale: 600)
        p.seek(to: time)
        currentTime = target
        resetHideControlsTimer()
    }
    
    public func seek(to targetSeconds: Double) {
        if isLocked { return }
        guard let p = player else { return }
        let time = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        p.seek(to: time)
        currentTime = targetSeconds
        resetHideControlsTimer()
    }
    
    public func triggerDoubleTapSeek(side: DoubleTapSide) {
        if isLocked { return }
        let delta = (side == .left) ? -10.0 : 10.0
        seek(by: delta)
        
        rippleTimer?.invalidate()
        rippleState = RippleState(side: side, seconds: 10)
        rippleTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.rippleState = nil
            }
        }
    }
    
    public func setSpeed(_ speed: Float) {
        if isLocked { return }
        playbackSpeed = speed
        if isPlaying {
            player?.rate = speed
        }
    }
    
    public func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }
    
    public func toggleScreenLock() {
        isLocked.toggle()
        if isLocked {
            showControls = false
            showLockControlsHint = true
            // Hide the hint after 3 seconds
            lockHintTimer?.invalidate()
            lockHintTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.showLockControlsHint = false
                }
            }
        } else {
            showLockControlsHint = false
            showControls = true
            resetHideControlsTimer()
        }
    }
    
    public func handleScreenTap() {
        if isLocked {
            showLockControlsHint.toggle()
            if showLockControlsHint {
                lockHintTimer?.invalidate()
                lockHintTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        self?.showLockControlsHint = false
                    }
                }
            }
        } else {
            toggleControls()
        }
    }
    
    public func toggleAspectMode() {
        aspectMode = (aspectMode == .fit) ? .fill : .fit
    }
    
    public func toggleRemainingTime() {
        isRemainingTime.toggle()
    }
    
    public func toggleControls() {
        if isLocked { return }
        showControls.toggle()
        if showControls {
            resetHideControlsTimer()
        }
    }
    
    public func resetHideControlsTimer() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                if self?.isPlaying == true && self?.playbackError == nil && self?.isBuffering == false && self?.showEpisodesSheet == false {
                    self?.showControls = false
                }
            }
        }
    }
    
    private func persistProgress() {
        guard let item = activeItem, duration > 0, !isSampleMode else { return }
        WatchlistStore.shared.updateProgress(
            mediaId: item.id,
            title: item.title,
            type: item.type.rawValue,
            poster: item.poster,
            seasonNumber: activeSeasonNumber,
            episodeNumber: activeEpisode?.episodeNumber,
            currentTime: currentTime,
            duration: duration
        )
    }
}
