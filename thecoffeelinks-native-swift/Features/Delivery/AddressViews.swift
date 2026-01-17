//
//  AddressViews.swift
//  thecoffeelinks-native-swift
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI

struct AddressManagementView: View {
    @StateObject private var vm = DeliveryViewModel(
        deliveryRepository: DependencyContainer.shared.deliveryRepository,
        locationService: DependencyContainer.shared.locationManager
    )
    @State private var showingAddSheet = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            // Header
            ReceiptHeader(title: "My Addresses", showBackButton: true, onBack: { dismiss() })
            
            VStack(spacing: 0) {
                Spacer().frame(height: 60) // Offset for header
                
                ScrollView {
                    VStack(spacing: AppLayout.spacingXL) {
                        
                        // Address List
                        if vm.isLoading {
                            ReceiptLoadingLog()
                        } else if vm.savedAddresses.isEmpty {
                            VStack(spacing: AppLayout.spacing) {
                                Text("No Addresses")
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textInk)
                                
                                Text("Add an address for faster checkout")
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                    .stroke(Color.border, style: StrokeStyle(lineWidth: 1, dash: AppLayout.dashedPattern))
                            )
                        } else {
                            LazyVStack(spacing: AppLayout.spacing) {
                                ForEach(vm.savedAddresses) { address in
                                    AddressRow(address: address, isSelected: vm.selectedAddress?.id == address.id)
                                        .onTapGesture {
                                            vm.selectAddress(address)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task { await vm.deleteAddress(address.id) }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        
                        // Add Button
                        Button {
                            showingAddSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add New Address")
                            }
                            .font(AppFont.monoCTA)
                            .foregroundStyle(Color.backgroundPaper)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
        .fullScreenCover(isPresented: $showingAddSheet) {
            AddAddressView(onSave: { _ in
                showingAddSheet = false
                Task { await vm.loadAddresses() }
            })
        }
        .task { await vm.loadAddresses() }
        .navigationBarHidden(true)
    }
}

struct AddressRow: View {
    let address: DeliveryAddress
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: AppLayout.spacing) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(address.label)
                        .font(AppFont.headline)
                        .foregroundStyle(Color.textInk)
                    
                    if address.isDefault {
                        Text("DEFAULT")
                            .font(AppFont.uiMicro)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.surfaceCard)
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.border, lineWidth: 1))
                    }
                }
                
                Text(address.fullAddress)
                    .font(AppFont.body)
                    .foregroundStyle(Color.textMuted)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.primaryEspresso)
            } else {
                Image(systemName: "circle")
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
}

struct AddAddressView: View {
    var onSave: (DeliveryAddress) -> Void
    
    @State private var label = ""
    @State private var fullAddress = ""
    @State private var notes = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPaper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Sheet Header
                HStack {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textMuted)
                    }
                    
                    Spacer()
                    
                    Text("New Address")
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textInk)
                    
                    Spacer()
                    
                    Button {
                        let new = DeliveryAddress(
                            id: UUID().uuidString,
                            label: label,
                            streetAddress: fullAddress,
                            buildingInfo: nil,
                            city: "Ho Chi Minh City",
                            district: nil,
                            coordinates: nil,
                            isDefault: false,
                            usageCount: 0,
                            lastUsedAt: nil,
                            createdAt: Date()
                        )
                        onSave(new)
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(AppFont.body.bold())
                            .foregroundStyle(Color.primaryEspresso)
                    }
                    .disabled(label.isEmpty || fullAddress.isEmpty)
                    .opacity(label.isEmpty || fullAddress.isEmpty ? 0.5 : 1.0)
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    VStack(spacing: AppLayout.spacingXL) {
                        
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Label")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            ReceiptTextField(placeholder: "e.g. Home, Office", text: $label)
                        }
                        
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Address")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            ReceiptTextField(placeholder: "Street address, apartment, etc.", text: $fullAddress)
                        }
                        
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text("Notes")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                            
                            ReceiptTextField(placeholder: "Instructions for driver", text: $notes)
                        }
                    }
                    .padding(AppLayout.spacing)
                }
            }
        }
    }
}
