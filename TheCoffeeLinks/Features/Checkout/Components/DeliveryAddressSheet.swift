//
//  DeliveryAddressSheet.swift
//  thecoffeelinks-client-ios
//
//  Sheet for selecting or managing delivery addresses
//

import SwiftUI

struct DeliveryAddressSheet: View {
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddAddress = false
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (centered title, balanced controls)
                VStack(spacing: BaseViewLayout.marginCompact) {
                    HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                        Text("Delivery Address")
                            .font(BaseViewFont.displayMedium)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button {
                            showAddAddress = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(BaseViewColor.accent)
                                .padding(12)
                                .background { Circle().fill(BaseViewColor.background) }
                                .overlay { Circle().strokeBorder(BaseViewColor.borderSecondary, lineWidth: 1) }
                        }
                        
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(BaseViewColor.textPrimary)
                                .padding(12)
                                .background { Circle().fill(BaseViewColor.background) }
                                .overlay { Circle().strokeBorder(BaseViewColor.borderSecondary, lineWidth: 1) }
                        }
                    }
                    .frame(minHeight: BaseViewLayout.touchTarget)
                    
                    Divider()
                        .background(BaseViewColor.borderSecondary)
                        .padding(.horizontal, -BaseViewLayout.spacing)
                }
                .padding(.horizontal, BaseViewLayout.spacing)
                .padding(.top, BaseViewLayout.spacing)
                .background(BaseViewColor.background)
                
                // Content
                ScrollView {
                    VStack(spacing: BaseViewLayout.spacing) {
                        if deliveryViewModel.savedAddresses.isEmpty {
                            EmptyAddressState(showAddAddress: $showAddAddress)
                        } else {
                            ForEach(deliveryViewModel.savedAddresses) { address in
                                AddressCard(
                                    address: address,
                                    isSelected: deliveryViewModel.selectedAddress?.id == address.id,
                                    onSelect: {
                                        deliveryViewModel.selectAddress(address)
                                        dismiss()
                                    },
                                    onEdit: {
                                        // Potential future edit feature
                                    },
                                    onDelete: {
                                        Task {
                                            await deliveryViewModel.deleteAddress(address.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(BaseViewLayout.spacing)
                }
            }
        }
        .sheet(isPresented: $showAddAddress) {
            AddAddressView()
                .environmentObject(deliveryViewModel)
        }
        .task {
            if deliveryViewModel.savedAddresses.isEmpty {
                await deliveryViewModel.loadAddresses()
            }
        }
    }
}

// MARK: - Address Card

struct AddressCard: View {
    let address: DeliveryAddress
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: BaseViewLayout.spacing) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(address.label)
                            .font(BaseViewFont.headline)
                            .foregroundStyle(BaseViewColor.textPrimary)
                        
                        if address.isDefault {
                            Text("Default")
                                .font(BaseViewFont.uiMicro)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BaseViewColor.accent.opacity(0.1))
                                .foregroundStyle(BaseViewColor.accent)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(address.fullAddress)
                        .font(BaseViewFont.body)
                        .foregroundStyle(BaseViewColor.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let notes = address.buildingInfo, !notes.isEmpty {
                         Text(notes)
                            .font(BaseViewFont.uiCaption)
                            .foregroundStyle(BaseViewColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image("circle_check")
                        .font(.system(size: 20))
                        .foregroundStyle(BaseViewColor.accent)
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
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label {
                            Text(String(localized: "common_delete"))
                        } icon: {
                            Image("trash")
                        }
            }
        }
    }
}

// MARK: - Empty State

struct EmptyAddressState: View {
    @Binding var showAddAddress: Bool
    
    var body: some View {
        VStack(spacing: BaseViewLayout.spacingXL) {
            Spacer().frame(height: 40)
            
            Image("map")
                .font(.system(size: 48))
                .foregroundStyle(BaseViewColor.textSecondary)
            
            Text("No saved addresses")
                .font(BaseViewFont.sectionHeader)
                .foregroundStyle(BaseViewColor.textPrimary)
            
            Text("Add a delivery address to place orders.")
                .font(BaseViewFont.body)
                .foregroundStyle(BaseViewColor.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showAddAddress = true
            } label: {
                Text("Add New Address")
                    .font(BaseViewFont.monoCTA)
                    .foregroundStyle(BaseViewColor.background)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(BaseViewColor.accent)
                    .clipShape(Capsule())
            }
        }
        .padding(BaseViewLayout.spacing)
    }
}
