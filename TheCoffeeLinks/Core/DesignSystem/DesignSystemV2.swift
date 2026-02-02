import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// Lightweight Icon wrapper: prefer bundled Lucide assets; fall back to SF Symbols
struct IconView: View {
    let name: String
    var body: some View {
        #if canImport(UIKit)
        if UIImage(named: name) != nil {
            Image(name)
                .renderingMode(.template)
        } else {
            Image(systemName: name)
        }
        #else
        Image(systemName: name)
        #endif
    }
}

// MARK: - Colors (Adaptive Light/Dark Mode)
// Light mode: Original Receipt-Editorial colors
// Dark mode: Black/grey/white only

extension Color {
    // MARK: - Backgrounds
    
    static let bgPrimary = Color.backgroundPaper
    static let bgSecondary = Color.surfaceCard
    // Tertiary background is intentionally a simple gray that does not need
    // an asset; we choose a neutral static value that is acceptable in both
    // schemes to avoid dynamic providers.
    static let bgTertiary = Color(white: 0.94)
    
    // MARK: - Surfaces (Cards, Sheets)
    
    static let surfacePrimary = Color.surfaceCard
    static let surfaceElevated = Color.white
    
    // MARK: - Text
    
    static let textPrimary = Color.textInk
    static let textSecondary = Color.textMuted
    static let textTertiary = Color(white: 0.5)
    static let textDisabled = Color(white: 0.7)
    
    // MARK: - Borders
    
    static let borderPrimary = Color.border
    static let borderSecondary = Color.borderTertiary
    
    // MARK: - Accent (from existing design system)
    
    static let accentPrimary = Color.primaryEspresso // Moss green light / Mint dark
    
    // MARK: - Button Colors
    
    // Light mode: 80% black for secondary buttons, accent for primary
    // Dark mode: white for highlighted
    static let buttonHighlight = Color(white: 0.2).opacity(0.8)
    static let buttonHighlightSecondary = Color(white: 0.2).opacity(0.8)
    
    // MARK: - States (Minimal semantic colors)
    
    static let stateError = Color.semanticError
    static let stateSuccess = Color.semanticSuccess
    static let stateWarning = Color.semanticWarning
    
    // MARK: - Light/Dark Initializer

#if canImport(UIKit)
// Helper: build a dynamic UIColor provider from plain UIColors in non-actor
// context so the provider closure is not implicitly MainActor-isolated.
// This version extracts RGBA components on the caller (main actor) and
// uses numeric components inside the dynamic provider to avoid capturing
// MainActor-isolated UIColor instances.
fileprivate static func dynamicUIColor(light: UIColor, dark: UIColor) -> UIColor {
    // Extract RGBA components safely on the caller thread
    func rgba(from color: UIColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (r, g, b, a)
        } else {
            let ci = CIColor(color: color)
            return (ci.red, ci.green, ci.blue, ci.alpha)
        }
    }

    let (lr, lg, lb, la) = rgba(from: light)
    let (dr, dg, db, da) = rgba(from: dark)

    return UIColor(dynamicProvider: { traits in
        switch traits.userInterfaceStyle {
        case .dark:
            return UIColor(red: dr, green: dg, blue: db, alpha: da)
        default:
            return UIColor(red: lr, green: lg, blue: lb, alpha: la)
        }
    })
}
#endif

    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        // Convert `SwiftUI.Color` to `UIColor` in a thread-safe way. Some
        // platforms may attempt to initialize static Colors off the main
        // thread, so we ensure conversion happens on the main thread.
        func uiColorFrom(_ color: Color) -> UIColor {
            if Thread.isMainThread {
                return UIColor(color)
            } else {
                var result: UIColor?
                DispatchQueue.main.sync { result = UIColor(color) }
                return result!
            }
        }

        let uiLight = uiColorFrom(light)
        let uiDark = uiColorFrom(dark)
        self.init(uiColor: Self.dynamicUIColor(light: uiLight, dark: uiDark))
        #else
        self = light
        #endif
    }
}

// MARK: - Spacing

struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    
    static let screenPadding: CGFloat = 16
    static let sectionGap: CGFloat = 24
}

// MARK: - Radius

struct AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let capsule: CGFloat = 9999
}

// MARK: - Typography

struct AppTypography {
    // Display
    static let displayLarge = Font.custom("GeologicaThinRoman-Bold", size: 28)
    static let displayMedium = Font.custom("GeologicaThinRoman-Medium", size: 22)
    
    // Body
    static let bodyLarge = Font.custom("GeologicaThinRoman-Regular", size: 17)
    static let bodyMedium = Font.custom("GeologicaThinRoman-Regular", size: 15)
    static let bodySmall = Font.custom("GeologicaThinRoman-Regular", size: 13)
    
