//
//  UXRecoveryComponents.swift
//  thecoffeelinks-native-swift
//
//  Components for UX failure recovery:
//  - Store picker with change affordance
//  - Address change inline
//  - Payment change (already implemented inline)
//

import SwiftUI

// MARK: - Store Picker Sheet

struct StorePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storesViewModel = StoresViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBackground.ignoresSafeArea()
                
                switch storesViewModel.viewState {
                case .loading:
                    ProgressView()
                case .error(let message):
                    VStack {
                        Text("Couldn't load stores")
                            .font(.headline)
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Button("Retry") {
                            Task { await storesViewModel.fetchStores() }
                        }
                    }
                case .loaded, .idle, .empty:
                    List {
                        Section("Nearby Stores") {
                            ForEach(storesViewModel.stores) { store in
                                StorePickerRow(
                                    store: store,
                                    isSelected: cartManager.selectedStoreId == store.id,
                                    onSelect: {
                                        cartManager.selectedStoreId = store.id
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        dismiss()
                                    }
                                )
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Select Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await storesViewModel.fetchStores()
            }
        }
    }
}

struct StorePickerRow: View {
    let store: Store
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.coffeeDark)
                    
                    if let address = store.address as String?, !address.isEmpty {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(Color.neutral500)
                            .lineLimit(1)
                    }
                    
                    if let hours = store.openingHours {
                        Text(hours)
                            .font(.caption2)
                            .foregroundStyle(Color.forestCanopy)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.forestCanopy)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Checkout Header with Store Change

struct CheckoutHeaderWithChangeStore: View {
    @ObservedObject private var cartManager = CartManager.shared
    @State private var showStorePicker = false
    
    let storeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Checkout")
                .font(.brandSerif(32))
                .foregroundColor(.coffeeDark)
            
            HStack {
                Text("\(cartManager.totalItemCount) item\(cartManager.totalItemCount > 1 ? "s" : "") in your order")
                    .font(.brandSans(14))
                    .foregroundColor(.neutral500)
                
                Spacer()
            }
            
            // Store selector with visible CHANGE affordance
            Button {
                showStorePicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.forestCanopy)
                    
                    Text(storeName)
                        .font(.caption)
                        .foregroundStyle(Color.coffeeDark)
                    
                    Text("Change")
                        .font(.caption.bold())
                        .foregroundStyle(Color.forestCanopy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.forestCanopy.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .sheet(isPresented: $showStorePicker) {
            StorePickerSheet()
        }
    }
}

// MARK: - Address Row with Clear Change Affordance

struct AddressRowWithChange: View {
    @ObservedObject private var deliveryService = DeliveryService.shared
    @Binding var showAddressPicker: Bool
    
    var body: some View {
        Button {
            showAddressPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.forestCanopy)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let address = deliveryService.selectedAddress {
                        HStack(spacing: 6) {
                            Text(address.label)
                                .font(.caption.bold())
                                .foregroundStyle(Color.forestCanopy)
                            
                            if address.isDefault {
                                Text("Default")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.forestCanopy)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(address.fullAddress)
                            .font(.subheadline)
                            .foregroundStyle(Color.coffeeDark)
                            .lineLimit(1)
                    } else {
                        Text("Select delivery address")
                            .font(.subheadline)
                            .foregroundStyle(Color.red)
                    }
                }
                
                Spacer()
                
                // Visible CHANGE affordance
                VStack(spacing: 2) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Change")
                        .font(.system(size: 9))
                }
                .foregroundStyle(Color.forestCanopy)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(deliveryService.selectedAddress == nil ? Color.red : Color.neutral200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Best In-Store Badge

struct BestInStoreBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text("Best fresh at store")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(Color.sunRay)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.sunRay.opacity(0.15))
        .cornerRadius(6)
    }
}

// MARK: - Delivery Mode Indicator

struct DeliveryModeIndicator: View {
    @ObservedObject private var cartManager = CartManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 12))
            Text(modeName)
                .font(.caption.bold())
        }
        .foregroundStyle(modeColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(modeColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch cartManager.selectedDeliveryOption {
        case .takeAway: return "bag.fill"
        case .dineIn: return "fork.knife"
        case .delivery: return "bicycle"
        }
    }
    
    private var modeName: String {
        switch cartManager.selectedDeliveryOption {
        case .takeAway: return "Pickup"
        case .dineIn: return "Dine-in"
        case .delivery: return "Delivery"
        }
    }
    
    private var modeColor: Color {
        switch cartManager.selectedDeliveryOption {
        case .takeAway: return .coffeeDark
        case .dineIn: return .forestCanopy
        case .delivery: return .brandAccent
        }
    }
}

// MARK: - Previews

#Preview("Store Picker") {
    StorePickerSheet()
}

#Preview("Address Row") {
    AddressRowWithChange(showAddressPicker: .constant(false))
        .padding()
}
