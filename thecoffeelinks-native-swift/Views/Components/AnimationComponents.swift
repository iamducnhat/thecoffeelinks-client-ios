//
//  AnimationComponents.swift
//  thecoffeelinks-native-swift
//
//  Premium animations per Blueprint - delight and polish
//

import SwiftUI

// MARK: - Confetti Effect

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let rotation: Double
    let x: CGFloat
    let speed: Double
}

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var isAnimating = false
    
    let colors: [Color] = [Editorial.Colors.primaryEspresso, Editorial.Colors.semanticSuccess, .red, .orange, .blue, .green]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.6)
                        .rotationEffect(.degrees(piece.rotation + (isAnimating ? 360 : 0)))
                        .offset(
                            x: piece.x - geometry.size.width / 2,
                            y: isAnimating ? geometry.size.height + 50 : -50
                        )
                        .animation(
                            .easeIn(duration: piece.speed).delay(Double.random(in: 0...0.5)),
                            value: isAnimating
                        )
                }
            }
        }
        .onAppear {
            generatePieces()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAnimating = true
            }
        }
        .allowsHitTesting(false)
    }
    
    private func generatePieces() {
        pieces = (0..<50).map { _ in
            ConfettiPiece(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                speed: Double.random(in: 2...4)
            )
        }
    }
}

// MARK: - Success Checkmark Animation

struct SuccessCheckmark: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Circle
            Circle()
                .stroke(Editorial.Colors.semanticSuccess.opacity(0.2), lineWidth: 4)
                .frame(width: 80, height: 80)
            
            // Animated circle
            Circle()
                .trim(from: 0, to: isAnimating ? 1 : 0)
                .stroke(Editorial.Colors.semanticSuccess, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: isAnimating)
            
            // Checkmark
            Path { path in
                path.move(to: CGPoint(x: 22, y: 40))
                path.addLine(to: CGPoint(x: 35, y: 55))
                path.addLine(to: CGPoint(x: 58, y: 28))
            }
            .trim(from: 0, to: isAnimating ? 1 : 0)
            .stroke(Editorial.Colors.semanticSuccess, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            .animation(.easeInOut(duration: 0.4).delay(0.4), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Fly to Cart Animation

struct FlyToCartModifier: ViewModifier {
    @Binding var isFlying: Bool
    let targetPosition: CGPoint
    @State private var position: CGPoint = .zero
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(x: isFlying ? targetPosition.x - position.x : 0,
                    y: isFlying ? targetPosition.y - position.y : 0)
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        position = CGPoint(x: geo.frame(in: .global).midX,
                                          y: geo.frame(in: .global).midY)
                    }
                }
            )
            .onChange(of: isFlying) { newValue in
                if newValue {
                    withAnimation(.easeIn(duration: 0.5)) {
                        scale = 0.3
                        opacity = 0.5
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isFlying = false
                        scale = 1
                        opacity = 1
                    }
                }
            }
    }
}

extension View {
    func flyToCart(isFlying: Binding<Bool>, targetPosition: CGPoint) -> some View {
        modifier(FlyToCartModifier(isFlying: isFlying, targetPosition: targetPosition))
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1)
            .animation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulse(duration: Double = 1.0) -> some View {
        modifier(PulseModifier(duration: duration))
    }
}

// MARK: - Shake Animation (for errors)

struct ShakeModifier: ViewModifier {
    @Binding var isShaking: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(x: isShaking ? -10 : 0)
            .animation(
                isShaking ? .default.repeatCount(5, autoreverses: true).speed(6) : .default,
                value: isShaking
            )
            .onChange(of: isShaking) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isShaking = false
                    }
                }
            }
    }
}

extension View {
    func shake(isShaking: Binding<Bool>) -> some View {
        modifier(ShakeModifier(isShaking: isShaking))
    }
}

// MARK: - Bounce Animation

struct BounceModifier: ViewModifier {
    @Binding var isBouncing: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? 1.2 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isBouncing)
            .onChange(of: isBouncing) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isBouncing = false
                    }
                }
            }
    }
}

extension View {
    func bounce(isBouncing: Binding<Bool>) -> some View {
        modifier(BounceModifier(isBouncing: isBouncing))
    }
}

// MARK: - Slide In Animation

struct SlideInModifier: ViewModifier {
    @State private var isVisible = false
    let edge: Edge
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .offset(x: offsetX, y: offsetY)
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
    
    private var offsetX: CGFloat {
        if !isVisible {
            switch edge {
            case .leading: return -50
            case .trailing: return 50
            default: return 0
            }
        }
        return 0
    }
    
    private var offsetY: CGFloat {
        if !isVisible {
            switch edge {
            case .top: return -30
            case .bottom: return 30
            default: return 0
            }
        }
        return 0
    }
}

extension View {
    func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        modifier(SlideInModifier(edge: edge, delay: delay))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        SuccessCheckmark()
        
        Text("Tap me!")
            .padding()
            .background(Editorial.Colors.semanticSuccess)
            .foregroundStyle(.white)
            .cornerRadius(12)
            .pulse()
        
        ConfettiView()
            .frame(height: 200)
    }
}
