const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const http = require('http');

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

// In-memory data structures
const dataDir = path.join(__dirname, 'data');
console.log('Loading in-memory catalog shards...');

const featured = JSON.parse(fs.readFileSync(path.join(dataDir, 'featured.json'), 'utf8'));
const searchIndex = JSON.parse(fs.readFileSync(path.join(dataDir, 'search-index.json'), 'utf8'));

// Load category shards
const categories = {
  'english-1080p': JSON.parse(fs.readFileSync(path.join(dataDir, 'english-1080p.json'), 'utf8')),
  'english-movies': JSON.parse(fs.readFileSync(path.join(dataDir, 'english-movies.json'), 'utf8')),
  'hindi-movies': JSON.parse(fs.readFileSync(path.join(dataDir, 'hindi-movies.json'), 'utf8')),
  'south-movies': JSON.parse(fs.readFileSync(path.join(dataDir, 'south-movies.json'), 'utf8')),
  'tv-series': JSON.parse(fs.readFileSync(path.join(dataDir, 'tv-series.json'), 'utf8')),
  'korean-tv': JSON.parse(fs.readFileSync(path.join(dataDir, 'korean-tv.json'), 'utf8')),
  'anime-series': JSON.parse(fs.readFileSync(path.join(dataDir, 'anime-series.json'), 'utf8')),
  'animation-movies': JSON.parse(fs.readFileSync(path.join(dataDir, 'animation-movies.json'), 'utf8')),
  'animation-1080p': JSON.parse(fs.readFileSync(path.join(dataDir, 'animation-1080p.json'), 'utf8')),
  'imdb-top250': JSON.parse(fs.readFileSync(path.join(dataDir, 'imdb-top250.json'), 'utf8')),
  'movies-3d': JSON.parse(fs.readFileSync(path.join(dataDir, 'movies-3d.json'), 'utf8')),
  'documentary': JSON.parse(fs.readFileSync(path.join(dataDir, 'documentary.json'), 'utf8')),
  'kolkata-bangla': JSON.parse(fs.readFileSync(path.join(dataDir, 'kolkata-bangla.json'), 'utf8')),
  'foreign-movies': JSON.parse(fs.readFileSync(path.join(dataDir, 'foreign-movies.json'), 'utf8'))
};

// Load or synthesize full items map
let fullItemMap = {};
const itemsMapPath = path.join(dataDir, 'items-map.json');
if (fs.existsSync(itemsMapPath)) {
  fullItemMap = JSON.parse(fs.readFileSync(itemsMapPath, 'utf8'));
} else {
  console.log('Synthesizing in-memory fullItemMap from category shards...');
  for (const catList of Object.values(categories)) {
    if (Array.isArray(catList)) {
      for (const item of catList) {
        if (item && item.id) fullItemMap[item.id] = item;
      }
    }
  }
}

console.log('All shards loaded successfully into memory.');

// Helper to sanitize items for carousel rows (exclude heavy episode trees)
const allItems = Object.values(fullItemMap);

function findBestMatches(queries, type) {
  const result = [];
  const addedIds = new Set();
  for (const q of queries) {
    const qLower = q.toLowerCase();
    const match = allItems
      .filter(i => (!type || i.type === type) && !addedIds.has(i.id) && i.title.toLowerCase().includes(qLower))
      .sort((a, b) => (b.year || 0) - (a.year || 0))[0];
    if (match) {
      result.push(match);
      addedIds.add(match.id);
    }
  }
  return result;
}

function toCard(item) {
  return {
    id: item.id,
    type: item.type,
    title: item.title,
    year: item.year,
    quality: item.quality,
    category: item.category,
    tags: item.tags,
    poster: item.poster,
    backdrop: item.backdrop || item.poster,
    streamUrl: item.streamUrl || null,
    totalSeasons: item.totalSeasons || null,
    totalEpisodes: item.totalEpisodes || null
  };
}

// 1. Featured Billboard Items
app.get('/api/featured', (req, res) => {
  res.json(featured);
});

