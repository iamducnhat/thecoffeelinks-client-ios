//
//  AddressMapPickerView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import MapKit
import CoreLocation

struct AddressMapPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var addressString: String
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 10.7769, longitude: 106.7009), // HCMC Default
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @State private var isGeocoding = false
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true)
                .ignoresSafeArea()
            
            // Center Pin
            Image("mappin")
                .font(.system(size: 40))
                .foregroundStyle(BaseViewColor.accent)
                .shadow(radius: 4)
                .padding(.bottom, 40)
            
            VStack {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image("circle_x")
                            .font(.system(size: 32))
                            .foregroundStyle(BaseViewColor.background)
                            .shadow(radius: 4)
                    }
                    Spacer()
                }
                .padding(.horizontal, BaseViewLayout.spacing)
                .padding(.top, 60)
                
                Spacer()
                
                Button {
                    isGeocoding = true
                    let center = region.center
                    let location = CLLocation(latitude: center.latitude, longitude: center.longitude)

                    CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                        DispatchQueue.main.async {
                            defer { isGeocoding = false }
                            selectedLocation = center

                            if let placemark = placemarks?.first {
                                let parts = [
                                    placemark.name,
                                    placemark.thoroughfare,
                                    placemark.subThoroughfare,
                                    placemark.locality,
                                    placemark.administrativeArea,
                                    placemark.postalCode,
                                    placemark.country
                                ].compactMap { $0 }

                                if !parts.isEmpty {
                                    addressString = parts.joined(separator: ", ")
                                } else {
                                    addressString = String(format: NSLocalizedString("Selected location (%@, %@)", comment: "Fallback coordinate string for selected location"), String(format: "%.2f", center.latitude), String(format: "%.2f", center.longitude))
                                }
                            } else {
                                addressString = String(format: NSLocalizedString("Selected location (%@, %@)", comment: "Fallback coordinate string for selected location"), String(format: "%.2f", center.latitude), String(format: "%.2f", center.longitude))
                            }

                            dismiss()
                        }
                    }
                } label: {
                    Group {
                        if isGeocoding {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: BaseViewColor.background))
                        } else {
                            Text("Confirm Location")
                                .font(BaseViewFont.monoCTA)
                        }
                    }
                    .foregroundStyle(BaseViewColor.background)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(BaseViewColor.accent)
                    .clipShape(Capsule())
                    .shadow(radius: 4)
                }
                .padding(BaseViewLayout.spacing)
                .padding(.bottom, 20)
                .disabled(isGeocoding)
            }
        }
        .navigationBarHidden(true)
    }
}
