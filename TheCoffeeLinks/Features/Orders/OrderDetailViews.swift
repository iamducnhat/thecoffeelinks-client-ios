//
//  OrderDetailViews.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    @State private var scrollOffset = CGFloat.zero
    @State private var showingIssueSheet = false
    @State private var issueText = ""
    @State private var issueMessage: String?
    @State private var isSubmittingIssue = false
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            // Fixed Navigation Header
            HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(BaseViewFont.navIcon)
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .frame(minWidth: BaseViewLayout.touchTarget, minHeight: BaseViewLayout.touchTarget)
                        .background {
                            Circle()
                                .fill(BaseViewColor.background)
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(BaseViewColor.textPrimary, lineWidth: 1)
                                .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                        }
                }
                
                Text("Order #\(order.id.prefix(8).uppercased())")
                    .font(BaseViewFont.displayTitle)
                    .lineLimit(1)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hidden()
            }
            .frame(minHeight: BaseViewLayout.touchTarget)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, BaseViewLayout.spacing)
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Navigation Header (Scrollable)
                    HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                        Image(systemName: "xmark")
                            .font(BaseViewFont.navIcon)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .frame(minWidth: BaseViewLayout.touchTarget, minHeight: BaseViewLayout.touchTarget)
                            .hidden()
                        
                        Text("Order #\(order.id.prefix(8).uppercased())")
                            .font(BaseViewFont.displayTitle)
                            .lineLimit(1)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: BaseViewLayout.touchTarget)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, BaseViewLayout.spacing)
                    .overlay(alignment: .bottom) {
                        Color.secondary.frame(height: 1, alignment: .top)
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    LazyVStack(spacing: BaseViewLayout.spacingXL) {
                        // Status Section
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text(String(localized: "order_detail_status"))
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(order.status.displayName)
                                        .font(BaseViewFont.headline)
                                        .foregroundStyle(BaseViewColor.textPrimary)
                                    Text(statusMessage)
                                        .font(BaseViewFont.uiCaption)
                                        .foregroundStyle(BaseViewColor.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text(order.status.isActive ? "ACTIVE" : "CLOSED")
                                    .font(BaseViewFont.monoBody)
                                    .foregroundStyle(order.status.isActive ? BaseViewColor.accent : BaseViewColor.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(order.status.isActive ? BaseViewColor.accent : BaseViewColor.border, lineWidth: 1)
                                    )
                            }
                            .padding(BaseViewLayout.spacing)
                            .background(BaseViewColor.surface)
                            .overlay(
                                Capsule()
                                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, BaseViewLayout.spacing)
                        
                        // Progress Bar (if active)
                        if order.status != .completed && order.status != .cancelled {
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                                Text(String(localized: "order_detail_progress"))
                                    .textCase(.uppercase)
                                    .font(BaseViewFont.sectionHeader)
                                    .foregroundStyle(BaseViewColor.textPrimary)
                                
                                OrderProgressBar(progress: progressValue)
                            }
                            .padding(.horizontal, BaseViewLayout.spacing)
                        }
                        
                        // Divider
                        WaveSeparator(stepWidth: BaseViewLayout.waveStepWidth)
    .stroke(Color.secondary, lineWidth: 1)
                            .frame(height: 1)
                            .padding(.horizontal, BaseViewLayout.spacing)
                        
                        // Items Section
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text(String(localized: "order_detail_items"))
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            VStack(spacing: 0) {
                                ForEach(order.items) { item in
                                    OrderItemRow(item: item)
                                    
                                    if item.id != order.items.last?.id {
                                        Color.secondary.frame(height: 1)
                                    }
                                }
                            }
                            .background(BaseViewColor.background)
                            .overlay(
                                Capsule()
                                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, BaseViewLayout.spacing)
                        
                        // Total Section
                        VStack(spacing: 0) {
                            ReceiptSummaryRow(label: "Subtotal", value: order.totalAmount.formattedVND)
                            ReceiptSummaryRow(label: "Tax & fees", value: (0.0).formattedVND)
                            ReceiptSummaryRow(label: "Total", value: order.totalAmount.formattedVND, isTotal: true)
                        }
                        .background(BaseViewColor.background)
                        .overlay(
                            Capsule()
                                .strokeBorder(BaseViewColor.textPrimary, lineWidth: 1)
                        )
                        .padding(.horizontal, BaseViewLayout.spacing)
                        
                        // Order Details
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text(String(localized: "order_detail_details"))
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            VStack(spacing: 0) {
                                DetailRow(label: "Order ID", value: String(order.id.prefix(8)).uppercased())
                                DetailRow(label: "Placed", value: order.createdAt.formatted(.dateTime.month().day().hour().minute()))
                                DetailRow(label: "Payment", value: order.paymentMethod.displayName)
                            }
                            .background(BaseViewColor.background)
                            .overlay(
                                Capsule()
                                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, BaseViewLayout.spacing)

                        // Support / Recovery
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text("Need help?")
                                .textCase(.uppercase)
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Report a payment, pickup, delivery, or quality issue tied to this order.")
                                    .font(BaseViewFont.uiCaption)
                                    .foregroundStyle(BaseViewColor.textSecondary)

                                Button {
                                    showingIssueSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "lifepreserver")
                                        Text("Contact support")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(BaseViewFont.uiButton)
                                    .foregroundStyle(BaseViewColor.background)
                                    .padding(BaseViewLayout.spacing)
                                    .background(BaseViewColor.textPrimary)
                                }

                                if let issueMessage {
                                    Text(issueMessage)
                                        .font(BaseViewFont.uiCaption)
                                        .foregroundStyle(BaseViewColor.textSecondary)
                                }
                            }
                            .padding(BaseViewLayout.spacing)
                            .background(BaseViewColor.surface)
                            .overlay(
                                Capsule()
                                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, BaseViewLayout.spacing)
                    }
                    .padding(.top, BaseViewLayout.spacing)
                    .padding(.bottom, 100)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
            }
            .zIndex(-Double.infinity)
        }
        .sheet(isPresented: $showingIssueSheet) {
            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                Text("Order support")
                    .font(BaseViewFont.displayTitle)
                    .foregroundStyle(BaseViewColor.textPrimary)

                Text("Tell us what happened. Support will see this with your order receipt.")
                    .font(BaseViewFont.uiCaption)
                    .foregroundStyle(BaseViewColor.textSecondary)

                TextEditor(text: $issueText)
                    .frame(minHeight: 160)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(BaseViewColor.border, lineWidth: 1)
                    )

                Button {
                    submitIssue()
                } label: {
                    HStack {
                        if isSubmittingIssue {
                            ProgressView()
                        }
                        Text(isSubmittingIssue ? "Sending..." : "Send to support")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(BaseViewLayout.spacing)
                    .background(BaseViewColor.textPrimary)
                    .foregroundStyle(BaseViewColor.background)
                }
                .disabled(isSubmittingIssue || issueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Cancel") {
                    showingIssueSheet = false
                }
                .frame(maxWidth: .infinity)
            }
            .padding(BaseViewLayout.spacingXL)
            .presentationDetents([.medium])
        }
    }

    private func submitIssue() {
        let detail = issueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !detail.isEmpty else { return }
        isSubmittingIssue = true
        Task {
            do {
                try await DependencyContainer.shared.orderRepository.reportOrderIssue(
                    id: order.id,
                    category: "support",
                    subject: "Customer reported an order issue",
                    description: detail
                )
                await MainActor.run {
                    issueMessage = "Support request sent."
                    issueText = ""
                    showingIssueSheet = false
                    isSubmittingIssue = false
                }
            } catch {
                await MainActor.run {
                    issueMessage = error.localizedDescription
                    isSubmittingIssue = false
                }
            }
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
                .font(BaseViewFont.monoBody)
            
            Text(barString)
                .font(BaseViewFont.monoBody)
                .foregroundStyle(BaseViewColor.accent)
            
            Text("]")
                .font(BaseViewFont.monoBody)
            
            Spacer()
            
            Text("\(Int(progress * 100))%")
                .font(BaseViewFont.monoBody)
                .foregroundStyle(BaseViewColor.accent)
        }
        .foregroundStyle(BaseViewColor.textPrimary)
        .padding(BaseViewLayout.spacing)
        .background(BaseViewColor.surface)
        .overlay(
            Capsule()
                .strokeBorder(BaseViewColor.border, lineWidth: 1)
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
        HStack(alignment: .top, spacing: BaseViewLayout.spacing) {
            Text("\(item.quantity)×")
                .font(BaseViewFont.monoBody.bold())
                .foregroundStyle(BaseViewColor.accent)
                .frame(width: 30, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(BaseViewFont.body)
                    .foregroundStyle(BaseViewColor.textPrimary)
                
                Text(item.customization.displayText)
                    .font(BaseViewFont.uiMicro)
                    .foregroundStyle(BaseViewColor.textSecondary)
                
                if let notes = item.customization.notes {
                    Text("Note: \(notes)")
                        .font(BaseViewFont.uiMicro)
                        .foregroundStyle(BaseViewColor.accent)
                }
            }
            
            Spacer()
            
            Text(item.totalPrice.formattedVND)
                .font(BaseViewFont.monoBody)
                .foregroundStyle(BaseViewColor.textPrimary)
        }
        .padding(BaseViewLayout.spacing)
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(BaseViewFont.uiCaption)
                .foregroundStyle(BaseViewColor.textSecondary)
            Spacer()
            Text(value)
                .font(BaseViewFont.monoBody)
                .foregroundStyle(BaseViewColor.textPrimary)
        }
        .padding(BaseViewLayout.spacing)
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
                .font(isTotal ? BaseViewFont.totalLabel : BaseViewFont.body)
                .foregroundStyle(BaseViewColor.textPrimary)
            Spacer()
            Text(value)
                .font(isTotal ? BaseViewFont.monoTitle : BaseViewFont.monoBody)
                .foregroundStyle(isTotal ? BaseViewColor.textPrimary : BaseViewColor.textSecondary)
        }
        .padding(BaseViewLayout.spacing)
        .background(isTotal ? BaseViewColor.surface : BaseViewColor.background)
    }
}
