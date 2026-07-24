import SwiftUI

struct AppTextField: View {
    let title: LocalizedStringKey?
    @Binding var text: String
    let placeholder: LocalizedStringKey
    var prefix: String?
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            if let title {
                Text(title)
                    .font(AppFont.labelStrong)
                    .foregroundStyle(AppColor.textSecondary)
            }

            HStack(spacing: AppSpacing.row) {
                if let prefix {
                    Text(prefix)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textPrimary)
                }
                TextField(placeholder, text: $text)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(keyboardType == .phonePad || keyboardType == .numberPad ? .never : .words)
            }
            .padding(.horizontal, AppSpacing.row)
            .frame(height: AppSpacing.fieldHeight)
            .background(AppColor.surface)
        }
    }
}

struct AppOTPField: View {
    @Binding var code: String

    var body: some View {
        TextField("otp_placeholder", text: $code)
            .font(AppFont.screenTitle)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .onChange(of: code) { value in
                code = String(value.filter(\.isNumber).prefix(6))
            }
            .frame(height: AppSpacing.fieldHeight)
            .background(AppColor.surface)
            .accessibilityLabel(Text("otp_accessibility"))
    }
}
