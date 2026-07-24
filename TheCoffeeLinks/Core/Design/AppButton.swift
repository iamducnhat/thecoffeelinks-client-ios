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
                    .tracking(1.2)
            }
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .frame(minHeight: AppSpacing.controlHeight)
            .padding(.horizontal, 18)
            .foregroundStyle(foreground)
            .background(background)
            .overlay(border)
            .contentShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous))
        }
        .buttonStyle(PressedButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.45 : 1)
    }

    private var foreground: Color {
        switch style {
        case .primary: AppColor.accentForeground
        case .secondary: AppColor.accent
        case .ghost: AppColor.textPrimary
        case .destructive: AppColor.error
        }
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                .fill(AppColor.accent)
        case .destructive:
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                .fill(AppColor.error.opacity(0.08))
        case .secondary, .ghost:
            Color.clear
        }
    }

    @ViewBuilder private var border: some View {
        switch style {
        case .secondary, .destructive:
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                .strokeBorder(foreground, lineWidth: AppSpacing.borderWidth)
        case .primary, .ghost:
            EmptyView()
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
