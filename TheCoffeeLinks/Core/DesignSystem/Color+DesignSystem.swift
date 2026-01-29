import SwiftUI

/// Receipt-Editorial Design System: Color Palette
/// 
/// Warm coffee-inspired palette with full Light/Dark mode support.
/// Uses SwiftUI semantic colors where possible for automatic adaptation.
/// Now backed by Asset Catalog for thread-safe dynamic resolution.
///
/// ACCENT USAGE (STRICT):
/// - `Color.accentColor` is ONLY for primary CTA buttons
/// - All other UI uses `.primary`, `.secondary`, `.tertiary`

extension Color {
    
    // MARK: - Background Colors
    
    /// Primary background - Paper white (light) / Near black (dark)
    static var backgroundPaper: Color {
        Color("Colors/BackgroundPaper")
    }
    
    /// Surface/Card background - Subtle cream (light) / Dark brown (dark)
    static var surfaceCard: Color {
        Color("Colors/SurfaceCard")
    }
    
    // MARK: - Text Colors
    
    /// Primary text - Very dark chocolate brown (light) / Warm white (dark)
    static var textInk: Color {
        Color("Colors/TextInk")
    }
    
    /// Secondary text - Warm cocoa brown (light) / Muted cream (dark)
    static var textMuted: Color {
        Color("Colors/TextMuted")
    }
    
    /// Tertiary text - Light coffee-stain tone (light) / Muted tan (dark)
    static var textTertiary: Color {
        Color("Colors/TextTertiary")
    }
    
    // MARK: - Accent Colors
    
    /// Primary accent (SINGLE ACCENT) - Moss green (light) / Mint (dark)
    /// Used for: primary actions, prices, selection states.
    static var primaryEspresso: Color {
        Color("Colors/PrimaryEspresso")
    }
    
    // MARK: - Border Colors
    
    /// Border/Separator - Warm gray (light) / Dark brown (dark)
    static var border: Color {
        Color("Colors/Border")
    }
    
    /// Tertiary border for dashed inputs
    static var borderTertiary: Color {
        Color("Colors/BorderTertiary")
    }
    
    // MARK: - Semantic Colors
    
    /// Error state - Warm red
    static var semanticError: Color {
        Color("Colors/SemanticError")
    }
    
    /// Success state - Forest/Lime green
    static var semanticSuccess: Color {
        Color("Colors/SemanticSuccess")
    }
    
    /// Warning state - Amber
    static var semanticWarning: Color {
        Color("Colors/SemanticWarning")
    }
    
    // MARK: - Legacy Aliases (Compatibility)
    
    static var primaryTerminal: Color { textInk }
    static var backgroundTerminal: Color { backgroundPaper }
    static var surfaceTerminal: Color { surfaceCard }
    static var accentTerminal: Color { primaryEspresso }
}

// MARK: - Hex Color Helper (Retained for utilities if needed elsewhere, but no longer used for system colors)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
