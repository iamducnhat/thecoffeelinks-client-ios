//
//  DeliveryModeBanner.swift
//  thecoffeelinks-native-swift
//
//  Persistent banner shown at top of HomeView when in delivery mode.
//  Shows: address, ETA, fee, and quick actions.
//

import SwiftUI

struct DeliveryModeBanner: View {
    let address: String
    let eta: String?
    let fee: String?
    let isSurge: Bool
    let minimumOrderAmount: Double?
    let onChangeAddress: () -> Void
    let onSwitchToPickup: () -> Void
    
    @ObservedObject private var deliveryService = DeliveryService.shared
    
    init(
        address: String,
        eta: String? = nil,
        fee: String? = nil,
        isSurge: Bool = false,
        minimumOrderAmount: Double? = nil,
        onChangeAddress: @escaping () -> Void,
        onSwitchToPickup: @escaping () -> Void
    ) {
        self.address = address
        self.eta = eta
        self.fee = fee
        self.isSurge = isSurge
        self.minimumOrderAmount = minimumOrderAmount
        self.onChangeAddress = onChangeAddress
        self.onSwitchToPickup = onSwitchToPickup
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main info row
            HStack(spacing: 12) {
                // Delivery icon
                Image(systemName: "bicycle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.brandPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.brandPrimary.opacity(0.12))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 3) {
                    // Address (truncated)
                    Text(truncatedAddress)
                        .font(.brandSans(14).weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // ETA & Fee row
                    HStack(spacing: 8) {
                        if let eta = eta {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 11))
                                Text(eta)
                            }
                            .font(.brandSans(12))
                            .foregroundColor(.secondary)
                        }
                        
                        if let fee = fee {
                            HStack(spacing: 4) {
                                Image(systemName: "banknote")
                                    .font(.system(size: 11))
                                Text(fee)
                                if isSurge {
                                    Text("⚡")
                                        .font(.system(size: 10))
                                }
                            }
                            .font(.brandSans(12))
                            .foregroundColor(isSurge ? .orange : .secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Change address button
                Button(action: onChangeAddress) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Action buttons row
            HStack(spacing: 12) {
                // Switch to Pickup button
                Button(action: onSwitchToPickup) {
                    HStack(spacing: 6) {
                        Image(systemName: "bag")
                            .font(.system(size: 12))
                        Text("Pickup Instead")
                            .font(.brandSans(12).weight(.medium))
                    }
                    .foregroundColor(.brandPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.brandPrimary.opacity(0.08))
                    .cornerRadius(16)
                }
                
                Spacer()
                
                // Minimum order reminder (if applicable)
                if let min = minimumOrderAmount, min > 0 {
                    Text("Min: \(min.toVND())")
                        .font(.brandSans(11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brandPrimary.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    private var truncatedAddress: String {
        if address.count > 35 {
            return String(address.prefix(32)) + "..."
        }
        return address
    }
}

// MARK: - Out of Zone Banner

struct DeliveryOutOfZoneBanner: View {
    let message: String
    let onSwitchToPickup: () -> Void
    let onChangeAddress: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "location.slash")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Outside Delivery Area")
                        .font(.brandSans(14).weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text(message)
                        .font(.brandSans(12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onSwitchToPickup) {
                    Text("Switch to Pickup")
                        .font(.brandSans(13).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.brandPrimary)
                        .cornerRadius(10)
                }
                
                Button(action: onChangeAddress) {
                    Text("Try Another Address")
                        .font(.brandSans(13).weight(.medium))
                        .foregroundColor(.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.brandPrimary, lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.05))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview("Delivery Mode Banner") {
    VStack(spacing: 20) {
        DeliveryModeBanner(
            address: "123 Nguyen Hue Street, District 1, HCMC",
            eta: "25-35 min",
            fee: "20,000đ",
            isSurge: false,
            minimumOrderAmount: 50000,
            onChangeAddress: {},
            onSwitchToPickup: {}
        )
        
        DeliveryModeBanner(
            address: "456 Le Loi Boulevard, District 1",
            eta: "30-45 min",
            fee: "28,000đ",
            isSurge: true,
            minimumOrderAmount: nil,
            onChangeAddress: {},
            onSwitchToPickup: {}
        )
        
        DeliveryOutOfZoneBanner(
            message: "Your address is outside our delivery area for this store.",
            onSwitchToPickup: {},
            onChangeAddress: {}
        )
    }
    .padding(.vertical)
    .background(Color.brandBackground)
}
