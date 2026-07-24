import SwiftUI

struct AppButton: View {
    enum Style {
        case primary
        case secondary
        case ghost
        case destructive
    }

    let title: LocalizedStringKey
    var icon: String?
    var style: Style = .primary
    var isLoading = false
    var isDisabled = false
    var fillsWidth = true
    var accessibilityIdentifier: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.compact) {
                if isLoading {
                    ProgressView().tint(foreground)
                } else if let icon {
                    IconView(name: icon)
                }

                Text(title)
                    .font(AppFont.button)
                    .tracking(2)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .frame(height: AppSpacing.buttonHeight)
            .padding(.horizontal, AppSpacing.row)
            .foregroundStyle(foreground)
            .background(background)
            .overlay(border)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressedButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.45 : 1)
        .appAccessibilityIdentifier(accessibilityIdentifier)
    }

    private var foreground: Color {
        switch style {
        case .primary: AppColor.accentForeground
        case .secondary: AppColor.textPrimary
        case .ghost: AppColor.textPrimary
        case .destructive: AppColor.accentForeground
        }
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .primary:
            AppColor.accent
        case .destructive:
            AppColor.error
        case .secondary, .ghost:
            Color.clear
        }
    }

    @ViewBuilder private var border: some View {
        switch style {
        case .secondary:
            Rectangle().strokeBorder(AppColor.border, lineWidth: AppSpacing.borderWidth)
        case .primary, .ghost, .destructive:
            EmptyView()
        }
    }
}

private extension View {
    @ViewBuilder
    func appAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}

private struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
