import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Play, Plus, Check, ThumbsUp, ChevronDown, Download } from 'lucide-react';
import { MediaItem } from '../types';
import { usePlayerStore } from '../store/usePlayerStore';
import { useAppStore } from '../store/useAppStore';
import { getPlayableStreamUrl } from '../utils/stream';

interface MediaCardProps {
  item: MediaItem;
  rank?: number;
  index?: number;
  totalItems?: number;
  isGrid?: boolean;
}

export const MediaCard: React.FC<MediaCardProps> = ({ 
  item, 
  rank, 
  index, 
  totalItems, 
  isGrid = false 
}) => {
  const [isHovered, setIsHovered] = useState(false);
  const [canLoadVideo, setCanLoadVideo] = useState(false);
  const [isVideoPlaying, setIsVideoPlaying] = useState(false);
  const [videoError, setVideoError] = useState(false);

  const hoverTimeoutRef = useRef<any>(null);
  const leaveTimeoutRef = useRef<any>(null);
  const videoTimeoutRef = useRef<any>(null);
  const videoRef = useRef<HTMLVideoElement>(null);

  const { playMedia } = usePlayerStore();
  const { setDetailItem, toggleWatchlist, watchlist, likes, setLike, getHistory, preferences } = useAppStore();

  const inWatchlist = Boolean(item && watchlist.includes(item.id));
  const isLiked = likes[item.id];
  const history = getHistory(item.id);

  useEffect(() => {
    return () => {
      if (hoverTimeoutRef.current) clearTimeout(hoverTimeoutRef.current);
      if (leaveTimeoutRef.current) clearTimeout(leaveTimeoutRef.current);
      if (videoTimeoutRef.current) clearTimeout(videoTimeoutRef.current);
    };
  }, []);

  const handleMouseEnter = () => {
    // Touch devices and mobile screens do not have hover - prevent touch jitter and clipping
    if (typeof window !== 'undefined' && ('ontouchstart' in window || window.innerWidth < 768)) {
      return;
    }

    // Cancel any pending exit immediately
    if (leaveTimeoutRef.current) {
      clearTimeout(leaveTimeoutRef.current);
      leaveTimeoutRef.current = null;
    }

    if (isHovered) return;

    // Smooth hover intent delay (200ms)
    hoverTimeoutRef.current = setTimeout(() => {
      setIsHovered(true);
      // Wait for card zoom to finish before attempting video buffer (eliminates buffer lag)
      videoTimeoutRef.current = setTimeout(() => {
        setCanLoadVideo(true);
      }, 500);
    }, 200);
  };

  const handleMouseLeave = () => {
    if (hoverTimeoutRef.current) {
      clearTimeout(hoverTimeoutRef.current);
      hoverTimeoutRef.current = null;
    }
    if (videoTimeoutRef.current) {
      clearTimeout(videoTimeoutRef.current);
      videoTimeoutRef.current = null;
    }

    // Debounce mouse leave by 120ms so moving between buttons or boundaries never flickers
    leaveTimeoutRef.current = setTimeout(() => {
      setIsHovered(false);
      setCanLoadVideo(false);
      setIsVideoPlaying(false);
    }, 120);
  };

  // Smart Netflix match algorithm: boosted if it aligns with user preferences
  const matchesTaste = (preferences || []).some((pref) => {
    const p = pref.toLowerCase();
    const title = (item.title || '').toLowerCase();
    const cat = (item.category || '').toLowerCase();
    const tags = (item.tags || []).join(' ').toLowerCase();
    return title.includes(p) || cat.includes(p) || tags.includes(p);
  });

  const matchPercent = matchesTaste ? 97 + (item.title.length % 3) : 89 + (item.title.length % 7);

  // Dynamic transform origin to prevent horizontal edge clipping in both rows and grids
  let transformOrigin = 'center center';
  if (isGrid) {
    if (index !== undefined) {
      if (index % 5 === 0) transformOrigin = 'left center';
      else if ((index + 1) % 5 === 0) transformOrigin = 'right center';
    }
  } else {
    if (index === 0 || rank === 1) transformOrigin = 'left center';
    else if ((totalItems && index === totalItems - 1) || rank === 10) transformOrigin = 'right center';
  }

  return (
    <div
      className={`relative aspect-[16/9] cursor-pointer will-change-transform ${
        isGrid ? 'w-full' : 'flex-none w-[170px] sm:w-[200px] md:w-[240px]'
      } ${isHovered ? 'z-50' : 'z-10'}`}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      {/* Base Card (Normal State) */}
      <div 
        onClick={() => setDetailItem(item)}
        className="w-full h-full rounded-md overflow-hidden bg-[#181818] shadow-md relative group border border-transparent hover:border-white/20 transition-all"
      >
        <img
          src={item.backdrop || item.poster || 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="300" height="169" fill="%23222"><rect width="300" height="169"/></svg>'}
          alt={item.title}
          loading="lazy"
          className="w-full h-full object-cover object-top transition-transform duration-300 group-hover:scale-105"
        />

        {/* Type Badge: Series vs Movie vs Anime */}
        <div className="absolute top-1.5 left-1.5 z-10 flex items-center space-x-1">
          {item.type === 'series' ? (
            <span className="bg-gradient-to-r from-blue-700 to-indigo-800 text-white text-[9px] font-black px-1.5 py-0.5 rounded shadow tracking-wider uppercase">
              {item.category?.includes('Anime') ? 'ANIME' : 'SERIES'}
            </span>
          ) : (
            <span className="bg-black/75 backdrop-blur-sm border border-white/30 text-gray-200 text-[9px] font-bold px-1.5 py-0.5 rounded shadow tracking-wider uppercase">
              MOVIE
            </span>
          )}
          {item.quality && (
            <span className="bg-black/60 text-gray-300 text-[8px] font-bold px-1 py-0.5 rounded shadow uppercase">
              {item.quality}
            </span>
          )}
        </div>

        {/* Top 10 Red Ribbon Badge */}
        {rank && (
          <div className="absolute top-1.5 right-1.5 bg-[#E50914] text-white text-[9px] font-black px-1.5 py-0.5 rounded shadow flex items-center space-x-1 tracking-wider uppercase z-10">
            <span>TOP 10</span>
          </div>
        )}

        {/* Progress bar overlay if previously watched */}
        {history && history.percent > 0 && (
          <div className="absolute bottom-0 left-0 right-0 h-1 bg-gray-700">
            <div
              className="h-full bg-[#E50914]"
              style={{ width: `${Math.min(100, Math.max(0, history.percent))}%` }}
            />
          </div>
        )}

        {/* Normal state Title footer banner */}
        <div className="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/95 via-black/50 to-transparent p-2 text-white">
          <p className="text-xs font-semibold truncate drop-shadow">{item.title}</p>
          <div className="flex items-center space-x-1.5 text-[10px] text-gray-400 font-medium">
            <span className="text-gray-300">{item.type === 'series' ? 'Series' : 'Movie'}</span>
            {item.year && <span>• {item.year}</span>}
          </div>
        </div>
      </div>

      {/* Expanded Hover Card Overlay - Silky Smooth 60fps Cubic-Bezier, Zero Spring Jitter */}
      <AnimatePresence>
        {isHovered && (
          <motion.div
            initial={{ opacity: 0, scale: 0.96 }}
            animate={{ opacity: 1, scale: 1.25 }}
            exit={{ opacity: 0, scale: 0.96 }}
            transition={{ 
              duration: 0.22, 
              ease: [0.25, 0.1, 0.25, 1] 
            }}
            className="absolute -top-6 left-0 w-full z-50 bg-[#181818] rounded-md shadow-[0_20px_50px_rgba(0,0,0,0.95)] overflow-hidden border border-white/20 will-change-transform transform-gpu pointer-events-auto"
            style={{ transformOrigin }}
          >
            {/* Card Preview Media Container */}
            <div 
              onClick={() => setDetailItem(item)}
              className="relative aspect-[16/9] w-full bg-[#111] overflow-hidden"
            >
              <img
                src={item.backdrop || item.poster || ''}
                alt={item.title}
                className="w-full h-full object-cover object-top transition-transform duration-700 ease-out"
              />

              {/* Video Preview: Only loads after card finishes expanding smoothly, avoiding buffering jitter */}
              {canLoadVideo && item.streamUrl && !videoError && (
                <video
                  ref={videoRef}
                  src={getPlayableStreamUrl(item.streamUrl)}
                  autoPlay
                  muted
                  playsInline
                  loop
                  onPlaying={() => setIsVideoPlaying(true)}
                  onError={() => setVideoError(true)}
                  className={`absolute inset-0 w-full h-full object-cover object-top transition-opacity duration-500 ${
                    isVideoPlaying ? 'opacity-100' : 'opacity-0'
                  }`}
                />
              )}

              {/* Badges Overlay */}
              <div className="absolute top-2 left-2 flex items-center space-x-1 z-20">
                <span className={`text-[8px] font-black px-1.5 py-0.5 rounded shadow tracking-wider uppercase ${
                  item.type === 'series'
                    ? (item.category?.includes('Anime') ? 'bg-pink-700 text-white' : 'bg-indigo-700 text-white')
                    : 'bg-black/80 border border-white/30 text-white'
                }`}>
                  {item.category?.includes('Anime') ? 'ANIME' : (item.type === 'series' ? 'SERIES' : 'MOVIE')}
                </span>
              </div>

              <div className="absolute top-2 right-2 bg-black/80 px-1.5 py-0.5 rounded text-[9px] font-bold text-gray-200 uppercase z-20">
                {item.quality || 'HD'}
              </div>
            </div>

            {/* Quick Actions & Metadata */}
            <div className="p-3 bg-[#181818] space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-1.5">
                  {/* Play Button */}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      playMedia(item);
                    }}
                    className="w-8 h-8 rounded-full bg-white hover:bg-white/80 flex items-center justify-center text-black transition-transform active:scale-90 shadow"
                    title="Play"
                  >
                    <Play className="w-4 h-4 fill-black translate-x-0.5" />
                  </button>

                  {/* Add / Remove from My List (Immediate reactive toggle) */}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      toggleWatchlist(item);
                    }}
                    className={`w-8 h-8 rounded-full border flex items-center justify-center transition-all active:scale-90 ${
                      inWatchlist 
                        ? 'border-green-500 bg-green-500/20 text-green-400' 
                        : 'border-gray-400 hover:border-white text-white'
                    }`}
                    title={inWatchlist ? 'Remove from My List' : 'Add to My List'}
                  >
                    {inWatchlist ? <Check className="w-4 h-4 text-green-400" /> : <Plus className="w-4 h-4" />}
                  </button>

                  {/* Like Button */}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setLike(item.id, !isLiked);
                    }}
                    className={`w-8 h-8 rounded-full border border-gray-400 hover:border-white flex items-center justify-center text-white transition-all active:scale-90 ${
                      isLiked === true ? 'border-[#E50914] bg-[#E50914]/20 text-[#E50914]' : ''
                    }`}
                    title="Like"
                  >
                    <ThumbsUp className="w-4 h-4" />
                  </button>

                  {/* Direct Download File */}
                  {item.streamUrl && (
                    <a
                      href={item.streamUrl}
                      download
                      onClick={(e) => e.stopPropagation()}
                      className="w-8 h-8 rounded-full border border-gray-400 hover:border-white flex items-center justify-center text-white transition-colors"
                      title="Download Video File"
                    >
                      <Download className="w-4 h-4" />
                    </a>
                  )}
                </div>

                {/* More Details Chevron */}
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setDetailItem(item);
                  }}
                  className="w-8 h-8 rounded-full border border-gray-400 hover:border-white flex items-center justify-center text-white transition-all active:scale-90"
                  title="Episodes & More Info"
                >
                  <ChevronDown className="w-4 h-4" />
                </button>
              </div>

              {/* Metadata Badges */}
              <div className="flex items-center space-x-2 text-[10px] font-semibold flex-wrap gap-y-0.5">
                {rank && (
                  <span className="bg-[#E50914] text-white font-black text-[9px] px-1.5 py-0.5 rounded uppercase tracking-wider">
                    #{rank} Today
                  </span>
                )}
                <span className="text-emerald-400 font-bold">{matchPercent}% Match</span>
                {matchesTaste && (
                  <span className="text-[8px] font-bold bg-emerald-500/20 text-emerald-300 px-1 py-0.2 rounded border border-emerald-500/30">
                    For You
                  </span>
                )}
                <span className="border border-gray-600 px-1 py-0.2 rounded text-[9px] text-gray-300">
                  {item.year || 2024}
                </span>
                <span className={`px-1.5 py-0.5 rounded text-[8px] font-black uppercase tracking-wider ${
                  item.type === 'series'
                    ? 'bg-blue-600/30 text-blue-400 border border-blue-500/40'
                    : 'bg-zinc-800 text-gray-300 border border-gray-600'
                }`}>
                  {item.category?.includes('Anime') ? 'ANIME' : (item.type === 'series' ? 'SERIES' : 'MOVIE')}
                </span>
                {item.type === 'series' && item.totalSeasons && (
                  <span className="text-gray-400 text-[10px]">
                    {item.totalSeasons} Season{item.totalSeasons > 1 ? 's' : ''}
                  </span>
                )}
                {item.tags && item.tags.length > 0 && (
                  <span className="text-[#E50914] text-[10px] truncate max-w-[80px]">
                    {item.tags[0]}
                  </span>
                )}
              </div>

              {/* Title */}
              <p className="text-xs font-bold text-white truncate">{item.title}</p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};
