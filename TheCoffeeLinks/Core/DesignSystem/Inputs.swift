import SwiftUI

struct BrandTextField: View {
    let title: String
    @Binding var text: String
    let icon: String?
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        AppTextInput(
            title: title,
            text: $text,
            leadingIcon: icon,
            keyboardType: keyboardType,
            isSecure: isSecure
        )
    }
}

struct SearchInput: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    
    var body: some View {
        AppSearchInput(text: $text, placeholder: placeholder)
    }
}

