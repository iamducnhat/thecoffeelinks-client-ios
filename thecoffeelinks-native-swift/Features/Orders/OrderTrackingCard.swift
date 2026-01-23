//
//  OrderTrackingCard.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Style Active Order Card
//  Matches App "Editorial" Design System
//

import SwiftUI
import CachedAsyncImage

struct OrderTrackingCard: View {
    let order: Order
    
    // Status Logic
    var statusMessage: String {
        switch order.status {
        case .placed: return "Order Placed"
        case .preparing: return "Preparing"
        case .ready: 
            return order.mode == .delivery ? "Driver Hearing Out" : "Ready for Pickup"
        case .delivering: return "On the Way"
        case .completed: return "Completed"
        default: return order.status.displayName
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Ticket Stub Style
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ORDER #\(order.id.prefix(6).uppercased())")
                        .font(AppFont.monoHeadline)
                        .foregroundStyle(Color.textInk)
                    
                    Text(statusMessage)
                        .font(AppFont.sectionHeader) // Geologica Medium 20
                        .foregroundStyle(Color.primaryEspresso)
                }
                
                Spacer()
                
                // Status Icon/Time
                VStack(alignment: .trailing, spacing: 4) {
                    if let eta = order.estimatedReadyAt {
                        Text(timeString(from: eta))
                            .font(AppFont.monoBody)
                            .foregroundStyle(Color.textInk)
                    } else {
                        Text("--:--")
                            .font(AppFont.monoBody)
                            .foregroundStyle(Color.textMuted)
                    }
                    
                    Text(order.mode == .delivery ? "Delivery" : "Pickup")
                        .font(AppFont.uiCaption)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.textMuted)
                }
            }
            .padding(AppLayout.spacing)
            .background(Color.surfaceCard)
            
            // Divider (Dashed Visual)
            Rectangle()
                .fill(Color.backgroundPaper)
                .frame(height: 1)
                .overlay(
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(Color.border)
                )
            
            // Content: Items List
            VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
                ForEach(order.items.prefix(3)) { item in
                    HStack(spacing: AppLayout.spacing) {
                        // Quantity Badge
                        Text("\(item.quantity)x")
                            .font(AppFont.monoBody)
                            .foregroundStyle(Color.primaryEspresso)
                            .padding(6)
                            .background(Color.primaryEspresso.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.productName)
                                .font(AppFont.body)
                                .foregroundStyle(Color.textInk)
                                .lineLimit(1)
                            
                            if !item.customization.displayText.isEmpty {
                                Text(item.customization.displayText)
                                    .font(AppFont.uiCaption)
                                    .foregroundStyle(Color.textMuted)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                if order.items.count > 3 {
                    Text("+ \(order.items.count - 3) more items...")
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.textMuted)
                        .padding(.leading, 40) // Align with text
                }
            }
            .padding(AppLayout.spacing)
            .background(Color.backgroundPaper)
            
            // Footer: Progress Indicator
            HStack(spacing: 4) {
                // Visualize 5 steps: Placed, Received(skipped in UI but logical), Preparing, Ready, Completed
                // Actually: Placed -> Preparing -> Ready -> Delivered/Completed
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < currentStepIndex ? Color.primaryEspresso : Color.border)
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppLayout.spacing)
            .padding(.bottom, AppLayout.spacing)
            .background(Color.backgroundPaper)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
        // Completion Overlay
        .overlay {
            if order.status == .completed {
                CompletionOverlay()
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: order.status)
    }
    
    // Step Helper
    var currentStepIndex: Int {
        switch order.status {
        case .placed: return 1
        case .preparing: return 2
        case .ready: return 3
        case .delivering, .completed: return 4
        default: return 0
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Completion Overlay Animation
struct CompletionOverlay: View {
    @State private var showCheck = false
    
    var body: some View {
        ZStack {
            Color.backgroundPaper
            
            VStack(spacing: 16) {
                // Check Circle
                ZStack {
                    Circle()
                        .fill(Color.primaryEspresso)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(showCheck ? 1 : 0.5)
                        .opacity(showCheck ? 1 : 0)
                }
                .scaleEffect(showCheck ? 1 : 0.8)
                .animation(.bouncy(duration: 0.6).delay(0.2), value: showCheck)
                
                Text("Order Completed")
                    .font(AppFont.displayTitle)
                    .foregroundStyle(Color.textInk)
                    .opacity(showCheck ? 1 : 0)
                    .offset(y: showCheck ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: showCheck)
                
                Text("Enjoy your coffee!")
                    .font(AppFont.body)
                    .foregroundStyle(Color.textMuted)
                    .opacity(showCheck ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: showCheck)
            }
        }
        .onAppear {
            withAnimation { showCheck = true }
        }
    }
}
