//
//  HapticManager.swift
//  thecoffeelinks-native-swift
//
//  Haptic feedback system per Blueprint - physical quality perception
//

import UIKit
import SwiftUI

// MARK: - Haptic Manager

@MainActor
class HapticManager {
    static let shared = HapticManager()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    private init() {
        // Pre-prepare generators for faster response
        prepare()
    }
    
    func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selection.prepare()
        notification.prepare()
    }
    
    // MARK: - Mapped Haptics per Blueprint
    
    /// Tab selection, category chip tap
    func tabSelected() {
        selection.selectionChanged()
    }
    
    /// Add item to cart
    func addedToCart() {
        mediumImpact.impactOccurred()
    }
    
    /// Remove item from cart
    func removedFromCart() {
        lightImpact.impactOccurred()
    }
    
    /// Checkout button tap
    func checkoutTapped() {
        heavyImpact.impactOccurred()
    }
    
    /// Order placed successfully
    func orderPlaced() {
        notification.notificationOccurred(.success)
    }
    
    /// Order ready notification
    func orderReady() {
        notification.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.notification.notificationOccurred(.success)
        }
    }
    
    /// Error occurred
    func error() {
        notification.notificationOccurred(.error)
    }
    
    /// Warning/attention
    func warning() {
        notification.notificationOccurred(.warning)
    }
    
    /// Button press
    func buttonPress() {
        lightImpact.impactOccurred()
    }
    
    /// Long press activated
    func longPressActivated() {
        rigidImpact.impactOccurred()
    }
    
    /// Pull to refresh triggered
    func pullToRefresh() {
        softImpact.impactOccurred()
    }
    
    /// Slider/picker value changed
    func valueChanged() {
        selection.selectionChanged()
    }
    
    /// Card expanded/collapsed
    func cardToggled() {
        lightImpact.impactOccurred()
    }
    
    /// Check-in at store
    func checkedIn() {
        heavyImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.notification.notificationOccurred(.success)
        }
    }
    
    /// Streak increased
    func streakIncreased() {
        mediumImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact.impactOccurred()
        }
    }
}

// MARK: - SwiftUI View Modifier

struct HapticOnTapModifier: ViewModifier {
    let type: HapticType
    
    enum HapticType {
        case light, medium, heavy, selection, success, error, warning
    }
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    triggerHaptic()
                }
            )
    }
    
    private func triggerHaptic() {
        let manager = HapticManager.shared
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            manager.orderPlaced()
        case .error:
            manager.error()
        case .warning:
            manager.warning()
        }
    }
}

extension View {
    func hapticOnTap(_ type: HapticOnTapModifier.HapticType = .light) -> some View {
        modifier(HapticOnTapModifier(type: type))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Button("Light Impact") {
            HapticManager.shared.buttonPress()
        }
        .padding()
        .background(Color.forestCanopy)
        .foregroundStyle(.white)
        .cornerRadius(12)
        
        Button("Add to Cart") {
            HapticManager.shared.addedToCart()
        }
        .padding()
        .background(Color.sunRay)
        .foregroundStyle(.white)
        .cornerRadius(12)
        
        Button("Order Placed") {
            HapticManager.shared.orderPlaced()
        }
        .padding()
        .background(Color.green)
        .foregroundStyle(.white)
        .cornerRadius(12)
        
        Button("Error") {
            HapticManager.shared.error()
        }
        .padding()
        .background(Color.red)
        .foregroundStyle(.white)
        .cornerRadius(12)
    }
}
