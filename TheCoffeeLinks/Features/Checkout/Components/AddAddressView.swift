//
//  AddAddressView.swift
//  thecoffeelinks-client-ios
//
//  Form to add a new delivery address
//

import SwiftUI
import MapKit

struct AddAddressView: View {
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Internal state to avoid modifying ViewModel state immediately if cancelled
    // However, DeliveryViewModel seems designed to hold this state.
    // We'll use the ViewModel directly as per its design in previous files.
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (centered title, balanced actions)
                VStack(spacing: BaseViewLayout.marginCompact) {
                    HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                        Text("Add Address")
                            .font(BaseViewFont.displayMedium)
                            .foregroundStyle(BaseViewColor.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button { dismiss() } label: {
                            Text(String(localized: "common_cancel"))
                                .font(BaseViewFont.body)
                                .foregroundStyle(BaseViewColor.textSecondary)
                                .padding(.vertical, BaseViewLayout.spacingMicro)
                                .padding(.horizontal, BaseViewLayout.spacingSmall)
                        }
                        
                        Button {
                            Task {
                                if let _ = await deliveryViewModel.saveAddress() {
                                    dismiss()
                                }
                            }
                        } label: {
                            if deliveryViewModel.isLoading {
                                ProgressView().tint(BaseViewColor.accent)
                                    .frame(height: BaseViewLayout.touchTarget / 2)
                            } else {
                                Text(String(localized: "common_save"))
                                    .font(BaseViewFont.headline)
                                    .foregroundStyle(deliveryViewModel.canSaveAddress ? BaseViewColor.accent : BaseViewColor.textSecondary)
                                    .padding(.vertical, BaseViewLayout.spacingMicro)
                                    .padding(.horizontal, BaseViewLayout.spacingSmall)
                            }
                        }
                        .disabled(!deliveryViewModel.canSaveAddress || deliveryViewModel.isLoading)
                    }
                    .frame(minHeight: BaseViewLayout.touchTarget)
                    
                    Divider()
                        .background(BaseViewColor.borderSecondary)
                        .padding(.horizontal, -BaseViewLayout.spacing)
                }
                .padding(.horizontal, BaseViewLayout.spacing)
                .padding(.top, BaseViewLayout.spacing)
                .background(BaseViewColor.background)
                
                ScrollView {
                    VStack(spacing: BaseViewLayout.spacingXL) {
                        
                        // Map / Location Section
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text(String(localized: "common_location"))
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            // Map Preview (Placeholder or Actual Map)
                            ZStack {
                                Capsule()
                                    .fill(BaseViewColor.surface)
                                    .frame(height: 200)
                                
                                if let location = deliveryViewModel.selectedLocation {
                                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                                        center: location,
                                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                    )))
                                    .disabled(true)
                                    .clipShape(Capsule())
                                    
                                    Image("map_pin")
                                        .font(.system(size: 32))
                                        .foregroundStyle(BaseViewColor.accent)
                                        .shadow(radius: 2)
                                } else {
                                    Button {
                                        Task { await deliveryViewModel.getCurrentLocation() }
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image("map_pin")
                                                .font(.system(size: 24))
                                            Text("Use Current Location")
                                                .font(BaseViewFont.headline)
                                        }
                                        .foregroundStyle(BaseViewColor.accent)
                                    }
                                }
                            }
                            
                             // Search Field
                             HStack {
                                 Image("magnifyingglass")
                                     .foregroundStyle(BaseViewColor.textSecondary)
                                 TextField("Search for address...", text: $deliveryViewModel.streetAddress)
                                     .textFieldStyle(PlainTextFieldStyle())
                                     .font(BaseViewFont.body)
                                     .foregroundStyle(BaseViewColor.textPrimary)
                                     .onSubmit {
                                         Task { await deliveryViewModel.searchAddress(deliveryViewModel.streetAddress) }
                                     }
                             }
                             .padding(12)
                             .background(BaseViewColor.background)
                             .overlay(
                                 Capsule()
                                     .strokeBorder(BaseViewColor.border, lineWidth: 1)
                             )
                        }
                        
                        // Details Form
                        VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                            Text(String(localized: "order_detail_details"))
                                .font(BaseViewFont.sectionHeader)
                                .foregroundStyle(BaseViewColor.textPrimary)
                            
                            VStack(spacing: BaseViewLayout.spacing) {
                                CustomTextField(title: "Label (e.g., Home, Office)", text: $deliveryViewModel.addressLabel)
                                CustomTextField(title: "Building / Floor / Unit (Optional)", text: $deliveryViewModel.buildingInfo)
                                CustomTextField(title: "Note for driver (Optional)", text: $deliveryViewModel.district) // Using district field as general note for now based on VM or create new field if needed. VM models district separately. Let's stick to VM fields.
                            }
                        }
                        
                        if let error = deliveryViewModel.error {
                            Text(error.localizedDescription)
                                .font(BaseViewFont.uiCaption)
                                .foregroundStyle(BaseViewColor.semanticError)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BaseViewColor.semanticError.opacity(0.1))
                                .cornerRadius(BaseViewLayout.cornerRadius)
                        }
                    }
                    .padding(BaseViewLayout.spacing)
                }
            }
        }
        .onAppear {
            if deliveryViewModel.selectedLocation == nil {
                Task { await deliveryViewModel.getCurrentLocation() }
            }
        }
    }
}

// MARK: - Custom TextField
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(BaseViewFont.uiCaption)
                .foregroundStyle(BaseViewColor.textSecondary)
            
            TextField("", text: $text)
                .font(BaseViewFont.body)
                .foregroundStyle(BaseViewColor.textPrimary)
                .padding(12)
                .background(BaseViewColor.background)
                .overlay(
                    Capsule()
                        .strokeBorder(BaseViewColor.border, lineWidth: 1)
                )
        }
    }
}
