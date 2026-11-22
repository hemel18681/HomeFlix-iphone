import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Download, Share, PlusSquare, X, Smartphone, Monitor, CheckCircle2 } from 'lucide-react';

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export const PWAInstallPrompt: React.FC = () => {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [isStandalone, setIsStandalone] = useState(false);
  const [isIOS, setIsIOS] = useState(false);
  const [showIOSModal, setShowIOSModal] = useState(false);
  const [showDesktopGuide, setShowDesktopGuide] = useState(false);
  const [hasDismissedBanner, setHasDismissedBanner] = useState(false);

  useEffect(() => {
    // Check if already running in standalone PWA mode
    const standaloneMode =
      window.matchMedia('(display-mode: standalone)').matches ||
      (window.navigator as any).standalone === true;
    setIsStandalone(standaloneMode);

    // Detect iOS Safari
    const userAgent = window.navigator.userAgent.toLowerCase();
    const isIOSDevice = /iphone|ipad|ipod/.test(userAgent) && !(window as any).MSStream;
    setIsIOS(isIOSDevice);

    // Capture Chrome/Edge/Android beforeinstallprompt
    const handleBeforeInstallPrompt = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);

    // Listen for app installed event
    window.addEventListener('appinstalled', () => {
      setIsStandalone(true);
      setDeferredPrompt(null);
      console.log('HomeFlix PWA installed successfully!');
    });

    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    };
  }, []);

  // If already running inside installed standalone PWA, do not render prompts
  if (isStandalone) return null;

  const handleInstallClick = async () => {
    if (deferredPrompt) {
      await deferredPrompt.prompt();
      const choiceResult = await deferredPrompt.userChoice;
      if (choiceResult.outcome === 'accepted') {
        setIsStandalone(true);
      }
      setDeferredPrompt(null);
    } else if (isIOS) {
      setShowIOSModal(true);
    } else {
      setShowDesktopGuide(true);
    }
  };

  return (
    <>
      {/* 1. Navbar / Top Banner Install Button */}
      <button
        onClick={handleInstallClick}
        className="flex items-center space-x-1.5 px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-full bg-[#E50914] hover:bg-red-700 text-white font-bold text-xs shadow-md shadow-red-950/40 transition-all active:scale-95 animate-pulse hover:animate-none"
        title="Add HomeFlix to your Desktop or Mobile Home Screen"
      >
        <Download className="w-3.5 h-3.5 stroke-[2.5]" />
        <span className="hidden sm:inline">Install App</span>
        <span className="sm:hidden">Install</span>
      </button>

      {/* 2. iOS Safari Add-To-Home-Screen Instructions Modal */}
      <AnimatePresence>
        {showIOSModal && (
          <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              className="relative w-full max-w-sm bg-[#181818] border border-gray-700/80 rounded-2xl shadow-2xl p-6 text-white space-y-5"
            >
              <button
                onClick={() => setShowIOSModal(false)}
                className="absolute top-4 right-4 p-1 rounded-full bg-white/10 hover:bg-white/20 text-gray-400 hover:text-white transition-colors"
              >
                <X className="w-4 h-4" />
              </button>

              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#E50914] to-red-600 flex items-center justify-center font-black text-sm text-white shadow">
                  HF
                </div>
                <div>
                  <h3 className="font-bold text-base text-white">Install on iPhone / iPad</h3>
                  <p className="text-xs text-gray-400">Add to Home Screen in 3 taps</p>
                </div>
              </div>

              <div className="space-y-3.5 text-xs text-gray-300">
                <div className="flex items-start space-x-3 p-2.5 rounded-lg bg-black/40 border border-white/5">
                  <div className="p-1.5 rounded bg-blue-500/20 text-blue-400 shrink-0">
                    <Share className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="font-bold text-white">Step 1: Tap Share</p>
                    <p className="text-[11px] text-gray-400">Tap the Share icon at the bottom of your Safari browser bar.</p>
                  </div>
                </div>

                <div className="flex items-start space-x-3 p-2.5 rounded-lg bg-black/40 border border-white/5">
                  <div className="p-1.5 rounded bg-emerald-500/20 text-emerald-400 shrink-0">
                    <PlusSquare className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="font-bold text-white">Step 2: Add to Home Screen</p>
                    <p className="text-[11px] text-gray-400">Scroll down the menu list and tap <strong className="text-white">"Add to Home Screen"</strong>.</p>
                  </div>
                </div>

                <div className="flex items-start space-x-3 p-2.5 rounded-lg bg-black/40 border border-white/5">
                  <div className="p-1.5 rounded bg-red-500/20 text-red-400 shrink-0">
                    <CheckCircle2 className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="font-bold text-white">Step 3: Tap Add</p>
                    <p className="text-[11px] text-gray-400">Tap "Add" in the top-right. HomeFlix will launch full-screen like a native app!</p>
                  </div>
                </div>
              </div>

              <button
                onClick={() => setShowIOSModal(false)}
                className="w-full bg-white/10 hover:bg-white/20 text-white font-bold py-2.5 rounded-lg text-xs transition-colors"
              >
                Got It
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* 3. Desktop Chrome / Edge Manual Guide Modal (if beforeinstallprompt was delayed) */}
      <AnimatePresence>
        {showDesktopGuide && (
          <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              className="relative w-full max-w-sm bg-[#181818] border border-gray-700/80 rounded-2xl shadow-2xl p-6 text-white space-y-5"
            >
              <button
                onClick={() => setShowDesktopGuide(false)}
                className="absolute top-4 right-4 p-1 rounded-full bg-white/10 hover:bg-white/20 text-gray-400 hover:text-white transition-colors"
              >
                <X className="w-4 h-4" />
              </button>

              <div className="flex items-center space-x-3">
                <div className="p-2.5 rounded-xl bg-[#E50914]/20 text-[#E50914]">
                  <Monitor className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="font-bold text-base text-white">Install on Desktop</h3>
                  <p className="text-xs text-gray-400">Windows, Mac & Chromebook</p>
                </div>
              </div>

              <div className="space-y-2.5 text-xs text-gray-300 bg-black/40 p-3.5 rounded-lg border border-white/5">
                <p>1. Look at the right side of your browser address bar.</p>
                <p>2. Click the <strong className="text-white">Install HomeFlix</strong> icon (or menu ⋮ &gt; <strong className="text-white">"Install HomeFlix"</strong>).</p>
                <p>3. HomeFlix will open in its own dedicated, borderless app window and pin to your Taskbar / Dock!</p>
              </div>

              <button
                onClick={() => setShowDesktopGuide(false)}
                className="w-full bg-[#E50914] hover:bg-red-700 text-white font-bold py-2.5 rounded-lg text-xs transition-colors"
              >
                Okay, Understood
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </>
  );
};
