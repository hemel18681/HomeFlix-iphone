import SwiftUI

public struct AsyncImageView: View {
    let url: URL?
    var aspectRatio: CGFloat = 16.0 / 9.0
    var contentMode: ContentMode = .fill
    var alignment: Alignment = .top
    
    public init(
        url: URL?,
        aspectRatio: CGFloat = 16.0 / 9.0,
        contentMode: ContentMode = .fill,
        alignment: Alignment = .top
    ) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
        self.alignment = alignment
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: alignment) {
                if let url = url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ShimmerLoadingView()
                                .frame(width: geo.size.width, height: geo.size.height)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height, alignment: alignment)
                                .clipped()
                        case .failure:
                            fallbackView
                                .frame(width: geo.size.width, height: geo.size.height)
                        @unknown default:
                            fallbackView
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                } else {
                    fallbackView
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: alignment)
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
