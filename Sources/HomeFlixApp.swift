import SwiftUI

#if canImport(UIKit)
import UIKit

public class AppDelegate: NSObject, UIApplicationDelegate {
    public static var orientationLock: UIInterfaceOrientationMask = .allButUpsideDown
    
    public func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
#endif

@main
public struct HomeFlixApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .background(Color(hex: "141414").edgesIgnoringSafeArea(.all))
        }
    }
}
