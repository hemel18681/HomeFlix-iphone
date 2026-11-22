import SwiftUI

public enum NetflixTheme {
    // Primary Netflix Palette
    public static let background = Color(hex: "141414")
    public static let cardBackground = Color(hex: "181818")
    public static let surface = Color(hex: "222222")
    public static let brandRed = Color(hex: "E50914")
    public static let brandRedDark = Color(hex: "B20710")
    public static let brandRedLight = Color(hex: "F40612")
    
    // Text Accents
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "A3A3A3")
    public static let textMuted = Color(hex: "737373")
    public static let border = Color(hex: "262626")
    public static let gold = Color(hex: "E5A00D")
    
    // Gradients
    public static let heroBottomGradient = LinearGradient(
        stops: [
            .init(color: .clear, location: 0.0),
            .init(color: .clear, location: 0.5),
            .init(color: background.opacity(0.7), location: 0.8),
            .init(color: background, location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let heroLeftGradient = LinearGradient(
        stops: [
            .init(color: background.opacity(0.85), location: 0.0),
            .init(color: background.opacity(0.4), location: 0.4),
            .init(color: .clear, location: 1.0)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    public static let heroTopGradient = LinearGradient(
        stops: [
            .init(color: background.opacity(0.85), location: 0.0),
            .init(color: .clear, location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let redButtonGradient = LinearGradient(
        colors: [brandRedLight, brandRedDark],
        startPoint: .top,
        endPoint: .bottom
    )
}

public extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
