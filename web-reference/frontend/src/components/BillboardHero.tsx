import React, { useState, useEffect, useRef } from 'react';
import { Play, Info, Volume2, VolumeX, Plus, Check } from 'lucide-react';
import { MediaItem } from '../types';
import { usePlayerStore } from '../store/usePlayerStore';
import { useAppStore } from '../store/useAppStore';
import { getPlayableStreamUrl } from '../utils/stream';

interface BillboardHeroProps {
  featured: MediaItem[];
}

export const BillboardHero: React.FC<BillboardHeroProps> = ({ featured }) => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isPlayingPreview, setIsPlayingPreview] = useState(false);
  const [isMuted, setIsMuted] = useState(true);
  const videoRef = useRef<HTMLVideoElement>(null);

  const { playMedia } = usePlayerStore();
  const { setDetailItem, toggleWatchlist, watchlist } = useAppStore();

  const currentItem = featured[currentIndex] || featured[0];
  const inWatchlist = Boolean(currentItem && watchlist.includes(currentItem.id));

  const toggleMute = (e: React.MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    const nextMuted = !isMuted;
    setIsMuted(nextMuted);
    if (videoRef.current) {
      videoRef.current.muted = nextMuted;
      if (!nextMuted) {
        videoRef.current.volume = 1;
        videoRef.current.play().catch(() => {});
      }
    }
  };

  useEffect(() => {
    // Delay video preview by 1.8 seconds after mounting
    const timer = setTimeout(() => {
      setIsPlayingPreview(true);
      if (videoRef.current) {
        videoRef.current.play().catch(() => {
          // Autoplay was prevented by browser policy
          setIsPlayingPreview(false);
        });
      }
    }, 1800);

    return () => clearTimeout(timer);
  }, [currentIndex]);

  if (!currentItem) return null;

  return (
    <div className="relative h-[65vh] sm:h-[75vh] md:h-[85vh] w-full bg-[#141414] overflow-hidden select-none">
      {/* Background Poster Image */}
      <img
        src={currentItem.backdrop || currentItem.poster || ''}
        alt={currentItem.title}
        className={`absolute inset-0 w-full h-full object-cover object-top transition-opacity duration-1000 ${
          isPlayingPreview ? 'opacity-0' : 'opacity-100'
        }`}
      />

      {/* Video Preview Layer */}
      {currentItem.streamUrl && (
        <video
          ref={videoRef}
          src={getPlayableStreamUrl(currentItem.streamUrl)}
          muted={isMuted}
          playsInline
          loop
          className={`absolute inset-0 w-full h-full object-cover transition-opacity duration-1000 ${
            isPlayingPreview ? 'opacity-100' : 'opacity-0'
          }`}
          onError={() => setIsPlayingPreview(false)}
          onEnded={() => setIsPlayingPreview(false)}
        />
      )}

      {/* Multi-layered Netflix Vignette Gradients */}
      <div className="absolute inset-0 bg-gradient-to-t from-[#141414] via-[#141414]/30 to-transparent" />
      <div className="absolute inset-0 bg-gradient-to-r from-[#141414] via-[#141414]/60 to-transparent w-full md:w-2/3" />
      <div className="absolute top-0 left-0 right-0 h-28 bg-gradient-to-b from-[#141414]/80 to-transparent" />

      {/* Hero Content Banner */}
      <div className="absolute bottom-16 sm:bottom-20 md:bottom-28 left-4 md:left-12 max-w-xl z-10 flex flex-col space-y-4">
        {/* Category & Badge */}
        <div className="flex items-center space-x-2 text-xs font-semibold tracking-wider uppercase text-gray-300">
          <span className="bg-[#E50914] text-white px-1.5 py-0.5 rounded font-black tracking-normal">
            TOP 10
          </span>
          <span>{currentItem.category}</span>
          {currentItem.quality && (
            <span className="border border-gray-400 px-1 py-0.2 rounded text-[10px]">
              {currentItem.quality}
            </span>
          )}
        </div>

        {/* Title */}
        <h1 className="text-3xl sm:text-4xl md:text-6xl font-black text-white tracking-tight drop-shadow-md leading-none">
          {currentItem.title}
        </h1>

        {/* Overview */}
        <p className="text-gray-200 text-xs sm:text-sm md:text-base line-clamp-3 drop-shadow leading-relaxed">
          {currentItem.overview ||
            `Watch ${currentItem.title} now in crisp ${currentItem.quality || 'HD'} quality with original audio. Exclusively on HomeFlix.`}
        </p>

        {/* Action Buttons */}
        <div className="flex flex-wrap items-center gap-2 sm:gap-3 pt-2">
          {/* Play Button */}
          <button
            onClick={() => playMedia(currentItem)}
            className="flex items-center space-x-2 bg-white text-black font-bold px-4 sm:px-7 py-2 sm:py-2.5 rounded hover:bg-white/80 transition-all transform active:scale-95 shadow-md text-xs sm:text-sm"
          >
            <Play className="w-4 h-4 sm:w-5 sm:h-5 fill-black" />
            <span>Play</span>
          </button>

          {/* My List Button */}
          <button
            onClick={() => toggleWatchlist(currentItem)}
            className={`flex items-center space-x-2 font-bold px-3.5 sm:px-6 py-2 sm:py-2.5 rounded transition-all transform active:scale-95 netflix-blur shadow-md border text-xs sm:text-sm ${
              inWatchlist 
                ? 'bg-black/60 border-green-500 text-green-400' 
                : 'bg-gray-500/60 border-white/30 hover:bg-gray-500/40 text-white'
            }`}
            title={inWatchlist ? 'Remove from My List' : 'Add to My List'}
          >
            {inWatchlist ? <Check className="w-4 h-4 sm:w-5 sm:h-5 text-green-400" /> : <Plus className="w-4 h-4 sm:w-5 sm:h-5" />}
            <span>{inWatchlist ? 'In My List' : 'My List'}</span>
          </button>

          {/* More Info Button */}
          <button
            onClick={() => setDetailItem(currentItem)}
            className="flex items-center space-x-2 bg-gray-500/60 hover:bg-gray-500/40 text-white font-bold px-4 sm:px-6 py-2 sm:py-2.5 rounded transition-all transform active:scale-95 netflix-blur shadow-md text-xs sm:text-sm"
          >
            <Info className="w-4 h-4 sm:w-5 sm:h-5" />
            <span>More Info</span>
          </button>
        </div>
      </div>

      {/* Audio Mute/Unmute Toggle & Maturity Badge */}
      <div className="absolute top-20 sm:top-auto sm:bottom-20 md:bottom-28 right-4 md:right-12 z-30 flex items-center space-x-2.5 pointer-events-auto">
        {currentItem.streamUrl && (
          <button
            onClick={toggleMute}
            className="w-9 h-9 sm:w-10 sm:h-10 rounded-full border border-white/60 bg-black/50 hover:bg-black/80 flex items-center justify-center text-white transition-all transform active:scale-90 shadow-xl netflix-blur"
            title={isMuted ? 'Unmute preview audio' : 'Mute preview audio'}
          >
            {isMuted ? <VolumeX className="w-4 h-4 sm:w-5 sm:h-5 text-gray-300" /> : <Volume2 className="w-4 h-4 sm:w-5 sm:h-5 text-white" />}
          </button>
        )}
        <div className="bg-gray-800/80 border-l-4 border-gray-400 text-white text-[11px] sm:text-xs px-2.5 sm:px-3 py-1 font-semibold uppercase shadow">
          {currentItem.quality || '1080p'}
        </div>
      </div>
    </div>
  );
};
