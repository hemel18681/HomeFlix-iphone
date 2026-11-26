import SwiftUI

public struct SearchModalView: View {
    @ObservedObject var catalogStore = CatalogStore.shared
    let onClose: () -> Void
    let onSelectItem: (MediaItem) -> Void
    
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "All"
    @State private var searchResults: [MediaItem] = []
    @FocusState private var isSearchFieldFocused: Bool
    
    public init(onClose: @escaping () -> Void, onSelectItem: @escaping (MediaItem) -> Void) {
        self.onClose = onClose
        self.onSelectItem = onSelectItem
    }
    
    private func dismissKeyboard() {
        isSearchFieldFocused = false
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
    
    private let filterOptions = ["All", "Movies", "TV Series", "Anime", "1080p"]
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    private func executeSearch() {
        let typeFilter = selectedFilter == "Movies" ? "movie" : (selectedFilter == "TV Series" ? "series" : nil)
        let categoryFilter = selectedFilter == "Anime" ? "Anime" : nil
        let qualityFilter = selectedFilter == "1080p" ? "1080p" : nil
        
        searchResults = catalogStore.search(
            query: searchText,
            typeFilter: typeFilter,
            categoryFilter: categoryFilter,
            qualityFilter: qualityFilter
        )
    }
    
    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                // Search Input Header (clears iPhone Notch & Dynamic Island)
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundColor(HomeFlixTheme.textMuted)
                        
                        TextField("Search movies, shows, anime...", text: $searchText)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                            .autocorrectionDisabled()
                            .focused($isSearchFieldFocused)
                            .submitLabel(.search)
                            .onSubmit {
                                dismissKeyboard()
                            }
                            .onChange(of: searchText) { _ in
                                executeSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                executeSearch()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(HomeFlixTheme.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "262626"))
                    .cornerRadius(6)
                    
                    Button("Cancel") {
                        dismissKeyboard()
                        onClose()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.top, max(56, proxy.safeAreaInsets.top + 10))
                .padding(.bottom, 12)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filterOptions, id: \.self) { opt in
                            Button(action: {
                                selectedFilter = opt
                                executeSearch()
                            }) {
                                Text(opt)
                                    .font(.system(size: 12, weight: selectedFilter == opt ? .bold : .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedFilter == opt ? HomeFlixTheme.brandRed : Color(hex: "222222"))
                                    .cornerRadius(14)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
                
                // Search Results Grid
                ScrollView(.vertical, showsIndicators: false) {
                    if searchResults.isEmpty && !searchText.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "film")
                                .font(.system(size: 40))
                                .foregroundColor(HomeFlixTheme.textMuted)
                                .padding(.top, 40)
                            Text("No matching titles found")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(HomeFlixTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissKeyboard()
                        }
                    } else {
                        let cardWidth = (proxy.size.width - 48) / 3
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(searchResults) { item in
                                MediaCardView(
                                    item: item,
                                    width: cardWidth,
                                    isLandscape: false,
                                    onSelect: { selected in
                                        dismissKeyboard()
                                        onSelectItem(selected)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        dismissKeyboard()
                    }
                )
            }
        }
        .background(HomeFlixTheme.background.edgesIgnoringSafeArea(.all))
        .onAppear {
            executeSearch()
        }
    }
}
