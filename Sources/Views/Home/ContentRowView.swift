import SwiftUI

public struct ContentRowView: View {
    let row: CategoryRow
    let onSelect: (MediaItem) -> Void
    
    public init(row: CategoryRow, onSelect: @escaping (MediaItem) -> Void) {
        self.row = row
        self.onSelect = onSelect
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Row Title
            HStack(spacing: 4) {
                Text(row.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HomeFlixTheme.textPrimary)
                
                if row.id != "continue-watching" {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(HomeFlixTheme.brandRed)
                }
                
                Spacer()
                
                if row.id == "continue-watching" {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            WatchlistStore.shared.clearWatchHistory()
                        }
                    }) {
                        Text("Clear All")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(HomeFlixTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Horizontal Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: row.isTop10 == true ? 4 : 10) {
                    ForEach(Array(row.items.enumerated()), id: \.element.id) { index, item in
                        if row.isTop10 == true {
                            HStack(alignment: .bottom, spacing: 0) {
                                Top10RankBadge(rank: index + 1)
                                MediaCardView(
                                    item: item,
                                    rank: index + 1,
                                    width: 145,
                                    isLandscape: true,
                                    onSelect: onSelect
                                )
                                .zIndex(1)
                            }
                        } else if row.id == "continue-watching" {
                            MediaCardView(
                                item: item,
                                width: 145,
                                isLandscape: true,
                                showRemoveButton: true,
                                onRemove: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        WatchlistStore.shared.removeFromWatchHistory(mediaId: item.id)
                                    }
                                },
                                onSelect: onSelect
                            )
                        } else {
                            MediaCardView(
                                item: item,
                                width: 145,
                                isLandscape: true,
                                onSelect: onSelect
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }
}
