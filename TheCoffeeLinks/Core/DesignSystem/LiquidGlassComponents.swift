import SwiftUI

// MARK: - Liquid Glass Components (iOS 26)
// Adapted for Editorial Design System

// MARK: - Liquid Glass Card

struct LiquidGlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    
    init(cornerRadius: CGFloat = 20, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            )
            .shadow(color: Editorial.Colors.primaryEspresso.opacity(0.1), radius: 16, x: 0, y: 8)
            .shadow(color: Editorial.Colors.primaryEspresso.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Liquid Glass Button

enum LiquidGlassButtonStyle {
    case primary
    case secondary
    case ghost
}

struct LiquidGlassButton: View {
    let title: String
    let icon: String?
    let style: LiquidGlassButtonStyle
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(_ title: String, icon: String? = nil, style: LiquidGlassButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .fontButton()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(backgroundView)
            .foregroundStyle(foregroundColor)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Editorial.Colors.primaryEspresso)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: Editorial.Colors.primaryEspresso.opacity(0.4), radius: 12, x: 0, y: 4)
            
        case .secondary:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Editorial.Colors.primaryEspresso.opacity(0.4), Editorial.Colors.primaryEspresso.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            
        case .ghost:
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return Editorial.Colors.primaryEspresso
        case .ghost:
            return Editorial.Colors.primaryEspresso
        }
    }
}