    // Mono (Prices, Codes)
    static let monoLarge = Font.custom("NotoSansMono-Medium", size: 22)
    static let monoMedium = Font.custom("NotoSansMono-Regular", size: 17)
    static let monoSmall = Font.custom("NotoSansMono-Regular", size: 13)
    
    // Labels
    static let labelLarge = Font.custom("GeologicaThinRoman-Medium", size: 17)
    static let labelMedium = Font.custom("GeologicaThinRoman-Medium", size: 15)
    static let labelSmall = Font.custom("GeologicaThinRoman-Medium", size: 12)
}

// MARK: - Capsule Button

enum CapsuleButtonStyle {
    case primary    // Liquid glass, one per screen
    case secondary  // Bordered capsule
    case ghost      // Text only
}

struct CapsuleButton: View {
    let title: String
    let style: CapsuleButtonStyle
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        _ title: String,
        style: CapsuleButtonStyle = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else {
                    Text(title)
                        .font(AppTypography.labelLarge)
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(height: 48)
            .frame(maxWidth: style == .ghost ? nil : .infinity)
            .padding(.horizontal, style == .ghost ? AppSpacing.lg : 0)
            .background(background)
            .clipShape(Capsule())
            .overlay(border)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            // Accent color button (green)
            Color.accentPrimary
                .shadow(color: Color.accentPrimary.opacity(0.2), radius: 8, x: 0, y: 4)
        case .secondary:
            // Light mode: black/80% black, Dark mode: liquid glass effect
            Group {
                if colorScheme == .dark {
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        Capsule().fill(Color.white.opacity(0.15))
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: Color.white.opacity(0.1), radius: 8, x: 0, y: 4)
                } else {
                    Color.buttonHighlight
                }
            }
        case .ghost:
            Color.clear
        }
    }
    
    @ViewBuilder
    private var border: some View {
        // No border needed for any style now
        EmptyView()
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return colorScheme == .dark ? .white : .white
        case .ghost:
            return .textSecondary
        }
    }
}

// MARK: - Capsule TextField

struct CapsuleTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var prefix: String? = nil
    var isSecure: Bool = false
    #if canImport(UIKit)
    var keyboardType: UIKeyboardType = .default
    #endif
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 24)
            }
            
            if let prefix {
                Text(prefix)
                    .font(AppTypography.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        #if canImport(UIKit)
                        .keyboardType(keyboardType)
                        #endif
                }
            }
            .font(AppTypography.bodyLarge)
            .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 48)
        .background(Color.surfacePrimary)
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(Color.borderPrimary, lineWidth: 0.5)
        )
    }
}

// MARK: - Capsule Segmented Picker

struct CapsuleSegmentedPicker<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let options: [(value: SelectionValue, label: String)]
    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = option.value
                    }
                } label: {
                    Text(option.label)
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(selection == option.value ? (colorScheme == .dark ? Color.black : Color.white) : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if selection == option.value {
                                Capsule()
                                    .fill(Color.accentPrimary)
                                    .matchedGeometryEffect(id: "SelectedTab", in: animation)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.surfacePrimary)
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(Color.borderSecondary, lineWidth: 0.5)
        )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.displayMedium)
                .foregroundStyle(Color.textPrimary)
            
            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - List Row

struct ListRow<Destination: View>: View {
    let title: String
    let icon: String?
    let value: String?
    let destination: Destination?
    let action: (() -> Void)?
    
    init(
        title: String,
        icon: String? = nil,
        value: String? = nil,
        destination: Destination,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.value = value
        self.destination = destination
        self.action = action
    }
    
    init(
        title: String,
        icon: String? = nil,
        value: String? = nil,
        action: @escaping () -> Void
    ) where Destination == EmptyView {
        self.title = title
        self.icon = icon
        self.value = value
        self.destination = nil
        self.action = action
    }
    
    var body: some View {
        Group {
            if let destination {
                NavigationLink(destination: destination) {
                    rowContent
                }
            } else if let action {
                Button(action: action) {
                    rowContent
                }
            } else {
                rowContent
            }
        }
        .buttonStyle(.plain)
    }
    
    private var rowContent: some View {
        HStack(spacing: AppSpacing.md) {
            if let icon {
                IconView(name: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 24)
            }
            
            Text(title)
                .font(AppTypography.bodyLarge)
                .foregroundStyle(Color.textPrimary)
            
            Spacer()
            
            if let value {
                Text(value)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(Color.textTertiary)
            }
            
            if destination != nil || action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.lg)
        .background(Color.surfacePrimary)
        .contentShape(Rectangle())
    }
}
