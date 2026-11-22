import React, { useState, useEffect } from 'react';
import { Search, X, Filter } from 'lucide-react';
import { useAppStore } from '../store/useAppStore';
import { MediaItem } from '../types';
import { MediaCard } from './MediaCard';

export const SearchModal: React.FC = () => {
  const { isSearchOpen, setIsSearchOpen, searchQuery, setSearchQuery } = useAppStore();
  const [results, setResults] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedFilter, setSelectedFilter] = useState<string>('all');

  useEffect(() => {
    if (!searchQuery.trim()) {
      setResults([]);
      return;
    }

    const timer = setTimeout(() => {
      setLoading(true);
      let url = `/api/search?q=${encodeURIComponent(searchQuery)}`;
      if (selectedFilter === 'movie') url += '&type=movie';
      if (selectedFilter === 'series') url += '&type=series';
      if (selectedFilter === 'anime') url += '&category=anime';
      if (selectedFilter === '1080p') url += '&quality=1080p';

      fetch(url)
        .then((res) => res.json())
        .then((data) => setResults(data))
        .catch((err) => console.error('Search error:', err))
        .finally(() => setLoading(false));
    }, 150);

    return () => clearTimeout(timer);
  }, [searchQuery, selectedFilter]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setIsSearchOpen(false);
        setSearchQuery('');
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [setIsSearchOpen, setSearchQuery]);

  if (!isSearchOpen && !searchQuery.trim()) return null;

  const filters = [
    { id: 'all', label: 'All Titles' },
    { id: 'movie', label: 'Movies' },
    { id: 'series', label: 'TV Shows' },
    { id: 'anime', label: 'Anime Hits' },
    { id: '1080p', label: '1080p Full HD' }
  ];

  return (
    <div className="fixed inset-0 z-40 bg-[#141414] overflow-y-auto pt-24 px-4 md:px-12 pb-36">
      {/* Header Bar */}
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="relative flex items-center bg-[#202020] border border-gray-700 rounded-lg px-4 py-3 shadow-lg">
          <Search className="w-5 h-5 text-gray-400 mr-3" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by title, year, tags, or actors..."
            autoFocus
            className="bg-transparent text-white text-base md:text-lg focus:outline-none w-full placeholder:text-gray-500"
          />
          {searchQuery && (
            <button onClick={() => setSearchQuery('')} className="p-1 text-gray-400 hover:text-white mr-2">
              <X className="w-5 h-5" />
            </button>
          )}
          <button
            onClick={() => {
              setIsSearchOpen(false);
              setSearchQuery('');
            }}
            className="text-xs uppercase font-bold tracking-wider text-gray-400 hover:text-white"
          >
            Cancel
          </button>
        </div>

        {/* Filter Chips */}
        <div className="flex items-center space-x-2 overflow-x-auto no-scrollbar pb-2">
          <span className="text-xs text-gray-500 flex items-center mr-1">
            <Filter className="w-3.5 h-3.5 mr-1" /> Filters:
          </span>
          {filters.map((f) => (
            <button
              key={f.id}
              onClick={() => setSelectedFilter(f.id)}
              className={`px-3 py-1 rounded-full text-xs font-semibold whitespace-nowrap transition-colors ${
                selectedFilter === f.id
                  ? 'bg-[#E50914] text-white'
                  : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>

        {/* Search Results Summary */}
        <div className="flex items-center justify-between text-xs text-gray-400 border-b border-gray-800 pb-2">
          <span>{loading ? 'Searching across 37,000+ titles...' : `Found ${results.length} results`}</span>
        </div>

        {/* Results Grid with clear gaps between cards */}
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 sm:gap-6 md:gap-8 gap-y-10 pt-4 pb-12">
          {results.map((item, idx) => (
            <MediaCard 
              key={item.id} 
              item={item} 
              isGrid={true}
              index={idx}
              totalItems={results.length}
            />
          ))}
        </div>

        {!loading && searchQuery && results.length === 0 && (
          <div className="text-center py-20 space-y-2">
            <p className="text-gray-400 text-sm">No titles matched your search query "{searchQuery}".</p>
            <p className="text-gray-500 text-xs">Try different keywords, years, or check spelling.</p>
          </div>
        )}
      </div>
    </div>
  );
};
