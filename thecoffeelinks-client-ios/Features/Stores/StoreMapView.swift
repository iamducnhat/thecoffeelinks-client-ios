//
//  StoreMapView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import MapKit

struct StoreMapView: View {
    let stores: [Store]
    @Binding var selectedStore: Store?
    @State private var region: MKCoordinateRegion
    
    init(stores: [Store], selectedStore: Binding<Store?>) {
        self.stores = stores
        self._selectedStore = selectedStore
        
        // Calculate region to fit all stores or default to user location/center
        if let first = stores.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        } else {
             // Default (e.g., Ho Chi Minh City)
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 10.7769, longitude: 106.7009),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: stores) { store in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude)) {
                Button {
                    selectedStore = store
                } label: {
                    VStack(spacing: 0) {
                        // Label bubble
                        Text("5m") // Wait time mock logic
                            .font(AppFont.uiMicro)
                            .foregroundStyle(Color.backgroundPaper)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primaryEspresso)
                            .clipShape(Capsule())
                            .shadow(radius: 2, y: 1)
                        
                        Image(systemName: "triangle.fill")
                            .resizable()
                            .frame(width: 8, height: 6)
                            .foregroundStyle(Color.primaryEspresso)
                            .rotationEffect(.degrees(180))
                            .offset(y: -2)
                        
                        Circle()
                            .fill(Color.backgroundPaper)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.primaryEspresso, lineWidth: 2))
                    }
                }
            }
        }
    }
}
