import React, { useState, useEffect } from 'react';
import { Sparkles, Sliders } from 'lucide-react';
import { Navbar } from './components/Navbar';
import { BillboardHero } from './components/BillboardHero';
import { ContentRow } from './components/ContentRow';
import { DetailModal } from './components/DetailModal';
import { NetflixPlayer } from './components/NetflixPlayer';
import { SearchModal } from './components/SearchModal';
import { MediaCard } from './components/MediaCard';
import { PreferencesModal } from './components/PreferencesModal';
import { NetworkGuard } from './components/NetworkGuard';
import { MediaItem, CategoryRow } from './types';
import { useAppStore } from './store/useAppStore';

interface PrefConfig {
  rowIds: string[];
  label: string;
  badge: string;
  personalizedTitle: string;
}

const PREF_CONFIG: Record<string, PrefConfig> = {
  'anime': {
    rowIds: ['anime-hits', 'anime-cartoons'],
    label: 'Anime & Manga Hits',
    badge: '⚔️ Anime',
    personalizedTitle: 'Because you love Anime: ⚔️ Trending Anime Hits'
  },
  'action': {
    rowIds: ['action-thrillers', 'top-1080p'],
    label: 'Action & Blockbusters',
    badge: '🍿 Action',
    personalizedTitle: 'Because you love Action: 🍿 Blockbuster Explosive Thrillers'
  },
  'tv-series': {
    rowIds: ['tv-series', 'top-10-tv'],
    label: 'Binge-Worthy TV Series',
    badge: '📺 TV Series',
    personalizedTitle: 'Because you love TV Series: 📺 Binge-Worthy TV & Web Series'
  },
  'korean': {
    rowIds: ['korean-tv'],
    label: 'K-Drama Sensations',
    badge: '💖 K-Drama',
    personalizedTitle: 'Because you love K-Drama: 💖 Hot K-Drama Sensations'
  },
  'sci-fi': {
    rowIds: ['sci-fi'],
    label: 'Sci-Fi & Cyberpunk',
    badge: '🚀 Sci-Fi',
    personalizedTitle: 'Because you love Sci-Fi: 🚀 Mind-Bending Sci-Fi & Cyberpunk'
  },
  'horror-thriller': {
    rowIds: ['horror-thriller'],
    label: 'Supernatural Horror',
    badge: '🩸 Horror',
    personalizedTitle: 'Because you love Horror: 🩸 Supernatural Horror & Chilling Mysteries'
  },
  'crime-mystery': {
    rowIds: ['crime-mystery'],
    label: 'Crime, Mafia & Heists',
    badge: '🔪 Crime & Heist',
    personalizedTitle: 'Because you love Crime & Thrillers: 🔪 Dark Heists & Psychological Thrillers'
  },
  'romance-drama': {
    rowIds: ['romance-drama'],
    label: 'Romance & Heartfelt Drama',
    badge: '✨ Romance',
    personalizedTitle: 'Because you love Romance: ✨ Romantic Comedies & Heartfelt Dramas'
  },
  'fantasy-adventure': {
    rowIds: ['fantasy-adventure'],
    label: 'High Fantasy & Epics',
    badge: '🐉 Fantasy',
    personalizedTitle: 'Because you love Fantasy: 🐉 High Fantasy & Mythological Epics'
  },
  'comedy': {
    rowIds: ['comedy'],
    label: 'Comedy & Feel-Good',
    badge: '😂 Comedy',
    personalizedTitle: 'Because you love Comedies: 😂 Feel-Good Comedies & Specials'
  },
  'hollywood-1080p': {
    rowIds: ['top-1080p', 'latest-2026'],
    label: 'Hollywood 1080p Cinema',
    badge: '🎬 1080p Full HD',
    personalizedTitle: 'Because you love Hollywood: 🌟 Top 1080p Full HD Blockbusters'
  },
  'hindi': {
    rowIds: ['hindi-cinema'],
    label: 'Bollywood & Hindi Cinema',
    badge: '🇮🇳 Bollywood',
    personalizedTitle: 'Because you love Bollywood: 🇮🇳 Latest Bollywood & Hindi Cinema'
  },
  'south-indian': {
    rowIds: ['south-indian'],
    label: 'South Indian Mass Action',
    badge: '💥 Mass Action',
    personalizedTitle: 'Because you love Mass Action: 💥 South Indian Mass Action & Entertainers'
  },
  'kolkata-bangla': {
    rowIds: ['kolkata-bangla'],
    label: 'Kolkata Bangla Cinema',
    badge: '🎭 Kolkata Bangla',
    personalizedTitle: 'Because you love Bangla Cinema: 🎭 Kolkata Bangla Cinema & Classics'
  },
  'imdb-classics': {
    rowIds: ['imdb-top-250'],
    label: 'IMDb Top Rated Classics',
    badge: '⭐ IMDb 8.5+',
    personalizedTitle: 'Because you love Classics: ⭐ Critically Acclaimed IMDb Top-250'
  },
  'animation': {
    rowIds: ['animation'],
    label: 'Animated Family & Pixar',
    badge: '🎨 Animation',
    personalizedTitle: 'Because you love Animation: 🎨 Animated Family Hits'
  },
  'documentary': {
    rowIds: ['documentaries'],
    label: 'Documentaries & True Crime',
    badge: '🌍 Docu',
    personalizedTitle: 'Because you love Documentaries: 🌍 Eye-Opening Documentaries'
  },
  'movies-3d': {
    rowIds: ['movies-3d'],
    label: '3D & IMAX Experiences',
    badge: '👓 3D / IMAX',
    personalizedTitle: 'Because you love 3D & IMAX: 👓 3D & IMAX High-Definition Experiences'
  }
};

