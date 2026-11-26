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
    @Published public var activeStreamURL: URL? = nil
    
    // Playback state
    @Published public var isPlaying: Bool = true
    @Published public var isBuffering: Bool = true
    @Published public var currentTime: Double = 0
    @Published public var duration: Double = 0
    @Published public var playbackSpeed: Float = 1.0
    @Published public var isMuted: Bool = false
    @Published public var isForceLandscape: Bool = false
    @Published public var showControls: Bool = true
    @Published public var statusToast: String? = nil
    @Published public var isUsingResilientFallback: Bool = false
    
    // HomeFlix Player Controls State
    @Published public var isLocked: Bool = false
    @Published public var showLockControlsHint: Bool = false
    @Published public var aspectMode: AspectMode = .fit
    @Published public var isRemainingTime: Bool = false
    @Published public var rippleState: RippleState? = nil
    @Published public var showEpisodesSheet: Bool = false
    
    // Track selection (Real Audio & Subtitles from active KSPlayer stream)
    @Published public var audioTracks: [String] = []
    @Published public var selectedAudioTrack: String = ""
    @Published public var subtitleTracks: [String] = ["Off"]
    @Published public var selectedSubtitleTrack: String = "Off"
    
    #if canImport(KSPlayer)
    public let subtitleModel = SubtitleModel()
    private var ksAudioTrackMap: [String: MediaPlayerTrack] = [:]
    private var ksSubtitleInfoMap: [String: any SubtitleInfo] = [:]
    #endif
    private var userDisabledSubtitles: Bool = false
    private var hasPerformedInitialSubtitleSync: Bool = false
    
    // Native AVPlayer & Engine references
    public private(set) var player: AVPlayer?
    public weak var activeKSPlayerLayer: AnyObject?
    public weak var activeKSPlayerView: AnyObject?
    private var timeObserverToken: Any?
    private var hideControlsTimer: Timer?
    private var watchdogTimer: Timer?
    private var lockHintTimer: Timer?
    private var rippleTimer: Timer?
    private var toastTimer: Timer?
    private var statusObserver: NSKeyValueObservation?
    private var bufferObserver: NSKeyValueObservation?
    public var pendingResumeTime: Double? = nil
    private var lastPersistTime: Double = 0
    
    public init() {
        #if canImport(KSPlayer)
        KSOptions.firstPlayerType = KSMEPlayer.self
        KSOptions.secondPlayerType = KSMEPlayer.self
        KSOptions.hardwareDecode = true
        KSOptions.asynchronousDecompression = false
        KSOptions.preferredFrame = false
        KSOptions.preferredForwardBufferDuration = 3.0
        KSOptions.isAutoPlay = true
        KSOptions.isSeekedAutoPlay = true
        #endif
    }
    
    public var currentTitle: String {
        guard let item = activeItem else { return "HomeFlix Video" }
        if item.type == .series, let ep = activeEpisode {
            let sNum = activeSeasonNumber ?? 1
            return "\(item.title) - S\(sNum):E\(ep.episodeNumber) \"\(ep.title)\""
        }
        return item.title
    }
    
    public var rawStreamURLString: String? {
        if let ep = activeEpisode, !ep.streamUrl.isEmpty {
            return ep.streamUrl
        }
        if let s = activeItem?.streamUrl, !s.isEmpty {
            return s
        }
        if let item = activeItem {
            if item.type == .movie, let resolved = CatalogStore.shared.getMovieStreamURL(for: item.id) {
                return resolved
            }
            if item.type == .series, let detail = CatalogStore.shared.getSeriesDetail(for: item.id),
               let firstEp = detail.seasons.first?.episodes.first, !firstEp.streamUrl.isEmpty {
                return firstEp.streamUrl
            }
        }
        return nil
    }
    
    public var resolvedStreamURL: URL? {
        guard let raw = rawStreamURLString?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        
        // 1. Direct standard URL initialization (fast path for already-valid URLs without forbidden brackets)
        if !raw.contains("[") && !raw.contains("]") {
            if let direct = URL(string: raw), direct.scheme != nil, direct.host != nil {
                return direct
            }
        }
        
        // 2. Decode any partial encoding first, then re-encode safely replacing forbidden brackets
        let decoded = raw.removingPercentEncoding ?? raw
        if let schemeRange = decoded.range(of: "://") {
            let schemeAndColon = decoded[..<schemeRange.upperBound]
            let afterScheme = decoded[schemeRange.upperBound...]
            
            if let slashIdx = afterScheme.firstIndex(of: "/") {
                let hostPort = String(afterScheme[..<slashIdx])
                let remaining = String(afterScheme[slashIdx...])
                
                var pathPart = remaining
                var queryPart = ""
                if let qIdx = remaining.firstIndex(of: "?") {
                    pathPart = String(remaining[..<qIdx])
                    queryPart = String(remaining[qIdx...])
                }
                
                var pathAllowed = CharacterSet.urlPathAllowed
                pathAllowed.remove(charactersIn: "[]")
                let encodedPath = pathPart.addingPercentEncoding(withAllowedCharacters: pathAllowed) ?? pathPart
                
                var queryAllowed = CharacterSet.urlQueryAllowed
                queryAllowed.remove(charactersIn: "[]")
                let encodedQuery = queryPart.isEmpty ? "" : (queryPart.addingPercentEncoding(withAllowedCharacters: queryAllowed) ?? queryPart)
                
                let assembled = "\(schemeAndColon)\(hostPort)\(encodedPath)\(encodedQuery)"
                if let url = URL(string: assembled) {
                    return url
                }
            }
        }
        
        // 3. Fallback encoding
        var generalAllowed = CharacterSet.urlQueryAllowed
        generalAllowed.insert(charactersIn: ":/?@!$&'()*+,;=")
        generalAllowed.remove(charactersIn: "[]")
        if let encoded = raw.addingPercentEncoding(withAllowedCharacters: generalAllowed),
           let url = URL(string: encoded) {
            return url
        }
        
        return nil
    }
    
    // Skip Intro Feature (for all content during opening credits, e.g. 4s - 85s)
    public var showSkipIntro: Bool {
        return currentTime >= 4.0 && currentTime <= 85.0 && duration > 120.0
    }
    
    public func skipIntro() {
        seek(to: 85.0)
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
    
    // Next Episode prompt during credits (last 45 seconds or > 95% complete)
    public var showNextEpisodePrompt: Bool {
        guard hasNextEpisode, duration > 60 else { return false }
        return (duration - currentTime <= 45.0) || ((currentTime / duration) >= 0.95)
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
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        AppDelegate.orientationLock = .landscape
        Task { @MainActor in
            if #available(iOS 16.0, *) {
                let scenes = UIApplication.shared.connectedScenes
                if let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? scenes.first as? UIWindowScene {
                    windowScene.windows.forEach { window in
                        window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                    let pref = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
                    windowScene.requestGeometryUpdate(pref) { _ in }
                }
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
        #endif
        self.isForceLandscape = true
        self.userDisabledSubtitles = false
        self.hasPerformedInitialSubtitleSync = false
        self.activeItem = item
        self.activeStreamURL = nil
        
        // Auto-resolve saved episode progress for series if not explicitly passed
        var effectiveSeasonNum = seasonNumber
        var effectiveEpisode = episode
        var effectiveResume = resumeTime
        
        if let saved = WatchlistStore.shared.getProgress(item.id), saved.percent > 1 && saved.percent < 95 {
            if effectiveResume == nil && saved.currentTime > 2.0 {
                effectiveResume = saved.currentTime
            }
            if item.type == .series && effectiveEpisode == nil {
                if let sNum = saved.seasonNumber, let epNum = saved.episodeNumber,
                   let detail = CatalogStore.shared.getSeriesDetail(for: item.id),
                   let season = detail.seasons.first(where: { $0.seasonNumber == sNum }),
                   let matchedEp = season.episodes.first(where: { $0.episodeNumber == epNum }) {
                    effectiveSeasonNum = sNum
                    effectiveEpisode = matchedEp
                }
            }
        }
        
        if item.type == .series && effectiveEpisode == nil {
            if let detail = CatalogStore.shared.getSeriesDetail(for: item.id),
               let firstSeason = detail.seasons.first,
               let firstEp = firstSeason.episodes.first {
                effectiveSeasonNum = firstSeason.seasonNumber
                effectiveEpisode = firstEp
            }
        }
        
        self.activeSeasonNumber = effectiveSeasonNum
        self.activeEpisode = effectiveEpisode
        self.isPresented = true
        self.isPlaying = true
        self.isBuffering = true
        self.showControls = true
        self.isLocked = false
        self.showLockControlsHint = false
        self.showEpisodesSheet = false
        self.isUsingResilientFallback = false
        self.statusToast = nil
        self.currentTime = effectiveResume ?? 0
        self.pendingResumeTime = (effectiveResume != nil && effectiveResume! > 2.0) ? effectiveResume : nil
        
        setupPlayer(resumeTime: effectiveResume)
        resetHideControlsTimer()
    }
    
    private func setupPlayer(resumeTime: Double?) {
        cleanPlayer()
        
        guard let streamUrl = activeStreamURL ?? resolvedStreamURL else {
            showToast("Stream URL not found")
            self.isBuffering = false
            return
        }
        self.activeStreamURL = streamUrl
        
        // Configure Audio Session for background playback & hardware passthrough
        #if canImport(AVFAudio)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        
        #if canImport(KSPlayer)
        KSOptions.firstPlayerType = KSMEPlayer.self
        KSOptions.secondPlayerType = KSMEPlayer.self
        KSOptions.hardwareDecode = true
        KSOptions.asynchronousDecompression = false
        KSOptions.preferredFrame = false
        KSOptions.preferredForwardBufferDuration = 3.0
        KSOptions.isAutoPlay = true
        KSOptions.isSeekedAutoPlay = true
        subtitleModel.url = streamUrl
        #else
        // Fallback to AVPlayer only when KSPlayer is not compiled
        let playerItem = AVPlayerItem(url: streamUrl)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        self.player = newPlayer
        
        statusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch item.status {
                case .readyToPlay:
                    self.isBuffering = false
                    let dur = CMTimeGetSeconds(item.duration)
                    if !dur.isNaN && dur > 0 {
                        self.duration = dur
                    }
                    if let resume = self.pendingResumeTime, resume > 2.0, self.duration > 0, resume < (self.duration - 5.0) {
                        let target = CMTime(seconds: resume, preferredTimescale: 600)
                        self.player?.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
                            if finished {
                                Task { @MainActor [weak self] in
                                    self?.showToast("Resumed from \(self?.formatTime(resume) ?? "")")
                                }
                            }
                        }
                        self.pendingResumeTime = nil
                    }
                    if self.isPlaying {
                        self.player?.play()
                        self.player?.rate = self.playbackSpeed
                    }
                case .failed:
                    self.isBuffering = false
                    if streamUrl.pathExtension.lowercased() == "mkv" {
                        self.showToast("Stream connection failed (MKV format requires KSPlayer engine)")
                    } else {
                        self.showToast("Stream connection failed")
                    }
                default:
                    break
                }
            }
        }
        
        bufferObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                self?.isBuffering = !item.isPlaybackLikelyToKeepUp
            }
        }
        
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
            if self.duration > 0 && self.currentTime >= (self.duration - 1.5) && self.hasNextEpisode {
                self.playNextEpisode()
            }
            self.persistProgress()
        }
        newPlayer.play()
        #endif
    }
    
    public func showToast(_ message: String) {
        statusToast = message
        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.statusToast = nil
            }
        }
    }
    
    public func close() {
        isForceLandscape = false
        #if canImport(UIKit)
        AppDelegate.orientationLock = .allButUpsideDown
        Task { @MainActor in
            if #available(iOS 16.0, *) {
                let scenes = UIApplication.shared.connectedScenes
                if let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? scenes.first as? UIWindowScene {
                    windowScene.windows.forEach { window in
                        window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                    let pref = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                    windowScene.requestGeometryUpdate(pref) { _ in }
                }
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
        #endif
        persistProgress(force: true)
        cleanPlayer()
        self.isPresented = false
        self.activeItem = nil
        self.activeEpisode = nil
        self.activeStreamURL = nil
        self.isLocked = false
        self.showLockControlsHint = false
        self.showEpisodesSheet = false
        self.isUsingResilientFallback = false
        self.statusToast = nil
    }
    
    private func cleanPlayer() {
        #if canImport(KSPlayer)
        if let ks = activeKSPlayerLayer as? KSPlayerLayer {
            ks.delegate = nil
            ks.pause()
        }
        activeKSPlayerView = nil
        activeKSPlayerLayer = nil
        ksAudioTrackMap.removeAll()
        ksSubtitleInfoMap.removeAll()
        subtitleModel.selectedSubtitleInfo = nil
        #else
        activeKSPlayerView = nil
        activeKSPlayerLayer = nil
        #endif
        audioTracks = []
        selectedAudioTrack = ""
        subtitleTracks = ["Off"]
        selectedSubtitleTrack = "Off"
        self.activeStreamURL = nil
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
        toastTimer?.invalidate()
        toastTimer = nil
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
        #if canImport(KSPlayer)
        if let ks = activeKSPlayerLayer as? KSPlayerLayer {
            if isPlaying {
                ks.pause()
                isPlaying = false
                persistProgress(force: true)
            } else {
                ks.play()
                isPlaying = true
            }
            resetHideControlsTimer()
            return
        }
        #endif
        guard let p = player else { return }
        if isPlaying {
            p.pause()
            isPlaying = false
            persistProgress(force: true)
        } else {
            p.play()
            p.rate = playbackSpeed
            isPlaying = true
        }
        resetHideControlsTimer()
    }
    
    public func seek(by delta: Double) {
        seek(to: currentTime + delta)
    }
    
    public func seek(to targetSeconds: Double) {
        if isLocked { return }
        let target = max(0, min(duration > 0 ? duration : targetSeconds, targetSeconds))
        #if canImport(KSPlayer)
        if let ks = activeKSPlayerLayer as? KSPlayerLayer {
            ks.seek(time: target, autoPlay: isPlaying) { [weak self] _ in
                Task { @MainActor in
                    self?.currentTime = target
                }
            }
            currentTime = target
            resetHideControlsTimer()
            return
        }
        #endif
        guard let p = player else { return }
        let time = CMTime(seconds: target, preferredTimescale: 600)
        p.seek(to: time)
        currentTime = target
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
        resetHideControlsTimer()
        #if canImport(KSPlayer)
        if let ks = activeKSPlayerLayer as? KSPlayerLayer {
            ks.player.playbackRate = speed
            showToast("Speed: \(String(format: "%.2g", speed))x")
            return
        }
        #endif
        if isPlaying {
            player?.rate = speed
            showToast("Speed: \(String(format: "%.2g", speed))x")
        }
    }
    
    private func cleanTrackLanguageName(rawName: String, rawLang: String?, rawLangCode: String?, fallbackPrefix: String, index: Int) -> String {
        let langMap: [String: String] = [
            "en": "English", "eng": "English",
            "hi": "Hindi", "hin": "Hindi",
            "bn": "Bengali", "ben": "Bengali", "bangla": "Bangla",
            "ja": "Japanese", "jpn": "Japanese",
            "ko": "Korean", "kor": "Korean",
            "ta": "Tamil", "tam": "Tamil",
            "te": "Telugu", "tel": "Telugu",
            "ml": "Malayalam", "mal": "Malayalam",
            "mr": "Marathi", "mar": "Marathi",
            "ur": "Urdu", "urd": "Urdu",
            "pa": "Punjabi", "pan": "Punjabi",
            "es": "Spanish", "spa": "Spanish",
            "fr": "French", "fre": "French", "fra": "French",
            "de": "German", "ger": "German", "deu": "German",
            "it": "Italian", "ita": "Italian",
            "pt": "Portuguese", "por": "Portuguese",
            "ru": "Russian", "rus": "Russian",
            "ar": "Arabic", "ara": "Arabic",
            "zh": "Chinese", "chi": "Chinese", "zho": "Chinese",
            "id": "Indonesian", "ind": "Indonesian",
            "th": "Thai", "tha": "Thai",
            "vi": "Vietnamese", "vie": "Vietnamese",
            "tr": "Turkish", "tur": "Turkish"
        ]
        
        // 1. Check explicit ISO languageCode first, then language, then rawName if it is a 2-3 letter code
        let candidateCodes = [rawLangCode, rawLang, rawName]
        for candidate in candidateCodes {
            guard let c = candidate?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  !c.isEmpty, c != "und" else { continue }
            if let mapped = langMap[c] {
                return mapped
            }
            // Strip any "(hearing impaired)" suffix on short codes
            let token = c.components(separatedBy: CharacterSet.alphanumerics.inverted).first ?? ""
            if let mapped = langMap[token] {
                return mapped
            }
            if (c.count == 2 || c.count == 3),
               let localized = Locale(identifier: "en").localizedString(forLanguageCode: c),
               !localized.isEmpty,
               localized.lowercased() != c {
                return localized.capitalized
            }
        }
        
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        let orderedLanguages = [
            "English", "Hindi", "Bengali", "Bangla", "Japanese", "Korean",
            "Tamil", "Telugu", "Malayalam", "Marathi", "Urdu", "Punjabi",
            "Spanish", "French", "German", "Italian", "Portuguese",
            "Russian", "Arabic", "Chinese", "Indonesian", "Thai", "Vietnamese", "Turkish"
        ]
        for langName in orderedLanguages {
            if lower.contains(langName.lowercased()) {
                return langName
            }
        }
        
        // Check individual words in rawName against langMap (e.g. "eng (hearing impaired)" or "hin_aac")
        let words = lower.components(separatedBy: CharacterSet.alphanumerics.inverted)
        for word in words where !word.isEmpty {
            if let mapped = langMap[word] {
                return mapped
            }
        }
        
        // Strip bracketed/parenthesized uploader or codec tags if no known language matched
        let cleaned = trimmed
            .replacingOccurrences(of: "\\[[^\\]]*\\]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\([^\\)]*\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "@\\S+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleaned.isEmpty || cleaned.count <= 3 {
            return "\(fallbackPrefix) \(index + 1)"
        }
        return cleaned
    }
    
    #if canImport(KSPlayer)
    public func refreshKSPlayerTracks(layer: KSPlayerLayer) {
        // 1. Real Audio Tracks (clean language labels)
        let rawAudio = layer.player.tracks(mediaType: .audio)
        var newAudioLabels: [String] = []
        var newAudioMap: [String: MediaPlayerTrack] = [:]
        var activeAudioLabel = ""
        
        for (idx, track) in rawAudio.enumerated() {
            let baseLabel = cleanTrackLanguageName(rawName: track.name, rawLang: track.language, rawLangCode: track.languageCode, fallbackPrefix: "Audio", index: idx)
            var label = baseLabel
            var suffix = 2
            while newAudioMap[label] != nil {
                label = "\(baseLabel) \(suffix)"
                suffix += 1
            }
            newAudioLabels.append(label)
            newAudioMap[label] = track
            if track.isEnabled {
                activeAudioLabel = label
            }
        }
        if activeAudioLabel.isEmpty, let first = newAudioLabels.first {
            activeAudioLabel = first
        }
        self.audioTracks = newAudioLabels
        self.ksAudioTrackMap = newAudioMap
        self.selectedAudioTrack = activeAudioLabel
        
        // 2. Real Embedded & External Subtitles (clean language labels)
        if let dataSource = layer.player.subtitleDataSouce {
            subtitleModel.addSubtitle(dataSouce: dataSource)
        }
        let infos = subtitleModel.subtitleInfos
        var newSubLabels: [String] = ["Off"]
        var newSubMap: [String: any SubtitleInfo] = [:]
        var activeSubLabel = "Off"
        
        for (idx, info) in infos.enumerated() {
            let mediaTrack = info as? MediaPlayerTrack
            let baseLabel = cleanTrackLanguageName(rawName: info.name, rawLang: mediaTrack?.language, rawLangCode: mediaTrack?.languageCode, fallbackPrefix: "Subtitle", index: idx)
            var label = baseLabel
            var suffix = 2
            while newSubMap[label] != nil {
                label = "\(baseLabel) \(suffix)"
                suffix += 1
            }
            newSubLabels.append(label)
            newSubMap[label] = info
            if info.isEnabled {
                activeSubLabel = label
            }
        }
        // Auto-select and bind first subtitle track unless user explicitly turned subtitles Off
        if !userDisabledSubtitles {
            let targetLabel = (activeSubLabel != "Off") ? activeSubLabel : (newSubLabels.dropFirst().first ?? "Off")
            if targetLabel != "Off", let targetInfo = newSubMap[targetLabel] {
                if let track = targetInfo as? MediaPlayerTrack {
                    if !track.isEnabled {
                        layer.player.select(track: track)
                    }
                    // Force FFmpeg to re-read initial subtitle packets (which were discarded during openThread)
                    if !hasPerformedInitialSubtitleSync {
                        hasPerformedInitialSubtitleSync = true
                        if pendingResumeTime == nil {
                            let syncTime = max(0, layer.player.currentPlaybackTime)
                            layer.seek(time: syncTime, autoPlay: true) { _ in }
                        }
                    }
                }
                if subtitleModel.selectedSubtitleInfo?.subtitleID != targetInfo.subtitleID {
                    subtitleModel.selectedSubtitleInfo = targetInfo
                }
                _ = subtitleModel.subtitle(currentTime: currentTime)
                activeSubLabel = targetLabel
            }
        }
        self.subtitleTracks = newSubLabels
        self.ksSubtitleInfoMap = newSubMap
        self.selectedSubtitleTrack = activeSubLabel
    }
    #endif
    
    public func selectAudioTrack(_ label: String) {
        selectedAudioTrack = label
        resetHideControlsTimer()
        #if canImport(KSPlayer)
        if let ks = activeKSPlayerLayer as? KSPlayerLayer, let track = ksAudioTrackMap[label] {
            ks.player.select(track: track)
            showToast("Audio: \(label)")
        }
        #endif
    }
    
    public func selectSubtitleTrack(_ label: String) {
        selectedSubtitleTrack = label
        resetHideControlsTimer()
        #if canImport(KSPlayer)
        if label == "Off" {
            userDisabledSubtitles = true
            subtitleModel.selectedSubtitleInfo = nil
            _ = subtitleModel.subtitle(currentTime: currentTime)
            showToast("Subtitles: Off")
            return
        }
        userDisabledSubtitles = false
        if let info = ksSubtitleInfoMap[label] {
            if let ks = activeKSPlayerLayer as? KSPlayerLayer, let track = info as? MediaPlayerTrack {
                ks.player.select(track: track)
            }
            subtitleModel.selectedSubtitleInfo = info
            _ = subtitleModel.subtitle(currentTime: currentTime)
            showToast("Subtitle: \(label)")
        }
        #endif
    }
    
    public func toggleMute() {
        isMuted.toggle()
        #if canImport(KSPlayer)
        if let ks = activeKSPlayerLayer as? KSPlayerLayer {
            ks.player.isMuted = isMuted
            return
        }
        #endif
        player?.isMuted = isMuted
    }
    
    public func updatePeriodicProgress() {
        if duration > 0 && currentTime >= (duration - 1.5) && hasNextEpisode {
            playNextEpisode()
        }
        persistProgress()
    }
    
    public func formatTime(_ seconds: Double) -> String {
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
    
    public func toggleScreenLock() {
        isLocked.toggle()
        if isLocked {
            showControls = false
            showLockControlsHint = true
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
        #if canImport(KSPlayer)
        if let ks = activeKSPlayerLayer as? KSPlayerLayer {
            ks.player.contentMode = (aspectMode == .fill) ? .scaleAspectFill : .scaleAspectFit
        }
        #endif
    }
    
    public func toggleRemainingTime() {
        isRemainingTime.toggle()
    }
    
    public func toggleOrientation() {
        #if canImport(UIKit)
        Task { @MainActor in
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? scenes.first as? UIWindowScene
            let keyWindow = windowScene?.windows.first(where: { $0.isKeyWindow }) ?? windowScene?.windows.first
            let isPhysicallyLandscape: Bool
            if let ws = windowScene {
                isPhysicallyLandscape = ws.interfaceOrientation.isLandscape || ((keyWindow?.bounds.width ?? 0) > (keyWindow?.bounds.height ?? 0))
            } else {
                isPhysicallyLandscape = false
            }
            
            let currentlyLandscape = isForceLandscape || isPhysicallyLandscape
            let targetLandscape = !currentlyLandscape
            isForceLandscape = targetLandscape
            AppDelegate.orientationLock = targetLandscape ? .landscapeRight : .portrait
            
            if #available(iOS 16.0, *), let windowScene = windowScene {
                windowScene.windows.forEach { window in
                    window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
                let targetMask: UIInterfaceOrientationMask = targetLandscape ? .landscapeRight : .portrait
                let pref = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: targetMask)
                windowScene.requestGeometryUpdate(pref) { error in
                    print("Rotation request error: \(error)")
                }
            } else {
                let target = targetLandscape ? UIInterfaceOrientation.landscapeRight.rawValue : UIInterfaceOrientation.portrait.rawValue
                UIDevice.current.setValue(target, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
        #else
        isForceLandscape.toggle()
        #endif
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
                if self?.isPlaying == true && self?.isBuffering == false && self?.showEpisodesSheet == false {
                    self?.showControls = false
                }
            }
        }
    }
    
    private func persistProgress(force: Bool = false) {
        guard let item = activeItem, duration > 10 else { return }
        
        // If content is >= 95% finished, remove from continue watching
        if (currentTime / duration) >= 0.95 {
            WatchlistStore.shared.removeFromWatchHistory(mediaId: item.id)
            return
        }
        
        // Throttle progress persistence unless forced
        guard force || abs(currentTime - lastPersistTime) >= 15.0 else { return }
        lastPersistTime = currentTime
        
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
