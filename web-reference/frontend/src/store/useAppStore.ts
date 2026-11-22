import { create } from 'zustand';
import { MediaItem, WatchProgress } from '../types';

interface AppState {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  
  detailItem: MediaItem | null;
  setDetailItem: (item: MediaItem | null) => void;

  isSearchOpen: boolean;
  setIsSearchOpen: (open: boolean) => void;
  searchQuery: string;
  setSearchQuery: (q: string) => void;

  watchlist: string[]; // item IDs
  watchlistItemMap: Record<string, MediaItem>;
  toggleWatchlist: (item: MediaItem) => void;
  isInWatchlist: (id: string) => boolean;

  likes: Record<string, boolean>; // id -> true (up), false (down)
  setLike: (id: string, isUp: boolean) => void;

  preferences: string[];
  setPreferences: (genres: string[]) => void;
  hasCompletedOnboarding: boolean;
  setHasCompletedOnboarding: (completed: boolean) => void;
  isPreferencesModalOpen: boolean;
  setIsPreferencesModalOpen: (open: boolean) => void;

  history: Record<string, WatchProgress>;
  updateHistory: (progress: WatchProgress) => void;
  getHistory: (mediaId: string) => WatchProgress | undefined;
  clearHistory: (mediaId: string) => void;
}

const STORAGE_KEY_WATCHLIST = 'homeflix_watchlist';
const STORAGE_KEY_LIKES = 'homeflix_likes';
const STORAGE_KEY_HISTORY = 'homeflix_history';
const STORAGE_KEY_PREFERENCES = 'homeflix_preferences';
const STORAGE_KEY_ONBOARDING = 'homeflix_onboarding_done';

function loadFromStorage<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key) || localStorage.getItem(key.replace('homeflix_', 'dhakaflix_'));
    return raw ? JSON.parse(raw) : fallback;
  } catch {
    return fallback;
  }
}

export const useAppStore = create<AppState>((set, get) => ({
  activeTab: 'home',
  setActiveTab: (tab) => set({ activeTab: tab }),

  detailItem: null,
  setDetailItem: (item) => set({ detailItem: item }),

  isSearchOpen: false,
  setIsSearchOpen: (open) => set({ isSearchOpen: open }),
  searchQuery: '',
  setSearchQuery: (q) => set({ searchQuery: q }),

  watchlist: loadFromStorage<string[]>(STORAGE_KEY_WATCHLIST, []),
  watchlistItemMap: loadFromStorage<Record<string, MediaItem>>('homeflix_watchlist_map', {}),
  toggleWatchlist: (item) => {
    const current = get().watchlist;
    const currentMap = get().watchlistItemMap || {};
    const exists = current.includes(item.id);
    const updated = exists ? current.filter(id => id !== item.id) : [...current, item.id];
    const updatedMap = { ...currentMap };
    if (exists) {
      delete updatedMap[item.id];
    } else {
      updatedMap[item.id] = item;
    }
    localStorage.setItem(STORAGE_KEY_WATCHLIST, JSON.stringify(updated));
    localStorage.setItem('homeflix_watchlist_map', JSON.stringify(updatedMap));
    set({ watchlist: updated, watchlistItemMap: updatedMap });
  },
  isInWatchlist: (id) => get().watchlist.includes(id),

  likes: loadFromStorage<Record<string, boolean>>(STORAGE_KEY_LIKES, {}),
  setLike: (id, isUp) => {
    const current = { ...get().likes };
    if (current[id] === isUp) {
      delete current[id];
    } else {
      current[id] = isUp;
    }
    localStorage.setItem(STORAGE_KEY_LIKES, JSON.stringify(current));
    set({ likes: current });
  },

  preferences: loadFromStorage<string[]>(STORAGE_KEY_PREFERENCES, []),
  setPreferences: (genres) => {
    localStorage.setItem(STORAGE_KEY_PREFERENCES, JSON.stringify(genres));
    set({ preferences: genres });
  },

  hasCompletedOnboarding: loadFromStorage<boolean>(STORAGE_KEY_ONBOARDING, false),
  setHasCompletedOnboarding: (completed) => {
    localStorage.setItem(STORAGE_KEY_ONBOARDING, JSON.stringify(completed));
    set({ hasCompletedOnboarding: completed });
  },

  isPreferencesModalOpen: false,
  setIsPreferencesModalOpen: (open) => set({ isPreferencesModalOpen: open }),

  history: loadFromStorage<Record<string, WatchProgress>>(STORAGE_KEY_HISTORY, {}),
  updateHistory: (progress) => {
    const updated = {
      ...get().history,
      [progress.mediaId]: progress
    };
    localStorage.setItem(STORAGE_KEY_HISTORY, JSON.stringify(updated));
    set({ history: updated });
  },
  getHistory: (mediaId) => get().history[mediaId],
  clearHistory: (mediaId) => {
    const updated = { ...get().history };
    delete updated[mediaId];
    localStorage.setItem(STORAGE_KEY_HISTORY, JSON.stringify(updated));
    set({ history: updated });
  }
}));
