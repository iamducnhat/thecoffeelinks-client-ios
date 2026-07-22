import SwiftUI

struct AppBadge: View {
    enum Style { case accent, neutral, success, warning }

    let text: String
    var style: Style = .accent

    var body: some View {
        Text(text)
            .font(AppFont.labelStrong)
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
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
