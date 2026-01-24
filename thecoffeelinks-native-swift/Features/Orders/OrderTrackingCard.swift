//
//  OrderTrackingCard.swift
//  thecoffeelinks-native-swift
//
//  Standardized Order Tracking Card
//  Supports Realtime, Pickup, and Delivery
//

import SwiftUI
import CachedAsyncImage

struct OrderTrackingCard: View {
    let order: Order
    
    // Derived UI State
    var isDelivery: Bool { order.mode == .delivery }
    
    var statusTitle: String {
        switch order.status {
        case .pending: return "Processing Order"
        case .placed: return "Order Placed"
        case .received: return "Order Confirmed"
        case .preparing: return "Preparing..."
        case .ready: return isDelivery ? "Out for Delivery" : "Ready for Pickup"
        case .delivering: return "Arriving Soon"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var statusSubtitle: String {
        switch order.status {
        case .pending: return "Verifying details..."
        case .placed: return "Waiting for store confirmation"
        case .received: return "We have received your order"
        case .preparing: return "Barista is making your drink"
        case .ready: return isDelivery ? "Driver is on the way" : "Head to counter to collect"
        case .delivering: return "Driver is nearby"
        case .completed: return "Thank you for visiting!"
        case .cancelled: return "Order was cancelled"
        }
    }
    
    // Progress for ProgressBar (0.0 to 1.0)
    var progress: CGFloat {
        switch order.status {
        case .pending: return 0.05
        case .placed: return 0.1
        case .received: return 0.25
        case .preparing: return 0.5
        case .ready: return 0.75
        case .delivering: return 0.9
        case .completed: return 1.0
        case .cancelled: return 0.0
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. Status Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(Color.primaryEspresso)
                    
                    Text(statusSubtitle)
                        .font(AppFont.body)
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // ETA or Type Badge
                VStack(alignment: .trailing, spacing: 4) {
                    if let eta = order.estimatedReadyAt, order.status.isActive {
                        Text(timeString(from: eta))
                            .font(AppFont.monoHeadline)
                            .foregroundStyle(Color.textInk)
                        
                        Text("ETA")
                            .font(AppFont.uiCaption)
                            .foregroundStyle(Color.textMuted)
                    } else {
                        // Badge
                        Text(isDelivery ? "DELIVERY" : "PICKUP")
                            .font(AppFont.monoCaption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.backgroundPaper)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.border, lineWidth: 1))
                    }
                }
            }
            .padding(AppLayout.spacing)
            .background(Color.surfaceCard)
            
            // 2. Progress Bar (Continuous)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.backgroundPaper)
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.primaryEspresso)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 4)
            
            // 3. Compact Item List
            VStack(alignment: .leading, spacing: 12) {
                ForEach(order.items.prefix(2)) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(item.quantity)x")
                            .font(AppFont.monoHeadline)
                            .foregroundStyle(Color.primaryEspresso)
                            .frame(minWidth: 24, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.productName)
                                .font(AppFont.headline)
                                .foregroundStyle(Color.textInk)
                                .lineLimit(1)
                            
                            if !item.customization.displayText.isEmpty {
                                Text(item.customization.displayText)
                                    .font(AppFont.uiCaption)
                                    .foregroundStyle(Color.textMuted)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                if order.items.count > 2 {
                    Text("+ \(order.items.count - 2) more items")
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.textMuted)
                        .padding(.leading, 36)
                }
            }
            .padding(AppLayout.spacing)
            .background(Color.white) // Use white/paper to differentiate from gray header
            
            // 4. Action / Location Footer (Contextual)
            if order.status.isActive {
                HStack {
                    if isDelivery {
                        Label("Tracking Driver", systemImage: "map.fill")
                            .font(AppFont.uiCaption)
                    } else {
                        Label("Store Directions", systemImage: "location.fill")
                            .font(AppFont.uiCaption)
                    }
                    
                    Spacer()
                    
                    Text("#\(order.id.prefix(6).uppercased())")
                        .font(AppFont.monoCaption)
                        .foregroundStyle(Color.textMuted)
                }
                .padding(.horizontal, AppLayout.spacing)
                .padding(.vertical, 12)
                .background(Color.backgroundPaper)
                .foregroundStyle(Color.textInk)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.border, lineWidth: 1)
        )
        .padding(.horizontal, AppLayout.spacing)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
