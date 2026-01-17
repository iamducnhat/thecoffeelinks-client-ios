import SwiftUI

/// Receipt-Editorial Design System: Color Palette
/// 
/// Warm coffee-inspired palette with full Light/Dark mode support.
/// Uses SwiftUI semantic colors where possible for automatic adaptation.
///
/// ACCENT USAGE (STRICT):
/// - `Color.accentColor` is ONLY for primary CTA buttons
/// - All other UI uses `.primary`, `.secondary`, `.tertiary`
///
/// LIGHT MODE:
/// - Background: Warm off-white paper (#F9F7F4)
/// - Surface: Subtle cream (#F0ECE6)
/// - Text Primary: Deep coffee brown (#1A1512)
/// - Text Secondary: Muted brown (#5C4D42)
/// - Accent CTA: Moss green (#3B5D48)
///
/// DARK MODE:
/// - Background: Near black, warm (#0F0D0B)
/// - Surface: Dark brown (#1A1714)
/// - Text Primary: Warm white (#F5F2EE)
/// - Text Secondary: Muted cream (#B8ADA2)
/// - Accent CTA: Mint/sage (#6E8F78)

extension Color {
    
    // MARK: - Adaptive Color Helper
    
    init(light: String, dark: String) {
        self.init(uiColor: UIColor { (traits) -> UIColor in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(Color(hex: hex))
        })
    }
    
    // MARK: - Background Colors
    
    /// Primary background - Paper white (light) / Near black (dark)
    static var backgroundPaper: Color {
        Color(light: "#F9F7F4", dark: "#0F0D0B")
    }
    
    /// Surface/Card background - Subtle cream (light) / Dark brown (dark)
    static var surfaceCard: Color {
        Color(light: "#F0ECE6", dark: "#1A1714")
    }
    
    // MARK: - Text Colors
    
    /// Primary text - Deep brown (light) / Warm white (dark)
    static var textInk: Color {
        Color(light: "#1A1512", dark: "#F5F2EE")
    }
    
    /// Secondary text - Muted brown (light) / Muted cream (dark)
    static var textMuted: Color {
        Color(light: "#5C4D42", dark: "#B8ADA2")
    }
    
    /// Tertiary text - Light brown (light) / Muted tan (dark)
    static var textTertiary: Color {
        Color(light: "#8B7B6E", dark: "#7A7068")
    }
    
    // MARK: - Accent Colors
    
    /// Primary accent (CTA ONLY) - Moss green (light) / Mint (dark)
    static var primaryEspresso: Color {
        Color(light: "#3B5D48", dark: "#6E8F78")
    }
    
    /// Secondary accent - Sage (light) / Muted sage (dark)
    static var secondaryLatte: Color {
        Color(light: "#6E8F78", dark: "#4A5E4D")
    }
    
    // MARK: - Border Colors
    
    /// Border/Separator - Warm gray (light) / Dark brown (dark)
    static var border: Color {
        Color(light: "#D4CCC2", dark: "#2A2520")
    }
    
    /// Tertiary border for dashed inputs
    static var borderTertiary: Color {
        Color(light: "#C4BAB0", dark: "#3A352F")
    }
    
    // MARK: - Semantic Colors
    
    /// Error state - Warm red
    static var semanticError: Color {
        Color(light: "#B91C1C", dark: "#DC2626")
    }
    
    /// Success state - Forest/Lime green
    static var semanticSuccess: Color {
        Color(light: "#15803D", dark: "#22C55E")
    }
    
    /// Warning state - Amber
    static var semanticWarning: Color {
        Color(light: "#D97706", dark: "#F59E0B")
    }
    
    // MARK: - Legacy Aliases (Compatibility)
    
    static var primaryTerminal: Color { textInk }
    static var backgroundTerminal: Color { backgroundPaper }
    static var surfaceTerminal: Color { surfaceCard }
    static var accentTerminal: Color { primaryEspresso }
}

// MARK: - Hex Color Helper

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
