import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Auth entry redesigned from the SignInView/SignUpView SVG specs.
struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var appFlowController: AppFlowController
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: AuthTab = .signIn
    @FocusState private var focusedField: AuthField?
    var isPresentedModally: Bool = true

    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header

                        if authViewModel.authState == .otpSent {
                            otpForm
                        } else {
                            tabSwitcher
                                .padding(.top, AuthMetric.headerToTabsGap)

                            Group {
                                switch selectedTab {
                                case .signIn:
                                    signInForm
                                case .signUp:
                                    signUpForm
                                }
                            }
                            .padding(.top, AuthMetric.tabsToFieldsGap)
                        }

                        Spacer(minLength: AuthMetric.formToFooterMinGap)
                        footer
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: AuthMetric.contentMinHeight(for: proxy.size.height), alignment: .top)
                    .padding(.top, AuthMetric.logoTopInset)
                    .padding(.bottom, AuthMetric.footerBottomInset)
                }
                .scrollDismissesKeyboard(.immediately)
            }

            skipButton
        }
        .ignoresSafeArea(.keyboard)
        .alert(isPresented: Binding<Bool>(
            get: { authViewModel.authState == .error },
            set: { show in if !show { authViewModel.authState = authViewModel.otpCode.isEmpty ? .idle : .otpSent } }
        )) {
            Alert(
                title: Text("Có lỗi xảy ra"),
                message: Text(authViewModel.error ?? "Vui lòng thử lại."),
                dismissButton: .default(Text("Đồng ý")) {
                    authViewModel.error = nil
                }
            )
        }
        .onAppear(perform: focusInitialField)
        .onChange(of: selectedTab) { _ in
            guard authViewModel.authState != .otpSent else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                focusedField = selectedTab == .signIn ? .phone : .name
            }
        }
        .onChange(of: authViewModel.authState) { state in
            if state == .otpSent {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    focusedField = .otp
                }
            }
        }
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            Button(action: skipAuth) {
                BaseUnderlinedCTA(title: "ĐỂ SAU")
                    .padding(4)
                    .background(BaseViewColor.background)
            }
            .buttonStyle(.plain)
            .padding(.top, AuthMetric.skipTopInset)
            .padding(.trailing, AuthMetric.horizontalInset + 1)
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            Image("LogoCompact")
                .resizable()
                .scaledToFit()
                .frame(width: AuthMetric.logoSize, height: AuthMetric.logoSize)

            Text(headerTitle)
                .font(AuthMetric.titleFont)
                .foregroundStyle(BaseViewColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AuthMetric.logoToTitleGap)

            Text(headerSubtitle)
                .font(AuthMetric.bodyFont)
                .foregroundStyle(AuthMetric.placeholderColor)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AuthMetric.titleToSubtitleGap)
        }
        .frame(maxWidth: .infinity)
    }

    private var tabSwitcher: some View {
        HStack(spacing: AuthMetric.segmentGap) {
            ForEach(AuthTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.title)
                        .font(AuthMetric.segmentFont)
                        .foregroundStyle(selectedTab == tab ? BaseViewColor.textPrimary : AuthMetric.placeholderColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AuthMetric.segmentVerticalPadding)
                        .frame(minHeight: AuthMetric.segmentHeight)
                        .overlay {
                            Rectangle()
                                .strokeBorder(selectedTab == tab ? BaseViewColor.textPrimary : AuthMetric.borderColor, lineWidth: 1)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AuthMetric.horizontalInset)
    }

    private var signInForm: some View {
        VStack(spacing: AuthMetric.fieldGap) {
            AuthTextField(
                placeholder: "912345678",
                text: $authViewModel.phoneNumber,
                prefix: "+84",
                focusedField: $focusedField,
                field: .phone,
                keyboardType: .numberPad
            )

            AuthTextField(
                placeholder: "Mật khẩu",
                text: $authViewModel.password,
                isSecure: true,
                focusedField: $focusedField,
                field: .password
            )

            AuthActionButton(
                title: "ĐĂNG NHẬP",
                style: .primary,
                isLoading: authViewModel.isLoading,
                action: authViewModel.loginWithPassword
            )
            .padding(.top, AuthMetric.fieldToPrimaryCTAGap - AuthMetric.fieldGap)

            AuthActionButton(
                title: "ĐĂNG NHẬP VỚI OTP",
                style: .outlined,
                isLoading: authViewModel.isLoading,
                action: requestOTP
            )
            .padding(.top, AuthMetric.primaryToSecondaryCTAGap - AuthMetric.fieldGap)
        }
        .padding(.horizontal, AuthMetric.horizontalInset)
    }

    private var signUpForm: some View {
        VStack(spacing: AuthMetric.fieldGap) {
            AuthTextField(
                placeholder: "Họ và Tên",
                text: $authViewModel.fullName,
                focusedField: $focusedField,
                field: .name,
                textContentType: .name
            )

            AuthTextField(
                placeholder: "912345678",
                text: $authViewModel.phoneNumber,
                prefix: "+84",
                focusedField: $focusedField,
                field: .phone,
                keyboardType: .numberPad
            )

            AuthTextField(
                placeholder: "Mật khẩu",
                text: $authViewModel.password,
                isSecure: true,
                focusedField: $focusedField,
                field: .password
            )

            AuthActionButton(
                title: "TẠO TÀI KHOẢN",
                style: .primary,
                isLoading: authViewModel.isLoading,
                action: authViewModel.register
            )
            .padding(.top, AuthMetric.fieldToPrimaryCTAGap - AuthMetric.fieldGap)
        }
        .padding(.horizontal, AuthMetric.horizontalInset)
    }

    private var otpForm: some View {
        VStack(spacing: AuthMetric.fieldGap) {
            AuthTextField(
                placeholder: "Mã OTP",
                text: $authViewModel.otpCode,
                focusedField: $focusedField,
                field: .otp,
                keyboardType: .numberPad,
                textContentType: .oneTimeCode
            )
            .padding(.top, AuthMetric.tabsToFieldsGap)

            AuthActionButton(
                title: "XÁC NHẬN",
                style: .primary,
                isLoading: authViewModel.isLoading
            ) {
                authViewModel.verifyOTP(code: authViewModel.otpCode)
            }
            .padding(.top, AuthMetric.fieldToPrimaryCTAGap - AuthMetric.fieldGap)

            AuthActionButton(
                title: "GỬI LẠI MÃ",
                style: .outlined,
                isLoading: authViewModel.isLoading
            ) {
                authViewModel.sendOTP(phoneNumber: authViewModel.phoneNumber)
            }
            .padding(.top, AuthMetric.primaryToSecondaryCTAGap - AuthMetric.fieldGap)

            Button {
                authViewModel.otpCode = ""
                authViewModel.error = nil
                authViewModel.authState = .idle
                focusedField = .phone
            } label: {
                BaseUnderlinedCTA(title: "ĐỔI SỐ ĐIỆN THOẠI")
                    .foregroundStyle(BaseViewColor.textPrimary)
            }
            .buttonStyle(.plain)
            .padding(.top, AuthMetric.fieldGap)
        }
        .padding(.horizontal, AuthMetric.horizontalInset)
    }

    private var footer: some View {
        VStack(spacing: AuthMetric.footerLineGap) {
            if selectedTab == .signUp && authViewModel.authState != .otpSent {
                Text("BẰNG CÁCH TIẾP TỤC, BẠN ĐỒNG Ý VỚI")
                    .font(AuthMetric.ctaFont)
                    .tracking(AuthMetric.letterSpacing)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button {
                // Terms screen is not wired in this view yet; keep the visible CTA tappable.
            } label: {
                Text("ĐIỀU KHOẢN SỬ DỤNG")
                    .font(AuthMetric.ctaFont)
                    .tracking(AuthMetric.letterSpacing)
                    .foregroundStyle(BaseViewColor.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AuthMetric.horizontalInset)
    }

    private var headerTitle: String {
        if authViewModel.authState == .otpSent { return "Xác nhận OTP" }
        return selectedTab == .signIn ? "Đăng nhập" : "Đăng kí"
    }

    private var headerSubtitle: String {
        if authViewModel.authState == .otpSent { return "Nhập mã đã gửi đến số điện thoại" }
        return selectedTab == .signIn ? "Chào mừng trở lại" : "Tạo tài khoản của bạn"
    }

    private func focusInitialField() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if authViewModel.authState == .otpSent {
                focusedField = .otp
            } else {
                focusedField = selectedTab == .signIn ? .phone : .name
            }
        }
    }

    private func requestOTP() {
        let normalized = authViewModel.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            authViewModel.error = "Vui lòng nhập số điện thoại"
            authViewModel.authState = .error
            return
        }

        authViewModel.phoneNumber = normalized
        authViewModel.sendOTP(phoneNumber: normalized)
    }

    private func skipAuth() {
        if isPresentedModally {
            dismiss()
        } else {
            appFlowController.transitionToLoggedOut()
        }
    }
}

