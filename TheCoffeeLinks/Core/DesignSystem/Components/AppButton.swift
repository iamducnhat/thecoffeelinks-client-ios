import SwiftUI

struct AppButton: View {
    enum Style {
        case primary
        case secondary
        case ghost
        case underlined
        case destructive
        case icon
    }

    let title: LocalizedStringKey?
    let icon: String?
    let style: Style
    let isLoading: Bool
    let isDisabled: Bool
    let fillsWidth: Bool
    let action: () -> Void

    init(
        _ title: LocalizedStringKey,
        icon: String? = nil,
        style: Style = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        fillsWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.fillsWidth = fillsWidth
        self.action = action
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        fillsWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.init(LocalizedStringKey(title), icon: icon, style: style, isLoading: isLoading, isDisabled: isDisabled, fillsWidth: fillsWidth, action: action)
    }

    init(
        icon: String,
        style: Style = .icon,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = nil
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.fillsWidth = false
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                }

                HStack(spacing: BaseViewLayout.spacingCompact) {
                    if let icon = icon {
                        IconView(name: icon)
                            .font(iconFont)
                    }

                    if let title {
                        Text(title)
                            .font(buttonFont)
                            .tracking(style == .underlined ? 2 : 1.2)
                            .underline(style == .underlined)
                    }
                }
                .opacity(isLoading ? 0 : 1)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .frame(minWidth: style == .icon ? BaseViewLayout.touchTarget : nil)
            .frame(minHeight: style == .icon ? BaseViewLayout.touchTarget : 44)
            .background(background)
            .foregroundStyle(foregroundColor)
            .overlay(
                border
            )
            .opacity(isDisabled || isLoading ? 0.6 : 1.0)
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(.plain)
        .scaleEffect(isDisabled ? 1.0 : 1.0)
        .modifier(ScaleButtonStyleModifier())
    }

    private var buttonFont: Font {
        switch style {
        case .primary, .secondary, .destructive:
            return BaseViewFont.cta
        case .ghost, .underlined:
            return BaseViewFont.cta
        case .icon:
            return BaseViewFont.body
        }
    }

    private var iconFont: Font {
        style == .icon ? BaseViewFont.navIcon : BaseViewFont.body
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .icon:
            return 10
        case .ghost, .underlined:
            return 0
        default:
            return 18
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .icon, .ghost, .underlined:
            return 0
        default:
            return 10
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: BaseViewLayout.cornerRadius, style: BaseViewLayout.cornerStyle)
                .fill(backgroundColor)
        case .secondary, .destructive, .icon:
            RoundedRectangle(cornerRadius: BaseViewLayout.cornerRadius, style: BaseViewLayout.cornerStyle)
                .fill(backgroundColor)
        case .ghost, .underlined:
            Color.clear
        }
    }

    @ViewBuilder
    private var border: some View {
        switch style {
        case .secondary, .destructive, .icon:
            RoundedRectangle(cornerRadius: BaseViewLayout.cornerRadius, style: BaseViewLayout.cornerStyle)
                .strokeBorder(borderColor, lineWidth: BaseViewLayout.borderWidth)
        case .primary, .ghost, .underlined:
            EmptyView()
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return BaseViewColor.accent
        case .secondary, .ghost, .underlined:
            return .clear
        case .destructive:
            return BaseViewColor.semanticError.opacity(0.08)
        case .icon:
            return BaseViewColor.elevatedSurface
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return BaseViewColor.accentForeground
        case .secondary:
            return BaseViewColor.accent
        case .ghost:
            return BaseViewColor.textSecondary
        case .underlined:
            return BaseViewColor.textPrimary
        case .destructive:
            return BaseViewColor.semanticError
        case .icon:
            return BaseViewColor.textPrimary
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary, .ghost, .underlined:
            return .clear
        case .secondary:
            return BaseViewColor.accent
        case .destructive:
            return BaseViewColor.semanticError.opacity(0.24)
        case .icon:
            return BaseViewColor.border
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

private struct ScaleButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

struct AppButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                AppButton("Checkout", style: .primary) {}
                AppButton("Browse Menu", style: .secondary) {}
                AppButton("View Tier Details", style: .underlined, fillsWidth: false) {}
                AppButton("Sign out", icon: "log_out", style: .destructive) {}
                AppButton(icon: "chevron.left") {}
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("English")
            .environment(\.locale, .init(identifier: "en"))
            
            VStack(spacing: 20) {
                AppButton("Checkout", style: .primary) {}
                AppButton("Browse Menu", style: .secondary) {}
                AppButton("View Tier Details", style: .underlined, fillsWidth: false) {}
                AppButton("Sign out", icon: "log_out", style: .destructive) {}
                AppButton(icon: "chevron.left") {}
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Vietnamese")
            .environment(\.locale, .init(identifier: "vi"))
        }
    }
}
