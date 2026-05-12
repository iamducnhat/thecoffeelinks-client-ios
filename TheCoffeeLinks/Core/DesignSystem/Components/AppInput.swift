import SwiftUI

struct AppInput: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty {
                Text(title)
                    .font(BaseViewFont.label)
                    .foregroundStyle(BaseViewColor.textSecondary)
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(BaseViewFont.body)
            .foregroundStyle(BaseViewColor.textPrimary)
            .padding(.horizontal, BaseViewLayout.badgeInset)
            .frame(height: BaseViewLayout.rowHeight)
            .background(BaseViewColor.elevatedSurface)
            .keyboardType(keyboardType)
        }
    }
}

struct AppInput_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AppInput(title: "Email", text: .constant(""), placeholder: "Enter your email")
            AppInput(title: "Password", text: .constant("secret"), isSecure: true)
        }
        .padding()
        .background(BaseViewColor.background)
        .previewLayout(.sizeThatFits)
    }
}
