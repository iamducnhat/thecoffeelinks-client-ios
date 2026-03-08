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
                            
                            // H2 FIX: Order details section with full price breakdown
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
                                    
                                    // Store name (H2 FIX)
                                    if let storeName = order.storeSnapshot?.name {
                                        HStack {
                                            Image(systemName: "storefront")
                                                .foregroundStyle(Color.textSecondary)
                                            Text(storeName)
                                                .font(AppFont.body)
                                                .foregroundStyle(Color.textPrimary)
                                        }
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
                                    
                                    // H2 FIX: Price breakdown
                                    VStack(alignment: .leading, spacing: 6) {
                                        // Subtotal line
                                        HStack {
                                            Text(String(localized: "subtotal_label"))
                                                .font(AppFont.body)
                                                .foregroundStyle(Color.textSecondary)
                                            Spacer()
                                            Text(order.subtotal.formattedVND)
                                                .font(AppFont.monoBody)
                                                .foregroundStyle(Color.textSecondary)
                                        }
                                        
                                        // Voucher discount
                                        if let voucherDiscount = order.voucherSnapshot?.appliedDiscount, voucherDiscount > 0 {
                                            HStack {
                                                Text(String(localized: "voucher_discount_label"))
                                                    .font(AppFont.body)
                                                    .foregroundStyle(Color.accentPrimary)
                                                if let code = order.voucherSnapshot?.code {
                                                    Text("(\(code))")
                                                        .font(AppFont.uiMicro)
                                                        .foregroundStyle(Color.accentPrimary)
                                                }
                                                Spacer()
                                                Text("-\(voucherDiscount.formattedVND)")
                                                    .font(AppFont.monoBody)
                                                    .foregroundStyle(Color.accentPrimary)
                                            }
                                        }
                                        
                                        // Points discount
                                        if let pointsUsed = order.pointsUsed, pointsUsed > 0 {
                                            let pointsDiscount = Double(pointsUsed) * 1000.0
                                            HStack {
                                                Text(String(localized: "points_discount_label"))
                                                    .font(AppFont.body)
                                                    .foregroundStyle(Color.accentPrimary)
                                                Text("(\(pointsUsed) pts)")
                                                    .font(AppFont.uiMicro)
                                                    .foregroundStyle(Color.accentPrimary)
                                                Spacer()
                                                Text("-\(pointsDiscount.formattedVND)")
                                                    .font(AppFont.monoBody)
                                                    .foregroundStyle(Color.accentPrimary)
                                            }
                                        }
                                        
                                        // Tax
                                        if let tax = order.tax, tax > 0 {
                                            let rateText = order.taxRate.map { "\(Int($0 * 100))%" } ?? "8%"
                                            HStack {
                                                Text(String(localized: "tax_label"))
                                                    .font(AppFont.body)
                                                    .foregroundStyle(Color.textSecondary)
                                                Text("(\(rateText))")
                                                    .font(AppFont.uiMicro)
                                                    .foregroundStyle(Color.textSecondary)
                                                Spacer()
                                                Text(tax.formattedVND)
                                                    .font(AppFont.monoBody)
                                                    .foregroundStyle(Color.textSecondary)
                                            }
                                        }
                                        
                                        // Delivery fee
                                        if order.deliveryFee > 0 {
                                            HStack {
                                                Text(String(localized: "delivery_fee_label"))
                                                    .font(AppFont.body)
                                                    .foregroundStyle(Color.textSecondary)
                                                Spacer()
                                                Text(order.deliveryFee.formattedVND)
                                                    .font(AppFont.monoBody)
                                                    .foregroundStyle(Color.textSecondary)
                                            }
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
                                    
                                    // Order type & payment
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
                                
                                // H2 FIX: Share/Receipt button
                                Button {
                                    shareOrderReceipt(order)
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text(String(localized: "share_receipt_button"))
                                    }
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textSecondary)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.bgSecondary)
                                    .clipShape(Capsule())
                                }
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
    
    // H2 FIX: Share receipt as text
    private func shareOrderReceipt(_ order: Order) {
        var receipt = "☕ TheCoffeeLinks - Receipt\n"
        receipt += "Order #\(String(order.id.prefix(8)).uppercased())\n"
        if let storeName = order.storeSnapshot?.name {
            receipt += "Store: \(storeName)\n"
        }
        receipt += String(repeating: "─", count: 30) + "\n"
        
        for item in order.items {
            receipt += "\(item.quantity)x \(item.productName) — \(item.totalPrice.formattedVND)\n"
        }
        
        receipt += String(repeating: "─", count: 30) + "\n"
        receipt += "Subtotal: \(order.subtotal.formattedVND)\n"
        
        if let discount = order.voucherSnapshot?.appliedDiscount, discount > 0 {
            let code = order.voucherSnapshot?.code ?? ""
            receipt += "Voucher (\(code)): -\(discount.formattedVND)\n"
        }
        if let pts = order.pointsUsed, pts > 0 {
            receipt += "Points (\(pts)): -\((Double(pts) * 1000.0).formattedVND)\n"
        }
        if let tax = order.tax, tax > 0 {
            receipt += "Tax: \(tax.formattedVND)\n"
        }
        if order.deliveryFee > 0 {
            receipt += "Delivery: \(order.deliveryFee.formattedVND)\n"
        }
        
        receipt += String(repeating: "─", count: 30) + "\n"
        receipt += "Total: \(order.totalAmount.formattedVND)\n"
        receipt += "\nThank you for your order! 🙏"
        
        let av = UIActivityViewController(activityItems: [receipt], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}
