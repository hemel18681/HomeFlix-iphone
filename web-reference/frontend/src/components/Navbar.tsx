import React, { useState, useEffect } from 'react';
import { Search, Bell, X, Sliders, ChevronDown, CheckCircle2 } from 'lucide-react';
import { useAppStore } from '../store/useAppStore';
import { PWAInstallPrompt } from './PWAInstallPrompt';

interface NavbarProps {
  onSelectCategory?: (categorySlug: string | null) => void;
}

export const Navbar: React.FC<NavbarProps> = ({ onSelectCategory }) => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const {
    activeTab,
    setActiveTab,
    isSearchOpen,
    setIsSearchOpen,
    searchQuery,
    setSearchQuery,
    preferences,
    setIsPreferencesModalOpen
  } = useAppStore();

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 40) {
        setIsScrolled(true);
      } else {
        setIsScrolled(false);
      }
    };
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navItems = [
    { id: 'home', label: 'Home', slug: null },
    { id: 'tv', label: 'TV Shows', slug: 'tv-series' },
    { id: 'movies', label: 'Movies', slug: 'english-1080p' },
    { id: 'korean', label: 'K-Drama', slug: 'korean-tv' },
    { id: 'anime', label: 'Anime', slug: 'anime-series' },
    { id: 'mylist', label: 'My List', slug: 'mylist' },
  ];

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-40 transition-colors duration-300 px-4 md:px-12 py-3 flex items-center justify-between ${
        isScrolled ? 'bg-[#141414]/95 shadow-lg netflix-blur' : 'bg-gradient-to-b from-black/80 via-black/40 to-transparent'
      }`}
    >
      {/* Left side: Brand Logo & Links */}
      <div className="flex items-center space-x-3 sm:space-x-6 md:space-x-10 shrink-0">
        <div 
          onClick={() => { setActiveTab('home'); if (onSelectCategory) onSelectCategory(null); }}
          className="cursor-pointer flex items-center space-x-1.5"
        >
          <span className="text-[#E50914] font-black tracking-tighter text-xl sm:text-2xl md:text-3xl font-mono select-none">
            HOME<span className="text-white">FLIX</span>
          </span>
        </div>

        <ul className="hidden md:flex items-center space-x-6 text-sm font-medium text-[#E5E5E5]">
          {navItems.map((item) => (
            <li key={item.id}>
              <button
                onClick={() => {
                  setActiveTab(item.id);
                  if (onSelectCategory) onSelectCategory(item.slug);
                }}
                className={`transition-colors hover:text-white ${
                  activeTab === item.id ? 'text-white font-bold' : 'text-[#B3B3B3]'
                }`}
              >
                {item.label}
              </button>
            </li>
          ))}
        </ul>
      </div>

      {/* Right side: Search, Notifications, Avatar */}
      <div className="flex items-center space-x-2 sm:space-x-4 md:space-x-6 text-white shrink-0">
        {/* Instant Search Bar */}
        <div className="relative flex items-center">
          {isSearchOpen ? (
            <div className="flex items-center bg-black/80 border border-white/50 px-2 sm:px-3 py-1 rounded transition-all w-36 sm:w-64 max-w-[45vw] sm:max-w-xs">
              <Search className="w-3.5 h-3.5 sm:w-4 sm:h-4 text-gray-400 mr-1.5 sm:mr-2 shrink-0" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search..."
                autoFocus
                className="bg-transparent text-white text-xs sm:text-sm focus:outline-none w-full placeholder:text-gray-500"
              />
              <button onClick={() => { setIsSearchOpen(false); setSearchQuery(''); }}>
                <X className="w-3.5 h-3.5 sm:w-4 sm:h-4 text-gray-400 hover:text-white" />
              </button>
            </div>
          ) : (
            <button
              onClick={() => setIsSearchOpen(true)}
              className="p-1 hover:text-gray-300 transition-colors"
              title="Search (Press /)"
            >
              <Search className="w-5 h-5" />
            </button>
          )}
        </div>

        {/* PWA Install Button (Desktop, Android, iOS) */}
        <PWAInstallPrompt />

        {/* Notifications */}
        <button className="hidden sm:block p-1 text-gray-300 hover:text-white transition-colors relative">
          <Bell className="w-5 h-5" />
          <span className="absolute top-0 right-0 w-2 h-2 bg-[#E50914] rounded-full"></span>
        </button>

        {/* Profile Avatar & Dropdown */}
        <div className="relative">
          <div
            onClick={() => setShowProfileMenu(!showProfileMenu)}
            className="flex items-center space-x-1.5 cursor-pointer group select-none"
          >
            <div className="w-8 h-8 rounded bg-gradient-to-tr from-[#E50914] to-red-600 flex items-center justify-center font-bold text-xs text-white shadow ring-2 ring-transparent group-hover:ring-white/40 transition-all">
              HF
            </div>
            <ChevronDown className={`w-3.5 h-3.5 text-gray-400 group-hover:text-white transition-transform ${showProfileMenu ? 'rotate-180' : ''}`} />
          </div>

          {/* Dropdown Menu */}
          {showProfileMenu && (
            <div className="absolute right-0 top-11 w-56 bg-[#181818] border border-gray-700/80 rounded-md shadow-2xl py-2 z-50 animate-in fade-in zoom-in-95 duration-150">
              <div className="px-4 py-2 border-b border-gray-800 text-xs">
                <p className="font-bold text-white">HomeFlix Viewer</p>
                <p className="text-[10px] text-gray-400 flex items-center space-x-1 mt-0.5">
                  <CheckCircle2 className="w-3 h-3 text-green-400" />
                  <span>{preferences.length > 0 ? `${preferences.length} Tastes active` : 'Default feed'}</span>
                </p>
              </div>

              <button
                onClick={() => {
                  setShowProfileMenu(false);
                  setIsPreferencesModalOpen(true);
                }}
                className="w-full text-left px-4 py-2.5 text-xs text-gray-200 hover:bg-[#E50914] hover:text-white transition-colors flex items-center space-x-2 font-medium"
              >
                <Sliders className="w-4 h-4" />
                <span>Personalize Preferences</span>
              </button>

              <button
                onClick={() => {
                  setShowProfileMenu(false);
                  setActiveTab('mylist');
                }}
                className="w-full text-left px-4 py-2 text-xs text-gray-300 hover:bg-white/10 transition-colors"
              >
                My List
              </button>

              <div className="border-t border-gray-800 my-1"></div>

              <div className="px-4 py-1 text-[10px] text-gray-500">
                BDIX FastPath Gigabit Active
              </div>
            </div>
          )}
        </div>
      </div>
    </nav>
  );
};
