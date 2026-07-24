import SwiftUI

struct AuthFlowView: View {
    enum Step { case phone, otp }

    @ObservedObject var session: AppSession
    @State private var step: Step = .phone
    @State private var phone = ""
    @State private var otp = ""

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Image("LogoCompact")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 116, height: 116)

                    Text(step == .phone ? AuthCopy.signIn : "auth.otp_title")
                        .font(AppFont.screenTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, AppSpacing.row)

                    Text(step == .phone ? AuthCopy.welcomeBack : "auth.otp_subtitle")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, AppSpacing.micro)

                    authControls
                        .padding(.top, step == .phone ? 57 : AppSpacing.section)

                    Spacer(minLength: AppSpacing.section)

                    Text(AuthCopy.terms)
                        .font(AppFont.labelStrong)
                        .tracking(2)
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColor.accent)
                }
                .frame(minHeight: max(proxy.size.height - 44, 700))
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, 28)
                .padding(.bottom, 22)
            }
        }
        .appScreen()
    }

    @ViewBuilder private var authControls: some View {
        VStack(spacing: AppSpacing.row) {
            if step == .phone {
                AppTextField(
                    title: nil,
                    text: $phone,
                    placeholder: "auth.phone_placeholder",
                    prefix: "+84",
                    keyboardType: .phonePad,
                    textContentType: .telephoneNumber
                )
                AppButton(
                    title: AuthCopy.signInWithOTP,
                    isLoading: session.isBusy,
                    isDisabled: phone.isEmpty,
                    accessibilityIdentifier: "auth.send_otp"
                ) {
                    Task { if await session.sendOTP(phone: phone) { step = .otp } }
                }
            } else {
                AppOTPField(code: $otp)
                AppButton(
                    title: "auth.verify",
                    isLoading: session.isBusy,
                    isDisabled: otp.count != 6,
                    accessibilityIdentifier: "auth.verify"
                ) {
                    Task { _ = await session.verifyOTP(otp) }
                }
                AppButton(title: "auth.change_phone", style: .secondary) {
                    otp = ""
                    step = .phone
                }
            }
        }
    }
}

private enum AuthCopy {
    private static var isVietnamese: Bool {
        Locale.current.language.languageCode?.identifier == "vi"
    }

    static var signIn: LocalizedStringKey { isVietnamese ? "Đăng nhập" : "Sign in" }
    static var welcomeBack: LocalizedStringKey { isVietnamese ? "Chào mừng trở lại" : "Welcome back" }
    static var signInWithOTP: LocalizedStringKey { isVietnamese ? "Đăng nhập với OTP" : "Sign in with OTP" }
    static var terms: LocalizedStringKey { isVietnamese ? "Điều khoản sử dụng" : "Terms of use" }
}
