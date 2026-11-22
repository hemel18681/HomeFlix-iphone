import SwiftUI
import AVKit

#if canImport(UIKit)
import UIKit

public struct PlayerViewRepresentable: UIViewRepresentable {
    public let player: AVPlayer
    
    public init(player: AVPlayer) {
        self.player = player
    }
    
    public func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.backgroundColor = .black
        return view
    }
    
    public func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

public class PlayerUIView: UIView {
    public var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    
    public override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }
}
#endif

public struct DedicatedPlayerView: View {
    @ObservedObject var playerManager = DedicatedPlayerManager.shared
    @State private var showAudioMenu: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Clean hardware AVPlayer video layer without default system overlay buttons
            if let p = playerManager.player {
                #if canImport(UIKit)
                PlayerViewRepresentable(player: p)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        playerManager.toggleControls()
                    }
                #else
                VideoPlayer(player: p)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        playerManager.toggleControls()
                    }
                #endif
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(NetflixTheme.brandRed)
                    Text("Connecting to High-Speed Stream...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(NetflixTheme.textSecondary)
                }
            }
            
            // Netflix Interactive Controls
            if playerManager.showControls {
                NetflixPlayerControls(
                    showAudioMenu: $showAudioMenu,
                    onClose: {
                        playerManager.close()
                    }
                )
                .transition(.opacity)
            }
            
            // Audio & Subtitles Menu Overlay
            if showAudioMenu {
                Color.black.opacity(0.6)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showAudioMenu = false
                    }
                
                AudioSubtitleMenu(onClose: {
                    showAudioMenu = false
                })
                .transition(.scale)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: playerManager.showControls)
        .animation(.easeInOut(duration: 0.25), value: showAudioMenu)
    }
}
