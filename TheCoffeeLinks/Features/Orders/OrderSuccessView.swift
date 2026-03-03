//
//  OrderSuccessView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design — H2 FIX: Show order details, items, total, ETA
//

import SwiftUI

struct OrderSuccessView: View {
    let order: Order?
    let onDismiss: () -> Void
    let onTrackOrder: (() -> Void)?
    
    @State private var lines: [String] = []
    @State private var showDone = false
    
    init(order: Order? = nil, onDismiss: @escaping () -> Void, onTrackOrder: (() -> Void)? = nil) {
        self.order = order
        self.onDismiss = onDismiss
        self.onTrackOrder = onTrackOrder
    }
    
    let terminalOutput = [
        "> Submitting order...",
        "> Securing payment...",
        "> Order confirmed",
        "> Notification sent",
        "> Processing...",
        "> Order placed successfully",
        "─────────────────────────",
        "✓ Enjoy your coffee!"
    ]
    
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.spacing) {
                    Spacer()
                    
                    // Terminal output simulation
                    ForEach(lines, id: \.self) { line in
                        Text(line)
                            .font(AppFont.monoBody)
                            .foregroundStyle(line.contains("successfully") || line.contains("✓") ? Color.accentPrimary : Color.textPrimary)
                    }
                    
                    if showDone {
                        VStack(alignment: .leading, spacing: AppLayout.spacingXL) {
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text(String(localized: "order_success_title"))
                                    .font(AppFont.displayTitle)
                                    .foregroundStyle(Color.textPrimary)
                                
                                Text(String(localized: "order_success_message"))
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(.top, AppLayout.spacingXL)
                            
                            // H2 FIX: Order details section
                            if let order = order {
                                VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
                                    // Order ID
                                    HStack {
                                        Text(String(localized: "order_id_label"))
                                            .font(AppFont.body)
                                            .foregroundStyle(Color.textSecondary)
                                        Spacer()
                                        Text("#\(String(order.id.prefix(8)).uppercased())")
                                            .font(AppFont.monoBody)
                                            .foregroundStyle(Color.textPrimary)
                                    }
                                    
                                    Divider()
                                    
                                    // Items summary
                                    ForEach(order.items) { item in
                                        HStack {
                                            Text("\(item.quantity)x \(item.productName)")
                                                .font(AppFont.body)
                                                .foregroundStyle(Color.textPrimary)
                                                .lineLimit(1)
                                            Spacer()
                                            Text(item.totalPrice.formattedVND)
                                                .font(AppFont.monoBody)
                                                .foregroundStyle(Color.textSecondary)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    // Total
                                    HStack {
                                        Text(String(localized: "total_label"))
                                            .font(AppFont.sectionHeader)
                                            .foregroundStyle(Color.textPrimary)
                                        Spacer()
                                        Text(order.totalAmount.formattedVND)
                                            .font(AppFont.monoTitle)
                                            .foregroundStyle(Color.accentPrimary)
                                    }
                                    
                                    // ETA
                                    if let eta = order.estimatedReadyAt {
                                        HStack {
                                            Image(systemName: "clock")
                                                .foregroundStyle(Color.textSecondary)
                                            Text(String(localized: "estimated_ready_label"))
                                                .font(AppFont.body)
                                                .foregroundStyle(Color.textSecondary)
                                            Spacer()
                                            Text(eta, style: .time)
                                                .font(AppFont.monoBody)
                                                .foregroundStyle(Color.textPrimary)
                                        }
                                    }
                                    
                                    // Order type
                                    HStack {
                                        Image(systemName: order.mode.iconName)
                                            .foregroundStyle(Color.textSecondary)
                                        Text(order.mode.displayName)
                                            .font(AppFont.body)
                                            .foregroundStyle(Color.textSecondary)
                                        Spacer()
                                        Text(order.paymentMethod.displayName)
                                            .font(AppFont.body)
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                }
                                .padding()
                                .background(Color.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
                            }
                            
                            // Track Order button
                            if let onTrackOrder = onTrackOrder {
                                Button {
                                    onTrackOrder()
                                } label: {
                                    HStack {
                                        Image(systemName: "location.circle")
                                        Text(String(localized: "track_order_button"))
                                    }
                                    .font(AppFont.monoCTA)
                                    .foregroundStyle(Color.accentPrimary)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.accentPrimary.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                            
                            Button {
                                onDismiss()
                            } label: {
                                Text(String(localized: "common_done"))
                                    .font(AppFont.monoCTA)
                                    .foregroundStyle(Color.bgPrimary)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.accentPrimary)
                                    .clipShape(Capsule())
                            }
                        }
                        .transition(.opacity)
                    }
                    
                    Spacer()
                }
                .padding(40)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            DependencyContainer.shared.hapticManager.playSuccess()
            simulateTerminal()
        }
    }
    
    private func simulateTerminal() {
        for (index, line) in terminalOutput.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                withAnimation {
                    lines.append(line)
                }
                
                if index == terminalOutput.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showDone = true
                        }
                    }
                }
            }
        }
    }
}
