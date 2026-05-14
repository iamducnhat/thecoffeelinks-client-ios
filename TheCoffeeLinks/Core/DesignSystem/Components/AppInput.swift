import SwiftUI

struct AppTextInput: View {
    let title: String?
    @Binding var text: String
    var placeholder: String = ""
    var leadingIcon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    init(
        title: String? = nil,
        text: Binding<String>,
        placeholder: String = "",
        leadingIcon: String? = nil,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.leadingIcon = leadingIcon
        self.keyboardType = keyboardType
        self.isSecure = isSecure
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(BaseViewFont.label)
                    .foregroundStyle(BaseViewColor.textSecondary)
            }

            HStack(spacing: BaseViewLayout.spacingCompact) {
                if let leadingIcon {
                    IconView(name: leadingIcon)
                        .font(BaseViewFont.body)
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
                .keyboardType(keyboardType)
            }
            .padding(.horizontal, BaseViewLayout.badgeInset)
            .padding(.vertical, BaseViewLayout.spacingCompact)
            .frame(minHeight: BaseViewLayout.rowHeight)
            .background(BaseViewColor.elevatedSurface)
            .overlay(
                Rectangle()
                    .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
            )
        }
    }
}

struct AppSearchInput: View {
    @Binding var text: String
    var placeholder: String = "Search..."

    var body: some View {
        HStack(spacing: BaseViewLayout.spacingCompact) {
            IconView(name: "magnifyingglass")
                .font(BaseViewFont.body)
                .foregroundStyle(BaseViewColor.textSecondary)

            TextField(placeholder, text: $text)
                .font(BaseViewFont.body)
                .foregroundStyle(BaseViewColor.textPrimary)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    IconView(name: "circle_x")
                        .font(BaseViewFont.body)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, BaseViewLayout.badgeInset)
        .padding(.vertical, BaseViewLayout.spacingCompact)
        .frame(minHeight: BaseViewLayout.rowHeight)
        .background(BaseViewColor.elevatedSurface)
        .overlay(
            Rectangle()
                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
    }
}

struct AppSegmentedPicker<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    init(
        options: [Option],
        selection: Binding<Option>,
        title: @escaping (Option) -> String
    ) {
        self.options = options
        self._selection = selection
        self.title = title
    }

    init(
        selection: Binding<Option>,
        options: [(value: Option, label: String)]
    ) {
        self.options = options.map(\.value)
        self._selection = selection
        let labels = Dictionary(uniqueKeysWithValues: options)
        self.title = { option in labels[option] ?? String(describing: option) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option

                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .font(BaseViewFont.labelStrong)
                        .foregroundStyle(isSelected ? BaseViewColor.accentForeground : BaseViewColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, BaseViewLayout.badgeInset)
                        .padding(.vertical, BaseViewLayout.spacingCompact)
                        .frame(minHeight: BaseViewLayout.rowHeight)
                        .background(isSelected ? BaseViewColor.accent : BaseViewColor.elevatedSurface)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(
            Rectangle()
                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
        )
    }
}

struct AppInput: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        AppTextInput(
            title: title,
            text: $text,
            placeholder: placeholder,
            keyboardType: keyboardType,
            isSecure: isSecure
        )
    }
}

struct AppInput_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AppTextInput(title: "Email", text: .constant(""), placeholder: "Enter your email")
            AppSearchInput(text: .constant("Cappuccino"))
            AppTextInput(title: "Password", text: .constant("secret"), isSecure: true)
        }
        .padding()
        .background(BaseViewColor.background)
        .previewLayout(.sizeThatFits)
    }
}
