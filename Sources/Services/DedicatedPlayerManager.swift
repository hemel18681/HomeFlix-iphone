import Foundation
import SwiftUI
import Combine
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

public enum ExternalPlayerApp: String, CaseIterable, Identifiable {
    case vlc = "VLC"
    case infuse = "Infuse"
    case outplayer = "Outplayer"
    case nplayer = "nPlayer"
    case iina = "IINA"
    
    public var id: String { rawValue }
    
    public func launchURL(for streamUrl: String) -> URL? {
        guard let encoded = streamUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        switch self {
        case .vlc:
            return URL(string: "vlc://\(streamUrl)") ?? URL(string: "vlc-x-callback://x-callback-url/stream?url=\(encoded)")
        case .infuse:
            return URL(string: "infuse://x-callback-url/play?url=\(encoded)")
        case .outplayer:
            return URL(string: "outplayer://\(streamUrl)")
        case .nplayer:
            return URL(string: "nplayer-\(streamUrl)")
        case .iina:
            return URL(string: "iina://weblink?url=\(encoded)")
        }
    }
}

@MainActor
public final class DedicatedPlayerManager: ObservableObject {
    public static let shared = DedicatedPlayerManager()
    
    @Published public var isPresented: Bool = false
    @Published public var activeItem: MediaItem?
    @Published public var activeSeasonNumber: Int?
    @Published public var activeEpisode: Episode?
    
    // Playback state
    @Published public var isPlaying: Bool = true
    @Published public var isBuffering: Bool = false
    @Published public var currentTime: Double = 0
    @Published public var duration: Double = 0
    @Published public var bufferedPercent: Double = 0
    @Published public var playbackSpeed: Float = 1.0
    @Published public var isMuted: Bool = false
    @Published public var isForceLandscape: Bool = false
    @Published public var showControls: Bool = true
    
    // Track selection
    @Published public var audioTracks: [String] = ["Original (5.1)", "Hindi (5.1)", "English (Stereo)"]
    @Published public var selectedAudioTrack: String = "Original (5.1)"
    @Published public var subtitleTracks: [String] = ["Off", "English [CC]"]
    @Published public var selectedSubtitleTrack: String = "English [CC]"
    
    // Native AVPlayer reference
    public private(set) var player: AVPlayer?
    private var timeObserverToken: Any?
    private var hideControlsTimer: Timer?
    
    public init() {}
    
    public var currentTitle: String {
        guard let item = activeItem else { return "HomeFlix Video" }
        if item.type == .series, let ep = activeEpisode {
            let sNum = activeSeasonNumber ?? 1
            return "\(item.title) - S\(sNum):E\(ep.episodeNumber) \"\(ep.title)\""
        }
        return item.title
    }
    
    public var resolvedStreamURL: URL? {
        if let ep = activeEpisode, !ep.streamUrl.isEmpty {
            return URL(string: ep.streamUrl)
        }
        if let s = activeItem?.streamUrl, !s.isEmpty {
            return URL(string: s)
        }
        return nil
    }
    
    public func play(
        item: MediaItem,
        seasonNumber: Int? = nil,
        episode: Episode? = nil,
        resumeTime: Double? = nil
    ) {
        self.activeItem = item
        self.activeSeasonNumber = seasonNumber
        self.activeEpisode = episode
        self.isPresented = true
        self.isPlaying = true
        self.currentTime = resumeTime ?? 0
        
        setupPlayer(resumeTime: resumeTime)
        resetHideControlsTimer()
    }
    
    private func setupPlayer(resumeTime: Double?) {
        guard let streamUrl = resolvedStreamURL else { return }
        
        // Clean previous
        cleanPlayer()
        
        // Configure Audio Session for background playback & hardware passthrough
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let playerItem = AVPlayerItem(url: streamUrl)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        self.player = newPlayer
        
        // Add periodic time observer
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
    }
    
    private func cleanPlayer() {
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
        guard let p = player else { return }
        let target = max(0, min(duration, currentTime + delta))
        let time = CMTime(seconds: target, preferredTimescale: 600)
        p.seek(to: time)
        currentTime = target
        resetHideControlsTimer()
    }
    
    public func seek(to targetSeconds: Double) {
        guard let p = player else { return }
        let time = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        p.seek(to: time)
        currentTime = targetSeconds
        resetHideControlsTimer()
    }
    
    public func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        if isPlaying {
            player?.rate = speed
        }
    }
    
    public func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }
    
    public func toggleControls() {
        showControls.toggle()
        if showControls {
            resetHideControlsTimer()
        }
    }
    
    public func resetHideControlsTimer() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                if self?.isPlaying == true {
                    self?.showControls = false
                }
            }
        }
    }
    
    private func persistProgress() {
        guard let item = activeItem, duration > 0 else { return }
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
    
    public func openExternal(_ app: ExternalPlayerApp) {
        guard let stream = activeEpisode?.streamUrl ?? activeItem?.streamUrl,
              let url = app.launchURL(for: stream) else { return }
        #if canImport(UIKit)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
