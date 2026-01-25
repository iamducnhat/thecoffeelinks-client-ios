//
//  AddressMapPickerView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import MapKit

struct AddressMapPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var addressString: String
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 10.7769, longitude: 106.7009), // HCMC Default
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true)
                .ignoresSafeArea()
            
            // Center Pin
            Image(systemName: "mappin")
                .font(.system(size: 40))
                .foregroundStyle(Color.primaryEspresso)
                .shadow(radius: 4)
                .padding(.bottom, 40)
            
            VStack {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.backgroundPaper)
                            .shadow(radius: 4)
                    }
                    Spacer()
                }
                .padding(.horizontal, AppLayout.spacing)
                .padding(.top, 60)
                
                Spacer()
                
                Button {
                    selectedLocation = region.center
                    // TODO: Implement proper reverse geocoding to convert coordinates to readable address
                    addressString = "Selected location (\(String(format: "%.2f", region.center.latitude)), \(String(format: "%.2f", region.center.longitude)))"
                    dismiss()
                } label: {
                    Text("Confirm Location")
                        .font(AppFont.monoCTA)
                        .foregroundStyle(Color.backgroundPaper)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        .shadow(radius: 4)
                }
                .padding(AppLayout.spacing)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
}