function buildCuratedRows() {
  // Top 10 Movies Today (Ranked #1-#10 with giant Netflix numbers)
  const movieTop10Queries = [
    'Deadpool', 'Cold Storage', 'Dune Part Two', 'Venom The Last Dance', 'Alien Romulus',
    'Twisters', 'Oppenheimer', 'Gladiator', 'Heart of the Beast', 'Odyssey'
  ];
  const top10Movies = findBestMatches(movieTop10Queries, 'movie').map(toCard);

  // Top 10 TV Shows Today (Ranked #1-#10 with giant Netflix numbers)
  const tvTop10Queries = [
    'Stranger Things', 'Squid Game', 'Witcher', 'Man on Fire', 'House of the Dragon',
    'Marshals', 'Neagley', 'Money Heist', 'Boyfriend on Demand', 'Black Mirror'
  ];
  const top10TV = findBestMatches(tvTop10Queries, 'series').map(toCard);

  // Filter for genuine streaming platform releases (Netflix [NF], Amazon Prime [AMZN])
  const nfAmznTrending = [
    ...categories['english-1080p'].filter(i => (i.tags.includes('Netflix') || i.tags.includes('Amazon Prime')) && i.year >= 2024),
    ...categories['tv-series'].filter(i => (i.tags.includes('Netflix') || i.tags.includes('Amazon Prime')) && i.year >= 2024),
    ...categories['foreign-movies'].filter(i => (i.tags.includes('Netflix') || i.tags.includes('Amazon Prime')) && i.year >= 2024)
  ].slice(0, 24).map(toCard);

  // Trending Anime Hits (Crunchyroll & Netflix Global)
  const animeQueries = [
    'Solo Leveling', 'Dandadan', 'Frieren', 'Demon Slayer', 'Kaiju', 'Jujutsu', 'One Piece', 'Attack on Titan'
  ];
  const animeCurated = findBestMatches(animeQueries, null);
  const animeHits = [
    ...animeCurated,
    ...categories['anime-series'].filter(i => i.year >= 2024 && !animeCurated.some(c => c.id === i.id)).slice(0, 16)
  ].map(toCard);

  // Action & High-Octane Thrillers
  const actionQueries = [
    'Mission Impossible', 'John Wick', 'Fast & Furious', 'Top Gun', 'Transformers', 'Mad Max', 'Batman', 'Gladiator'
  ];
  const actionCurated = findBestMatches(actionQueries, 'movie');
  const actionThrillers = [
    ...actionCurated,
    ...categories['english-1080p'].filter(i => i.quality === '1080p' && !actionCurated.some(c => c.id === i.id)).slice(0, 16)
  ].map(toCard);

  // Sci-Fi & Cyberpunk
  const sciFiQueries = ['Interstellar', 'Dune', 'The Matrix', 'Blade Runner', 'Tenet', 'Inception', 'Arrival', 'Avatar', 'Star Wars', 'Edge of Tomorrow'];
  const sciFiCurated = findBestMatches(sciFiQueries, 'movie');
  const sciFiItems = [
    ...sciFiCurated,
    ...categories['english-1080p'].filter(i => {
      const tags = (i.tags || []).join(' ').toLowerCase();
      return (tags.includes('sci-fi') || tags.includes('space')) && !sciFiCurated.some(c => c.id === i.id);
    }).slice(0, 16)
  ].map(toCard);

  // Supernatural Horror & Thrillers
  const horrorQueries = ['The Conjuring', 'A Quiet Place', 'Alien', 'Smile', 'Insidious', 'Evil Dead', 'Halloween', 'Scream', 'It Chapter'];
  const horrorCurated = findBestMatches(horrorQueries, 'movie');
  const horrorItems = [
    ...horrorCurated,
    ...categories['english-1080p'].filter(i => {
      const tags = (i.tags || []).join(' ').toLowerCase();
      return (tags.includes('horror') || tags.includes('thriller')) && !horrorCurated.some(c => c.id === i.id);
    }).slice(0, 16)
  ].map(toCard);

  // Crime, Mafia & Heists
  const crimeQueries = ['Breaking Bad', 'Peaky Blinders', 'Money Heist', 'Narcos', 'The Godfather', 'Goodfellas', 'Mindhunter', 'Dexter', 'The Batman'];
  const crimeCurated = findBestMatches(crimeQueries);
  const crimeItems = [
    ...crimeCurated,
    ...categories['tv-series'].filter(i => {
      const tags = (i.tags || []).join(' ').toLowerCase();
      return (tags.includes('crime') || tags.includes('mystery')) && !crimeCurated.some(c => c.id === i.id);
    }).slice(0, 16)
  ].map(toCard);

  // Romance & Heartfelt Drama
  const romanceQueries = ['Crash Landing on You', 'Queen of Tears', 'La La Land', 'Titanic', 'About Time', 'Pride and Prejudice', 'The Notebook', 'Past Lives'];
  const romanceCurated = findBestMatches(romanceQueries);
  const romanceItems = [
    ...romanceCurated,
    ...categories['korean-tv'].filter(i => !romanceCurated.some(c => c.id === i.id)).slice(0, 8),
    ...categories['english-1080p'].filter(i => {
      const tags = (i.tags || []).join(' ').toLowerCase();
      return (tags.includes('romance') || tags.includes('drama')) && !romanceCurated.some(c => c.id === i.id);
    }).slice(0, 8)
  ].map(toCard);

  // High Fantasy & Mythological Epics
  const fantasyQueries = ['Lord of the Rings', 'House of the Dragon', 'The Witcher', 'Harry Potter', 'Hobbit', 'Percy Jackson', 'Game of Thrones'];
  const fantasyCurated = findBestMatches(fantasyQueries);
  const fantasyItems = [
    ...fantasyCurated,
    ...categories['english-1080p'].filter(i => {
      const tags = (i.tags || []).join(' ').toLowerCase();
      return (tags.includes('fantasy') || tags.includes('adventure')) && !fantasyCurated.some(c => c.id === i.id);
    }).slice(0, 16)
  ].map(toCard);

  // Feel-Good Comedies & Stand-Up
  const comedyQueries = ['Deadpool', 'The Office', 'Friends', 'Brooklyn Nine-Nine', 'Ted Lasso', 'Hangover', 'Superbad', 'The Big Bang Theory'];
  const comedyCurated = findBestMatches(comedyQueries);
  const comedyItems = [
    ...comedyCurated,
    ...categories['english-1080p'].filter(i => {
      const tags = (i.tags || []).join(' ').toLowerCase();
      return tags.includes('comedy') && !comedyCurated.some(c => c.id === i.id);
    }).slice(0, 16)
  ].map(toCard);

  return [
    {
      id: 'top-10-movies',
      title: '🏆 Top 10 Movies Today',
      isTop10: true,
      items: top10Movies
    },
    {
      id: 'top-10-tv',
      title: '📺 Top 10 TV Shows Today',
      isTop10: true,
      items: top10TV
    },
    {
      id: 'trending-nf-amzn',
      title: '🔥 Trending Now on Netflix & Prime',
      items: nfAmznTrending.length >= 10 ? nfAmznTrending : [
        ...categories['english-1080p'].slice(0, 12).map(toCard),
        ...categories['tv-series'].slice(0, 12).map(toCard)
      ]
    },
    {
      id: 'anime-hits',
      title: '⚔️ Trending Anime Hits (Crunchyroll & Netflix)',
      items: animeHits
    },
    {
      id: 'latest-2026',
      title: '✨ Latest 2026 Releases',
      items: [
        ...categories['english-1080p'].filter(i => i.year === 2026).slice(0, 12).map(toCard),
        ...categories['hindi-movies'].filter(i => i.year === 2026).slice(0, 6).map(toCard),
        ...categories['south-movies'].filter(i => i.year === 2026).slice(0, 6).map(toCard)
      ]
    },
    {
      id: 'top-1080p',
      title: '🌟 Top 1080p Full HD Blockbusters',
      items: categories['english-1080p'].slice(0, 24).map(toCard)
    },
    {
      id: 'action-thrillers',
      title: '🍿 Action & High-Octane Thrillers',
      items: actionThrillers
    },
    {
      id: 'sci-fi',
      title: '🚀 Mind-Bending Sci-Fi & Cyberpunk',
      items: sciFiItems
    },
    {
      id: 'horror-thriller',
      title: '🩸 Supernatural Horror & Chilling Mysteries',
      items: horrorItems
    },
    {
      id: 'crime-mystery',
      title: '🔪 Dark Heists, Mob & Psychological Thrillers',
      items: crimeItems
    },
    {
      id: 'romance-drama',
      title: '✨ Romantic Comedies & Heartfelt Dramas',
      items: romanceItems
    },
    {
      id: 'fantasy-adventure',
      title: '🐉 High Fantasy & Mythological Epics',
      items: fantasyItems
    },
    {
      id: 'comedy',
      title: '😂 Feel-Good Comedies & Stand-Up Specials',
      items: comedyItems
    },
    {
      id: 'tv-series',
      title: '📺 Binge-Worthy TV & Web Series (2025–2026)',
      items: categories['tv-series'].slice(0, 24).map(toCard)
    },
    {
      id: 'korean-tv',
      title: '💖 Hot K-Drama Sensations (2025–2026)',
      items: categories['korean-tv'].slice(0, 24).map(toCard)
    },
    {
      id: 'hindi-cinema',
      title: '🇮🇳 Latest Bollywood & Hindi Cinema',
      items: categories['hindi-movies'].slice(0, 24).map(toCard)
    },
    {
      id: 'south-indian',
      title: '💥 South Indian Action & Mass Entertainers',
      items: categories['south-movies'].slice(0, 24).map(toCard)
    },
    {
      id: 'anime-cartoons',
      title: '⚡ Classic & Ongoing Anime Series',
      items: categories['anime-series'].slice(0, 24).map(toCard)
    },
    {
      id: 'animation',
      title: '🎨 Animated Family Hits (2025–2026)',
      items: categories['animation-1080p'].slice(0, 24).map(toCard)
    },
    {
      id: 'imdb-top-250',
      title: '⭐ Critically Acclaimed IMDb Top-250 Classics',
      items: categories['imdb-top250'].slice(0, 24).map(toCard)
    },
    {
      id: 'documentaries',
      title: '🌍 Eye-Opening Documentaries',
      items: categories['documentary'].slice(0, 24).map(toCard)
    },
    {
      id: 'kolkata-bangla',
      title: '🎭 Kolkata Bangla Cinema',
      items: categories['kolkata-bangla'].slice(0, 24).map(toCard)
    },
    {
      id: 'movies-3d',
      title: '👓 3D & IMAX High-Definition Experiences',
      items: categories['movies-3d'].slice(0, 24).map(toCard)
    }
  ];
}