private enum AuthTab: CaseIterable, Identifiable {
    case signIn
    case signUp

    var id: Self { self }

    var title: String {
        switch self {
        case .signIn: return "Đăng nhập"
        case .signUp: return "Đăng kí"
        }
    }
}

private enum AuthField: Hashable {
    case name
    case phone
    case password
    case otp
}

private enum AuthActionStyle {
    case primary
    case outlined
}

private struct AuthTextField: View {
    @Environment(\.colorScheme) private var colorScheme

    let placeholder: String
    @Binding var text: String
    var prefix: String? = nil
    var isSecure: Bool = false
    var focusedField: FocusState<AuthField?>.Binding
    var field: AuthField
    #if canImport(UIKit)
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    #endif

    var body: some View {
        HStack(spacing: AuthMetric.phonePrefixGap) {
            if let prefix {
                Text(prefix)
                    .font(AuthMetric.bodyFont)
                    .foregroundStyle(BaseViewColor.textPrimary)
            }

            Group {
                if isSecure {
                    SecureField(
                        "",
                        text: $text,
                        prompt: Text(placeholder)
                            .font(AuthMetric.bodyFont)
                            .foregroundColor(AuthMetric.placeholderColor)
                    )
                    .focused(focusedField, equals: field)
                    #if canImport(UIKit)
                    .textContentType(.password)
                    #endif
                } else {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text(placeholder)
                            .font(AuthMetric.bodyFont)
                            .foregroundColor(AuthMetric.placeholderColor)
                    )
                    .focused(focusedField, equals: field)
                    #if canImport(UIKit)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    #endif
                }
            }
            .font(AuthMetric.bodyFont)
            .foregroundStyle(BaseViewColor.textPrimary)
        }
        .padding(.horizontal, AuthMetric.fieldHorizontalPadding)
        .padding(.vertical, AuthMetric.fieldVerticalPadding)
        .frame(minHeight: AuthMetric.fieldHeight)
        .frame(maxWidth: .infinity)
        .background(fieldBackground)
        .textInputAutocapitalization(field == .name ? .words : .never)
        .autocorrectionDisabled(field != .name)
    }

    private var fieldBackground: Color {
        colorScheme == .dark
            ? BaseViewColor.textPrimary.opacity(0.12)
            : BaseViewColor.textPrimary.opacity(0.08)
    }
}

