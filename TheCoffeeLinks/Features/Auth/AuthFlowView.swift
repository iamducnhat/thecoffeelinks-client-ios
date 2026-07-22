import SwiftUI

struct AuthFlowView: View {
    enum Step { case phone, otp }

    @ObservedObject var session: AppSession
    @State private var step: Step = .phone
    @State private var phone = ""
    @State private var otp = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                BrandHeader()

                VStack(alignment: .leading, spacing: AppSpacing.compact) {
                    Text(step == .phone ? "auth.title" : "auth.otp_title")
                        .font(AppFont.screenTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(step == .phone ? "auth.subtitle" : "auth.otp_subtitle")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textSecondary)
                }

                if step == .phone {
                    AppTextField(
                        title: "auth.phone",
                        text: $phone,
                        placeholder: "auth.phone_placeholder",
                        keyboardType: .phonePad,
                        textContentType: .telephoneNumber
                    )
                    AppButton(
                        title: "auth.send_otp",
                        isLoading: session.isBusy,
                        isDisabled: phone.isEmpty
                    ) {
                        Task { if await session.sendOTP(phone: phone) { step = .otp } }
                    }
                } else {
                    AppOTPField(code: $otp)
                    AppButton(
                        title: "auth.verify",
                        isLoading: session.isBusy,
                        isDisabled: otp.count != 6
                    ) {
                        Task { _ = await session.verifyOTP(otp) }
                    }
                    AppButton(title: "auth.change_phone", style: .ghost) {
                        otp = ""
                        step = .phone
                    }
                }

                Text("auth.terms")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, 40)
        }
        .appScreen()
    }
}

private struct BrandHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("LogoCompact")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
            Text("The Coffee Links")
                .font(AppFont.cardTitle)
                .foregroundStyle(AppColor.textPrimary)
        }
    }
}
