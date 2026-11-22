import { create } from 'zustand';
import { MediaItem, Episode } from '../types';

interface PlayerState {
  isOpen: boolean;
  activeItem: MediaItem | null;
  activeEpisode: Episode | null;
  activeSeasonNumber: number;
  
  resumeTime: number | null;
  showResumePrompt: boolean;
  setShowResumePrompt: (show: boolean) => void;

  nextEpisodeCountdown: number | null;
  setNextEpisodeCountdown: (cd: number | null) => void;

  isDrawerOpen: boolean;
  setIsDrawerOpen: (open: boolean) => void;

  playMedia: (item: MediaItem, episode?: Episode, seasonNumber?: number, startTime?: number) => void;
  playNextEpisode: () => void;
  closePlayer: () => void;
}

export const usePlayerStore = create<PlayerState>((set, get) => ({
  isOpen: false,
  activeItem: null,
  activeEpisode: null,
  activeSeasonNumber: 1,

  resumeTime: null,
  showResumePrompt: false,
  setShowResumePrompt: (show) => set({ showResumePrompt: show }),

  nextEpisodeCountdown: null,
  setNextEpisodeCountdown: (cd) => set({ nextEpisodeCountdown: cd }),

  isDrawerOpen: false,
  setIsDrawerOpen: (open) => set({ isDrawerOpen: open }),

  playMedia: (item, episode, seasonNumber = 1, startTime) => {
    let ep = episode;
    // If it is a series and no episode was passed, pick the first episode of the specified season
    if (item.type === 'series' && !ep && item.seasons && item.seasons.length > 0) {
      const season = item.seasons.find(s => s.seasonNumber === seasonNumber) || item.seasons[0];
      ep = season.episodes[0];
    }

    set({
      isOpen: true,
      activeItem: item,
      activeEpisode: ep || null,
      activeSeasonNumber: seasonNumber,
      resumeTime: startTime && startTime > 15 ? startTime : null,
      showResumePrompt: !!(startTime && startTime > 15),
      nextEpisodeCountdown: null,
      isDrawerOpen: false
    });
  },

  playNextEpisode: () => {
    const { activeItem, activeEpisode, activeSeasonNumber } = get();
    if (!activeItem || activeItem.type !== 'series' || !activeItem.seasons) return;

    const currentSeason = activeItem.seasons.find(s => s.seasonNumber === activeSeasonNumber);
    if (!currentSeason) return;

    const epIndex = currentSeason.episodes.findIndex(e => e.episodeNumber === activeEpisode?.episodeNumber);
    if (epIndex !== -1 && epIndex < currentSeason.episodes.length - 1) {
      // Next episode in current season
      const nextEp = currentSeason.episodes[epIndex + 1];
      set({
        activeEpisode: nextEp,
        resumeTime: null,
        showResumePrompt: false,
        nextEpisodeCountdown: null
      });
    } else {
      // Check if next season exists
      const nextSeason = activeItem.seasons.find(s => s.seasonNumber === activeSeasonNumber + 1);
      if (nextSeason && nextSeason.episodes.length > 0) {
        set({
          activeSeasonNumber: nextSeason.seasonNumber,
          activeEpisode: nextSeason.episodes[0],
          resumeTime: null,
          showResumePrompt: false,
          nextEpisodeCountdown: null
        });
      }
    }
  },

  closePlayer: () => {
    set({
      isOpen: false,
      activeItem: null,
      activeEpisode: null,
      resumeTime: null,
      showResumePrompt: false,
      nextEpisodeCountdown: null,
      isDrawerOpen: false
    });
  }
}));
