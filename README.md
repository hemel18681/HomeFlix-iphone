# HomeFlix Mobile — Pure Native Standalone iOS Application (Swift & SwiftUI)

A native iOS application engineered with **Swift 5.9+** and **SwiftUI** for Apple macOS and Xcode. It mirrors the authentic Netflix streaming UI and delivers playback of all video formats directly from local BDIX networks without server dependencies or WebKit browser engine restrictions.

---

## 🚀 Key Architectural Advantages

### 1. 100% Serverless & Standalone Architecture
- **No Node.js Backend Required:** The complete catalog index (37,000+ titles, 23 curated Netflix rows, 10 Billboard Hero specials, and hundreds of episodic TV/Anime seasons) is bundled directly into the application under `Sources/Resources/`.
- **Instantaneous Search & Filtering (<1ms):** Searches execute directly in memory on Apple Silicon (A-series / M-series CPUs) with zero network roundtrips.
- **On-Device Watchlist & Progress Persistence:** Your "My List", continue-watching percentage, and audio preferences are persisted automatically using local system storage (`UserDefaults` and JSON disk cache).

### 2. Dedicated Universal Video Player Engine
- **No Browser Engine Restrictions:** Bypasses iOS Safari/WebKit constraints which block `.mkv` containers and Dolby Digital multi-channel AC3 dual-audio.
- **Hardware-Accelerated Apple Decoders:** High-throughput streaming via AVFoundation with automatic buffer pre-caching.
- **Full App Transport Security (ATS) Exemption:** Configured in `Info.plist` (`NSAllowsArbitraryLoads` and `NSAllowsLocalNetworking`) so your iPhone can stream directly from local BDIX server IPs (`http://172.16.50.4/...` and `http://172.16.50.7/...`) over home Wi-Fi.
- **Authentic Netflix Player UI:**
  - Center 10-second skip backward / forward buttons and circular Play/Pause toggle.
  - Top navigation bar with media title, season/episode details, and audio & subtitle switcher.
  - Bottom scrub bar in Netflix Red (`#E50914`) with elapsed time and duration timestamps.
  - Playback speed adjustment (0.75x, 1.0x, 1.25x, 1.5x).
  - Landscape auto-lock orientation.
  - Multi-track dual-audio selector (Original 5.1, Hindi 5.1, English Stereo).
  - Pure in-app universal decoding for all containers (MKV, MP4, HLS) and audio tracks directly on-screen.

