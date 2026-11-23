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
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(HomeFlixTheme.brandRed)
                
                Spacer()
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