let cachedRows = buildCuratedRows();

// 2. Curated Netflix Carousel Rows
app.get('/api/rows', (req, res) => {
  res.json(cachedRows);
});

// 3. Paginated Category Listings
app.get('/api/category/:id', (req, res) => {
  const cat = categories[req.params.id];
  if (!cat) return res.status(404).json({ error: 'Category not found' });

  const page = parseInt(req.query.page, 10) || 1;
  const limit = parseInt(req.query.limit, 10) || 40;
  const start = (page - 1) * limit;
  const end = start + limit;

  const paginated = cat.slice(start, end).map(toCard);
  res.json({
    category: req.params.id,
    page,
    totalPages: Math.ceil(cat.length / limit),
    totalItems: cat.length,
    items: paginated
  });
});

// 4. Detail info for single item
app.get('/api/item/:id', (req, res) => {
  const item = fullItemMap[req.params.id];
  if (!item) return res.status(404).json({ error: 'Item not found' });

  // Find similar items for "More Like This"
  const catItems = categories[item.category] || Object.values(categories)[0];
  const moreLikeThis = (catItems || [])
    .filter(i => i.id !== item.id)
    .slice(0, 9)
    .map(toCard);

  res.json({
    ...item,
    moreLikeThis
  });
});

// 5. In-Memory Instant Substring / Prefix Search Across All Titles
app.get('/api/search', (req, res) => {
  const query = (req.query.q || '').trim().toLowerCase();
  const typeFilter = req.query.type || null;
  const categoryFilter = req.query.category || null;
  const qualityFilter = req.query.quality || null;
  const limit = parseInt(req.query.limit, 10) || 60;

  if (!query && !typeFilter && !categoryFilter && !qualityFilter) {
    return res.json([]);
  }

  const queryTerms = query ? query.split(/\s+/).filter(Boolean) : [];

  const matched = [];
  for (let i = 0; i < searchIndex.length; i++) {
    const item = searchIndex[i];

    // Filter by type: movie vs series (anime/tv)
    if (typeFilter && item.type !== typeFilter) {
      continue;
    }

    // Filter by category: anime, korean, hindi, english, etc.
    if (categoryFilter && !item.category.toLowerCase().includes(categoryFilter.toLowerCase())) {
      continue;
    }

    // Filter by quality: 1080p, 720p, etc.
    if (qualityFilter && item.quality !== qualityFilter) {
      continue;
    }

    // Multi-term matching across title, tags, year, and category
    if (queryTerms.length > 0) {
      const titleLower = item.title.toLowerCase();
      const tagsStr = (item.tags || []).join(' ').toLowerCase();
      const yearStr = item.year ? String(item.year) : '';
      const catLower = (item.category || '').toLowerCase();

      const matchAll = queryTerms.every(term => 
        titleLower.includes(term) || tagsStr.includes(term) || yearStr.includes(term) || catLower.includes(term)
      );
      if (!matchAll) continue;
    }

    matched.push(item);
    if (matched.length >= limit) break;
  }

  res.json(matched);
});

