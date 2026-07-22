import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var session: AppSession
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            Spacer()
            VStack(alignment: .leading, spacing: AppSpacing.compact) {
                Text("profile.welcome")
                    .font(AppFont.screenTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text("profile.name_once")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            AppTextField(
                title: "profile.full_name",
                text: $name,
                placeholder: "profile.name_placeholder",
                textContentType: .name
            )
            AppButton(
                title: "profile.continue",
                isLoading: session.isBusy,
                isDisabled: name.trimmingCharacters(in: .whitespaces).count < 2
            ) {
                Task { _ = await session.saveName(name) }
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.screen)
        .appScreen()
    }
}
