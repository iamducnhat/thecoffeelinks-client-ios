//
//  EmptyStateView.swift
//  thecoffeelinks-native-swift
//
//  Illustrated empty states per Blueprint - engaging and actionable
//

import SwiftUI

// MARK: - Empty State Types

enum EmptyStateType {
    case orders
    case cart
    case search
    case favorites
    case vouchers
    case notifications
    case stores
    case network
    
    var icon: String {
        switch self {
        case .orders: return "cup.and.saucer"
        case .cart: return "cart"
        case .search: return "magnifyingglass"
        case .favorites: return "heart"
        case .vouchers: return "ticket"
        case .notifications: return "bell"
        case .stores: return "mappin.and.ellipse"
        case .network: return "person.2"
        }
    }
    
    var title: String {
        switch self {
        case .orders: return "No orders yet"
        case .cart: return "Your cart is empty"
        case .search: return "No results found"
        case .favorites: return "No favorites yet"
        case .vouchers: return "No vouchers available"
        case .notifications: return "All caught up"
        case .stores: return "No stores nearby"
        case .network: return "No connections yet"
        }
    }
    
    var subtitle: String {
        switch self {
        case .orders: return "Your coffee journey starts with one sip. Ready to order?"
        case .cart: return "Add something delicious and we'll keep it warm here."
        case .search: return "Try a different search term or browse categories."
        case .favorites: return "Tap the heart on items you love to save them here."
        case .vouchers: return "Complete orders to unlock exclusive rewards."
        case .notifications: return "We'll let you know when something exciting happens."
        case .stores: return "Check your location or try a different area."
        case .network: return "Check in at a store to connect with other members."
        }
    }
    
    var actionTitle: String? {
        switch self {
        case .orders, .cart: return "Browse Menu"
        case .search: return "Clear Search"
        case .favorites: return "Explore Products"
        case .vouchers: return "View Rewards"
        case .stores: return "Enable Location"
        case .network: return "Check In Now"
        case .notifications: return nil
        }
    }
    
    var illustrationColor: Color {
        switch self {
        case .orders, .cart: return .sunRay
        case .search: return .forestCanopy
        case .favorites: return .sunRay
        case .vouchers: return .sunRay
        case .notifications: return .forestCanopy
        case .stores: return .forestCanopy
        case .network: return .forestCanopy
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let type: EmptyStateType
    var onAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // Illustration
            ZStack {
                Circle()
                    .fill(type.illustrationColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: type.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(type.illustrationColor)
            }
            
            // Text
            VStack(spacing: 8) {
                Text(type.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.forestCanopy)
                
                Text(type.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.neutral500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Action Button
            if let actionTitle = type.actionTitle, let action = onAction {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.forestCanopy)
                        .cornerRadius(24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let message: String
    var onRetry: (() -> Void)? = nil
    
    @State private var isShaking = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon with shake
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundStyle(.red)
            }
            .offset(x: isShaking ? -10 : 0)
            .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: isShaking)
            
            // Text
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.forestCanopy)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.neutral500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Retry Button
            if let retry = onRetry {
                Button(action: {
                    isShaking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isShaking = false
                        retry()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.forestCanopy)
                    .cornerRadius(24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            // Shake on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isShaking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isShaking = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        EmptyStateView(type: .cart) {
            print("Action tapped")
        }
        
        Divider()
        
        ErrorStateView(message: "Could not load data. Please check your connection.") {
            print("Retry tapped")
        }
    }
}