const { spawn, execSync } = require('child_process');

let hasFfmpeg = false;
try {
  execSync('ffmpeg -version', { stdio: 'ignore' });
  hasFfmpeg = true;
  console.log('🎬 FFmpeg real-time stream remuxer: ACTIVE (Universal Mobile In-Browser Support)');
} catch (_) {
  console.log('⚠️ FFmpeg not detected in PATH. Falling back to HTTP Range streaming proxy.');
}

// 6. HTTP Range & Remux Stream Proxy with Mobile Media Support
app.get('/api/stream-proxy', (req, res) => {
  const targetUrl = req.query.url;
  if (!targetUrl) return res.status(400).send('Missing url parameter');

  const isMkv = targetUrl.toLowerCase().includes('.mkv');
  const forceDirect = req.query.direct === '1';

  // Real-time zero-copy remuxer for mobile in-browser playback:
  // -c:v copy copies video packets without re-encoding (takes < 0.1s and ~0% CPU)
  // -c:a aac converts AC3 5.1/DTS audio to stereo AAC for mobile phone compatibility
  // -movflags frag_keyframe+empty_moov+default_base_moof streams fragmented MP4 directly to browser
  if (isMkv && hasFfmpeg && !forceDirect) {
    const startSec = parseFloat(req.query.t || req.query.start || '0');

    res.writeHead(200, {
      'Content-Type': 'video/mp4',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Range, Content-Type, Accept',
      'Accept-Ranges': 'none',
      'Cache-Control': 'no-cache, no-store'
    });

    const ffmpegArgs = [];
    if (startSec > 0) {
      ffmpegArgs.push('-ss', `${startSec}`);
    }
    ffmpegArgs.push(
      '-reconnect', '1',
      '-reconnect_streamed', '1',
      '-reconnect_delay_max', '5',
      '-i', targetUrl,
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-b:a', '192k',
      '-ac', '2',
      '-movflags', 'frag_keyframe+empty_moov+default_base_moof',
      '-f', 'mp4',
      'pipe:1'
    );

    const ffmpegProc = spawn('ffmpeg', ffmpegArgs, {
      stdio: ['ignore', 'pipe', 'ignore']
    });

    ffmpegProc.stdout.pipe(res);

    req.on('close', () => {
      ffmpegProc.kill('SIGKILL');
    });

    ffmpegProc.on('error', (err) => {
      console.error('FFmpeg remux error:', err);
      if (!res.headersSent) res.status(502).send('Remux error');
    });

    return;
  }

  // Standard high-speed HTTP Range Streaming Proxy (MP4 or direct)
  try {
    const parsedUrl = new URL(targetUrl);
    const headers = { ...req.headers };
    delete headers.host;
    headers['user-agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

    const proxyReq = http.request(targetUrl, {
      method: req.method,
      headers: headers,
      timeout: 15000
    }, (proxyRes) => {
      const responseHeaders = { ...proxyRes.headers };
      
      // Ensure CORS for cross-device mobile playback
      responseHeaders['access-control-allow-origin'] = '*';
      responseHeaders['access-control-allow-headers'] = 'Range, Content-Type, Accept';
      responseHeaders['access-control-expose-headers'] = 'Content-Range, Content-Length, Accept-Ranges';

      // Mobile browsers (Safari/Chrome) reject 'application/octet-stream' in <video> elements.
      if (!responseHeaders['content-type'] || responseHeaders['content-type'] === 'application/octet-stream') {
        responseHeaders['content-type'] = 'video/mp4';
      }

      res.writeHead(proxyRes.statusCode, responseHeaders);
      proxyRes.pipe(res);
    });

    proxyReq.on('timeout', () => {
      proxyReq.destroy();
      if (!res.headersSent) {
        res.status(504).send('Stream proxy connection timed out');
      }
    });

    proxyReq.on('error', (err) => {
      if (!res.headersSent) {
        res.status(502).send(`Stream proxy error: ${err.message}`);
      }
    });

    req.on('close', () => {
      proxyReq.destroy();
    });

    if (req.method === 'POST') {
      req.pipe(proxyReq);
    } else {
      proxyReq.end();
    }
  } catch (err) {
    if (!res.headersSent) {
      res.status(400).send(`Invalid URL: ${err.message}`);
    }
  }
});

// 7. Automated Incremental Catalog Sync Engine
const { syncState, runIncrementalSync, startScheduledSync } = require('./sync-worker');

app.get('/api/sync/status', (req, res) => {
  res.json({
    ...syncState,
    catalogTotal: searchIndex.length,
    uptime: process.uptime()
  });
});

app.post('/api/sync/trigger', async (req, res) => {
  const result = await runIncrementalSync(dataDir, () => {
    console.log('🔄 Hot-reloading shards into memory...');
    cachedRows = buildCuratedRows();
  });
  res.json(result);
});

// Start background auto-sync daemon (runs every 6 hours)
startScheduledSync(dataDir, () => {
  console.log('🔄 Auto-sync hot-reloaded shards into memory.');
  cachedRows = buildCuratedRows();
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    totalCatalogItems: searchIndex.length,
    timestamp: new Date().toISOString()
  });
});

