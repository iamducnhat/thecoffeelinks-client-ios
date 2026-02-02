//
//  OrderTrackingCard.swift
//  thecoffeelinks-client-ios
//

import SwiftUI
import CachedAsyncImage

struct OrderTrackingCard: View {
    let order: Order
    var onResumePayment: (() -> Void)? = nil
    
    // Derived UI State
    var isDelivery: Bool { order.mode == .delivery }
    
    var statusTitle: LocalizedStringKey {
        switch order.status {
        case .pending: return "Action Required"
        case .placed: return "Order Received"
        case .received: return "Confirmed"
        case .preparing: return "Crafting..."
        case .ready: return isDelivery ? "Out for Delivery" : "Ready to Pickup"
        case .delivering: return "Driver Nearby"
        case .completed: return "Enjoy Your Drink"
        case .cancelled: return "Terminated"
        }
    }
    
    var statusSubtitle: LocalizedStringKey {
        switch order.status {
        case .pending: return "Payment verification needed"
        case .placed: return "Waiting for store acknowledgment"
        case .received: return "Your order is in the queue"
        case .preparing: return "Barista is preparing your selection"
        case .ready: return isDelivery ? "Driver has left the store" : "Available at the collection counter"
        case .delivering: return "Arriving at your location soon"
        case .completed: return "Thank you for choosing us"
        case .cancelled: return "This order will not be fulfilled"
        }
    }
    
    private var progress: CGFloat {
        switch order.status {
        case .pending: return 0.1
        case .placed: return 0.2
        case .received: return 0.4
        case .preparing: return 0.6
        case .ready: return 0.8
        case .delivering: return 0.9
        case .completed: return 1.0
        case .cancelled: return 0.0
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 1. Status Header (The "Receipt Header")
            VStack(alignment: .leading, spacing: AppLayout.spacingSmall) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(statusTitle)
                            .font(AppFont.sectionHeader)
                            .foregroundStyle(Color.accentPrimary)
                            .textCase(.uppercase)
                        
                        Text(statusSubtitle)
                            .font(AppFont.body)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    // Mode Badge
                    Text(order.mode.displayName)
                        .font(AppFont.monoCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.bgPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous).strokeBorder(Color.border, lineWidth: 0.5)
                        )
                }
                
                if let eta = order.estimatedReadyAt, order.status.isActive {
                    HStack(spacing: 4) {
                        Image("clock")
                            .font(AppFont.monoCaption)
                        Text("ETA: \(timeString(from: eta))")
                            .font(AppFont.monoHeadline)
                    }
                    .foregroundStyle(Color.textPrimary)
                    .padding(.top, 4)
                }
            }
            .padding(AppLayout.spacing)
            .background(Color.surfacePrimary)
            
            // MARK: 2. Status Progress (The "Editorial Timeline")
            ZStack {
                Rectangle()
                    .fill(Color.border)
                    .frame(height: 1)
                
                HStack(spacing: 0) {
                    ProgressPoint(active: order.status.isActive || order.status == .completed)
                    Spacer()
                    ProgressPoint(active: order.status == .preparing || order.status == .ready || order.status == .delivering || order.status == .completed)
                    Spacer()
                    ProgressPoint(active: order.status == .ready || order.status == .delivering || order.status == .completed)
                    Spacer()
                    ProgressPoint(active: order.status == .completed)
                }
                .padding(.horizontal, AppLayout.spacing * 2)
            }
            .padding(.bottom, AppLayout.spacingMedium)
            .background(Color.surfacePrimary)
            
            // MARK: 3. Item Manifest
            VStack(alignment: .leading, spacing: AppLayout.spacingSmall) {
                ForEach(order.items.prefix(3)) { item in
                    HStack(alignment: .top, spacing: AppLayout.spacingMedium) {
                        Text("\(item.quantity)×")
                            .font(AppFont.monoHeadline)
                            .foregroundStyle(Color.accentPrimary)
                            .frame(width: 32, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.productName)
                                .font(AppFont.headline)
                                .foregroundStyle(Color.textPrimary)
                                .lineLimit(1)
                            
                            if !item.customization.displayText.isEmpty {
                                Text(item.customization.displayText)
                                    .font(AppFont.uiMicro)
                                    .foregroundStyle(Color.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        Text(item.totalPrice.formattedVND)
                            .font(AppFont.monoCaption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                if order.items.count > 3 {
                    Text("+ \(order.items.count - 3) more items")
                        .font(AppFont.uiMicro)
                        .foregroundStyle(Color.textTertiary)
                        .padding(.leading, 44)
                }
            }
            .padding(AppLayout.spacing)
            .background(Color.bgPrimary)
            
            // MARK: 4. Actions & Identification
            VStack(spacing: 0) {
                Divider()
                    .background(Color.border)
                
                HStack {
                    Text("#\(order.id.prefix(8).uppercased())")
                        .font(AppFont.monoCaption)
                        .foregroundStyle(Color.textTertiary)
                    
                    Spacer()
                    
                    if order.status == .pending && order.paymentUrl != nil {
                        Button {
                            onResumePayment?()
                        } label: {
                            HStack(spacing: 4) {
                                Text(String(localized: "order_complete_payment_action"))
                                Image("credit_card")
                            }
                            .font(AppFont.monoCaption)
                            .foregroundStyle(Color.bgPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentPrimary)
                            .clipShape(Capsule())
                        }
                    } else if order.status.isActive {
                        Label {
                            Text(isDelivery ? "LIVE TRACKING" : "GET DIRECTIONS")
                        } icon: {
                            Image(isDelivery ? "map" : "map_pin")
                        }
                            .font(AppFont.monoCaption)
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
                .padding(.horizontal, AppLayout.spacing)
                .padding(.vertical, AppLayout.spacingMedium)
            }
            .background(Color.bgPrimary)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay(
            Capsule()
                .stroke(Color.border, lineWidth: AppLayout.borderWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        .padding(.horizontal, AppLayout.margin)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct ProgressPoint: View {
    let active: Bool
    
    var body: some View {
        Circle()
            .fill(active ? Color.accentPrimary : Color.border)
            .frame(width: 8, height: 8)
            .background(
                Circle()
                    .stroke(Color.surfacePrimary, lineWidth: 4)
            )
    }
}
