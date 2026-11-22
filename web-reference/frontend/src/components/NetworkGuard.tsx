import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { WifiOff, RefreshCw, Copy, Check, Server, AlertTriangle, ShieldAlert, ArrowRight } from 'lucide-react';

interface NetworkCheckResult {
  reachable: boolean;
  target: string;
  status?: number;
  responseTimeMs?: number;
  error?: string;
}

interface NetworkGuardProps {
  children: React.ReactNode;
}

export const NetworkGuard: React.FC<NetworkGuardProps> = ({ children }) => {
  const [status, setStatus] = useState<'checking' | 'online' | 'offline'>('checking');
  const [checkDetails, setCheckDetails] = useState<NetworkCheckResult | null>(null);
  const [copied, setCopied] = useState(false);
  const [isBypassed, setIsBypassed] = useState(false);
  const [showTechDetails, setShowTechDetails] = useState(false);

  const runNetworkCheck = useCallback(async () => {
    setStatus('checking');
    const startTime = Date.now();

    // Check query params for forced simulation (e.g. ?offline=1 or ?simulate=offline)
    const urlParams = new URLSearchParams(window.location.search);
    const forceOffline = urlParams.get('offline') === '1' || urlParams.get('simulate') === 'offline';
    const forceOnline = urlParams.get('online') === '1' || urlParams.get('simulate') === 'online';

    try {
      let endpoint = '/api/network-check';
      if (forceOffline) endpoint += '?simulate=offline';
      else if (forceOnline) endpoint += '?simulate=online';

      const res = await fetch(endpoint);
      const data: NetworkCheckResult = await res.json();

      // Ensure loading screen is visible for at least 1200ms so user sees the check animation
      const elapsed = Date.now() - startTime;
      const minDelay = 1200;
      if (elapsed < minDelay) {
        await new Promise((r) => setTimeout(r, minDelay - elapsed));
      }

      setCheckDetails(data);
      if (data.reachable) {
        setStatus('online');
      } else {
        setStatus('offline');
      }
    } catch (err: any) {
      const elapsed = Date.now() - startTime;
      if (elapsed < 1200) {
        await new Promise((r) => setTimeout(r, 1200 - elapsed));
      }
      setCheckDetails({
        reachable: false,
        target: '172.16.50.4',
        error: err.message || 'Network request failed'
      });
      setStatus('offline');
    }
  }, []);

  useEffect(() => {
    runNetworkCheck();
  }, [runNetworkCheck]);

  const copyIspMessage = () => {
    const msg = `Hello, my home network cannot route to the DhakaFlix BDIX media server (172.16.50.4). Could your NOC / network team please enable the BDIX optical route to 172.16.50.4 so I can access the media server? Thank you!`;
    navigator.clipboard.writeText(msg).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 3000);
    });
  };

  // If online or user chose to explore in demo/preview mode:
  if (status === 'online' || isBypassed) {
    return (
      <>
        {isBypassed && (
          <div className="bg-amber-600/90 text-white text-xs px-4 py-2 flex items-center justify-between z-50 sticky top-0 shadow">
            <div className="flex items-center space-x-2">
              <AlertTriangle className="w-4 h-4 shrink-0" />
              <span>
                <strong>Preview / Offline Mode Active:</strong> DhakaFlix server (172.16.50.4) was unreachable on your current network. Full video playback requires your ISP to peer with BDIX.
              </span>
            </div>
            <button
              onClick={() => {
                setIsBypassed(false);
                runNetworkCheck();
              }}
              className="bg-black/40 hover:bg-black/60 px-2.5 py-1 rounded text-[11px] font-bold ml-4 shrink-0 transition-colors"
            >
              Re-check Server
            </button>
          </div>
        )}
        {children}
      </>
    );
  }

  return (
    <div className="fixed inset-0 z-50 bg-[#141414] text-white flex flex-col items-center justify-center p-4 selection:bg-[#E50914] selection:text-white">
      {/* Background ambient red glow */}
      <div className="absolute inset-0 bg-radial-gradient pointer-events-none opacity-20" />

      <AnimatePresence mode="wait">
        {/* ============================================================== */}
        {/* 1. INITIAL LOADING SCREEN (VERIFYING 172.16.50.4)             */}
        {/* ============================================================== */}
        {status === 'checking' && (
          <motion.div
            key="checking"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            transition={{ duration: 0.3 }}
            className="flex flex-col items-center text-center max-w-md w-full space-y-6"
          >
            {/* Netflix-Style Red Brand Pulse */}
            <div className="relative flex items-center justify-center">
              <div className="w-24 h-24 rounded-full bg-[#E50914]/20 animate-ping absolute" />
              <div className="w-20 h-20 rounded-2xl bg-gradient-to-tr from-[#E50914] to-red-700 flex items-center justify-center shadow-2xl shadow-red-600/50 relative z-10">
                <span className="text-white text-4xl font-black font-mono tracking-tighter">
                  HF
                </span>
              </div>
            </div>

            <div className="space-y-2">
              <h2 className="text-2xl font-black tracking-tight text-white">
                Connecting to Media Cloud
              </h2>
              <p className="text-sm text-gray-400">
                Verifying your network provider access to{' '}
                <span className="text-white font-mono bg-white/10 px-1.5 py-0.5 rounded text-xs">
                  172.16.50.4
                </span>{' '}
                (DhakaFlix Server)...
              </p>
            </div>

            {/* Smooth Loading Indicator */}
            <div className="w-64 h-1.5 bg-gray-800 rounded-full overflow-hidden relative">
              <motion.div
                className="h-full bg-[#E50914]"
                animate={{
                  x: ['-100%', '100%']
                }}
                transition={{
                  repeat: Infinity,
                  duration: 1.2,
                  ease: 'easeInOut'
                }}
                style={{ width: '60%' }}
              />
            </div>

            <p className="text-[11px] text-gray-500 uppercase tracking-widest font-semibold">
              BDIX Gigabit Peering Check
            </p>
          </motion.div>
        )}

        {/* ============================================================== */}
        {/* 2. ERROR PAGE: NETWORK PROVIDER DOES NOT HAVE DHAKAFLIX       */}
        {/* ============================================================== */}
        {status === 'offline' && (
          <motion.div
            key="offline"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.4 }}
            className="flex flex-col items-center text-center max-w-lg w-full space-y-6 bg-[#181818]/90 border border-white/10 p-6 sm:p-8 rounded-2xl shadow-2xl backdrop-blur-md"
          >
            {/* Warning / Network Icon */}
            <div className="w-16 h-16 rounded-full bg-red-500/10 border border-red-500/30 flex items-center justify-center text-[#E50914] shadow-lg shadow-red-500/10">
              <WifiOff className="w-8 h-8" />
            </div>

            {/* Error Heading */}
            <div className="space-y-2">
              <div className="inline-flex items-center space-x-1.5 bg-red-950/60 border border-red-800/40 text-red-400 text-[11px] font-bold px-2.5 py-1 rounded-full uppercase tracking-wider">
                <ShieldAlert className="w-3.5 h-3.5" />
                <span>ISP Peering Required</span>
              </div>
              <h1 className="text-xl sm:text-2xl font-black text-white tracking-tight leading-snug">
                Your Network Provider Doesn’t Have DhakaFlix Server
              </h1>
              <p className="text-xs sm:text-sm text-gray-300 leading-relaxed">
                We could not establish a connection to the DhakaFlix storage node at{' '}
                <strong className="text-white font-mono bg-white/10 px-1 rounded">172.16.50.4</strong>.
                This indicates that your internet service provider (ISP) does not have BDIX routing enabled for DhakaFlix media servers.
              </p>
            </div>

            {/* Actionable Message Box for ISP */}
            <div className="w-full bg-[#111] border border-gray-800 rounded-xl p-4 text-left space-y-2.5">
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-bold text-gray-400 uppercase tracking-wider flex items-center space-x-1.5">
                  <Server className="w-3.5 h-3.5 text-[#E50914]" />
                  <span>What to tell your ISP:</span>
                </span>
                <button
                  onClick={copyIspMessage}
                  className="flex items-center space-x-1 text-xs text-[#E50914] hover:text-red-400 font-semibold transition-colors"
                >
                  {copied ? (
                    <>
                      <Check className="w-3.5 h-3.5 text-green-400" />
                      <span className="text-green-400">Copied!</span>
                    </>
                  ) : (
                    <>
                      <Copy className="w-3.5 h-3.5" />
                      <span>Copy Message</span>
                    </>
                  )}
                </button>
              </div>

              <div className="bg-[#181818] p-3 rounded text-xs text-gray-300 font-mono leading-relaxed border border-gray-800 select-all">
                "Please enable BDIX optical route to IP 172.16.50.4 for DhakaFlix media streaming."
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex flex-col sm:flex-row items-center gap-3 w-full pt-1">
              {/* Retry Button */}
              <button
                onClick={runNetworkCheck}
                className="w-full sm:flex-1 flex items-center justify-center space-x-2 bg-[#E50914] hover:bg-red-700 text-white font-bold py-2.5 px-4 rounded-lg transition-all active:scale-95 shadow-lg shadow-red-700/30 text-sm"
              >
                <RefreshCw className="w-4 h-4" />
                <span>Retry Connection</span>
              </button>

              {/* Bypass / Preview Demo Mode Button */}
              <button
                onClick={() => setIsBypassed(true)}
                className="w-full sm:flex-1 flex items-center justify-center space-x-2 bg-gray-800 hover:bg-gray-700 text-gray-200 font-bold py-2.5 px-4 rounded-lg transition-all active:scale-95 text-sm border border-gray-700"
              >
                <span>Continue in Preview</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>

            {/* Collapsible Technical Details */}
            <div className="w-full pt-2">
              <button
                onClick={() => setShowTechDetails(!showTechDetails)}
                className="text-[11px] text-gray-500 hover:text-gray-400 underline transition-colors"
              >
                {showTechDetails ? 'Hide Network Diagnosis' : 'View Network Diagnosis'}
              </button>

              {showTechDetails && (
                <div className="mt-3 text-left text-[11px] text-gray-400 bg-black/60 p-3 rounded border border-gray-800 font-mono space-y-1">
                  <div>Target Node: 172.16.50.4:80 (HTTP)</div>
                  <div>Protocol: BDIX Direct Peering</div>
                  <div>Status Code: {checkDetails?.status || 'Connection Failed / Timeout'}</div>
                  <div>Diagnosis: {checkDetails?.error || 'Destination Host Unreachable'}</div>
                  <div>Timestamp: {new Date().toLocaleTimeString()}</div>
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};
