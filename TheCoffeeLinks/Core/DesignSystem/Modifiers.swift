import SwiftUI

struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double
    
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial)
            .background(Color.white.opacity(opacity))
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1)
            )
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 16, opacity: Double = 0.4) -> some View {
        modifier(LiquidGlass(cornerRadius: cornerRadius, opacity: opacity))
    }
    
    func deepForestCard() -> some View {
        self
            .background(Editorial.Colors.primaryEspresso)
            .cornerRadius(16)
            .shadow(color: Editorial.Colors.primaryEspresso.opacity(0.3), radius: 15, x: 0, y: 8)
    }
    
    func neomorphicEffect() -> some View {
        self
            .shadow(color: Color.white, radius: 8, x: -4, y: -4)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 4, y: 4)
    }
}