export const App: React.FC = () => {
  const [featured, setFeatured] = useState<MediaItem[]>([]);
  const [rows, setRows] = useState<CategoryRow[]>([]);
  const [categoryView, setCategoryView] = useState<{ slug: string; items: MediaItem[]; page: number } | null>(null);
  const [loading, setLoading] = useState(true);

  const {
    activeTab,
    setActiveTab,
    history,
    watchlist,
    watchlistItemMap,
    preferences,
    setIsPreferencesModalOpen
  } = useAppStore();

  // Load home data
  useEffect(() => {
    Promise.all([
      fetch('/api/featured').then((r) => r.json()),
      fetch('/api/rows').then((r) => r.json())
    ])
      .then(([featuredData, rowsData]) => {
        setFeatured(featuredData);
        setRows(rowsData);
      })
      .catch((err) => console.error('Error loading home feed:', err))
      .finally(() => setLoading(false));
  }, []);

  // Handle category tab change
  const handleSelectCategory = (categorySlug: string | null) => {
    if (!categorySlug || categorySlug === 'mylist') {
      setCategoryView(null);
      return;
    }

    setLoading(true);
    fetch(`/api/category/${categorySlug}?page=1&limit=48`)
      .then((r) => r.json())
      .then((data) => {
        setCategoryView({
          slug: categorySlug,
          items: data.items,
          page: 1
        });
      })
      .catch((err) => console.error('Category error:', err))
      .finally(() => setLoading(false));
  };

  // Build "Continue Watching" Row from history
  const continueWatchingItems: MediaItem[] = Object.values(history)
    .filter((h) => h.percent > 1 && h.percent < 95)
    .sort((a, b) => b.updatedAt - a.updatedAt)
    .map((h) => ({
      id: h.mediaId,
      title: h.title,
      type: h.type,
      category: 'In Progress',
      poster: h.poster,
      backdrop: h.poster
    }));

  // Build Deduplicated "My List" Items
  const seenIds = new Set<string>();
  const mylistItems: MediaItem[] = [];

  const storedItems = Object.values(watchlistItemMap || {});
  storedItems.forEach((item) => {
    if (watchlist.includes(item.id) && !seenIds.has(item.id)) {
      seenIds.add(item.id);
      mylistItems.push(item);
    }
  });

  const allKnownItems = rows.flatMap((r) => r.items);
  allKnownItems.forEach((item) => {
    if (watchlist.includes(item.id) && !seenIds.has(item.id)) {
      seenIds.add(item.id);
      mylistItems.push(item);
    }
  });

  // Personalization Engine: Prioritize and customize rows based on taste profile
  const top10Rows = rows.filter((r) => r.isTop10);
  const regularRows = rows.filter((r) => !r.isTop10);

  const personalizedRows: CategoryRow[] = [];
  const processedRowIds = new Set<string>();

  // Boost and re-title rows matching user's selected preferences in order
  preferences.forEach((prefId) => {
    const config = PREF_CONFIG[prefId];
    if (!config) return;

    config.rowIds.forEach((targetRowId, idx) => {
      if (processedRowIds.has(targetRowId)) return;
      const matchedRow = regularRows.find((r) => r.id === targetRowId);
      if (matchedRow && matchedRow.items.length > 0) {
        processedRowIds.add(targetRowId);
        personalizedRows.push({
          ...matchedRow,
          title: idx === 0 
            ? config.personalizedTitle 
            : `More ${config.label}: ${matchedRow.title.replace(/^[^\w\s]+/, '').trim()}`
        });
      }
    });
  });

  // Remaining catalog rows not in user's direct preferences
  const remainingRows = regularRows.filter((r) => !processedRowIds.has(r.id));

  // Build dynamic "🎯 Top Picks for You" row blended from user's chosen tastes
  const topPicksItems: MediaItem[] = [];
  const pickedIds = new Set<string>();

  const sourceRowsForPicks = personalizedRows.length > 0 ? personalizedRows : regularRows;
  sourceRowsForPicks.forEach((r) => {
    r.items.slice(0, 4).forEach((item) => {
      if (!pickedIds.has(item.id)) {
        topPicksItems.push(item);
        pickedIds.add(item.id);
      }
    });
  });

  const displayRows: CategoryRow[] = [
    ...top10Rows,
    ...(topPicksItems.length > 0
      ? [
          {
            id: 'top-picks-for-you',
            title: preferences.length > 0
              ? `🎯 Top Picks for You (${preferences.length} Tastes Blended)`
              : '🎯 Top Picks for You',
            items: topPicksItems
          }
        ]
      : []),
    ...personalizedRows,
    ...remainingRows
  ];

  return (
    <NetworkGuard>
      <div className="min-h-screen bg-[#141414] text-[#E5E5E5] flex flex-col font-sans relative selection:bg-[#E50914] selection:text-white">
      {/* Top Navbar */}
      <Navbar onSelectCategory={handleSelectCategory} />

      {/* Main Content Area */}
      {activeTab === 'mylist' ? (
        /* Dedicated My List View */
        <main className="flex-1 pt-24 px-4 md:px-12 pb-16">
          <h1 className="text-2xl sm:text-3xl font-black text-white mb-6">My List</h1>
          {mylistItems.length > 0 ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 sm:gap-6 md:gap-8 gap-y-10">
              {mylistItems.map((item, idx) => (
                <MediaCard 
                  key={item.id} 
                  item={item} 
                  isGrid={true} 
                  index={idx} 
                  totalItems={mylistItems.length} 
                />
              ))}
            </div>
          ) : (
            <div className="py-24 text-center space-y-3">
              <p className="text-gray-400 text-base">You haven't added any titles to your list yet.</p>
              <button
                onClick={() => setActiveTab('home')}
                className="bg-white text-black font-bold px-6 py-2 rounded text-sm hover:bg-white/80 transition-colors"
              >
                Explore Titles
              </button>
            </div>
          )}
        </main>
      ) : categoryView ? (
        /* Dedicated Category Grid View */
        <main className="flex-1 pt-24 px-4 md:px-12 pb-16">
          <div className="flex items-center justify-between mb-6">
            <h1 className="text-2xl sm:text-3xl font-black text-white capitalize">
              {categoryView.slug.replace('-', ' ')}
            </h1>
            <button
              onClick={() => setCategoryView(null)}
              className="text-xs uppercase font-bold text-gray-400 hover:text-white"
            >
              Back to Home
            </button>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 sm:gap-6 md:gap-8 gap-y-10">
            {categoryView.items.map((item, idx) => (
              <MediaCard 
                key={item.id} 
                item={item} 
                isGrid={true} 
                index={idx} 
                totalItems={categoryView.items.length} 
              />
            ))}
          </div>
        </main>
      ) : (
        /* Default Home Feed */
        <main className="flex-1 pb-16">
          {/* Billboard Hero Banner */}
          {featured.length > 0 && <BillboardHero featured={featured} />}

          {/* Interactive Taste Profile Pill Bar */}
          {preferences.length > 0 && (
            <div 
              data-testid="taste-pill-bar"
              id="taste-pill-bar"
              className="relative z-30 px-4 md:px-12 -mt-12 sm:-mt-16 mb-3 flex items-center space-x-2 overflow-x-auto no-scrollbar py-2"
            >
              <div className="flex items-center space-x-1.5 text-[11px] sm:text-xs font-bold text-gray-300 uppercase tracking-wider shrink-0 bg-black/85 backdrop-blur-md px-3 py-1.5 rounded-full border border-white/10 shadow-lg">
                <Sparkles className="w-3.5 h-3.5 text-[#E50914]" />
                <span>Your Tastes:</span>
              </div>
              {preferences.map((p) => {
                const config = PREF_CONFIG[p];
                if (!config) return null;
                return (
                  <span
                    key={p}
                    className="text-xs font-semibold px-3 py-1.5 rounded-full bg-black/75 backdrop-blur-md border border-white/15 text-gray-200 shrink-0 flex items-center space-x-1 shadow-sm"
                  >
                    <span>{config.badge}</span>
                  </span>
                );
              })}
              <button
                onClick={() => setIsPreferencesModalOpen(true)}
                className="text-xs font-bold px-3 py-1.5 rounded-full bg-[#E50914]/20 hover:bg-[#E50914] text-[#E50914] hover:text-white border border-[#E50914]/40 transition-all shrink-0 flex items-center space-x-1 shadow-sm active:scale-95"
                title="Edit your Netflix taste preferences"
              >
                <Sliders className="w-3 h-3" />
                <span>Personalize</span>
              </button>
            </div>
          )}

          {/* Prominent "Continue Watching" Row */}
          {continueWatchingItems.length > 0 && (
            <div className="relative -mt-4 mb-2 z-20">
              <ContentRow title="⏳ Continue Watching" items={continueWatchingItems} />
            </div>
          )}

          {/* Curated & Personalized Content Rows */}
          <div className={`space-y-2 relative z-20 ${
            continueWatchingItems.length > 0 
              ? 'mt-2' 
              : preferences.length > 0 
              ? 'mt-1 sm:mt-2' 
              : '-mt-16 sm:-mt-24'
          }`}>
            {displayRows.map((row) => (
              <ContentRow key={row.id} title={row.title} items={row.items} isTop10={row.isTop10} />
            ))}
          </div>
        </main>
      )}

      {/* Footer */}
      <footer className="mt-auto border-t border-gray-800 py-10 px-4 md:px-12 text-gray-500 text-xs space-y-4">
        <p className="font-semibold text-gray-400">Questions? Contact your ISP Network Administrator.</p>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <span>FAQ</span>
          <span>Help Center</span>
          <span>Media Centers</span>
          <span>Terms of Use</span>
          <span>Privacy</span>
          <span>Speed Test</span>
          <span>Corporate Info</span>
          <span>HomeFlix Originals</span>
        </div>
        <p className="text-[11px] pt-4">© 2026 HomeFlix Media Cloud. High-Performance Personal Entertainment.</p>
      </footer>

      {/* Floating Modals and Player Engine */}
      <PreferencesModal />
      <DetailModal />
      <SearchModal />
      <NetflixPlayer />
    </div>
  </NetworkGuard>
  );
};
export default App;
