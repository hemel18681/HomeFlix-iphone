import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Check, Sparkles, X, RotateCcw, CheckCheck } from 'lucide-react';
import { useAppStore } from '../store/useAppStore';

export interface GenreOption {
  id: string;
  label: string;
  subtitle: string;
  badge: string;
  gradient: string;
}

export const GENRE_OPTIONS: GenreOption[] = [
  {
    id: 'anime',
    label: 'Anime & Manga Hits',
    subtitle: 'Solo Leveling, Dandadan, Frieren, Jujutsu',
    badge: '⚔️ Anime',
    gradient: 'from-purple-900/80 to-indigo-950/90'
  },
  {
    id: 'action',
    label: 'Action & Blockbusters',
    subtitle: 'Deadpool, Top Gun, Mission Impossible, Mad Max',
    badge: '🍿 Action',
    gradient: 'from-red-950/80 to-zinc-900/90'
  },
  {
    id: 'tv-series',
    label: 'Binge-Worthy TV Series',
    subtitle: 'Stranger Things, Squid Game, Witcher, Marshals',
    badge: '📺 TV Series',
    gradient: 'from-blue-950/80 to-slate-900/90'
  },
  {
    id: 'korean',
    label: 'K-Drama Sensations',
    subtitle: 'Crash Landing on You, Queen of Tears, Glory',
    badge: '💖 K-Drama',
    gradient: 'from-pink-950/80 to-rose-950/90'
  },
  {
    id: 'sci-fi',
    label: 'Sci-Fi & Cyberpunk',
    subtitle: 'Dune, Interstellar, Matrix, Blade Runner, Tenet',
    badge: '🚀 Sci-Fi',
    gradient: 'from-cyan-950/80 to-indigo-950/90'
  },
  {
    id: 'horror-thriller',
    label: 'Supernatural Horror',
    subtitle: 'The Conjuring, A Quiet Place, Smile, Alien',
    badge: '🩸 Horror',
    gradient: 'from-emerald-950/80 to-stone-950/90'
  },
  {
    id: 'crime-mystery',
    label: 'Crime, Mafia & Heists',
    subtitle: 'Breaking Bad, Peaky Blinders, Money Heist, Narcos',
    badge: '🔪 Crime & Heist',
    gradient: 'from-zinc-900/90 to-stone-900/90'
  },
  {
    id: 'romance-drama',
    label: 'Romance & Heartfelt Drama',
    subtitle: 'La La Land, Past Lives, Titanic, About Time',
    badge: '✨ Romance',
    gradient: 'from-rose-900/80 to-pink-950/90'
  },
  {
    id: 'fantasy-adventure',
    label: 'High Fantasy & Epics',
    subtitle: 'Lord of the Rings, House of the Dragon, Hobbit',
    badge: '🐉 Fantasy',
    gradient: 'from-amber-900/80 to-yellow-950/90'
  },
  {
    id: 'comedy',
    label: 'Comedy & Feel-Good',
    subtitle: 'The Office, Friends, Brooklyn 99, Deadpool',
    badge: '😂 Comedy',
    gradient: 'from-amber-950/80 to-orange-950/90'
  },
  {
    id: 'hollywood-1080p',
    label: 'Hollywood 1080p Cinema',
    subtitle: 'Oppenheimer, Cold Storage, Marvel Universe',
    badge: '🎬 1080p Full HD',
    gradient: 'from-blue-900/80 to-stone-900/90'
  },
  {
    id: 'hindi',
    label: 'Bollywood & Hindi Cinema',
    subtitle: 'Jawan, Animal, Pathaan, Stree 2, Sholay',
    badge: '🇮🇳 Bollywood',
    gradient: 'from-orange-900/80 to-zinc-900/90'
  },
  {
    id: 'south-indian',
    label: 'South Indian Mass Action',
    subtitle: 'RRR, KGF, Pushpa, Salaar, Kalki 2898 AD',
    badge: '💥 Mass Action',
    gradient: 'from-red-900/80 to-stone-950/90'
  },
  {
    id: 'kolkata-bangla',
    label: 'Kolkata Bangla Cinema',
    subtitle: 'Feluda, Byomkesh, Chander Pahar, Tollywood',
    badge: '🎭 Kolkata Bangla',
    gradient: 'from-emerald-900/80 to-teal-950/90'
  },
  {
    id: 'imdb-classics',
    label: 'IMDb Top Rated Classics',
    subtitle: 'The Godfather, Shawshank, Dark Knight, Nolan',
    badge: '⭐ IMDb 8.5+',
    gradient: 'from-yellow-900/80 to-neutral-900/90'
  },
  {
    id: 'animation',
    label: 'Animated Family & Pixar',
    subtitle: 'Spider-Verse, Toy Story, Moana 2, Inside Out 2',
    badge: '🎨 Animation',
    gradient: 'from-sky-950/80 to-blue-950/90'
  },
  {
    id: 'documentary',
    label: 'Documentaries & True Crime',
    subtitle: 'Wild Life, Tech Giants, True Crime & History',
    badge: '🌍 Docu',
    gradient: 'from-teal-950/80 to-slate-950/90'
  },
  {
    id: 'movies-3d',
    label: '3D & IMAX Experiences',
    subtitle: 'Avatar, Gravity, Life of Pi, 3D Masterpieces',
    badge: '👓 3D / IMAX',
    gradient: 'from-purple-950/80 to-violet-950/90'
  }
];

