import SwiftUI

struct AppInput: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacingMicro) {
            if !title.isEmpty {
                Text(title)
                    .fontMicro()
                    .foregroundColor(.textMuted)
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .fontBody()
            .foregroundColor(.textInk)
            .padding(AppLayout.spacingCompact)
            .background(Color.surfaceCard)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(Color.border, lineWidth: AppLayout.borderWidth)
            )
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
        .background(Color.backgroundPaper)
        .previewLayout(.sizeThatFits)
    }
}
