import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Play, Plus, Check, ThumbsUp, Download, Clock, Smartphone } from 'lucide-react';
import { MediaItem, Season } from '../types';
import { useAppStore } from '../store/useAppStore';
import { usePlayerStore } from '../store/usePlayerStore';
import { MediaCard } from './MediaCard';
import { getExternalPlayerLinks } from '../utils/stream';

export const DetailModal: React.FC = () => {
  const { detailItem, setDetailItem, toggleWatchlist, watchlist, likes, setLike, getHistory } = useAppStore();
  const { playMedia } = usePlayerStore();

  const [fullDetail, setFullDetail] = useState<MediaItem | null>(null);
  const [selectedSeasonNumber, setSelectedSeasonNumber] = useState(1);
  const [loading, setLoading] = useState(false);

  const closeModal = () => setDetailItem(null);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') closeModal();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  useEffect(() => {
    if (!detailItem) {
      setFullDetail(null);
      return;
    }

    // Fetch full item hierarchy (seasons and episodes)
    setLoading(true);
    fetch(`/api/item/${detailItem.id}`)
      .then((res) => res.json())
      .then((data) => {
        setFullDetail(data);
        if (data.seasons && data.seasons.length > 0) {
          setSelectedSeasonNumber(data.seasons[0].seasonNumber);
        }
      })
      .catch((err) => {
        console.error('Failed to load item detail:', err);
        setFullDetail(detailItem);
      })
      .finally(() => setLoading(false));
  }, [detailItem]);

  if (!detailItem) return null;

  const currentItem = fullDetail || detailItem;
  const inWatchlist = Boolean(currentItem && watchlist.includes(currentItem.id));
  const isLiked = likes[currentItem.id];
  const history = getHistory(currentItem.id);

  const seasons: Season[] = currentItem.seasons || [];
  const currentSeason = seasons.find((s) => s.seasonNumber === selectedSeasonNumber) || seasons[0];

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 overflow-y-auto bg-black/85 backdrop-blur-md flex justify-center items-start p-0 sm:p-4 md:p-6">
        {/* Backdrop Click Dismiss */}
        <div className="fixed inset-0" onClick={() => setDetailItem(null)} />

        {/* Modal Window Container */}
        <motion.div
          initial={{ opacity: 0, y: 25 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 25 }}
          transition={{ duration: 0.22, ease: [0.16, 1, 0.3, 1] }}
          className="relative w-full max-w-4xl bg-[#181818] rounded-b-none sm:rounded-xl shadow-2xl overflow-hidden z-10 my-0 sm:my-8 text-[#E5E5E5] border-t sm:border border-white/10 min-h-screen sm:min-h-0"
        >
          {/* Close Button */}
          <button
            onClick={() => setDetailItem(null)}
            className="absolute top-3.5 right-3.5 sm:top-4 sm:right-4 z-30 w-9 h-9 rounded-full bg-black/70 hover:bg-black text-white flex items-center justify-center transition-all active:scale-90 shadow-lg border border-white/20"
            title="Close"
          >
            <X className="w-5 h-5" />
          </button>

          {/* Hero Banner Header */}
          <div className="relative aspect-[16/9] w-full bg-black overflow-hidden">
            <img
              src={currentItem.backdrop || currentItem.poster || ''}
              alt={currentItem.title}
              className="w-full h-full object-cover object-top"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-[#181818] via-transparent to-black/30" />

            {/* Banner Floating Actions & Title */}
            <div className="absolute bottom-6 left-6 right-6 space-y-4">
              <h2 className="text-2xl sm:text-4xl font-black text-white drop-shadow-md">
                {currentItem.title}
              </h2>

              <div className="flex flex-wrap items-center gap-2.5 sm:gap-3">
                {/* Play Action */}
                <button
                  onClick={() => {
                    const resume = history ? history.currentTime : undefined;
                    playMedia(currentItem, undefined, selectedSeasonNumber, resume);
                    closeModal();
                  }}
                  className="flex items-center space-x-2 bg-white text-black font-bold px-5 sm:px-6 py-2 sm:py-2.5 rounded hover:bg-white/80 transition-all active:scale-95 shadow text-xs sm:text-sm"
                >
                  <Play className="w-4 h-4 sm:w-5 sm:h-5 fill-black" />
                  <span>{history && history.currentTime > 15 ? 'Resume' : 'Play'}</span>
                </button>

                {/* External VLC Player Mobile Action */}
                {currentItem.streamUrl && (
                  <a
                    href={`vlc://${currentItem.streamUrl}`}
                    className="flex items-center space-x-1.5 bg-black/60 hover:bg-black/90 border border-white/40 text-white font-semibold px-3 py-2 sm:py-2.5 rounded text-xs transition-all active:scale-95"
                    title="Open in VLC App"
                  >
                    <Smartphone className="w-4 h-4 text-[#E50914]" />
                    <span className="hidden sm:inline">VLC App</span>
                  </a>
                )}

                {/* Add to Watchlist */}
                <button
                  onClick={() => {
                    if (currentItem) toggleWatchlist(currentItem);
                  }}
                  className={`w-9 h-9 sm:w-10 sm:h-10 rounded-full border flex items-center justify-center text-white transition-all active:scale-95 ${
                    inWatchlist
                      ? 'border-green-500 bg-green-500/20 text-green-400'
                      : 'border-gray-400 bg-black/40 hover:border-white'
                  }`}
                  title={inWatchlist ? 'Remove from My List' : 'Add to My List'}
                >
                  {inWatchlist ? <Check className="w-4 h-4 sm:w-5 sm:h-5 text-green-400" /> : <Plus className="w-4 h-4 sm:w-5 sm:h-5" />}
                </button>

                {/* Thumbs Up */}
                <button
                  onClick={() => setLike(currentItem.id, true)}
                  className={`w-9 h-9 sm:w-10 sm:h-10 rounded-full border border-gray-400 bg-black/40 hover:border-white flex items-center justify-center text-white transition-colors ${
                    isLiked === true ? 'border-[#E50914] text-[#E50914]' : ''
                  }`}
                >
                  <ThumbsUp className="w-4 h-4 sm:w-5 sm:h-5" />
                </button>

                {/* Direct Download */}
                {currentItem.streamUrl && (
                  <a
                    href={currentItem.streamUrl}
                    download
                    className="w-9 h-9 sm:w-10 sm:h-10 rounded-full border border-gray-400 bg-black/40 hover:border-white flex items-center justify-center text-white transition-colors"
                    title="Download Movie"
                  >
                    <Download className="w-4 h-4 sm:w-5 sm:h-5" />
                  </a>
                )}
              </div>
            </div>
          </div>

          {/* Modal Body Details */}
          <div className="p-6 md:p-8 space-y-8">
            {/* Metadata Info & Synopsis Grid */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-sm">
              <div className="md:col-span-2 space-y-4">
                <div className="flex items-center space-x-3 text-xs sm:text-sm font-semibold">
                  <span className="text-green-400">98% Match</span>
                  <span>{currentItem.year || 2024}</span>
                  <span className="border border-gray-500 px-1.5 py-0.5 rounded text-xs text-gray-400">
                    {currentItem.quality || 'HD'}
                  </span>
                  <span>
                    {currentItem.type === 'series'
                      ? `${currentItem.totalSeasons || 1} Season${(currentItem.totalSeasons || 1) > 1 ? 's' : ''}`
                      : 'Movie'}
                  </span>
                </div>

                <p className="text-gray-300 leading-relaxed text-sm sm:text-base">
                  {currentItem.overview ||
                    `Experience '${currentItem.title}' in stunning ${currentItem.quality || 'HD'} resolution. Directly hosted on the local high-speed ISP storage cluster.`}
                </p>
              </div>

              {/* Attributes Sidebar */}
              <div className="space-y-2 text-xs text-gray-400">
                <p>
                  <span className="text-gray-500">Category:</span>{' '}
                  <span className="text-gray-200">{currentItem.category}</span>
                </p>
                {currentItem.tags && currentItem.tags.length > 0 && (
                  <p>
                    <span className="text-gray-500">Audio/Tags:</span>{' '}
                    <span className="text-gray-200">{currentItem.tags.join(', ')}</span>
                  </p>
                )}
                {currentItem.totalEpisodes && (
                  <p>
                    <span className="text-gray-500">Total Episodes:</span>{' '}
                    <span className="text-gray-200">{currentItem.totalEpisodes}</span>
                  </p>
                )}
              </div>
            </div>

            {/* TV Series Seasons & Episodes Section */}
            {currentItem.type === 'series' && seasons.length > 0 && (
              <div className="space-y-4 pt-4 border-t border-gray-800">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <h3 className="text-lg sm:text-xl font-bold text-white">Episodes</h3>
                    <span className="text-xs text-gray-400 font-mono">
                      ({currentSeason?.episodes.length || 0} Total)
                    </span>
                  </div>

                  {/* Season Dropdown */}
                  {seasons.length > 1 ? (
                    <select
                      value={selectedSeasonNumber}
                      onChange={(e) => setSelectedSeasonNumber(Number(e.target.value))}
                      className="bg-[#242424] hover:bg-[#2e2e2e] text-white text-xs sm:text-sm font-bold border border-gray-700 hover:border-white/40 rounded px-3 py-1.5 focus:outline-none transition-colors cursor-pointer shadow"
                    >
                      {seasons.map((s) => (
                        <option key={s.seasonNumber} value={s.seasonNumber} className="bg-[#181818] py-1">
                          {s.seasonName} ({s.episodes.length} Episodes)
                        </option>
                      ))}
                    </select>
                  ) : (
                    <span className="text-xs font-semibold text-gray-400">
                      Season 1
                    </span>
                  )}
                </div>

                {/* Netflix-Style Episode List */}
                {currentSeason && (
                  <div className="divide-y divide-gray-800/80 border-t border-b border-gray-800/80 max-h-[460px] overflow-y-auto pr-2 no-scrollbar">
                    {currentSeason.episodes.map((ep) => {
                      const epHistory = getHistory(`${currentItem.id}_s${selectedSeasonNumber}_e${ep.episodeNumber}`) || getHistory(currentItem.id);
                      return (
                        <div
                          key={ep.episodeNumber}
                          onClick={() => {
                            playMedia(currentItem, ep, selectedSeasonNumber);
                            closeModal();
                          }}
                          className="flex items-start sm:items-center justify-between p-3 sm:p-4 hover:bg-[#282828]/60 transition-colors cursor-pointer group rounded-md"
                        >
                          <div className="flex items-start sm:items-center space-x-3 sm:space-x-4 flex-1 min-w-0 pr-4">
                            {/* Episode Number */}
                            <span className="text-lg sm:text-2xl font-bold text-gray-500 group-hover:text-white w-6 sm:w-8 text-center shrink-0 pt-3 sm:pt-0">
                              {ep.episodeNumber}
                            </span>

                            {/* 16:9 Thumbnail Preview */}
                            <div className="relative w-28 sm:w-36 aspect-video bg-[#202020] rounded overflow-hidden shrink-0 shadow">
                              <img
                                src={currentItem.backdrop || currentItem.poster || ''}
                                alt={ep.title}
                                loading="lazy"
                                className="w-full h-full object-cover object-top group-hover:scale-105 transition-transform duration-300"
                              />
                              <div className="absolute inset-0 bg-black/40 group-hover:bg-black/20 flex items-center justify-center transition-colors">
                                <div className="w-8 h-8 rounded-full bg-black/70 border border-white flex items-center justify-center group-hover:scale-110 transition-transform shadow">
                                  <Play className="w-3.5 h-3.5 fill-white text-white translate-x-0.5" />
                                </div>
                              </div>
                              {/* Progress bar if watched */}
                              {epHistory && epHistory.percent > 0 && (
                                <div className="absolute bottom-0 inset-x-0 h-1 bg-gray-700">
                                  <div
                                    className="h-full bg-[#E50914]"
                                    style={{ width: `${Math.min(100, Math.max(0, epHistory.percent))}%` }}
                                  />
                                </div>
                              )}
                            </div>

                            {/* Episode Metadata & Synopsis */}
                            <div className="space-y-1 min-w-0 flex-1">
                              <div className="flex items-center justify-between">
                                <h4 className="text-xs sm:text-sm font-bold text-white group-hover:text-[#E50914] transition-colors truncate">
                                  {ep.title}
                                </h4>
                                <span className="text-xs font-mono text-gray-400 shrink-0 ml-2">
                                  {ep.duration ? `${Math.round(ep.duration / 60)}m` : '45m'}
                                </span>
                              </div>
                              <p className="text-[11px] sm:text-xs text-gray-400 line-clamp-2 leading-relaxed">
                                {`Season ${selectedSeasonNumber}, Episode ${ep.episodeNumber}. Stream in full 1080p high definition with instant multi-audio and high-speed BDIX playback.`}
                              </p>
                            </div>
                          </div>

                          {/* Direct Download Icon */}
                          <div className="flex items-center space-x-2 shrink-0">
                            {ep.fileSize && (
                              <span className="text-[11px] font-mono text-gray-500 hidden md:inline">
                                {ep.fileSize}
                              </span>
                            )}
                            <a
                              href={ep.streamUrl}
                              download
                              onClick={(e) => e.stopPropagation()}
                              className="p-2 rounded-full hover:bg-white/10 text-gray-400 hover:text-white transition-colors"
                              title="Download Episode"
                            >
                              <Download className="w-4 h-4" />
                            </a>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            )}

            {/* "More Like This" Recommendations Grid */}
            {currentItem.moreLikeThis && currentItem.moreLikeThis.length > 0 && (
              <div className="space-y-4 pt-6 border-t border-gray-800">
                <h3 className="text-xl font-bold text-white">More Like This</h3>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  {currentItem.moreLikeThis.map((sim) => (
                    <div
                      key={sim.id}
                      onClick={() => setDetailItem(sim)}
                      className="bg-[#242424] rounded overflow-hidden cursor-pointer hover:border-white/30 border border-transparent transition-all group"
                    >
                      <div className="aspect-[16/9] w-full bg-black overflow-hidden relative">
                        <img
                          src={sim.backdrop || sim.poster || ''}
                          alt={sim.title}
                          className="w-full h-full object-cover object-top group-hover:scale-105 transition-transform"
                        />
                        <div className="absolute top-2 right-2 bg-black/70 px-1 rounded text-[10px] text-gray-200">
                          {sim.quality || 'HD'}
                        </div>
                      </div>
                      <div className="p-3 space-y-1">
                        <p className="text-xs font-bold text-white truncate">{sim.title}</p>
                        <p className="text-[10px] text-gray-400">{sim.year || 'Classic'}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
