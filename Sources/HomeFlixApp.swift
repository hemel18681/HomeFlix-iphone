import SwiftUI

@main
public struct HomeFlixApp: App {
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .background(Color(hex: "141414").edgesIgnoringSafeArea(.all))
        }
    }
}