export const PreferencesModal: React.FC = () => {
  const {
    preferences,
    setPreferences,
    hasCompletedOnboarding,
    setHasCompletedOnboarding,
    isPreferencesModalOpen,
    setIsPreferencesModalOpen
  } = useAppStore();

  const [selected, setSelected] = useState<string[]>(
    preferences.length > 0 ? preferences : ['anime', 'action', 'sci-fi']
  );

  const isOpen = !hasCompletedOnboarding || isPreferencesModalOpen;

  if (!isOpen) return null;

  const toggleGenre = (id: string) => {
    setSelected((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  const handleSelectAll = () => {
    setSelected(GENRE_OPTIONS.map((g) => g.id));
  };

  const handleClear = () => {
    setSelected([]);
  };

  const handleSave = () => {
    setPreferences(selected);
    setHasCompletedOnboarding(true);
    setIsPreferencesModalOpen(false);
  };

  const handleSkip = () => {
    if (selected.length === 0) {
      setPreferences(['action', 'tv-series', 'sci-fi']);
    } else {
      setPreferences(selected);
    }
    setHasCompletedOnboarding(true);
    setIsPreferencesModalOpen(false);
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 overflow-y-auto bg-black/85 backdrop-blur-md flex items-center justify-center p-3 sm:p-6 animate-in fade-in duration-300">
        {/* Backdrop Dismiss */}
        <div className="fixed inset-0" onClick={handleSkip} />

        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          transition={{ type: 'spring', damping: 25, stiffness: 300 }}
          className="relative w-full max-w-4xl bg-[#181818] border border-gray-700/80 rounded-xl shadow-2xl p-4 sm:p-7 space-y-4 sm:space-y-5 text-white my-auto max-h-[90vh] flex flex-col z-10"
        >
          {/* Close button always accessible */}
          <button
            onClick={handleSkip}
            className="absolute top-3.5 right-3.5 p-1.5 rounded-full bg-black/50 hover:bg-white/20 text-gray-400 hover:text-white transition-colors z-20"
            title="Close"
          >
            <X className="w-5 h-5" />
          </button>

          {/* Header */}
          <div className="space-y-1.5 text-center max-w-xl mx-auto shrink-0 pt-1">
            <div className="inline-flex items-center space-x-1.5 px-3 py-1 rounded-full bg-[#E50914]/20 text-[#E50914] text-xs font-bold uppercase tracking-wider mb-1">
              <Sparkles className="w-3.5 h-3.5" />
              <span>Netflix Taste Personalization</span>
            </div>
            <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
              What do you love to watch?
            </h2>
            <p className="text-xs sm:text-sm text-gray-400">
              Select 3 or more genres to customize your recommendation rows, Top Picks, and taste matches.
            </p>

            {/* Quick Helper Actions */}
            <div className="flex items-center justify-center space-x-3 pt-1 text-[11px] text-gray-400">
              <button
                onClick={handleSelectAll}
                className="hover:text-white flex items-center space-x-1 px-2 py-0.5 rounded bg-white/5 hover:bg-white/10 transition-colors"
              >
                <CheckCheck className="w-3 h-3 text-red-500" />
                <span>Select All ({GENRE_OPTIONS.length})</span>
              </button>
              <span className="text-gray-600">•</span>
              <button
                onClick={handleClear}
                className="hover:text-white flex items-center space-x-1 px-2 py-0.5 rounded bg-white/5 hover:bg-white/10 transition-colors"
              >
                <RotateCcw className="w-3 h-3 text-gray-400" />
                <span>Reset</span>
              </button>
            </div>
          </div>

          {/* Genre Selection Grid (Scrollable) */}
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-3 lg:grid-cols-3 gap-3 overflow-y-auto p-1 pr-2 max-h-[52vh] rounded-lg">
            {GENRE_OPTIONS.map((g) => {
              const isSelected = selected.includes(g.id);
              return (
                <div
                  key={g.id}
                  onClick={() => toggleGenre(g.id)}
                  className={`relative p-3.5 sm:p-4 rounded-lg cursor-pointer transition-all border text-left select-none bg-gradient-to-br ${g.gradient} ${
                    isSelected
                      ? 'border-[#E50914] shadow-lg shadow-red-950/50 ring-1 ring-[#E50914] scale-[1.01] bg-opacity-100'
                      : 'border-white/10 hover:border-white/30 opacity-75 hover:opacity-100 hover:scale-[1.005]'
                  }`}
                >
                  {/* Selected Checkmark Badge */}
                  <div className="flex items-start justify-between mb-2">
                    <span className="text-[10px] font-bold text-gray-200 font-mono tracking-wide">
                      {g.badge}
                    </span>
                    <div
                      className={`w-5 h-5 rounded-full flex items-center justify-center transition-all ${
                        isSelected ? 'bg-[#E50914] text-white shadow-sm ring-2 ring-red-500/40' : 'border border-white/30 bg-black/30'
                      }`}
                    >
                      {isSelected && <Check className="w-3 h-3 stroke-[3]" />}
                    </div>
                  </div>

                  <p className="text-xs sm:text-sm font-bold text-white leading-tight">
                    {g.label}
                  </p>
                  <p className="text-[10px] text-gray-300/80 truncate mt-1">
                    {g.subtitle}
                  </p>
                </div>
              );
            })}
          </div>

          {/* Footer Actions */}
          <div className="flex items-center justify-between pt-3 border-t border-gray-800 shrink-0">
            <div className="flex items-center space-x-2 text-xs">
              <span className="text-gray-400">
                <strong className="text-white font-bold">{selected.length}</strong> of {GENRE_OPTIONS.length} selected
              </span>
              {selected.length >= 3 ? (
                <span className="text-emerald-400 font-semibold text-[11px] hidden sm:inline">
                  ✓ Tailored feed ready
                </span>
              ) : (
                <span className="text-amber-400 text-[11px] hidden sm:inline">
                  (Pick at least 3 for best results)
                </span>
              )}
            </div>

            <div className="flex items-center space-x-3">
              {!hasCompletedOnboarding && (
                <button
                  onClick={handleSkip}
                  className="px-3 py-2 text-xs font-semibold text-gray-400 hover:text-white transition-colors"
                >
                  Skip for now
                </button>
              )}
              <button
                onClick={handleSave}
                disabled={selected.length === 0}
                className="bg-[#E50914] hover:bg-red-700 disabled:bg-gray-800 disabled:text-gray-500 text-white font-bold px-6 py-2.5 rounded text-xs sm:text-sm transition-all shadow-md active:scale-95 flex items-center space-x-2"
              >
                <Sparkles className="w-4 h-4" />
                <span>{hasCompletedOnboarding ? 'Update Recommendations' : 'Start Streaming'}</span>
              </button>
            </div>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