// Network Probe: Check if ISP has access to DhakaFlix storage server (172.16.50.4)
app.get('/api/network-check', (req, res) => {
  const simulate = req.query.simulate;
  if (simulate === 'offline') {
    return res.json({
      reachable: false,
      target: '172.16.50.4',
      status: 0,
      responseTimeMs: 3000,
      error: 'Simulated failure: Your network provider does not have DhakaFlix server routing to 172.16.50.4'
    });
  }
  if (simulate === 'online') {
    return res.json({
      reachable: true,
      target: '172.16.50.4',
      status: 200,
      responseTimeMs: 8,
      message: 'DhakaFlix BDIX server is active and reachable'
    });
  }

  let responded = false;
  const sendResponse = (payload) => {
    if (responded) return;
    responded = true;
    res.json(payload);
  };

  const startTime = Date.now();
  const probeReq = http.request(
    {
      hostname: '172.16.50.4',
      port: 80,
      path: '/',
      method: 'HEAD',
      timeout: 3500,
      headers: {
        'User-Agent': 'HomeFlix-ISP-Probe/1.0'
      }
    },
    (probeRes) => {
      const responseTimeMs = Date.now() - startTime;
      sendResponse({
        reachable: probeRes.statusCode >= 200 && probeRes.statusCode < 500,
        target: '172.16.50.4',
        status: probeRes.statusCode,
        responseTimeMs,
        server: probeRes.headers['server'] || 'nginx'
      });
    }
  );

  probeReq.on('timeout', () => {
    probeReq.destroy();
    sendResponse({
      reachable: false,
      target: '172.16.50.4',
      status: 504,
      responseTimeMs: Date.now() - startTime,
      error: 'Connection timed out (3500ms). Your network provider does not route to DhakaFlix server (172.16.50.4).'
    });
  });

  probeReq.on('error', (err) => {
    sendResponse({
      reachable: false,
      target: '172.16.50.4',
      status: 503,
      responseTimeMs: Date.now() - startTime,
      error: err.message || 'Host unreachable'
    });
  });

  probeReq.end();
});

// Serve built frontend static assets if available (enables single-port hosting for TV & Phone)
const frontendDist = path.join(__dirname, '..', 'frontend', 'dist');
if (fs.existsSync(frontendDist)) {
  console.log(`Serving frontend static build from ${frontendDist}`);
  app.use(express.static(frontendDist));
  app.use((req, res, next) => {
    if (req.method === 'GET' && !req.path.startsWith('/api')) {
      return res.sendFile(path.join(frontendDist, 'index.html'));
    }
    next();
  });
}

app.listen(PORT, '0.0.0.0', () => {
  console.log(`HomeFlix High-Speed Backend running on http://0.0.0.0:${PORT}`);
});
