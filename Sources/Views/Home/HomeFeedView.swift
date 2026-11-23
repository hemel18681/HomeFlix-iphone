import SwiftUI

public struct HomeFeedView: View {
    @ObservedObject var catalogStore = CatalogStore.shared
    @ObservedObject var watchlistStore = WatchlistStore.shared
    @Binding var selectedTab: String
    
    let onSelectItem: (MediaItem) -> Void
    let onPlayItem: (MediaItem) -> Void
    
    // Page sub-filters
    @State private var tvFilter: String = "All"
    @State private var movieFilter: String = "All"
    @State private var animeFilter: String = "All"
    
    public init(
        selectedTab: Binding<String>,
        onSelectItem: @escaping (MediaItem) -> Void,
        onPlayItem: @escaping (MediaItem) -> Void
    ) {
        self._selectedTab = selectedTab
        self.onSelectItem = onSelectItem
        self.onPlayItem = onPlayItem
    }
    
    public var body: some View {
        ZStack {
            HomeFlixTheme.background
                .edgesIgnoringSafeArea(.all)
            
            switch selectedTab {
            case "home":
                homePage
            case "series":
                tvShowsPage
            case "movies":
                moviesPage
            case "anime":
                animePage
            case "mylist":
                myListPage
            default:
                homePage
            }
        }
    }
    
