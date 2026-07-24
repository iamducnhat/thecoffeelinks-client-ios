import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var session: AppSession
    @State private var name = ""

    var body: some View {
        VStack(spacing: 0) {
            Image("LogoCompact")
                .resizable()
                .scaledToFit()
                .frame(width: 116, height: 116)

            VStack(spacing: AppSpacing.micro) {
                Text("profile.welcome")
                    .font(AppFont.screenTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text("profile.name_once")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppSpacing.row)

            AppTextField(
                title: nil,
                text: $name,
                placeholder: "profile.name_placeholder",
                textContentType: .name
            )
            .padding(.top, AppSpacing.section)

            AppButton(
                title: "profile.continue",
                isLoading: session.isBusy,
                isDisabled: name.trimmingCharacters(in: .whitespaces).count < 2,
                accessibilityIdentifier: "profile.continue"
            ) {
                Task { _ = await session.saveName(name) }
            }
            .padding(.top, AppSpacing.row)

            Spacer(minLength: AppSpacing.section)
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, 48)
        .padding(.bottom, 22)
        .appScreen()
    }
}
