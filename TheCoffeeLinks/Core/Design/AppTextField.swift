import SwiftUI

struct AppTextField: View {
    let title: LocalizedStringKey?
    @Binding var text: String
    let placeholder: LocalizedStringKey
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            if let title {
                Text(title)
                    .font(AppFont.labelStrong)
                    .foregroundStyle(AppColor.textSecondary)
            }

            TextField(placeholder, text: $text)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(keyboardType == .phonePad || keyboardType == .numberPad ? .never : .words)
                .padding(.horizontal, AppSpacing.row)
                .padding(.vertical, 12)
                .frame(minHeight: AppSpacing.controlHeight)
                .background(AppColor.elevated)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                        .strokeBorder(AppColor.border, lineWidth: AppSpacing.borderWidth)
                }
        }
    }
}

struct AppOTPField: View {
    @Binding var code: String

    var body: some View {
        TextField("otp_placeholder", text: $code)
            .font(AppFont.points)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .onChange(of: code) { value in
                code = String(value.filter(\.isNumber).prefix(6))
            }
            .padding(.vertical, 12)
            .background(AppColor.elevated)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                    .strokeBorder(AppColor.border, lineWidth: AppSpacing.borderWidth)
            }
            .accessibilityLabel(Text("otp_accessibility"))
    }
}
