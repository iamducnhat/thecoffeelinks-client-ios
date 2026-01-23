//
//  OrderDetailViews.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    @State private var scrollOffset = CGFloat.zero
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            // Fixed Navigation Header
            HStack(alignment: .center, spacing: AppLayout.spacing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(AppFont.navIcon)
                        .foregroundStyle(Color.textInk)
                        .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                        .background {
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .fill(Color.backgroundPaper)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.textInk, lineWidth: min(66.6, max(scrollOffset, 0.0)) / 66.6)
                                .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                        }
                }
                
                Text("Order #\(order.id.prefix(8).uppercased())")
                    .font(AppFont.displayTitle)
                    .lineLimit(1)
                    .foregroundStyle(Color.textInk)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hidden()
            }
            .frame(minHeight: AppLayout.touchTarget)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, AppLayout.spacing)
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Navigation Header (Scrollable)
                    HStack(alignment: .center, spacing: AppLayout.spacing) {
                        Image(systemName: "xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textInk)
                            .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                            .hidden()
                        
                        Text("Order #\(order.id.prefix(8).uppercased())")
                            .font(AppFont.displayTitle)
                            .lineLimit(1)
                            .foregroundStyle(Color.textInk)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: AppLayout.touchTarget)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, AppLayout.spacing)
                    .overlay(alignment: .bottom) {
                        Color.secondary.frame(height: 1, alignment: .top)
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    LazyVStack(spacing: AppLayout.spacingXL) {
                        // Status Section
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Status")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(order.status.displayName)
                                        .font(AppFont.headline)
                                        .foregroundStyle(Color.textInk)
                                    Text(statusMessage)
                                        .font(AppFont.uiCaption)
                                        .foregroundStyle(Color.textMuted)
                                }
                                
                                Spacer()
                                
                                Text(order.status.isActive ? "ACTIVE" : "CLOSED")
                                    .font(AppFont.monoBody)
                                    .foregroundStyle(order.status.isActive ? Color.primaryEspresso : Color.textMuted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                            .stroke(order.status.isActive ? Color.primaryEspresso : Color.border, lineWidth: 1)
                                    )
                            }
                            .padding(AppLayout.spacing)
                            .background(Color.surfaceCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        
                        // Progress Bar (if active)
                        if order.status != .completed && order.status != .cancelled {
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("Progress")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textInk)
                                
                                OrderProgressBar(progress: progressValue)
                            }
                            .padding(.horizontal, AppLayout.spacing)
                        }
                        
                        // Divider
                        WaveSeparator(stepWidth: AppLayout.waveStepWidth)
                            .stroke(Color.secondary, lineWidth: 1)
                            .frame(height: 1)
                            .padding(.horizontal, AppLayout.spacing)
                        
                        // Items Section
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Items")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            VStack(spacing: 0) {
                                ForEach(order.items) { item in
                                    OrderItemRow(item: item)
                                    
                                    if item.id != order.items.last?.id {
                                        Color.secondary.frame(height: 1)
                                    }
                                }
                            }
                            .background(Color.backgroundPaper)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, AppLayout.spacing)
                        
                        // Total Section
                        VStack(spacing: 0) {
                            ReceiptSummaryRow(label: "Subtotal", value: order.totalAmount.formattedVND)
                            ReceiptSummaryRow(label: "Tax & fees", value: (0.0).formattedVND)
                            ReceiptSummaryRow(label: "Total", value: order.totalAmount.formattedVND, isTotal: true)
                        }
                        .background(Color.backgroundPaper)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.textInk, lineWidth: 2)
                        )
                        .padding(.horizontal, AppLayout.spacing)
                        
                        // Order Details
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Details")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            VStack(spacing: 0) {
                                DetailRow(label: "Order ID", value: String(order.id.prefix(8)).uppercased())
                                DetailRow(label: "Placed", value: order.createdAt.formatted(.dateTime.month().day().hour().minute()))
                                DetailRow(label: "Payment", value: order.paymentMethod.displayName)
                            }
                            .background(Color.backgroundPaper)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, AppLayout.spacing)
                    }
                    .padding(.top, AppLayout.spacing)
                    .padding(.bottom, 100)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
            }
            .zIndex(-Double.infinity)
        }
    }
    
    private var progressValue: Double {
        switch order.status {
        case .pending: return 0.1
        case .placed: return 0.25
        case .preparing: return 0.5
        case .ready: return 0.75
        case .delivering: return 0.85
        case .completed: return 1.0
        case .cancelled: return 0.0
        case .received: return 0.35
        }
    }
    
    private var statusMessage: String {
        switch order.status {
        case .pending: return "We've received your order"
        case .placed: return "Order confirmed by the shop"
        case .preparing: return "Your coffee is being prepared"
        case .ready: return "Your order is ready for pickup"
        case .delivering: return "Your order is on the way"
        case .completed: return "Hope you enjoyed it!"
        case .cancelled: return "This order was cancelled"
        case .received: return "The kitchen has received your order"
        }
    }
}

