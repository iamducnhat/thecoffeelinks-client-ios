import SwiftUI

struct Animations {
    // Confetti
    struct ConfettiView: View {
        @State private var confetti: [ConfettiParticle] = []
        @State private var timer: Timer?
        
        var body: some View {
            ZStack {
                ForEach(confetti) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                startConfetti()
            }
        }
        
        func startConfetti() {
            // Emit particles logic
        }
    }
    
    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var color: Color
        var size: CGFloat
        var opacity: Double
    }
    
    // Fly to Cart Modifier
    struct FlyToCartModifier: ViewModifier {
        @Binding var isTriggered: Bool
        var targetPosition: CGPoint
        
        func body(content: Content) -> some View {
            content
                .overlay(
                    GeometryReader { geo in
                        if isTriggered {
                            content
                                .frame(width: 20, height: 20)
                                .position(x: geo.size.width/2, y: geo.size.height/2)
                                .transition(.asymmetric(insertion: .identity, removal: .opacity))
                        }
                    }
                )
                .onChange(of: isTriggered) { newValue in
                    if newValue {
                        withAnimation(.spring()) {
                            // Animate to target
                        }
                    }
                }
        }
    }
}

extension View {
    func flyToCart(trigger: Binding<Bool>, target: CGPoint) -> some View {
        self.modifier(Animations.FlyToCartModifier(isTriggered: trigger, targetPosition: target))
    }
}
