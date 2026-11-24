import SwiftUI

// MARK: - Color Hex Initializer
extension Color {
    public init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}

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

