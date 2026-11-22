import SwiftUI

public struct AsyncImageView: View {
    let url: URL?
    var aspectRatio: CGFloat = 16.0 / 9.0
    var contentMode: ContentMode = .fill
    
    public init(url: URL?, aspectRatio: CGFloat = 16.0 / 9.0, contentMode: ContentMode = .fill) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
    }
    
    public var body: some View {
        ZStack {
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ShimmerLoadingView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipped()
    }
    
    private var fallbackView: some View {
        ZStack {
            Color(hex: "222222")
            VStack(spacing: 6) {
                Image(systemName: "film")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(Color(hex: "666666"))
                Text("HOMEFLIX")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "555555"))
            }
        }
    }
}
