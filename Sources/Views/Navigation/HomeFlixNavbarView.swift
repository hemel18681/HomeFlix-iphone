import SwiftUI

public struct HomeFlixNavbarView: View {
    @Binding var selectedTab: String
    let onSearchTap: () -> Void
    let onPreferencesTap: () -> Void
    
    public let tabs = [
        ("home", "Home"),
        ("series", "TV Shows"),
        ("movies", "Movies"),
        ("anime", "Anime"),
        ("mylist", "My List")
    ]
    
    public init(
        selectedTab: Binding<String>,
        onSearchTap: @escaping () -> Void,
        onPreferencesTap: @escaping () -> Void
    ) {
        self._selectedTab = selectedTab
        self.onSearchTap = onSearchTap
        self.onPreferencesTap = onPreferencesTap
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Main Navigation Bar Row
            HStack(spacing: 12) {
                // HomeFlix Brand Logo
                Text("HOMEFLIX")
                    .font(.system(size: 20, weight: .black, design: .default))
                    .tracking(2.0)
                    .foregroundColor(HomeFlixTheme.brandRed)
                
                Spacer()
                
                // Taste Personalization Button
                Button(action: onPreferencesTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .semibold))
                        Text("For You")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(14)
                }
                
                // Search Button
                Button(action: onSearchTap) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Sub-category Navigation Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(tabs, id: \.0) { tabId, label in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tabId
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(label)
                                    .font(.system(size: 13, weight: selectedTab == tabId ? .bold : .medium))
                                    .foregroundColor(selectedTab == tabId ? .white : HomeFlixTheme.textSecondary)
                                
                                if selectedTab == tabId {
                                    Rectangle()
                                        .fill(HomeFlixTheme.brandRed)
                                        .frame(height: 2)
                                        .cornerRadius(1)
                                } else {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 2)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 6)
        }
        .background(
            HomeFlixTheme.background.opacity(0.92)
                .background(.ultraThinMaterial)
        )
    }
}

