# HomeFlix Mobile — Native iOS Media Streaming Application

A native iOS media streaming application built with **Swift 5.9+** and **SwiftUI**. Designed for high-performance media playback over local area networks with local caching and offline catalog browsing.

---

## Features

- **Standalone Catalog:**
  - Bundled media catalog index and metadata stored locally in the application bundle.
  - Sub-millisecond in-memory search and category filtering powered by Swift native collections.
  - Local persistence for watch history and user favorites via system storage.

- **Integrated Media Player:**
  - Hardware-accelerated playback engine using Apple's AVFoundation.
  - Native gesture controls, skip forward/backward, scrub bar, and playback rate adjustments.
  - Multi-track audio and subtitle channel switcher.
  - External media player support integration.

- **Modern Dark Interface:**
  - High-resolution hero display with custom gradient vignettes.
  - Horizontal scrolling media carousels and top-ranked collections.
  - Modal detail sheets featuring season and episode listings.
  - Fast grid-based catalog search with real-time query matching.
  - Customizable content preference categories.

---

## Tech Stack

- **Language:** Swift 5.9+
- **Framework:** SwiftUI
- **Media Engine:** AVFoundation / AVKit
- **Package Management:** Swift Package Manager (SPM)
- **Minimum Requirements:** iOS 16.0+ / macOS 13.0+

---

## Project Structure

```
mobile-app/
├── Package.swift                    # Swift Package Manager configuration
├── Info.plist                       # App configuration and network settings
├── README.md                        # Project documentation
├── HomeFlix.xcodeproj/              # Xcode project files
├── Sources/
│   ├── HomeFlixApp.swift            # App entry point
│   ├── Resources/                   # Bundled catalog data and indices
│   ├── Theme/                       # UI styling, colors, and typography
│   ├── Models/                      # Media and preference data models
│   ├── Services/                    # Catalog search and storage services
│   └── Views/                       # SwiftUI views and player components
└── web-reference/                   # Reference web client and backend
```

---

## Build & Installation

### Requirements
- macOS Ventura 13.0+
- Xcode 15.0+
- Physical iOS device or iOS Simulator (iOS 16.0+)

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/hemel18681/mobile-app.git
   cd mobile-app
   ```
2. Open the project in Xcode:
   ```bash
   open Package.swift
   # Or open HomeFlix.xcodeproj
   ```
3. Select your development signing team in Xcode under Target Settings > Signing & Capabilities.
4. Select your target device or simulator and run (`Cmd + R`).

---

## License

This project is licensed under the MIT License.
