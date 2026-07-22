import SwiftUI

struct AppStateView: View {
    enum Kind { case loading, empty, error }

    let kind: Kind
    let title: LocalizedStringKey
    var message: LocalizedStringKey?
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.card) {
            if kind == .loading {
                ProgressView().tint(AppColor.accent)
            } else {
                IconView(name: kind == .error ? "exclamationmark.triangle" : "cup.and.saucer", size: 28)
                    .foregroundStyle(kind == .error ? AppColor.error : AppColor.textSecondary)
            }

            Text(title)
                .font(AppFont.cardTitle)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                AppButton(title: actionTitle, style: .secondary, fillsWidth: false, action: action)
            }
        }
        .padding(AppSpacing.screen)
        .frame(maxWidth: .infinity)
    }
}
