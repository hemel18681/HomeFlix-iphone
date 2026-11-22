import SwiftUI

public struct MoreLikeThisGridView: View {
    let items: [MediaItem]
    let onSelectItem: (MediaItem) -> Void
    
    public init(items: [MediaItem], onSelectItem: @escaping (MediaItem) -> Void) {
        self.items = items
        self.onSelectItem = onSelectItem
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More Like This")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items) { item in
                    MediaCardView(
                        item: item,
                        width: 108,
                        isLandscape: false,
                        onSelect: onSelectItem
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
