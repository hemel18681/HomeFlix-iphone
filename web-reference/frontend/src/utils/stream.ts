/**
 * Universal Stream Resolution and Mobile Video Engine Utilities
 */

export const SAMPLE_FALLBACK_STREAM =
  'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

/**
 * Resolves a raw BDIX or remote video URL into a playable stream URL.
 * Automatically wraps private subnet BDIX URLs (172.16.x.x) into the high-speed
 * HTTP Range stream proxy (/api/stream-proxy?url=...) so that mobile devices connected
 * over Wi-Fi can stream directly through the host server without routing failures.
 */
export function getPlayableStreamUrl(
  rawUrl?: string | null,
  options?: {
    forceDirect?: boolean;
    useSampleFallback?: boolean;
  }
): string {
  if (options?.useSampleFallback) {
    return SAMPLE_FALLBACK_STREAM;
  }

  if (!rawUrl) return '';

  // If already relative (e.g. /api/... or local sample), return as is
  if (rawUrl.startsWith('/')) {
    return rawUrl;
  }

  // If forced direct, return raw
  if (options?.forceDirect) {
    return rawUrl;
  }

  // If it's a private BDIX ISP URL (e.g. 172.16.x.x or local subnet),
  // mobile devices on Wi-Fi cannot connect to it directly due to router WAN/LAN boundaries.
  // Wrap in our streaming proxy:
  if (rawUrl.includes('172.16.') || rawUrl.startsWith('http://10.') || rawUrl.startsWith('http://192.168.')) {
    return `/api/stream-proxy?url=${encodeURIComponent(rawUrl)}`;
  }

  return rawUrl;
}

/**
 * Returns deep-link protocols for launching external mobile video players
 * (VLC, MX Player, KMPlayer) which have native hardware decoding for MKV,
 * HEVC x265, and multi-track AC3/DTS audio.
 */
export function getExternalPlayerLinks(rawUrl?: string | null, title?: string) {
  if (!rawUrl) {
    return {
      direct: '',
      vlc: '',
      mxPlayer: '',
      webProxy: ''
    };
  }

  const encodedTitle = encodeURIComponent(title || 'HomeFlix Movie');
  const webProxy = `/api/stream-proxy?url=${encodeURIComponent(rawUrl)}`;

  return {
    direct: rawUrl,
    vlc: `vlc://${rawUrl}`,
    mxPlayer: `intent:${rawUrl}#Intent;package=com.mxtech.videoplayer.ad;type=video/*;S.title=${encodedTitle};end`,
    webProxy
  };
}

/**
 * Mobile device detector based on screen width and touch capability
 */
export function isMobileScreen(): boolean {
  if (typeof window === 'undefined') return false;
  return window.innerWidth < 768 || ('ontouchstart' in window && window.innerWidth < 1024);
}
