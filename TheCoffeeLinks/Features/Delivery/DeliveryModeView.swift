//
//  DeliveryModeView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
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
        VStack(spacing: BaseViewLayout.spacing) {
            Button(action: onChangeMode) {
                HStack(spacing: BaseViewLayout.spacing) {
                    IconView(name: currentMode.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(BaseViewColor.accent)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentMode.displayName)
                            .font(BaseViewFont.headline)
                            .foregroundStyle(BaseViewColor.textPrimary)
                        
                        if currentMode == .delivery {
                            if let address = currentAddress {
                                Text(address.shortAddress)
                                    .font(BaseViewFont.uiCaption)
                                    .foregroundStyle(BaseViewColor.textSecondary)
                            } else {
                                Text(String(localized: "delivery_select_address"))
                                    .font(BaseViewFont.uiCaption)
                                    .foregroundStyle(BaseViewColor.semanticError)
                            }
                        } else {
                            Text(String(localized: "delivery_pickup_option"))
                                .font(BaseViewFont.uiCaption)
                                .foregroundStyle(BaseViewColor.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image("chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
                .padding(BaseViewLayout.spacing)
                .background(BaseViewColor.surface)
                .overlay(
                    Capsule()
                        .strokeBorder(BaseViewColor.border, lineWidth: 1)
                )
                .clipShape(Capsule())
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
                            .tint(BaseViewColor.accent)
                        Text(String(localized: "delivery_checking_status"))
                            .font(BaseViewFont.uiMicro)
                            .foregroundStyle(BaseViewColor.textSecondary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BaseViewColor.background)
                    .overlay(
                        Capsule()
                            .strokeBorder(BaseViewColor.border, style: StrokeStyle(lineWidth: 1, dash: BaseViewLayout.dashedPattern))
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
        HStack(spacing: BaseViewLayout.spacing) {
            Image("triangle_alert")
                .foregroundStyle(BaseViewColor.semanticError)
            Text(reason?.message ?? "Delivery unavailable")
                .font(BaseViewFont.uiCaption)
                .foregroundStyle(BaseViewColor.textPrimary)
            Spacer()
        }
        .padding(BaseViewLayout.spacing)
        .background(BaseViewColor.semanticError.opacity(0.1))
        .overlay(
            Capsule()
                .strokeBorder(BaseViewColor.semanticError.opacity(0.3), lineWidth: 1)
        )
        .clipShape(Capsule())
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
                        .foregroundStyle(BaseViewColor.semanticSuccess)
                    Text(String(localized: "delivery_available_label"))
                        .font(BaseViewFont.uiCaption)
                        .foregroundStyle(BaseViewColor.semanticSuccess)
                }
                Spacer()
                if let eta = availability.eta {
                    Text(eta.displayRange)
                        .font(BaseViewFont.monoBody)
                        .foregroundStyle(BaseViewColor.textPrimary)
                }
            }
            
            if let fee = availability.fee {
                HStack {
                    Text(String(localized: "delivery_fee_label"))
                        .font(BaseViewFont.uiMicro)
                        .foregroundStyle(BaseViewColor.textSecondary)
                    Spacer()
                    Text(fee.displayAmount)
                        .font(BaseViewFont.uiMicro)
                        .foregroundStyle(BaseViewColor.textPrimary)
                }
            }
            
            if let minOrder = availability.minOrderAmount {
                HStack {
                    Text(String(localized: "delivery_min_order_label"))
                        .font(BaseViewFont.uiMicro)
                        .foregroundStyle(BaseViewColor.textSecondary)
                    Spacer()
                    Text(minOrder.formattedVND)
                        .font(BaseViewFont.uiMicro)
                        .foregroundStyle(BaseViewColor.textPrimary)
                }
            }
        }
        .padding(BaseViewLayout.spacing)
        .background(BaseViewColor.background)
        .overlay(
            Capsule()
                .strokeBorder(BaseViewColor.semanticSuccess, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Mode Sheet

struct OrderingModeSheet: View {
    let currentMode: OrderingMode
    let onSelect: (OrderingMode) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: BaseViewLayout.lg) {
                    HStack {
                        Button { dismiss() } label: {
                            Text(String(localized: "common_cancel"))
                                .font(BaseViewFont.bodyMedium)
                                .foregroundStyle(BaseViewColor.textSecondary)
                        }
                        
                        Text(String(localized: "delivery_order_type_label"))
                            .font(BaseViewFont.displayMedium)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .fixedSize()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        
                        Color.clear.frame(width: 50)
                    }
                    .padding(.horizontal, BaseViewLayout.screenPadding)
                    
                    Divider()
                        .background(BaseViewColor.borderSecondary)
                        .padding(.horizontal, -BaseViewLayout.screenPadding)
                }
                .background(BaseViewColor.background)
                
                ScrollView {
                    VStack(spacing: BaseViewLayout.spacing) {
                        Text(String(localized: "delivery_mode_prompt"))
                            .font(BaseViewFont.sectionHeader)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .padding(.top, BaseViewLayout.spacing)
                        
                        VStack(spacing: BaseViewLayout.spacing) {
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
                    .padding(BaseViewLayout.spacing)
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
            HStack(spacing: BaseViewLayout.spacing) {
                IconView(name: mode.iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? BaseViewColor.accent : BaseViewColor.textSecondary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(BaseViewFont.headline)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    Text(modeDescription)
                        .font(BaseViewFont.uiCaption)
                        .foregroundStyle(BaseViewColor.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image("circle_check")
                        .font(.system(size: 20))
                        .foregroundStyle(BaseViewColor.accent)
                } else {
                    Image("circle")
                        .font(.system(size: 20))
                        .foregroundStyle(BaseViewColor.border)
                }
            }
            .padding(BaseViewLayout.spacing)
            .background(isSelected ? BaseViewColor.surface : BaseViewColor.background)
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? BaseViewColor.accent : BaseViewColor.border, lineWidth: 1)
            )
            .clipShape(Capsule())
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
