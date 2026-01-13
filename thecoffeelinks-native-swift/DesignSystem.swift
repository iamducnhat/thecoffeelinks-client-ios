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

// MARK: - Liquid Glass Primary Button
/// A primary button that uses iOS 26 Liquid Glass style when available,
/// with a graceful fallback for older iOS versions.
struct LiquidGlassPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let tintColor: Color
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        tint: Color = .coffeeDark,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.tintColor = tint
        self.action = action
    }
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                buttonContent
            }
            .buttonStyle(.glassProminent)
            .tint(tintColor)
            .disabled(isDisabled || isLoading)
        } else {
            Button(action: action) {
                buttonContent
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isDisabled ? Color.neutral400 : tintColor)
                    .cornerRadius(16)
                    .shadow(color: tintColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(isDisabled || isLoading)
        }
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                if let icon = icon {
                    if UIImage(named: icon) != nil {
                        Image(icon)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                    }
                }
                Text(title)
                    .font(.brandSans(16))
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }
}

// MARK: - Liquid Glass Secondary Button (for less prominent actions)
struct LiquidGlassSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                buttonContent
            }
            .buttonStyle(.glass)
            .tint(Color.coffeeDark)
        } else {
            Button(action: action) {
                buttonContent
                    .foregroundStyle(Color.coffeeDark)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.neutral200, lineWidth: 1)
                    }
            }
        }
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                if UIImage(named: icon) != nil {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                }
            }
            Text(title)
                .font(.brandSans(16))
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Splash Loading View
/// A clean branded loading screen that replaces the "Brewing..." text
struct SplashLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.ivory, Color.cream.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo Container with subtle animation
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.caramel.opacity(0.2), lineWidth: 3)
                        .frame(width: 120, height: 120)
                    
                    // Animated arc
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(
                            LinearGradient(
                                colors: [Color.caramel, Color.coffeeRich],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 1.2)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    // Icon
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.coffeeRich)
                }
                
                // Brand name
                VStack(spacing: 8) {
                    Text("The Coffee Links")
                        .font(.brandSerif(28))
                        .foregroundStyle(Color.coffeeDark)
                    
                    // Subtle loading indicator dots
                    HStack(spacing: 6) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.caramel)
                                .frame(width: 6, height: 6)
                                .opacity(isAnimating ? 1 : 0.3)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                }
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview("Splash Loading") {
    SplashLoadingView()
}
