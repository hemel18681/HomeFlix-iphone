import SwiftUI

public struct Top10RankBadge: View {
    let rank: Int
    
    public init(rank: Int) {
        self.rank = rank
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Shadow / Outline Layer
            Text("\(rank)")
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundColor(HomeFlixTheme.background)
                .shadow(color: Color(hex: "595959"), radius: 1, x: -1, y: -1)
                .shadow(color: Color(hex: "595959"), radius: 1, x: 1, y: -1)
                .shadow(color: Color(hex: "595959"), radius: 1, x: -1, y: 1)
                .shadow(color: Color(hex: "595959"), radius: 1, x: 1, y: 1)
            
            // Core Fill Layer
            Text("\(rank)")
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: "1F1F1F"))
        }
        .frame(width: rank == 10 ? 76 : 52, height: 110, alignment: .bottom)
        .offset(x: 10)
        .zIndex(0)
    }
}
