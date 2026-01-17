import SwiftUI

struct AppButton: View {
    enum Style {
        case primary
        case secondary
        case destructive
    }
    
    let title: String
    let icon: String?
    let style: Style
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: AppLayout.spacingCompact) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Text(title)
                    .fontButton()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(borderColor, lineWidth: AppLayout.borderWidth)
            )
            .opacity(isDisabled || isLoading ? 0.6 : 1.0)
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(foregroundColor)
                    }
                }
            )
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return .primaryEspresso
        case .secondary: return .clear
        case .destructive: return .semanticError.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .surfaceCard
        case .secondary: return .primaryEspresso
        case .destructive: return .semanticError
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .secondary: return .primaryEspresso
        case .destructive: return .clear
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct AppButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AppButton("Checkout • $15.50", style: .primary) {}
            AppButton("Browse Menu", style: .secondary) {}
            AppButton("Logout", icon: "arrow.right.square", style: .destructive) {}
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
