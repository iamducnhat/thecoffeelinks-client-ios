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
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text(String(localized: "common_close"))
                            .font(AppFont.body)
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("Delivery Address")
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        showAddAddress = true
                    } label: {
                        Image("plus")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                // Content
                ScrollView {
                    VStack(spacing: AppLayout.spacing) {
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
                    .padding(AppLayout.spacing)
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
            HStack(spacing: AppLayout.spacing) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(address.label)
                            .font(AppFont.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        if address.isDefault {
                            Text("Default")
                                .font(AppFont.uiMicro)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentPrimary.opacity(0.1))
                                .foregroundStyle(Color.accentPrimary)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(address.fullAddress)
                        .font(AppFont.body)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let notes = address.buildingInfo, !notes.isEmpty {
                         Text(notes)
                            .font(AppFont.uiCaption)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image("circle_check")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.accentPrimary)
                }
            }
            .padding(AppLayout.spacing)
            .background(isSelected ? Color.surfacePrimary : Color.bgPrimary)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentPrimary : Color.border, lineWidth: 1)
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
        VStack(spacing: AppLayout.spacingXL) {
            Spacer().frame(height: 40)
            
            Image("map")
                .font(.system(size: 48))
                .foregroundStyle(Color.textSecondary)
            
            Text("No saved addresses")
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textPrimary)
            
            Text("Add a delivery address to place orders.")
                .font(AppFont.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showAddAddress = true
            } label: {
                Text("Add New Address")
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.bgPrimary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.accentPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(AppLayout.spacing)
    }
}
