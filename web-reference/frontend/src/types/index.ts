export interface Episode {
  episodeNumber: number;
  title: string;
  fileName: string;
  streamUrl: string;
  fileSize?: string;
  duration?: number;
}

export interface Season {
  seasonNumber: number;
  seasonName: string;
  episodes: Episode[];
}

export interface MediaItem {
  id: string;
  type: 'movie' | 'series';
  title: string;
  rawName?: string;
  year?: number | null;
  quality?: string;
  category: string;
  tags?: string[];
  poster?: string | null;
  backdrop?: string | null;
  streamUrl?: string | null;
  overview?: string;
  totalSeasons?: number | null;
  totalEpisodes?: number | null;
  seasons?: Season[];
  moreLikeThis?: MediaItem[];
}

export interface CategoryRow {
  id: string;
  title: string;
  items: MediaItem[];
  isTop10?: boolean;
}

export interface WatchProgress {
  mediaId: string;
  episodeNumber?: number;
  seasonNumber?: number;
  currentTime: number;
  duration: number;
  percent: number;
  updatedAt: number;
  title: string;
  poster?: string | null;
  type: 'movie' | 'series';
}