private struct AuthActionButton: View {
    let title: String
    let style: AuthActionStyle
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                }

                Text(title)
                    .font(AuthMetric.ctaFont)
                    .tracking(AuthMetric.letterSpacing)
                    .foregroundStyle(foregroundColor)
                    .multilineTextAlignment(.center)
                    .opacity(isLoading ? 0 : 1)
            }
            .padding(.horizontal, AuthMetric.ctaHorizontalPadding)
            .padding(.vertical, AuthMetric.ctaVerticalPadding)
            .frame(minHeight: AuthMetric.ctaMinHeight)
            .frame(maxWidth: .infinity)
            .background(background)
            .overlay {
                if style == .outlined {
                    Rectangle().strokeBorder(AuthMetric.borderColor, lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
            .opacity(isLoading ? 0.65 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private var foregroundColor: Color {
        style == .primary ? BaseViewColor.accentForeground : BaseViewColor.textPrimary
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            Rectangle().fill(BaseViewColor.accent)
        case .outlined:
            Rectangle().fill(Color.clear)
        }
    }
}

private enum AuthMetric {
    static let horizontalInset: CGFloat = 23
    static let innerInset: CGFloat = 13
    static let skipTopInset: CGFloat = 26

    static let logoTopInset: CGFloat = 52
    static let logoSize: CGFloat = 116
    static let logoToTitleGap: CGFloat = 13
    static let titleHeight: CGFloat = 27
    static let titleToSubtitleGap: CGFloat = 10
    static let bodyLineHeight: CGFloat = 23
    static let headerToTabsGap: CGFloat = 17

    static let segmentHeight: CGFloat = 26
    static let segmentVerticalPadding: CGFloat = 5
    static let segmentGap: CGFloat = 8
    static let tabsToFieldsGap: CGFloat = 23

    static let fieldHeight: CGFloat = 49
    static let fieldGap: CGFloat = 13
    static let fieldHorizontalPadding: CGFloat = innerInset
    static let fieldVerticalPadding: CGFloat = 13
    static let phonePrefixGap: CGFloat = 20
    static let fieldToPrimaryCTAGap: CGFloat = 40
    static let primaryToSecondaryCTAGap: CGFloat = 13

    static let ctaMinHeight: CGFloat = 38
    static let ctaHorizontalPadding: CGFloat = 18
    static let ctaVerticalPadding: CGFloat = 10
    static let letterSpacing: CGFloat = 2

    static let formToFooterMinGap: CGFloat = 56
    static let footerLineGap: CGFloat = 13
    static let footerBottomInset: CGFloat = 34

    static let titleFont = Font.custom("BeVietnamPro-Bold", size: 22)
    static let bodyFont = BaseViewFont.body
    static let segmentFont = BaseViewFont.label
    static let ctaFont = BaseViewFont.cta

    static let placeholderColor = Color(hex: "#979797")
    static let borderColor = Color(hex: "#979797")

    static func contentMinHeight(for availableHeight: CGFloat) -> CGFloat {
        max(0, availableHeight - logoTopInset - footerBottomInset)
    }
}

#Preview {
    LoginView(isPresentedModally: false)
        .environmentObject(DependencyContainer.shared.makeAuthViewModel())
        .environmentObject(DependencyContainer.shared.appFlowController)
}
