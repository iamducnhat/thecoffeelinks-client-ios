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
            Color.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Text(String(localized: "common_cancel"))
                            .font(AppFont.body)
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("Add Address")
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        Task {
                            if let _ = await deliveryViewModel.saveAddress() {
                                dismiss()
                            }
                        }
                    } label: {
                        if deliveryViewModel.isLoading {
                            ProgressView().tint(Color.accentPrimary)
                        } else {
                            Text(String(localized: "common_save"))
                                .font(AppFont.headline)
                                .foregroundStyle(deliveryViewModel.canSaveAddress ? Color.accentPrimary : Color.textSecondary)
                        }
                    }
                    .disabled(!deliveryViewModel.canSaveAddress || deliveryViewModel.isLoading)
                }
                .padding(AppLayout.spacing)
                
                Color.secondary.frame(height: 1)
                
                ScrollView {
                    VStack(spacing: AppLayout.spacingXL) {
                        
                        // Map / Location Section
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text(String(localized: "common_location"))
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            // Map Preview (Placeholder or Actual Map)
                            ZStack {
                                Capsule()
                                    .fill(Color.surfacePrimary)
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
                                        .foregroundStyle(Color.accentPrimary)
                                        .shadow(radius: 2)
                                } else {
                                    Button {
                                        Task { await deliveryViewModel.getCurrentLocation() }
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image("map_pin")
                                                .font(.system(size: 24))
                                            Text("Use Current Location")
                                                .font(AppFont.headline)
                                        }
                                        .foregroundStyle(Color.accentPrimary)
                                    }
                                }
                            }
                            
                             // Search Field
                             HStack {
                                 Image("magnifyingglass")
                                     .foregroundStyle(Color.textSecondary)
                                 TextField("Search for address...", text: $deliveryViewModel.streetAddress)
                                     .textFieldStyle(PlainTextFieldStyle())
                                     .font(AppFont.body)
                                     .foregroundStyle(Color.textPrimary)
                                     .onSubmit {
                                         Task { await deliveryViewModel.searchAddress(deliveryViewModel.streetAddress) }
                                     }
                             }
                             .padding(12)
                             .background(Color.bgPrimary)
                             .overlay(
                                 Capsule()
                                     .stroke(Color.border, lineWidth: 1)
                             )
                        }
                        
                        // Details Form
                        VStack(alignment: .leading, spacing: AppLayout.spacing) {
                            Text(String(localized: "order_detail_details"))
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textPrimary)
                            
                            VStack(spacing: AppLayout.spacing) {
                                CustomTextField(title: "Label (e.g., Home, Office)", text: $deliveryViewModel.addressLabel)
                                CustomTextField(title: "Building / Floor / Unit (Optional)", text: $deliveryViewModel.buildingInfo)
                                CustomTextField(title: "Note for driver (Optional)", text: $deliveryViewModel.district) // Using district field as general note for now based on VM or create new field if needed. VM models district separately. Let's stick to VM fields.
                            }
                        }
                        
                        if let error = deliveryViewModel.error {
                            Text(error.localizedDescription)
                                .font(AppFont.uiCaption)
                                .foregroundStyle(Color.stateError)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.stateError.opacity(0.1))
                                .cornerRadius(AppLayout.cornerRadius)
                        }
                    }
                    .padding(AppLayout.spacing)
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
                .font(AppFont.uiCaption)
                .foregroundStyle(Color.textSecondary)
            
            TextField("", text: $text)
                .font(AppFont.body)
                .foregroundStyle(Color.textPrimary)
                .padding(12)
                .background(Color.bgPrimary)
                .overlay(
                    Capsule()
                        .stroke(Color.border, lineWidth: 1)
                )
        }
    }
}
