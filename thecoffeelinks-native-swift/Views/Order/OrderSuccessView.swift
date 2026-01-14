//
//  OrderSuccessView.swift
//  thecoffeelinks-native-swift
//
//  Order Success Celebration per Blueprint O-005
//

import SwiftUI

struct OrderSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    let order: Order?
    
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Background
            Color.morningFog.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success Animation
                SuccessCheckmark()
                    .onAppear {
                        HapticManager.shared.orderPlaced()
                        showConfetti = true
                    }
                
                // Premium Copy
                VStack(spacing: 12) {
                    Text("Perfect.")
                        .font(.title.bold())
                        .foregroundStyle(Color.forestCanopy)
                    
                    Text("We're on it.")
                        .font(.title3)
                        .foregroundStyle(Color.neutral600)
                    
                    if let order = order {
                        Text("Order #\(order.id.prefix(6).uppercased())")
                            .font(.caption.monospaced())
                            .foregroundStyle(Color.neutral400)
                            .padding(.top, 8)
                    }
                }
                
                Spacer()
                
                // Estimated Time
                VStack(spacing: 8) {
                    Text("Estimated ready in")
                        .font(.subheadline)
                        .foregroundStyle(Color.neutral500)
                    
                    Text("5-7 min")
                        .font(.title2.bold())
                        .foregroundStyle(Color.forestCanopy)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Actions
                VStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Track Order")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.forestCanopy)
                            .cornerRadius(12)
                    }
                    .hapticOnTap(.medium)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue Shopping")
                            .font(.subheadline)
                            .foregroundStyle(Color.forestCanopy)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Preview

#Preview {
    OrderSuccessView(order: nil)
}
