//
//  DeliveryModeView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

// MARK: - Banner

struct DeliveryModeBanner: View {
    let currentMode: OrderingMode
    let currentAddress: DeliveryAddress?
    let deliveryAvailability: DeliveryAvailability?
    let onChangeMode: () -> Void
    let onChangeAddress: () -> Void
    
    var body: some View {
        VStack(spacing: AppLayout.spacing) {
            Button(action: onChangeMode) {
                HStack(spacing: AppLayout.spacing) {
                    Image(currentMode.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.primaryEspresso)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentMode.displayName)
                            .font(AppFont.headline)
                            .foregroundStyle(Color.textInk)
                        
                        if currentMode == .delivery {
                            if let address = currentAddress {
                                Text(address.shortAddress)
                                    .font(AppFont.uiCaption)
                                    .foregroundStyle(Color.textMuted)
                            } else {
                                Text(String(localized: "delivery_select_address"))
                                    .font(AppFont.uiCaption)
                                    .foregroundStyle(Color.semanticError)
                            }
                        } else {
                            Text(String(localized: "delivery_pickup_option"))
                                .font(AppFont.uiCaption)
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                    
                    Spacer()
                    
                    Image("chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textMuted)
                }
                .padding(AppLayout.spacing)
                .background(Color.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                        .stroke(Color.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
            .buttonStyle(.plain)
            
            // Availability Warning / Info
            if currentMode == .delivery {
                if let availability = deliveryAvailability, !availability.available {
                    DeliveryUnavailableWarning(reason: availability.unavailableReason)
                } else if currentAddress != nil, deliveryAvailability == nil {
                    // Loading State
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.primaryEspresso)
                        Text(String(localized: "delivery_checking_status"))
                            .font(AppFont.uiMicro)
                            .foregroundStyle(Color.textMuted)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.backgroundPaper)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                            .stroke(Color.border, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                    )
                } else if let availability = deliveryAvailability, availability.available {
                    DeliveryInfoCard(availability: availability)
                }
            }
        }
    }
}

// MARK: - Warning

struct DeliveryUnavailableWarning: View {
    let reason: DeliveryAvailability.UnavailableReason?
    
    var body: some View {
        HStack(spacing: AppLayout.spacing) {
            Image("triangle_alert")
                .foregroundStyle(Color.semanticError)
            Text(reason?.message ?? "Delivery unavailable")
                .font(AppFont.uiCaption)
                .foregroundStyle(Color.textInk)
            Spacer()
        }
        .padding(AppLayout.spacing)
        .background(Color.semanticError.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.semanticError.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
    }
}

// MARK: - Info Card

struct DeliveryInfoCard: View {
    let availability: DeliveryAvailability
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                HStack(spacing: 4) {
                    Image("bicycle")
                        .foregroundStyle(Color.semanticSuccess)
                    Text(String(localized: "delivery_available_label"))
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.semanticSuccess)
                }
                Spacer()
                if let eta = availability.eta {
                    Text(eta.displayRange)
                        .font(AppFont.monoBody)
                        .foregroundStyle(Color.textInk)
                }
            }
            
            if let fee = availability.fee {
                HStack {
                    Text(String(localized: "delivery_fee_label"))
                        .font(AppFont.uiMicro)
                        .foregroundStyle(Color.textMuted)
                    Spacer()
                    Text(fee.displayAmount)
                        .font(AppFont.uiMicro)
                        .foregroundStyle(Color.textInk)
                }
            }
            
            if let minOrder = availability.minOrderAmount {
                HStack {
                    Text(String(localized: "delivery_min_order_label"))
                        .font(AppFont.uiMicro)
                        .foregroundStyle(Color.textMuted)
                    Spacer()
                    Text(minOrder.formattedVND)
                        .font(AppFont.uiMicro)
                        .foregroundStyle(Color.textInk)
                }
            }
        }
        .padding(AppLayout.spacing)
        .background(Color.backgroundPaper)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                .stroke(Color.semanticSuccess, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
    }
}

// MARK: - Mode Sheet

struct OrderingModeSheet: View {
    let currentMode: OrderingMode
    let onSelect: (OrderingMode) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text(String(localized: "common_cancel"))
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                    }
                    
                    Spacer()
                    
                    Text(String(localized: "delivery_order_type_label"))
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 50)
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    VStack(spacing: AppLayout.spacing) {
                        Text(String(localized: "delivery_mode_prompt"))
                            .font(AppFont.sectionHeader)
                            .foregroundStyle(Color.textInk)
                            .padding(.top, AppLayout.spacing)
                        
                        VStack(spacing: AppLayout.spacing) {
                            ForEach(OrderingMode.allCases, id: \.self) { mode in
                                ModeOptionCard(
                                    mode: mode,
                                    isSelected: mode == currentMode,
                                    onTap: {
                                        onSelect(mode)
                                        dismiss()
                                    }
                                )
                            }
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}

// MARK: - Option Card

struct ModeOptionCard: View {
    let mode: OrderingMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppLayout.spacing) {
                Image(mode.iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? Color.primaryEspresso : Color.textMuted)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(AppFont.headline)
                        .foregroundStyle(Color.textInk)
                    Text(modeDescription)
                        .font(AppFont.uiCaption)
                        .foregroundStyle(Color.textMuted)
                }
                
                Spacer()
                
                if isSelected {
                    Image("circle_check")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.primaryEspresso)
                } else {
                    Image("circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.border)
                }
            }
            .padding(AppLayout.spacing)
            .background(isSelected ? Color.surfaceCard : Color.backgroundPaper)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                    .stroke(isSelected ? Color.primaryEspresso : Color.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
        }
        .buttonStyle(.plain)
    }
    
    private var modeDescription: String {
        switch mode {
        case .pickup: return "Order ahead and pick up at store"
        case .dineIn: return "Order from your table"
        case .delivery: return "Get it delivered to your door"
        }
    }
}

struct DeliveryValidation {
    static func validateForCheckout(cart: Cart, availability: DeliveryAvailability?) -> DeliveryCheckoutValidation {
        guard cart.mode == .delivery else {
            return DeliveryCheckoutValidation(isValid: true, errors: [])
        }
        
        var errors: [String] = []
        
        if cart.deliveryAddressId == nil {
            errors.append("Please select a delivery address")
        }
        
        guard let availability = availability else {
            errors.append("Checking delivery availability...")
            return DeliveryCheckoutValidation(isValid: false, errors: errors)
        }
        
        if !availability.available {
            errors.append(availability.unavailableReason?.message ?? "Delivery unavailable")
        }
        
        if let minOrder = availability.minOrderAmount, cart.subtotal < minOrder {
            errors.append("Minimum order: \(minOrder.formattedVND)")
        }
        
        // Check for non-deliverable items
        // Use property from ProductModels.swift
        let nonDeliverableItems = cart.items.filter { !$0.product.canBeDelivered }
        if !nonDeliverableItems.isEmpty {
            errors.append("\(nonDeliverableItems.count) item(s) cannot be delivered")
        }
        
        return DeliveryCheckoutValidation(isValid: errors.isEmpty, errors: errors)
    }
}

struct DeliveryCheckoutValidation {
    let isValid: Bool
    let errors: [String]
}
