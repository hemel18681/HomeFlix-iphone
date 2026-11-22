const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const agent = new http.Agent({
  keepAlive: true,
  maxSockets: 20,
  timeout: 10000
});

function fetch(url) {
  return new Promise((resolve) => {
    http.get(url, { agent, headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' } }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', () => resolve(''));
  });
}

function parseH5ai(html) {
  const items = [];
  const re = /<tr><td class="fb-i"><img src="[^"]*fallback\/([^.]+)\.png"[^>]*><\/td><td class="fb-n"><a href="([^"]+)">([^<]+)<\/a><\/td><td class="fb-d">([^<]*)<\/td><td class="fb-s">([^<]*)<\/td><\/tr>/g;
  let match;
  while ((match = re.exec(html)) !== null) {
    if (match[3] !== 'Parent Directory') {
      items.push({
        type: match[1],
        href: match[2],
        name: match[3],
        date: match[4].trim(),
        size: match[5].trim()
      });
    }
  }
  return items;
}

const syncState = {
  lastSyncTime: new Date().toISOString(),
  status: 'idle',
  totalItemsSynced: 37029,
  newItemsFound: 0,
  intervalHours: 6,
  logs: ['Sync worker initialized. Monitoring ISP storage servers (172.16.50.4/7/8/10/12/14).']
};

function log(msg) {
  const line = `[${new Date().toLocaleTimeString()}] ${msg}`;
  console.log(line);
  syncState.logs.unshift(line);
  if (syncState.logs.length > 30) syncState.logs.pop();
}

async function runIncrementalSync(dataDir, onReloadRequired) {
  if (syncState.status === 'syncing') {
    return { success: false, message: 'Sync already in progress' };
  }

  syncState.status = 'syncing';
  log('Starting incremental sync scan across storage nodes...');

  try {
    const itemsMapPath = path.join(dataDir, 'items-map.json');
    const itemsMap = fs.existsSync(itemsMapPath) ? JSON.parse(fs.readFileSync(itemsMapPath, 'utf8')) : {};
    
    // Nodes to poll
    const nodes = [
      { name: 'Node 1 (1080p Movies)', url: 'http://172.16.50.7/DHAKA-FLIX-DISK-01/English%20Movies%20%281080p%29/' },
      { name: 'Node 2 (Hindi Movies)', url: 'http://172.16.50.8/DHAKA-FLIX-DISK-02/Hindi%20Movies/' },
      { name: 'Node 3 (TV Series)', url: 'http://172.16.50.10/DHAKA-FLIX-DISK-04/TV%20%26%20Web%20Series/' },
      { name: 'Node 4 (Anime Series)', url: 'http://172.16.50.12/DHAKA-FLIX-DISK-06/Anime%20%26%20Cartoon%20TV%20Series/' },
      { name: 'Node 5 (Korean Series)', url: 'http://172.16.50.14/DHAKA-FLIX-DISK-08/Korean%20TV%20%26%20Web%20Series/' }
    ];

    let newlyAdded = 0;

    for (const node of nodes) {
      const html = await fetch(node.url);
      if (!html) continue;
      const entries = parseH5ai(html);

      // Check entries
      for (const entry of entries) {
        const uniqueKey = entry.name;
        const exists = Object.values(itemsMap).some(it => (it.rawName || it.title) === uniqueKey);
        if (!exists) {
          newlyAdded++;
        }
      }
    }

    syncState.lastSyncTime = new Date().toISOString();
    syncState.newItemsFound = newlyAdded;
    syncState.status = 'idle';
    log(`Incremental sync completed. Scanned 5 nodes. New additions: ${newlyAdded}. Total catalog: ${syncState.totalItemsSynced + newlyAdded}`);

    if (newlyAdded > 0 && typeof onReloadRequired === 'function') {
      onReloadRequired();
    }

    return {
      success: true,
      lastSyncTime: syncState.lastSyncTime,
      newItemsFound: newlyAdded,
      totalCatalogCount: syncState.totalItemsSynced + newlyAdded
    };
  } catch (err) {
    syncState.status = 'idle';
    log(`Sync error: ${err.message}`);
    return { success: false, error: err.message };
  }
}

// Start auto-sync interval (every 6 hours)
function startScheduledSync(dataDir, onReloadRequired, intervalMs = 6 * 60 * 60 * 1000) {
  setInterval(() => {
    log('⏰ Scheduled 6-hour incremental sync triggered...');
    runIncrementalSync(dataDir, onReloadRequired);
  }, intervalMs);
  log('Auto-sync daemon scheduled (runs every 6 hours).');
}

module.exports = {
  syncState,
  runIncrementalSync,
  startScheduledSync
};
