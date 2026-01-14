//
//  OrderTrackingBanner.swift
//  thecoffeelinks-native-swift
//
//  Persistent order tracking banner shown when order is active
//

import SwiftUI

struct OrderTrackingBanner: View {
    let order: Order
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Status indicator
            statusIndicator
            
            // Order info
            VStack(alignment: .leading, spacing: 2) {
                Text(statusCopy)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white)
                
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            
            Spacer()
            
            // Time/Action
            VStack(alignment: .trailing, spacing: 2) {
                Text(estimatedTime)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.sunRay)
                
                Text("Track")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.forestCanopy.gradient)
        }
        .shadow(color: Color.forestCanopy.opacity(0.3), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicator: some View {
        ZStack {
            // Pulsing background for active states
            if isActiveState {
                Circle()
                    .fill(statusColor.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
            }
            
            Circle()
                .fill(statusColor)
                .frame(width: 36, height: 36)
            
            Image(systemName: statusIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.forestCanopy)
        }
    }
    
    // MARK: - Status-based Properties
    
    private var orderStatus: String {
        order.status?.lowercased() ?? "unknown"
    }
    
    private var isActiveState: Bool {
        ["received", "preparing"].contains(orderStatus)
    }
    
    private var statusColor: Color {
        switch orderStatus {
        case "received": return Color.sunRay
        case "preparing": return Color.filteredLight
        case "ready": return Color.successGreen
        default: return Color.neutral300
        }
    }
    
    private var statusIcon: String {
        switch orderStatus {
        case "received": return "checkmark"
        case "preparing": return "flame.fill"
        case "ready": return "bell.fill"
        default: return "questionmark"
        }
    }
    
    // MARK: - Premium Microcopy
    
    private var statusCopy: String {
        switch orderStatus {
        case "received": return "Order confirmed"
        case "preparing": return "Crafting your order..."
        case "ready": return "Ready at the bar"
        default: return "Processing"
        }
    }
    
    private var statusSubtitle: String {
        switch orderStatus {
        case "received": return "We've got it. Starting soon."
        case "preparing": return "Almost there. Smells good already."
        case "ready": return "Come get it. Still hot."
        default: return "Hang tight"
        }
    }
    
    private var estimatedTime: String {
        switch orderStatus {
        case "received": return "~8 min"
        case "preparing": return "~4 min"
        case "ready": return "Now"
        default: return "--"
        }
    }
}

// MARK: - Compact Version (for Home)

struct OrderTrackingBannerCompact: View {
    let order: Order
    
    var body: some View {
        HStack(spacing: 12) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            
            Text(statusCopy)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.forestCanopy)
            
            Spacer()
            
            Text(estimatedTime)
                .font(.caption.bold())
                .foregroundStyle(Color.sunRay)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.sunRay.opacity(0.15))
                .cornerRadius(8)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.neutral400)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.forestCanopy.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private var orderStatus: String {
        order.status?.lowercased() ?? "unknown"
    }
    
    private var statusColor: Color {
        switch orderStatus {
        case "received": return Color.sunRay
        case "preparing": return Color.filteredLight
        case "ready": return Color.successGreen
        default: return Color.neutral300
        }
    }
    
    private var statusCopy: String {
        switch orderStatus {
        case "received": return "Order confirmed"
        case "preparing": return "Crafting yours..."
        case "ready": return "Ready at the bar!"
        default: return "Processing"
        }
    }
    
    private var estimatedTime: String {
        switch orderStatus {
        case "received": return "~8 min"
        case "preparing": return "~4 min"
        case "ready": return "Now"
        default: return "--"
        }
    }
}

// MARK: - Preview

#Preview("Order Tracking Banner - Received") {
    VStack(spacing: 20) {
        OrderTrackingBanner(order: Order(
            id: "123",
            userId: "user1",
            status: "received",
            totalAmount: 75000,
            type: "take_away",
            tableId: nil,
            createdAt: nil,
            deliveryAddress: nil,
            orderItems: nil
        ))
        
        OrderTrackingBanner(order: Order(
            id: "123",
            userId: "user1",
            status: "preparing",
            totalAmount: 75000,
            type: "take_away",
            tableId: nil,
            createdAt: nil,
            deliveryAddress: nil,
            orderItems: nil
        ))
        
        OrderTrackingBanner(order: Order(
            id: "123",
            userId: "user1",
            status: "ready",
            totalAmount: 75000,
            type: "take_away",
            tableId: nil,
            createdAt: nil,
            deliveryAddress: nil,
            orderItems: nil
        ))
    }
    .padding()
    .background(Color.morningFog)
}

#Preview("Compact Banner") {
    OrderTrackingBannerCompact(order: Order(
        id: "123",
        userId: "user1",
        status: "preparing",
        totalAmount: 75000,
        type: "take_away",
        tableId: nil,
        createdAt: nil,
        deliveryAddress: nil,
        orderItems: nil
    ))
    .padding()
    .background(Color.morningFog)
}
