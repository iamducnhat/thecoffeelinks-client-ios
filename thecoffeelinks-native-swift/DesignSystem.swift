//
//  DesignSystem.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let coffeeBlack = Color(hex: 0x0d0906)
    static let coffeeDark = Color(hex: 0x1a1210) // Primary Text / Headings
    static let coffeeRich = Color(hex: 0x2d1f18)
    
    static let caramel = Color(hex: 0xc89b6a) // Accents
    static let caramelLight = Color(hex: 0xdbb896)
    
    static let ivory = Color(hex: 0xfaf8f5) // Background
    static let cream = Color(hex: 0xf5ebe0)
    
    static let gold = Color(hex: 0xb8860b) // Premium / Reward
    static let sage = Color(hex: 0x7a9e7e) // Trust / Connection
    
    // Neutrals
    static let neutral50 = Color(hex: 0xfdfcfa)
    static let neutral100 = Color(hex: 0xf8f6f2)
    static let neutral200 = Color(hex: 0xefe9e0)
    static let neutral300 = Color(hex: 0xddd4c8)
    static let neutral400 = Color(hex: 0xb8a899)
    static let neutral500 = Color(hex: 0x8f8175)
    static let neutral600 = Color(hex: 0x6b5f54)
    static let neutral900 = Color(hex: 0x1a1614)
}

// MARK: - Semantic Colors
extension Color {
    static let brandBackground = Color.ivory
    static let brandPrimary = Color.coffeeDark
    static let brandAccent = Color.caramel
    static let brandSuccess = Color.sage
    static let brandPremium = Color.gold
}

// MARK: - Typography
extension Font {
    /// Apple New York serif font - system serif design
    static func brandSerif(_ size: CGFloat) -> Font {
        return .system(size: size, design: .serif).weight(.bold)
    }
    
    /// System rounded sans-serif
    static func brandSans(_ size: CGFloat) -> Font {
        return .system(size: size, design: .default)
    }
}

// MARK: - Modifiers
struct PremiumCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.coffeeBlack.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func premiumCard() -> some View {
        modifier(PremiumCardModifier())
    }
}

// MARK: - Hex Helper
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
