import SwiftUI

struct BrandTextField: View {
    let title: String
    @Binding var text: String
    let icon: String?
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Editorial.uiCaption())
                .fontWeight(.medium)
                .foregroundStyle(Editorial.Colors.textMuted)
            
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(Editorial.Colors.textMuted)
                }
                
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .padding()
            .background(Editorial.Colors.secondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Editorial.Colors.separator, lineWidth: 1)
            )
        }
    }
}

struct SearchInput: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Editorial.Colors.textMuted)
            
            TextField(placeholder, text: $text)
                .font(Editorial.uiBody())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Editorial.Colors.textMuted)
                }
            }
        }
        .padding()
        .background(Editorial.Colors.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

