import SwiftUI

public struct ShimmerLoadingView: View {
    @State private var phase: CGFloat = -1.0
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: "1F1F1F")
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.08),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * geometry.size.width)
            }
            .clipped()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
}
