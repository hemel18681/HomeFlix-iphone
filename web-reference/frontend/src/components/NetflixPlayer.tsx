import React, { useState, useEffect, useRef } from 'react';
import {
  ArrowLeft,
  Play,
  Pause,
  RotateCcw,
  RotateCw,
  Volume2,
  VolumeX,
  Maximize,
  Minimize,
  FastForward,
  Layers,
  MessageSquare,
  PictureInPicture,
  X,
  Smartphone,
  ExternalLink,
  RefreshCw,
  AlertCircle,
  HelpCircle,
  Tv
} from 'lucide-react';
import { usePlayerStore } from '../store/usePlayerStore';
import { useAppStore } from '../store/useAppStore';
import {
  getPlayableStreamUrl,
  getExternalPlayerLinks,
  SAMPLE_FALLBACK_STREAM
} from '../utils/stream';

export const NetflixPlayer: React.FC = () => {
  const {
    isOpen,
    activeItem,
    activeEpisode,
    activeSeasonNumber,
    resumeTime,
    showResumePrompt,
    setShowResumePrompt,
    nextEpisodeCountdown,
    setNextEpisodeCountdown,
    isDrawerOpen,
    setIsDrawerOpen,
    playNextEpisode,
    playMedia,
    closePlayer
  } = usePlayerStore();

  const { updateHistory } = useAppStore();

  const videoRef = useRef<HTMLVideoElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const [isPlaying, setIsPlaying] = useState(true);
  const [isBuffering, setIsBuffering] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [bufferedPercent, setBufferedPercent] = useState(0);
  const [volume, setVolume] = useState(1);
  const [isMuted, setIsMuted] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [playbackSpeed, setPlaybackSpeed] = useState(1);
  const [showSpeedMenu, setShowSpeedMenu] = useState(false);
  const [showAudioMenu, setShowAudioMenu] = useState(false);
  const [showExternalMenu, setShowExternalMenu] = useState(false);
  const [selectedAudio, setSelectedAudio] = useState('Original (5.1)');
  const [selectedSubtitle, setSelectedSubtitle] = useState('English [CC]');
  const [controlsVisible, setControlsVisible] = useState(true);

  // Mobile & Stream Recovery State
  const [isMobile, setIsMobile] = useState<boolean>(
    () => typeof window !== 'undefined' && (window.innerWidth < 768 || window.innerHeight < 768)
  );
  const [isForceLandscape, setIsForceLandscape] = useState(false);
  const [isPortrait, setIsPortrait] = useState<boolean>(() =>
    typeof window !== 'undefined' ? window.innerHeight > window.innerWidth : false
  );
  const [streamMode, setStreamMode] = useState<'proxy' | 'direct' | 'sample'>('proxy');
  const [hasPlaybackError, setHasPlaybackError] = useState(false);
  const [doubleTapRipple, setDoubleTapRipple] = useState<{
    side: 'left' | 'right';
    id: number;
  } | null>(null);

  const hideTimeoutRef = useRef<any>(null);
  const lastTapRef = useRef<{ time: number; x: number }>({ time: 0, x: 0 });

  const rawVideoSrc = activeItem?.type === 'series'
    ? activeEpisode?.streamUrl
    : activeItem?.streamUrl;

  const resolvedVideoSrc = streamMode === 'sample'
    ? SAMPLE_FALLBACK_STREAM
    : getPlayableStreamUrl(rawVideoSrc, { forceDirect: streamMode === 'direct' });

  const currentTitle = activeItem?.type === 'series'
    ? `${activeItem.title} - S${activeSeasonNumber}E${activeEpisode?.episodeNumber || 1}: ${activeEpisode?.title || ''}`
    : activeItem?.title || '';

  const externalLinks = getExternalPlayerLinks(rawVideoSrc, currentTitle);

  // Responsive mobile and orientation detection listener
  useEffect(() => {
    const handleResize = () => {
      const portrait = window.innerHeight > window.innerWidth;
      setIsPortrait(portrait);
      setIsMobile(window.innerWidth < 768 || window.innerHeight < 768);
    };
    window.addEventListener('resize', handleResize);
    window.addEventListener('orientationchange', handleResize);
    return () => {
      window.removeEventListener('resize', handleResize);
      window.removeEventListener('orientationchange', handleResize);
    };
  }, []);

  // Attempt hardware orientation lock to landscape on phone when player is opened
  useEffect(() => {
    if (!isOpen) return;
    if (isMobile) {
      try {
        if ((screen.orientation as any)?.lock) {
          (screen.orientation as any).lock('landscape').catch(() => {});
        }
      } catch (_) {}
    }
    return () => {
      try {
        if (screen.orientation?.unlock) {
          screen.orientation.unlock();
        }
      } catch (_) {}
    };
  }, [isOpen, isMobile]);

  const resetHideTimer = () => {
    setControlsVisible(true);
    if (hideTimeoutRef.current) clearTimeout(hideTimeoutRef.current);
    hideTimeoutRef.current = setTimeout(() => {
      if (isPlaying && !hasPlaybackError) {
        setControlsVisible(false);
        setShowSpeedMenu(false);
        setShowAudioMenu(false);
        setShowExternalMenu(false);
      }
    }, isMobile ? 3500 : 2500);
  };

  useEffect(() => {
    if (!isOpen) return;

    // Reset error state on fresh open
    setHasPlaybackError(false);
    setIsBuffering(false);

    const handleKeyDown = (e: KeyboardEvent) => {
      resetHideTimer();
      if (e.key === ' ' || e.key === 'k') {
        e.preventDefault();
        togglePlay();
      } else if (e.key === 'f') {
        e.preventDefault();
        toggleFullscreen();
      } else if (e.key === 'm') {
        e.preventDefault();
        toggleMute();
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        seekRelative(10);
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault();
        seekRelative(-10);
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        adjustVolume(0.1);
      } else if (e.key === 'ArrowDown') {
        e.preventDefault();
        adjustVolume(-0.1);
      } else if (e.key === 'n' && activeItem?.type === 'series') {
        e.preventDefault();
        playNextEpisode();
      } else if (e.key === 'Escape') {
        if (!document.fullscreenElement) {
          closePlayer();
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, isPlaying, isFullscreen, isMuted, volume]);

  useEffect(() => {
    const video = videoRef.current;
    if (!video || !activeItem) return;

    const onTimeUpdate = () => {
      setCurrentTime(video.currentTime);
      const dur = video.duration || 1;
      setDuration(dur);

      if (video.buffered.length > 0) {
        const bufferedEnd = video.buffered.end(video.buffered.length - 1);
        setBufferedPercent((bufferedEnd / dur) * 100);
      }

      if (activeItem.type === 'series' && dur > 60 && dur - video.currentTime <= 30) {
        const remaining = Math.max(0, Math.ceil(dur - video.currentTime));
        setNextEpisodeCountdown(remaining);
      } else {
        setNextEpisodeCountdown(null);
      }

      const percent = (video.currentTime / dur) * 100;
      updateHistory({
        mediaId: activeItem.id,
        episodeNumber: activeEpisode?.episodeNumber,
        seasonNumber: activeSeasonNumber,
        currentTime: video.currentTime,
        duration: dur,
        percent,
        updatedAt: Date.now(),
        title: currentTitle,
        poster: activeItem.backdrop || activeItem.poster,
        type: activeItem.type
      });
    };

    const onEnded = () => {
      if (activeItem.type === 'series') {
        playNextEpisode();
      } else {
        setIsPlaying(false);
      }
    };

    const onWaiting = () => setIsBuffering(true);
    const onPlaying = () => {
      setIsBuffering(false);
      setIsPlaying(true);
      setHasPlaybackError(false);
    };
    const onCanPlay = () => setIsBuffering(false);
    const onError = () => {
      setIsBuffering(false);
      setHasPlaybackError(true);
    };

    video.addEventListener('timeupdate', onTimeUpdate);
    video.addEventListener('ended', onEnded);
    video.addEventListener('waiting', onWaiting);
    video.addEventListener('playing', onPlaying);
    video.addEventListener('canplay', onCanPlay);
    video.addEventListener('error', onError);

    // Initial play attempt with mobile browser autoplay policy handling
    video.play().catch(() => {
      // Mobile browsers prevent unmuted autoplay without prior user interaction
      setIsPlaying(false);
    });

    return () => {
      video.removeEventListener('timeupdate', onTimeUpdate);
      video.removeEventListener('ended', onEnded);
      video.removeEventListener('waiting', onWaiting);
      video.removeEventListener('playing', onPlaying);
      video.removeEventListener('canplay', onCanPlay);
      video.removeEventListener('error', onError);
    };
  }, [activeItem, activeEpisode, activeSeasonNumber, resolvedVideoSrc]);

  if (!isOpen || !activeItem) return null;

  const togglePlay = () => {
    if (videoRef.current) {
      if (isPlaying) {
        videoRef.current.pause();
        setIsPlaying(false);
      } else {
        videoRef.current.play().then(() => {
          setIsPlaying(true);
          setHasPlaybackError(false);
        }).catch(() => {
          setIsPlaying(false);
        });
      }
    }
  };

  const seekRelative = (seconds: number) => {
    if (videoRef.current) {
      videoRef.current.currentTime = Math.max(
        0,
        Math.min(duration || 10000, videoRef.current.currentTime + seconds)
      );
    }
  };

  const seekTo = (percent: number) => {
    if (videoRef.current && duration) {
      videoRef.current.currentTime = (percent / 100) * duration;
    }
  };

  const skipIntro = () => {
    if (videoRef.current) {
      videoRef.current.currentTime = Math.min(duration, videoRef.current.currentTime + 85);
    }
  };

  const adjustVolume = (delta: number) => {
    if (videoRef.current) {
      const newVol = Math.max(0, Math.min(1, volume + delta));
      videoRef.current.volume = newVol;
      setVolume(newVol);
      setIsMuted(newVol === 0);
    }
  };

  const toggleMute = () => {
    if (videoRef.current) {
      const nextMuted = !isMuted;
      videoRef.current.muted = nextMuted;
      setIsMuted(nextMuted);
    }
  };

  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      containerRef.current?.requestFullscreen().catch(() => {});
      setIsFullscreen(true);
    } else {
      document.exitFullscreen().catch(() => {});
      setIsFullscreen(false);
    }
  };

  const togglePiP = () => {
    if (videoRef.current) {
      if (document.pictureInPictureElement) {
        document.exitPictureInPicture().catch(() => {});
      } else {
        videoRef.current.requestPictureInPicture().catch(() => {});
      }
    }
  };

  const changeSpeed = (speed: number) => {
    if (videoRef.current) {
      videoRef.current.playbackRate = speed;
      setPlaybackSpeed(speed);
      setShowSpeedMenu(false);
    }
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    const hrs = Math.floor(mins / 60);
    if (hrs > 0) {
      return `${hrs}:${String(mins % 60).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    }
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  };

  // Double-tap seeking gestures for authentic mobile player
  const handleTouchStart = (e: React.TouchEvent<HTMLDivElement>) => {
    const now = Date.now();
    const touch = e.touches[0];
    const rect = containerRef.current?.getBoundingClientRect();
    if (!rect) return;
    const x = touch.clientX - rect.left;
    const width = rect.width;

    if (now - lastTapRef.current.time < 320) {
      // Double tap detected!
      if (x < width * 0.38) {
        // Left side double tap: Rewind 10s
        seekRelative(-10);
        setDoubleTapRipple({ side: 'left', id: now });
        setTimeout(() => setDoubleTapRipple(null), 700);
      } else if (x > width * 0.62) {
        // Right side double tap: Forward 10s
        seekRelative(10);
        setDoubleTapRipple({ side: 'right', id: now });
        setTimeout(() => setDoubleTapRipple(null), 700);
      } else {
        // Center double tap: Play / Pause toggle
        togglePlay();
      }
    } else {
      resetHideTimer();
    }
    lastTapRef.current = { time: now, x };
  };

  const seasons = activeItem.seasons || [];
  const currentSeason = seasons.find((s) => s.seasonNumber === activeSeasonNumber) || seasons[0];

  return (
    <div
      ref={containerRef}
      onMouseMove={resetHideTimer}
      onClick={resetHideTimer}
      onTouchStart={handleTouchStart}
      data-testid="netflix-player"
      style={
        isMobile && isForceLandscape && isPortrait
          ? {
              transform: 'rotate(90deg)',
              transformOrigin: 'center center',
              width: '100vh',
              height: '100vw',
              top: 'calc((100vh - 100vw) / 2)',
              left: 'calc((100vw - 100vh) / 2)',
              position: 'fixed',
              zIndex: 9999
            }
          : undefined
      }
      className="fixed inset-0 z-[9999] bg-black flex items-center justify-center select-none overflow-hidden touch-none"
    >
      {/* Video Element */}
      <video
        ref={videoRef}
        src={resolvedVideoSrc || ''}
        autoPlay
        playsInline
        className="w-full h-full object-contain cursor-pointer"
        onClick={togglePlay}
      />

      {/* Double Tap Ripple Indicators (Mobile Netflix Gesture) */}
      {doubleTapRipple && (
        <div
          className={`absolute top-1/2 -translate-y-1/2 z-40 pointer-events-none flex flex-col items-center justify-center text-white animate-in zoom-in-75 duration-200 ${
            doubleTapRipple.side === 'left' ? 'left-12 sm:left-24' : 'right-12 sm:right-24'
          }`}
        >
          <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-full bg-white/20 backdrop-blur-md flex items-center justify-center shadow-2xl">
            {doubleTapRipple.side === 'left' ? (
              <RotateCcw className="w-8 h-8 sm:w-10 sm:h-10 text-white" />
            ) : (
              <RotateCw className="w-8 h-8 sm:w-10 sm:h-10 text-white" />
            )}
          </div>
          <span className="text-sm font-bold mt-2 drop-shadow">
            {doubleTapRipple.side === 'left' ? '-10 seconds' : '+10 seconds'}
          </span>
        </div>
      )}

      {/* Signature Center Play / Pause & Seek Controls (Authentic Mobile + Desktop Overlay) */}
      <div
        className={`absolute inset-0 flex items-center justify-center pointer-events-none z-30 transition-opacity duration-300 ${
          controlsVisible || !isPlaying || isBuffering || hasPlaybackError
            ? 'opacity-100'
            : 'opacity-0'
        }`}
      >
        {isBuffering ? (
          <div className="flex flex-col items-center justify-center space-y-3">
            <div className="w-14 h-14 border-4 border-[#E50914] border-t-transparent rounded-full animate-spin" />
            <span className="text-xs font-semibold text-white drop-shadow">Buffering...</span>
          </div>
        ) : (
          <div className="flex items-center space-x-6 sm:space-x-12 pointer-events-auto">
            {/* Rewind 10s with 10 centered inside */}
            <button
              onClick={(e) => {
                e.stopPropagation();
                seekRelative(-10);
                resetHideTimer();
              }}
              className="w-12 h-12 sm:w-16 sm:h-16 rounded-full bg-black/60 hover:bg-black/80 border border-white/30 backdrop-blur-md flex items-center justify-center text-white transition-all transform active:scale-90 shadow-2xl relative"
              title="Rewind 10s"
            >
              <RotateCcw className="w-6 h-6 sm:w-8 sm:h-8" />
              <span className="absolute text-[8px] sm:text-[10px] font-black font-mono leading-none pt-0.5">10</span>
            </button>

            {/* Giant Center Play / Pause Toggle */}
            <button
              onClick={(e) => {
                e.stopPropagation();
                togglePlay();
                resetHideTimer();
              }}
              className="w-16 h-16 sm:w-24 sm:h-24 rounded-full bg-black/70 hover:bg-black/90 border-2 border-white/40 backdrop-blur-lg flex items-center justify-center text-white transition-all transform active:scale-95 shadow-2xl"
              title={isPlaying ? 'Pause' : 'Play'}
            >
              {isPlaying ? (
                <Pause className="w-8 h-8 sm:w-12 sm:h-12 fill-white" />
              ) : (
                <Play className="w-8 h-8 sm:w-12 sm:h-12 fill-white translate-x-0.5 sm:translate-x-1" />
              )}
            </button>

            {/* Forward 10s with 10 centered inside */}
            <button
              onClick={(e) => {
                e.stopPropagation();
                seekRelative(10);
                resetHideTimer();
              }}
              className="w-12 h-12 sm:w-16 sm:h-16 rounded-full bg-black/60 hover:bg-black/80 border border-white/30 backdrop-blur-md flex items-center justify-center text-white transition-all transform active:scale-90 shadow-2xl relative"
              title="Forward 10s"
            >
              <RotateCw className="w-6 h-6 sm:w-8 sm:h-8" />
              <span className="absolute text-[8px] sm:text-[10px] font-black font-mono leading-none pt-0.5">10</span>
            </button>
          </div>
        )}
      </div>

      {/* Signature Netflix "Skip Intro" Button */}
      {currentTime > 5 && currentTime < 90 && (
        <button
          onClick={skipIntro}
          className="absolute bottom-24 sm:bottom-28 right-4 sm:right-8 z-40 bg-black/70 hover:bg-black/90 border border-white text-white font-bold px-4 sm:px-5 py-2 sm:py-2.5 rounded text-xs sm:text-sm transition-all netflix-blur active:scale-95 flex items-center space-x-2 shadow-2xl"
        >
          <span>Skip Intro</span>
          <FastForward className="w-4 h-4 fill-white" />
        </button>
      )}

      {/* Resume Playback Prompt Overlay */}
      {showResumePrompt && resumeTime && (
        <div className="absolute inset-0 bg-black/80 z-50 flex items-center justify-center p-4">
          <div className="bg-[#181818] border border-white/20 p-6 rounded-xl max-w-sm w-full text-center space-y-4 shadow-2xl">
            <h3 className="text-lg font-bold text-white">Resume Playback?</h3>
            <p className="text-gray-300 text-xs sm:text-sm">
              Continue from{' '}
              <span className="font-mono font-bold text-[#E50914]">{formatTime(resumeTime)}</span>?
            </p>
            <div className="flex items-center justify-center space-x-3 pt-2">
              <button
                onClick={() => {
                  if (videoRef.current) videoRef.current.currentTime = resumeTime;
                  setShowResumePrompt(false);
                }}
                className="bg-[#E50914] hover:bg-[#B81D24] text-white font-bold px-5 py-2 rounded text-xs transition-all active:scale-95 shadow"
              >
                Resume
              </button>
              <button
                onClick={() => {
                  if (videoRef.current) videoRef.current.currentTime = 0;
                  setShowResumePrompt(false);
                }}
                className="bg-gray-700 hover:bg-gray-600 text-white font-bold px-5 py-2 rounded text-xs transition-all active:scale-95"
              >
                Start Over
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Next Episode Countdown Overlay (Bottom Right) */}
      {nextEpisodeCountdown !== null && activeItem.type === 'series' && (
        <div className="absolute bottom-24 sm:bottom-28 right-4 sm:right-6 z-40 bg-[#181818]/95 border border-white/20 p-3 sm:p-4 rounded-lg shadow-2xl flex items-center space-x-3 animate-in fade-in duration-300">
          <div>
            <p className="text-[10px] sm:text-xs text-gray-400 font-semibold uppercase">Up Next</p>
            <p className="text-xs sm:text-sm font-bold text-white">Next episode in {nextEpisodeCountdown}s</p>
          </div>
          <button
            onClick={playNextEpisode}
            className="flex items-center space-x-1 bg-white text-black font-bold px-3 py-1.5 rounded text-xs hover:bg-white/80 transition-colors"
          >
            <FastForward className="w-3.5 h-3.5 fill-black" />
            <span>Play</span>
          </button>
        </div>
      )}

      {/* Netflix Stream Recovery & External Player Modal (Senior QA Resilience Engine) */}
      {hasPlaybackError && (
        <div className="absolute inset-0 bg-black/90 z-50 flex items-center justify-center p-4">
          <div className="bg-[#181818] border border-red-600/40 p-6 rounded-2xl max-w-md w-full space-y-4 shadow-2xl text-white">
            <div className="flex items-center space-x-3 text-red-500">
              <AlertCircle className="w-7 h-7 shrink-0" />
              <div>
                <h3 className="text-base sm:text-lg font-bold text-white">Mobile Playback Notice</h3>
                <p className="text-xs text-gray-400">Audio/video container format resolution</p>
              </div>
            </div>

            <p className="text-xs sm:text-sm text-gray-300 leading-relaxed">
              This high-bitrate ISP title is in <span className="font-bold text-white">Matroska (.mkv)</span> format with multi-channel audio. Mobile web browsers (Safari iOS / Android) may require native hardware decoding or our stream proxy.
            </p>

            <div className="space-y-2.5 pt-1">
              {/* 1-Tap VLC / MX Player Launch */}
              {rawVideoSrc && (
                <a
                  href={externalLinks.vlc}
                  className="w-full flex items-center justify-center space-x-2 bg-[#E50914] hover:bg-red-700 text-white font-bold py-2.5 px-4 rounded-lg text-xs sm:text-sm transition-all active:scale-95 shadow-lg"
                >
                  <Smartphone className="w-4 h-4" />
                  <span>⚡ Open in VLC Player (Recommended)</span>
                </a>
              )}

              {/* Retry with Proxy */}
              <button
                onClick={() => {
                  setStreamMode('proxy');
                  setHasPlaybackError(false);
                  if (videoRef.current) {
                    videoRef.current.load();
                    videoRef.current.play().catch(() => {});
                  }
                }}
                className="w-full flex items-center justify-center space-x-2 bg-gray-700 hover:bg-gray-600 text-white font-bold py-2.5 px-4 rounded-lg text-xs sm:text-sm transition-all active:scale-95"
              >
                <RefreshCw className="w-4 h-4" />
                <span>Retry via Stream Proxy</span>
              </button>

              {/* Sample Web Stream Fallback */}
              <button
                onClick={() => {
                  setStreamMode('sample');
                  setHasPlaybackError(false);
                  if (videoRef.current) {
                    videoRef.current.load();
                    videoRef.current.play().catch(() => {});
                  }
                }}
                className="w-full flex items-center justify-center space-x-2 bg-gray-800 hover:bg-gray-700 text-gray-300 font-semibold py-2 px-4 rounded-lg text-xs transition-all"
              >
                <Play className="w-3.5 h-3.5 fill-gray-300" />
                <span>Play High-Speed Web MP4 Test Stream</span>
              </button>
            </div>

            <div className="flex justify-end pt-2">
              <button
                onClick={closePlayer}
                className="text-xs text-gray-400 hover:text-white underline font-semibold"
              >
                Close Player
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Top Header Navigation HUD */}
      <div
        className={`absolute top-0 inset-x-0 p-3 sm:p-5 md:p-6 bg-gradient-to-b from-black/95 via-black/50 to-transparent flex items-center justify-between z-40 transition-opacity duration-300 ${
          controlsVisible ? 'opacity-100' : 'opacity-0 pointer-events-none'
        }`}
        style={{ paddingTop: 'max(0.75rem, env(safe-area-inset-top))' }}
      >
        {/* Left: Back Button & Title */}
        <div className="flex items-center space-x-3 sm:space-x-4 max-w-[70%] sm:max-w-[75%]">
          <button
            onClick={closePlayer}
            className="w-10 h-10 rounded-full hover:bg-white/20 active:scale-95 flex items-center justify-center text-white transition-all shrink-0"
            title="Exit (Esc)"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div className="min-w-0">
            <h2 className="text-xs sm:text-base md:text-lg font-bold text-white drop-shadow truncate">
              {currentTitle}
            </h2>
            <div className="flex items-center space-x-2 text-[10px] sm:text-xs text-gray-400 font-mono">
              <span className="bg-[#E50914] text-white px-1 py-0.2 rounded font-black text-[9px]">
                {activeItem.quality || '1080p'}
              </span>
              <span className="truncate">{activeItem.category}</span>
            </div>
          </div>
        </div>

        {/* Right Top Actions (Audio, Episodes, External Player, Horizontal View) */}
        <div className="flex items-center space-x-2 sm:space-x-3 text-white shrink-0">
          {/* Horizontal Landscape Orientation Toggle (Mobile) */}
          {isMobile && (
            <button
              onClick={() => setIsForceLandscape(!isForceLandscape)}
              className={`px-2.5 py-1 rounded-full text-xs font-bold transition-all flex items-center space-x-1.5 border ${
                isForceLandscape
                  ? 'bg-[#E50914] border-red-500 text-white shadow-lg shadow-red-950/50'
                  : 'bg-black/50 hover:bg-black/80 border-white/40 text-gray-200'
              }`}
              title={isForceLandscape ? 'Exit Horizontal View' : 'Switch to Horizontal Landscape View'}
            >
              <Smartphone className={`w-3.5 h-3.5 transition-transform duration-300 ${isForceLandscape ? 'rotate-90 text-white' : 'text-gray-300'}`} />
              <span className="text-[11px] font-semibold">{isForceLandscape ? 'Portrait' : 'Landscape'}</span>
            </button>
          )}

          {/* External App Menu Toggle */}
          <div className="relative">
            <button
              onClick={() => setShowExternalMenu(!showExternalMenu)}
              className={`p-2 rounded-full hover:bg-white/20 active:scale-95 transition-colors ${
                showExternalMenu ? 'text-[#E50914] bg-white/10' : 'text-gray-300'
              }`}
              title="External Players (VLC / MX Player)"
            >
              <Smartphone className="w-5 h-5" />
            </button>

            {showExternalMenu && (
              <div className="absolute top-12 right-0 bg-[#181818] border border-white/20 rounded-xl p-3 w-64 shadow-2xl z-50 text-xs space-y-2.5 animate-in fade-in zoom-in-95 duration-150">
                <p className="font-bold text-white uppercase text-[10px] tracking-wider text-gray-400">
                  External Mobile Streaming
                </p>
                {rawVideoSrc && (
                  <a
                    href={externalLinks.vlc}
                    className="flex items-center space-x-2 p-2 rounded-lg bg-[#E50914] hover:bg-red-700 text-white font-bold transition-colors"
                  >
                    <Smartphone className="w-4 h-4 shrink-0" />
                    <span>Launch in VLC Player</span>
                  </a>
                )}
                {rawVideoSrc && (
                  <a
                    href={externalLinks.mxPlayer}
                    className="flex items-center space-x-2 p-2 rounded-lg bg-gray-800 hover:bg-gray-700 text-gray-200 font-semibold transition-colors"
                  >
                    <Tv className="w-4 h-4 shrink-0" />
                    <span>Launch in MX Player (Android)</span>
                  </a>
                )}
                <div className="border-t border-gray-700 pt-2 text-[10px] text-gray-400">
                  Direct BDIX Stream:
                  <input
                    readOnly
                    value={rawVideoSrc || ''}
                    className="w-full mt-1 bg-black/60 p-1 rounded font-mono text-[9px] text-gray-300 border border-gray-700"
                    onClick={(e) => (e.target as HTMLInputElement).select()}
                  />
                </div>
              </div>
            )}
          </div>

          {/* Audio & Subtitles Dialog */}
          <div className="relative">
            <button
              onClick={() => setShowAudioMenu(!showAudioMenu)}
              className={`p-2 rounded-full hover:bg-white/20 active:scale-95 transition-colors ${
                showAudioMenu ? 'text-[#E50914] bg-white/10' : 'text-gray-300'
              }`}
              title="Audio & Subtitles"
            >
              <MessageSquare className="w-5 h-5" />
            </button>

            {showAudioMenu && (
              <div className="absolute top-12 right-0 bg-[#181818] border border-white/20 rounded-xl p-3.5 w-64 shadow-2xl z-50 text-xs space-y-3 animate-in fade-in zoom-in-95 duration-150">
                <div>
                  <p className="font-bold text-gray-400 mb-1.5 uppercase text-[10px] tracking-wider">
                    Audio Track
                  </p>
                  {['Original (5.1)', 'Hindi Dubbed (2.0)', 'English [Default]'].map((aud) => (
                    <button
                      key={aud}
                      onClick={() => {
                        setSelectedAudio(aud);
                        setShowAudioMenu(false);
                      }}
                      className={`w-full text-left py-1.5 px-2 rounded transition-colors ${
                        selectedAudio === aud
                          ? 'text-[#E50914] font-bold bg-white/10'
                          : 'text-gray-300 hover:bg-white/5'
                      }`}
                    >
                      ✓ {aud}
                    </button>
                  ))}
                </div>
                <div className="border-t border-gray-700 pt-2">
                  <p className="font-bold text-gray-400 mb-1.5 uppercase text-[10px] tracking-wider">
                    Subtitles
                  </p>
                  {['Off', 'English [CC]', 'Bangla [Sub]'].map((sub) => (
                    <button
                      key={sub}
                      onClick={() => {
                        setSelectedSubtitle(sub);
                        setShowAudioMenu(false);
                      }}
                      className={`w-full text-left py-1.5 px-2 rounded transition-colors ${
                        selectedSubtitle === sub
                          ? 'text-[#E50914] font-bold bg-white/10'
                          : 'text-gray-300 hover:bg-white/5'
                      }`}
                    >
                      ✓ {sub}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* In-Player Season Drawer Toggle */}
          {activeItem.type === 'series' && seasons.length > 0 && (
            <button
              onClick={() => setIsDrawerOpen(!isDrawerOpen)}
              className={`p-2 rounded-full hover:bg-white/20 active:scale-95 transition-colors ${
                isDrawerOpen ? 'text-[#E50914] bg-white/10' : 'text-gray-300'
              }`}
              title="Episodes & Seasons"
            >
              <Layers className="w-5 h-5" />
            </button>
          )}
        </div>
      </div>

      {/* Bottom Controls HUD */}
      <div
        className={`absolute bottom-0 inset-x-0 p-3 sm:p-6 md:p-8 bg-gradient-to-t from-black/95 via-black/60 to-transparent z-40 space-y-2 sm:space-y-3 transition-opacity duration-300 ${
          controlsVisible ? 'opacity-100' : 'opacity-0 pointer-events-none'
        }`}
        style={{ paddingBottom: 'max(0.75rem, env(safe-area-inset-bottom))' }}
      >
        {/* Scrubber Seekbar */}
        <div
          className="relative group cursor-pointer py-2.5 sm:py-2"
          onClick={(e) => {
            const rect = e.currentTarget.getBoundingClientRect();
            const clickPercent = ((e.clientX - rect.left) / rect.width) * 100;
            seekTo(clickPercent);
          }}
        >
          <div className="w-full h-1.5 sm:h-1 group-hover:h-2 bg-gray-700/80 rounded transition-all relative overflow-visible">
            {/* Buffered Progress */}
            <div
              className="absolute top-0 bottom-0 left-0 bg-gray-500/70 rounded-l"
              style={{ width: `${bufferedPercent}%` }}
            />
            {/* Played Progress */}
            <div
              className="absolute top-0 bottom-0 left-0 bg-[#E50914] rounded-l"
              style={{ width: `${(currentTime / (duration || 1)) * 100}%` }}
            />
            {/* Netflix Signature Circular Head Thumb */}
            <div
              className="absolute top-1/2 -translate-y-1/2 -translate-x-1/2 w-3.5 h-3.5 bg-[#E50914] rounded-full border-2 border-white shadow-lg pointer-events-none transition-transform group-hover:scale-125"
              style={{ left: `${(currentTime / (duration || 1)) * 100}%` }}
            />
          </div>
        </div>

        {/* Dynamic Controls Bar: Mobile vs Desktop */}
        {isMobile ? (
          /* Mobile Bottom Row (Clean, Zero Overflow, Essential Controls) */
          <div className="flex items-center justify-between text-white text-xs px-1">
            {/* Elapsed Time */}
            <div className="font-mono text-gray-300">
              <span>{formatTime(currentTime)}</span>
            </div>

            {/* Mobile Actions: Speed & Next Episode */}
            <div className="flex items-center space-x-3">
              {activeItem.type === 'series' && (
                <button
                  onClick={playNextEpisode}
                  className="hover:text-gray-300 transition-colors flex items-center space-x-1 text-xs font-bold text-gray-200"
                >
                  <FastForward className="w-4 h-4 fill-white" />
                  <span>Next Ep</span>
                </button>
              )}

              {/* Speed Menu */}
              <div className="relative">
                <button
                  onClick={() => setShowSpeedMenu(!showSpeedMenu)}
                  className="hover:text-gray-300 transition-colors text-[11px] font-bold font-mono px-2 py-0.5 border border-white/40 rounded active:scale-95"
                >
                  {playbackSpeed}x
                </button>
                {showSpeedMenu && (
                  <div className="absolute bottom-8 right-0 bg-[#181818] border border-white/20 rounded-lg py-1 w-20 shadow-2xl z-50 text-xs">
                    {[0.5, 0.75, 1, 1.25, 1.5].map((spd) => (
                      <button
                        key={spd}
                        onClick={() => changeSpeed(spd)}
                        className={`w-full text-left px-3 py-1.5 hover:bg-[#E50914] hover:text-white transition-colors ${
                          playbackSpeed === spd ? 'font-bold text-[#E50914]' : ''
                        }`}
                      >
                        {spd}x
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Total Duration or Remaining Time */}
            <div className="font-mono text-gray-400">
              <span>-{formatTime(Math.max(0, duration - currentTime))}</span>
            </div>
          </div>
        ) : (
          /* Desktop Bottom Row (Full Rich Netflix HUD) */
          <div className="flex items-center justify-between text-white">
            {/* Left Desktop Actions */}
            <div className="flex items-center space-x-4 sm:space-x-5">
              <button onClick={togglePlay} className="hover:text-gray-300 transition-colors">
                {isPlaying ? <Pause className="w-6 h-6 fill-white" /> : <Play className="w-6 h-6 fill-white" />}
              </button>

              <button
                onClick={() => seekRelative(-10)}
                className="hover:text-gray-300 transition-colors"
                title="Rewind 10s"
              >
                <RotateCcw className="w-5 h-5" />
              </button>

              <button
                onClick={() => seekRelative(10)}
                className="hover:text-gray-300 transition-colors"
                title="Forward 10s"
              >
                <RotateCw className="w-5 h-5" />
              </button>

              {/* Volume Slider */}
              <div className="flex items-center space-x-2 group">
                <button onClick={toggleMute} className="hover:text-gray-300 transition-colors">
                  {isMuted || volume === 0 ? <VolumeX className="w-5 h-5" /> : <Volume2 className="w-5 h-5" />}
                </button>
                <input
                  type="range"
                  min="0"
                  max="1"
                  step="0.05"
                  value={isMuted ? 0 : volume}
                  onChange={(e) => {
                    const val = parseFloat(e.target.value);
                    if (videoRef.current) {
                      videoRef.current.volume = val;
                      videoRef.current.muted = val === 0;
                    }
                    setVolume(val);
                    setIsMuted(val === 0);
                  }}
                  className="w-16 sm:w-20 h-1 accent-[#E50914] bg-gray-600 rounded cursor-pointer"
                />
              </div>

              {/* Elapsed / Total Time */}
              <div className="text-xs font-mono text-gray-300">
                <span>{formatTime(currentTime)}</span>
                <span className="mx-1 text-gray-500">/</span>
                <span>{formatTime(duration)}</span>
              </div>
            </div>

            {/* Right Desktop Actions */}
            <div className="flex items-center space-x-4 relative">
              {/* Next Episode Button */}
              {activeItem.type === 'series' && (
                <button
                  onClick={playNextEpisode}
                  className="hover:text-gray-300 transition-colors flex items-center space-x-1 text-xs font-bold"
                  title="Next Episode (N)"
                >
                  <FastForward className="w-5 h-5" />
                  <span>Next Ep</span>
                </button>
              )}

              {/* Desktop Speed Menu */}
              <div className="relative">
                <button
                  onClick={() => setShowSpeedMenu(!showSpeedMenu)}
                  className="hover:text-gray-300 transition-colors text-xs font-bold font-mono px-1.5 py-0.5 border border-white/40 rounded"
                >
                  {playbackSpeed}x
                </button>
                {showSpeedMenu && (
                  <div className="absolute bottom-8 right-0 bg-[#181818] border border-white/20 rounded py-1 w-20 shadow-xl z-50 text-xs">
                    {[0.5, 0.75, 1, 1.25, 1.5].map((spd) => (
                      <button
                        key={spd}
                        onClick={() => changeSpeed(spd)}
                        className={`w-full text-left px-3 py-1.5 hover:bg-[#E50914] hover:text-white transition-colors ${
                          playbackSpeed === spd ? 'font-bold text-[#E50914]' : ''
                        }`}
                      >
                        {spd}x
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Picture in Picture Button */}
              <button
                onClick={togglePiP}
                className="hover:text-gray-300 transition-colors"
                title="Picture in Picture"
              >
                <PictureInPicture className="w-5 h-5" />
              </button>

              {/* Fullscreen Button */}
              <button
                onClick={toggleFullscreen}
                className="hover:text-gray-300 transition-colors"
                title="Fullscreen (F)"
              >
                {isFullscreen ? <Minimize className="w-5 h-5" /> : <Maximize className="w-5 h-5" />}
              </button>
            </div>
          </div>
        )}
      </div>

      {/* In-Player Season & Episode Side Drawer */}
      {isDrawerOpen && activeItem.type === 'series' && (
        <div className="absolute top-0 bottom-0 right-0 w-full sm:w-96 bg-[#181818]/95 border-l border-white/20 z-50 p-4 overflow-y-auto space-y-4 netflix-blur">
          <div className="flex items-center justify-between border-b border-gray-700 pb-3">
            <h3 className="font-bold text-white text-base">Episodes</h3>
            <button
              onClick={() => setIsDrawerOpen(false)}
              className="p-1 text-gray-400 hover:text-white"
            >
              <X className="w-6 h-6" />
            </button>
          </div>

          {seasons.length > 1 && (
            <select
              value={activeSeasonNumber}
              onChange={(e) => {
                const sNum = Number(e.target.value);
                const s = seasons.find((x) => x.seasonNumber === sNum);
                if (s && s.episodes.length > 0) {
                  playMedia(activeItem, s.episodes[0], sNum);
                }
              }}
              className="w-full bg-[#242424] text-white text-xs font-bold border border-gray-700 rounded-lg p-2.5 focus:outline-none"
            >
              {seasons.map((s) => (
                <option key={s.seasonNumber} value={s.seasonNumber}>
                  {s.seasonName} ({s.episodes.length} Episodes)
                </option>
              ))}
            </select>
          )}

          <div className="space-y-2">
            {currentSeason?.episodes.map((ep) => {
              const isCurrent = ep.episodeNumber === activeEpisode?.episodeNumber;
              return (
                <div
                  key={ep.episodeNumber}
                  onClick={() => playMedia(activeItem, ep, activeSeasonNumber)}
                  className={`p-3 rounded-lg cursor-pointer transition-colors flex items-center justify-between text-xs ${
                    isCurrent
                      ? 'bg-[#E50914] text-white font-bold'
                      : 'bg-[#242424] hover:bg-[#2e2e2e] text-gray-300'
                  }`}
                >
                  <div className="flex items-center space-x-2 truncate">
                    <span className="font-bold">{ep.episodeNumber}.</span>
                    <span className="truncate">{ep.title}</span>
                  </div>
                  {isCurrent && <Play className="w-4 h-4 fill-white shrink-0" />}
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};
