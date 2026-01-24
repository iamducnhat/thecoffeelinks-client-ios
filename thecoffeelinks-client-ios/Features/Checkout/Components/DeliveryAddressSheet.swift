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
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text("Close")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                    }
                    
                    Spacer()
                    
                    Text("Delivery Address")
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Button {
                        showAddAddress = true
                    } label: {
                        Image(systemName: "plus")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.primaryEspresso)
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
                            .foregroundStyle(Color.textInk)
                        
                        if address.isDefault {
                            Text("Default")
                                .font(AppFont.uiMicro)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primaryEspresso.opacity(0.1))
                                .foregroundStyle(Color.primaryEspresso)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(address.fullAddress)
                        .font(AppFont.body)
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let notes = address.buildingInfo, !notes.isEmpty {
                         Text(notes)
                            .font(AppFont.uiCaption)
                            .foregroundStyle(Color.textMuted)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.primaryEspresso)
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
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
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
            
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(Color.textMuted)
            
            Text("No saved addresses")
                .font(AppFont.sectionHeader)
                .foregroundStyle(Color.textInk)
            
            Text("Add a delivery address to place orders.")
                .font(AppFont.body)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
            
            Button {
                showAddAddress = true
            } label: {
                Text("Add New Address")
                    .font(AppFont.monoCTA)
                    .foregroundStyle(Color.backgroundPaper)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.primaryEspresso)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
            }
        }
        .padding(AppLayout.spacing)
    }
}
