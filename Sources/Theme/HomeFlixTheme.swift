import SwiftUI

public enum HomeFlixTheme {
    // Primary HomeFlix Palette
    public static let brandRed = Color(hex: "E50914")
    public static let background = Color(hex: "141414")
    public static let cardBackground = Color(hex: "1F1F1F")
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "AAAAAA")
    public static let textMuted = Color(hex: "777777")
    
    // Gradients
    public static let heroTopGradient = LinearGradient(
        colors: [background.opacity(0.8), .clear],
        startPoint: .top,
        endPoint: .center
    )
    
    public static let heroBottomGradient = LinearGradient(
        colors: [.clear, background.opacity(0.8), background],
        startPoint: .center,
        endPoint: .bottom
    )
    
    public static let heroLeftGradient = LinearGradient(
        colors: [background.opacity(0.85), .clear],
        startPoint: .leading,
        endPoint: .trailing
    )
}

