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

    // NOTE: Programmatic dynamic `UIColor` providers were removed to avoid
    // MainActor isolation and AsyncRenderer crashes that occur when SwiftUI
    // resolves color providers on background render threads. Use asset-
    // backed color sets defined in `Color+DesignSystem.swift` (e.g.
    // `Color.backgroundPaper`, `Color.textInk`, `Color.primaryEspresso`) or
    // use static `Color(white: ...)` values where appropriate.
    //
    // If you must add a new adaptive color, prefer adding it to the Asset
    // Catalog and referencing it via `Color("Colors/YourName")` to ensure
    // safe system-managed dynamic resolution.

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
        AppButton(
            title,
            style: mappedStyle,
            isLoading: isLoading,
            isDisabled: isDisabled,
            fillsWidth: style != .ghost,
            action: action
        )
    }

    private var mappedStyle: AppButton.Style {
        switch style {
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        case .ghost:
            return .ghost
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
    var isFocused: FocusState<Bool>.Binding? = nil
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
                        .applyOptionalFocus(isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .applyOptionalFocus(isFocused)
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

private extension View {
    @ViewBuilder
    func applyOptionalFocus(_ focusBinding: FocusState<Bool>.Binding?) -> some View {
        if let focusBinding {
            self.focused(focusBinding)
        } else {
            self
        }
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
        AppListRow(
            title: title,
            detail: value,
            icon: icon,
            showsChevron: destination != nil || action != nil
        )
    }
}
