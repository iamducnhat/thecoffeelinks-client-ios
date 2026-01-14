//
//  DesignSystem.swift
//  thecoffeelinks-native-swift
//
//  Created by AppCafe on 2026-01-12.
//

import SwiftUI

// MARK: - Brand Colors - Sequoia Forest Palette
extension Color {
    // Sequoia Forest Primary Colors - Calm, Grounded, Timeless
    static let forestCanopy = Color(hex: 0x1F2D24)      /* Primary - deep forest */
    static let forestFloor = Color(hex: 0x3A2E25)       /* Secondary - grounded earth */
    static let morningFog = Color(hex: 0xF2EFEA)        /* Main background - light, spacious */
    static let filteredLight = Color(hex: 0x6F8F72)     /* Accent - soft, green trust */
    static let sunRay = Color(hex: 0xC2A14D)            /* Premium actions - rare gold */
    
    // Neutrals - Desaturated, Natural
    static let neutral50 = Color(hex: 0xFAFAF8)
    static let neutral100 = Color(hex: 0xF5F2ED)
    static let neutral200 = Color(hex: 0xE8E4DD)
    static let neutral300 = Color(hex: 0xD8D0C8)
    static let neutral400 = Color(hex: 0xC2B5A8)
    static let neutral500 = Color(hex: 0x9E9285)
    static let neutral600 = Color(hex: 0x7A6E63)
    static let neutral700 = Color(hex: 0x5C4F46)
    static let neutral800 = Color(hex: 0x3A332A)
    static let neutral900 = Color(hex: 0x1F1B17)
    
    // Semantic Colors - Muted, Calm
    static let successGreen = Color(hex: 0x4a7a5a)     /* Validation - muted green */
    static let warningAmber = Color(hex: 0xb89a4a)     /* Warning - warm amber */
    static let dangerRed = Color(hex: 0xa85a5a)        /* Danger - muted red */
    static let infoBlue = Color(hex: 0x5a7a9a)         /* Info - cool muted blue */
    
    // Legacy Coffee Tones (for transition compatibility)
    static let coffeeBlack = Color(hex: 0x0d0906)
    static let coffeeDark = Color.forestCanopy         /* Use forest canopy instead */
    static let coffeeRich = Color.forestFloor          /* Use forest floor instead */
    
    static let caramel = Color.sunRay                  /* Map to sun ray */
    static let caramelLight = Color.sunRay.opacity(0.7)
    
    static let ivory = Color.morningFog                /* Map to morning fog */
    static let cream = Color.morningFog.opacity(0.9)
    
    static let gold = Color.sunRay                     /* Map to sun ray */
    static let sage = Color.filteredLight              /* Map to filtered light */
}

// MARK: - Semantic Colors
extension Color {
    static let brandBackground = Color.morningFog
    static let brandPrimary = Color.forestCanopy
    static let brandAccent = Color.filteredLight
    static let brandSuccess = Color.successGreen
    static let brandPremium = Color.sunRay
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
        tint: Color = .forestCanopy,
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
                    .padding(.vertical, 14)
                    .background(isDisabled ? Color.neutral400 : tintColor)
                    .cornerRadius(14)
                    .shadow(color: tintColor.opacity(0.2), radius: 8, x: 0, y: 4)
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
                    .font(.system(size: 16, weight: .semibold, design: .default))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
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
            .tint(Color.forestCanopy)
        } else {
            Button(action: action) {
                buttonContent
                    .foregroundStyle(Color.forestCanopy)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.neutral300, lineWidth: 1.5)
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
                .font(.system(size: 16, weight: .semibold, design: .default))
        }
    }
}

// MARK: - Splash Loading View
/// A clean branded loading screen that embodies the Sequoia Forest experience
struct SplashLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Gradient background - Morning Fog to light neutral
            LinearGradient(
                colors: [Color.morningFog, Color.neutral100.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo Container with calm, weighted animation
                ZStack {
                    // Outer subtle ring
                    Circle()
                        .stroke(Color.filteredLight.opacity(0.15), lineWidth: 2)
                        .frame(width: 120, height: 120)
                    
                    // Animated arc - weighted motion
                    Circle()
                        .trim(from: 0, to: 0.25)
                        .stroke(
                            LinearGradient(
                                colors: [Color.sunRay, Color.filteredLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    // Icon - forest canopy
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.forestCanopy)
                }
                
                // Brand name - Sequoia Forest typography
                VStack(spacing: 12) {
                    Text("The Coffee Links")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .tracking(0.5)
                        .foregroundStyle(Color.forestCanopy)
                    
                    // Subtle loading indicator dots - calm breathing
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.filteredLight)
                                .frame(width: 6, height: 6)
                                .opacity(isAnimating ? 0.8 : 0.3)
                                .animation(
                                    .easeInOut(duration: 0.8)
                                    .repeatForever()
                                    .delay(Double(index) * 0.25),
                                    value: isAnimating
                                )
                        }
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview("Splash Loading - Sequoia Forest") {
    SplashLoadingView()
}