    // MARK: - 1. DEDICATED HOME PAGE
    private var homePage: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 22) {
                // Dynamic Billboard Hero (matches user affinities & rotates on refresh)
                BillboardHeroView(
                    item: catalogStore.getPersonalizedHero(
                        history: watchlistStore.history,
                        preferences: watchlistStore.preferences,
                        refreshSeed: catalogStore.refreshSeed
                    ),
                    onPlay: onPlayItem,
                    onMoreInfo: onSelectItem
                )
                
                // Continue Watching (if user has watch progress)
                if !watchlistStore.continueWatchingItems.isEmpty {
                    ContentRowView(
                        row: CategoryRow(
                            id: "continue-watching",
                            title: "⏳ Continue Watching for You",
                            items: watchlistStore.continueWatchingItems
                        ),
                        onSelect: onSelectItem
                    )
                }
                
                // Dynamic Real-Time Personalized Rows (Watch History + Likes + Preferences + Discoveries)
                let rows = catalogStore.getPersonalizedRows(
                    selectedPreferences: watchlistStore.preferences,
                    history: watchlistStore.history,
                    likes: watchlistStore.likes,
                    refreshSeed: catalogStore.refreshSeed
                )
                ForEach(rows) { row in
                    ContentRowView(row: row, onSelect: onSelectItem)
                }
                
                Color.clear.frame(height: 80)
            }
        }
        .refreshable {
            withAnimation(.easeInOut(duration: 0.25)) {
                catalogStore.refreshFeed()
            }
        }
    }
    
    // MARK: - 2. DEDICATED TV SHOWS PAGE
    private var tvShowsPage: some View {
        let tvHeroes = catalogStore.featured.filter { $0.type == .series }
        let tvHero = !tvHeroes.isEmpty ? tvHeroes[abs(catalogStore.refreshSeed) % tvHeroes.count] :
                     catalogStore.curatedRows.first(where: { $0.id == "top-10-tv" })?.items.first
        
        let tvFilters = ["All", "Top 10", "Binge-Worthy", "K-Drama", "Anime Series"]
        
        return ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // TV Shows Billboard Hero
                if let hero = tvHero {
                    BillboardHeroView(
                        item: hero,
                        onPlay: onPlayItem,
                        onMoreInfo: onSelectItem
                    )
                }
                
                // TV Sub-filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(tvFilters, id: \.self) { filter in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    tvFilter = filter
                                }
                            }) {
                                Text(filter)
                                    .font(.system(size: 12, weight: tvFilter == filter ? .bold : .medium))
                                    .foregroundColor(tvFilter == filter ? .white : HomeFlixTheme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(tvFilter == filter ? HomeFlixTheme.brandRed : Color(hex: "222222"))
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Filtered TV Rows
                let tvRows = getTVRows()
                ForEach(tvRows) { row in
                    ContentRowView(row: row, onSelect: onSelectItem)
                }
                
                Color.clear.frame(height: 80)
            }
        }
        .refreshable {
            withAnimation(.easeInOut(duration: 0.25)) {
                catalogStore.refreshFeed()
            }
        }
    }
    
    private func getTVRows() -> [CategoryRow] {
        let allTvRows = catalogStore.curatedRows.filter { row in
            row.id == "top-10-tv" ||
            row.id == "tv-series" ||
            row.id == "korean-tv" ||
            row.id == "anime-hits" ||
            row.id == "anime-cartoons" ||
            row.items.contains { $0.type == .series }
        }
        
        switch tvFilter {
        case "Top 10":
            return allTvRows.filter { $0.id == "top-10-tv" }
        case "Binge-Worthy":
            return allTvRows.filter { $0.id == "tv-series" }
        case "K-Drama":
            return allTvRows.filter { $0.id == "korean-tv" }
        case "Anime Series":
            return allTvRows.filter { $0.id.contains("anime") }
        default:
            return allTvRows
        }
    }
    
    // MARK: - 3. DEDICATED MOVIES PAGE
    private var moviesPage: some View {
        let movieHeroes = catalogStore.featured.filter { $0.type == .movie }
        let movieHero = !movieHeroes.isEmpty ? movieHeroes[abs(catalogStore.refreshSeed) % movieHeroes.count] :
                        catalogStore.curatedRows.first(where: { $0.id == "top-10-movies" })?.items.first
        
        let movieFilters = ["All", "Top 10", "1080p HD", "Action", "Sci-Fi", "Horror", "Comedy", "3D / IMAX"]
        
        return ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Movies Billboard Hero
                if let hero = movieHero {
                    BillboardHeroView(
                        item: hero,
                        onPlay: onPlayItem,
                        onMoreInfo: onSelectItem
                    )
                }
                
                // Movie Sub-filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(movieFilters, id: \.self) { filter in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    movieFilter = filter
                                }
                            }) {
                                Text(filter)
                                    .font(.system(size: 12, weight: movieFilter == filter ? .bold : .medium))
                                    .foregroundColor(movieFilter == filter ? .white : HomeFlixTheme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(movieFilter == filter ? HomeFlixTheme.brandRed : Color(hex: "222222"))
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Filtered Movie Rows
                let movieRows = getMovieRows()
                ForEach(movieRows) { row in
                    ContentRowView(row: row, onSelect: onSelectItem)
                }
                
                Color.clear.frame(height: 80)
            }
        }
        .refreshable {
            withAnimation(.easeInOut(duration: 0.25)) {
                catalogStore.refreshFeed()
            }
        }
    }
    
    private func getMovieRows() -> [CategoryRow] {
        let allMovieRows = catalogStore.curatedRows.filter { row in
            row.id == "top-10-movies" ||
            row.id == "latest-2026" ||
            row.id == "top-1080p" ||
            row.id == "action-thrillers" ||
            row.id == "sci-fi" ||
            row.id == "horror-thriller" ||
            row.id == "crime-mystery" ||
            row.id == "romance-drama" ||
            row.id == "fantasy-adventure" ||
            row.id == "comedy" ||
            row.id == "hindi-cinema" ||
            row.id == "south-indian" ||
            row.id == "animation" ||
            row.id == "imdb-top-250" ||
            row.id == "documentaries" ||
            row.id == "kolkata-bangla" ||
            row.id == "movies-3d"
        }
        
        switch movieFilter {
        case "Top 10":
            return allMovieRows.filter { $0.id == "top-10-movies" }
        case "1080p HD":
            return allMovieRows.filter { $0.id == "top-1080p" || $0.id == "latest-2026" }
        case "Action":
            return allMovieRows.filter { $0.id == "action-thrillers" || $0.id == "south-indian" }
        case "Sci-Fi":
            return allMovieRows.filter { $0.id == "sci-fi" }
        case "Horror":
            return allMovieRows.filter { $0.id == "horror-thriller" }
        case "Comedy":
            return allMovieRows.filter { $0.id == "comedy" }
        case "3D / IMAX":
            return allMovieRows.filter { $0.id == "movies-3d" }
        default:
            return allMovieRows
        }
    }
    
    // MARK: - 4. DEDICATED ANIME PAGE
    private var animePage: some View {
        let animeHits = catalogStore.curatedRows.first(where: { $0.id == "anime-hits" })?.items ?? []
        let animeHero = !animeHits.isEmpty ? animeHits[abs(catalogStore.refreshSeed) % animeHits.count] :
                        catalogStore.curatedRows.first(where: { $0.id == "anime-cartoons" })?.items.first
        
        let animeFilters = ["All", "Trending", "Classics", "Animation"]
        
        return ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Anime Billboard Hero
                if let hero = animeHero {
                    BillboardHeroView(
                        item: hero,
                        onPlay: onPlayItem,
                        onMoreInfo: onSelectItem
                    )
                }
                
                // Anime Sub-filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(animeFilters, id: \.self) { filter in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    animeFilter = filter
                                }
                            }) {
                                Text(filter)
                                    .font(.system(size: 12, weight: animeFilter == filter ? .bold : .medium))
                                    .foregroundColor(animeFilter == filter ? .white : HomeFlixTheme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(animeFilter == filter ? HomeFlixTheme.brandRed : Color(hex: "222222"))
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Filtered Anime Rows
                let animeRows = getAnimeRows()
                ForEach(animeRows) { row in
                    ContentRowView(row: row, onSelect: onSelectItem)
                }
                
                Color.clear.frame(height: 80)
            }
        }
        .refreshable {
            withAnimation(.easeInOut(duration: 0.25)) {
                catalogStore.refreshFeed()
            }
        }
    }
    
    private func getAnimeRows() -> [CategoryRow] {
        let allAnimeRows = catalogStore.curatedRows.filter { row in
            row.id == "anime-hits" ||
            row.id == "anime-cartoons" ||
            row.id == "animation" ||
            row.title.contains("Anime")
        }
        
        switch animeFilter {
        case "Trending":
            return allAnimeRows.filter { $0.id == "anime-hits" }
        case "Classics":
            return allAnimeRows.filter { $0.id == "anime-cartoons" }
        case "Animation":
            return allAnimeRows.filter { $0.id == "animation" }
        default:
            return allAnimeRows
        }
    }
    
    // MARK: - 5. DEDICATED MY LIST PAGE (WITH 1-TAP REMOVE BUTTON ON CARDS)
    private var myListPage: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(alignment: .firstTextBaseline) {
                        Text("My List")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.white)
                        
                        Text("\(watchlistStore.mylistItems.count) Titles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(HomeFlixTheme.textSecondary)
                            .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 74)
                    
                    // Empty State
                    if watchlistStore.mylistItems.isEmpty {
                        VStack(spacing: 16) {
                            Spacer().frame(height: 40)
                            
                            Image(systemName: "bookmark.slash")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(Color(hex: "555555"))
                            
                            Text("Your list is empty")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Explore movies and TV shows and tap '+' on any title to save them here.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(HomeFlixTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                withAnimation {
                                    selectedTab = "home"
                                }
                            }) {
                                Text("Explore HomeFlix")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 10)
                                    .background(HomeFlixTheme.brandRed)
                                    .cornerRadius(6)
                            }
                            .padding(.top, 8)
                            
                            Spacer().frame(height: 60)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // 3-Column HomeFlix Poster Grid
                        let cardWidth = (proxy.size.width - 52) / 3
                        let columns = [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(watchlistStore.mylistItems) { item in
                                MediaCardView(
                                    item: item,
                                    width: cardWidth,
                                    isLandscape: false,
                                    showRemoveButton: true,
                                    onRemove: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            watchlistStore.removeFromWatchlist(id: item.id)
                                        }
                                    },
                                    onSelect: onSelectItem
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Color.clear.frame(height: 80)
                }
            }
        }
    }
}
