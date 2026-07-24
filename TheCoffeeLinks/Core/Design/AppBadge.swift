import SwiftUI

struct AppBadge: View {
    enum Style { case accent, neutral, success, warning }

    let text: String
    var style: Style = .accent

    var body: some View {
        Text(text)
            .font(AppFont.labelStrong)
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(foreground)
            .padding(.horizontal, AppSpacing.micro)
            .frame(height: AppSpacing.badgeHeight)
            .background(background)
    }

    private var background: Color {
        switch style {
        case .accent: AppColor.accent
        case .neutral: AppColor.surface
        case .success: AppColor.success
        case .warning: AppColor.warning
        }
    }

    private var foreground: Color {
        style == .neutral ? AppColor.textPrimary : AppColor.accentForeground
    }
}