// MARK: - Progress Bar

struct OrderProgressBar: View {
    let progress: Double
    let length: Int = 20
    
    var body: some View {
        HStack(spacing: 4) {
            Text("[")
                .font(AppFont.monoBody)
            
            Text(barString)
                .font(AppFont.monoBody)
                .foregroundStyle(Color.primaryEspresso)
            
            Text("]")
                .font(AppFont.monoBody)
            
            Spacer()
            
            Text("\(Int(progress * 100))%")
                .font(AppFont.monoBody)
                .foregroundStyle(Color.primaryEspresso)
        }
        .foregroundStyle(Color.textInk)
        .padding(AppLayout.spacing)
        .background(Color.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.border, lineWidth: 1)
        )
    }
    
    private var barString: String {
        let filledCount = Int(Double(length) * progress)
        let emptyCount = length - filledCount
        return String(repeating: "=", count: max(0, filledCount - 1)) + (filledCount > 0 ? ">" : "") + String(repeating: "-", count: emptyCount)
    }
}

// MARK: - Order Item Row

struct OrderItemRow: View {
    let item: OrderItem
    
    var body: some View {
        HStack(alignment: .top, spacing: AppLayout.spacing) {
            Text("\(item.quantity)×")
                .font(AppFont.monoBody.bold())
                .foregroundStyle(Color.primaryEspresso)
                .frame(width: 30, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(AppFont.body)
                    .foregroundStyle(Color.textInk)
                
                Text(item.customization.displayText)
                    .font(AppFont.uiMicro)
                    .foregroundStyle(Color.textMuted)
                
                if let notes = item.customization.notes {
                    Text("Note: \(notes)")
                        .font(AppFont.uiMicro)
                        .foregroundStyle(Color.primaryEspresso)
                }
            }
            
            Spacer()
            
            Text(item.totalPrice.formattedVND)
                .font(AppFont.monoBody)
                .foregroundStyle(Color.textInk)
        }
        .padding(AppLayout.spacing)
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFont.uiCaption)
                .foregroundStyle(Color.textMuted)
            Spacer()
            Text(value)
                .font(AppFont.monoBody)
                .foregroundStyle(Color.textInk)
        }
        .padding(AppLayout.spacing)
    }
}

// MARK: - Summary Row

struct ReceiptSummaryRow: View {
    let label: String
    let value: String
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? AppFont.totalLabel : AppFont.body)
                .foregroundStyle(Color.textInk)
            Spacer()
            Text(value)
                .font(isTotal ? AppFont.monoTitle : AppFont.monoBody)
                .foregroundStyle(isTotal ? Color.textInk : Color.textMuted)
        }
        .padding(AppLayout.spacing)
        .background(isTotal ? Color.surfaceCard : Color.backgroundPaper)
    }
}