### 3. Exact Netflix UI Replica (Pixel-for-Pixel)
- **Palette & Dark Aesthetic:** Background `#141414`, Card Surface `#181818`, Accents `#E50914`.
- **Billboard Hero:** 16:9 widescreen backdrop with triple vignette gradients (top, left, bottom), Top 10 badges, 4K/1080p indicators, Dual Audio badges, Play, and More Info actions.
- **Top 10 Numbered Rows:** Giant stylized Netflix numbered outline badges (#1 to #10) nestled beside each poster card.
- **18-Category Personalization Engine:** Multi-select taste profile sheet that dynamically elevates matching rows to the top of your feed with personalized badges.
- **Slide-up Detail Sheet:** Full synopsis, season/episode picker with file size & duration, and "More Like This" recommendation grid.
- **Instant Search:** Dynamic 3-column Netflix grid with category filtering chips.

---

## 📁 Project Directory Structure

```
mobile-app/
├── Package.swift                    # SwiftPM configuration (iOS 16+, macOS 13+)
├── Info.plist                       # iOS configuration (ATS HTTP BDIX streaming, background audio)
├── README.md                        # This documentation
├── Sources/
│   ├── HomeFlixApp.swift            # App entry point (@main)
│   ├── Resources/                   # Bundled serverless data
│   │   ├── featured.json            # 10 Featured Billboard items
│   │   ├── curated-rows.json        # 23 Curated Netflix carousel rows
│   │   ├── series-episodes.json     # TV and Anime series season & episode trees
│   │   └── search-index.json        # 37,000+ searchable catalog index
│   ├── Theme/
│   │   └── NetflixTheme.swift       # Netflix colors, gradients, and typography
│   ├── Models/
│   │   ├── MediaItem.swift          # Media item, quality, and metadata
│   │   ├── SeasonEpisode.swift      # Season, Episode, and SeriesDetail models
│   │   ├── CategoryRow.swift        # Curated carousel row definition
│   │   ├── WatchProgress.swift      # Continue Watching progress tracking
│   │   └── TastePreference.swift    # 18 taste personalization profiles
│   ├── Services/
│   │   ├── CatalogStore.swift       # In-memory search & personalized curation
│   │   ├── WatchlistStore.swift     # Local persistent storage
│   │   └── DedicatedPlayerManager.swift # Fullscreen dedicated player coordinator
│   └── Views/
│       ├── Root/
│       │   └── ContentView.swift    # Master navigation & overlay coordinator
│       ├── Navigation/
│       │   └── NetflixNavbarView.swift # Netflix logo, tabs, search & taste buttons
│       ├── Home/
│       │   ├── HomeFeedView.swift   # Main vertical scrolling feed
│       │   ├── BillboardHeroView.swift # 16:9 Billboard hero with vignettes
│       │   ├── ContentRowView.swift # Horizontal scrolling carousel row
│       │   ├── MediaCardView.swift  # Netflix card with progress & badges
│       │   └── Top10RankBadge.swift # Giant outline numbers (#1 - #10)
│       ├── Detail/
│       │   ├── DetailSheetView.swift # Slide-up detail sheet
│       │   ├── EpisodeListView.swift # Season selector & episode list
│       │   └── MoreLikeThisGridView.swift # Similar titles recommendation grid
│       ├── Player/
│       │   ├── DedicatedPlayerView.swift # Fullscreen dedicated player
│       │   ├── NetflixPlayerControls.swift # Netflix on-screen playback controls
│       │   └── AudioSubtitleMenu.swift # Multi-track audio & subtitle selector
│       ├── Search/
│       │   └── SearchModalView.swift # Real-time instant search modal
│       ├── Preferences/
│       │   └── TastePreferencesSheet.swift # 18 taste categories selection
│       └── Components/
│           ├── AsyncImageView.swift # Asynchronous image loader with cache
│           └── ShimmerLoadingView.swift # Skeleton loading shimmer animation
└── web-reference/                   # Preserved web frontend and backend code
    ├── frontend/
    └── backend/
```

---

## 🖥️ How to Build & Run in Xcode (macOS)

### 1. Requirements
- **Mac:** Any Mac running macOS Monterey, Ventura, Sonoma, or Sequoia.
- **Xcode:** Xcode 15 or 16 (available free from the Mac App Store).
- **Target Device:** Any physical iPhone running iOS 16.0+ (or an iOS Simulator).
- **Apple ID:** A free personal Apple ID (or paid Apple Developer Account) for code signing.

---

### 2. Opening the Project in Xcode
1. Copy or clone the `/workspace/mobile-app` folder onto your Mac.
2. Launch **Xcode**.
3. Select **File > Open...** (or press **Cmd + O**).
4. Navigate to and select the `mobile-app` folder (or double-click `Package.swift`).
5. Xcode will automatically resolve the Swift Package, index the Swift 5.9 source files, and load the bundled resources.

---

### 3. Configuring Signing (For Physical iPhone)
1. In the Xcode toolbar or project navigator, click on the **HomeFlix** project / target.
2. Go to the **Signing & Capabilities** tab.
3. Check **Automatically manage signing**.
4. In the **Team** dropdown, select your personal Apple ID or development team.
   *(If not logged in yet, go to **Xcode > Settings > Accounts** and click `+` to sign in with your Apple ID)*.
5. Set the **Bundle Identifier** to something unique if needed (e.g., `com.yourname.homeflix`).

---

### 4. Running on iPhone or Simulator
1. Connect your physical iPhone to your Mac via USB cable (or select an **iOS Simulator** like *iPhone 16 Pro* from the top device target selector).
2. If connecting a physical iPhone for the first time:
   - Unlock your iPhone and tap **"Trust This Computer"**.
   - Ensure **Developer Mode** is turned on: on iPhone, go to **Settings > Privacy & Security > Developer Mode** (toggle ON & restart).
3. In Xcode, press **Cmd + R** (or click the **Play** button in the top-left toolbar).
4. Xcode compiles the app, signs it with your personal profile, installs it on your iPhone, and starts live debugging!

---

### 5. First-Time Launch Approval on Physical iPhone
If using a free personal Apple ID, the first time the app installs, iOS will display:
> *"Untrusted Developer"*

To approve it:
1. On your iPhone, open **Settings**.
2. Navigate to **General > VPN & Device Management**.
3. Under **Developer App**, tap your Apple ID email.
4. Tap **Trust "[Your Apple ID]"** and confirm.
5. Tap **HomeFlix** on your home screen — it will open immediately!

---

## 📱 Playing Over Local Wi-Fi (BDIX Streaming)

1. Ensure your iPhone is connected to the same home Wi-Fi network that has access to the BDIX servers (`172.16.50.4` or `172.16.50.7`).
2. Launch **HomeFlix**.
3. Browse the home feed or search across all 37,000+ titles.
4. Tap **Play** on any card or episode — the dedicated player connects directly to the stream.
5. If playing an MKV file containing multi-track audio (e.g., Hindi 5.1 + English 5.1), tap **Audio** in the top right to switch audio tracks on the fly directly in the player.
