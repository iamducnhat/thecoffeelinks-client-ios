//
//  SpaceView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import MapKit
import Combine

struct SpaceView: View {
    @StateObject private var vm = SpaceViewModel()
    @EnvironmentObject var storeViewModel: StoreViewModel
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8542),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            Map(coordinateRegion: $region, annotationItems: storeViewModel.stores) { store in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: store.latitude ?? 0, longitude: store.longitude ?? 0)) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 24, height: 24)
                        .overlay(Circle().strokeBorder(Color.bgPrimary, lineWidth: 2))
                        .onTapGesture {
                            storeViewModel.selectStore(store)
                        }
                }
            }
            .ignoresSafeArea()
            
            // Bottom Sheet
            if let selected = storeViewModel.selectedStore {
                StoreDetailSheet(store: selected)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: selected)
            } else {
                // Store Cards
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppLayout.spacing) {
                            ForEach(storeViewModel.stores) { store in
                                StoreCardCompact(store: store)
                                    .onTapGesture {
                                        storeViewModel.selectStore(store)
                                        region.center = CLLocationCoordinate2D(latitude: store.latitude ?? 0, longitude: store.longitude ?? 0)
                                    }
                            }
                        }
                        .padding(AppLayout.spacing)
                    }
                }
                .background(
                    LinearGradient(
                        colors: [.clear, Color.bgPrimary.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .onAppear {
            storeViewModel.loadStores()
        }
    }
}

class SpaceViewModel: ObservableObject {
    // Placeholder for future space-specific logic
}

// MARK: - Store Card Compact

struct StoreCardCompact: View {
    let store: Store
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            Rectangle()
                .fill(Color.surfacePrimary)
                .frame(height: 80)
                .overlay(
                    Text(String(store.name.prefix(1)))
                        .font(AppFont.displayTitle)
                        .foregroundStyle(Color.textSecondary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(AppFont.body)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                
                Text(store.address)
                    .font(AppFont.uiCaption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(store.isCurrentlyOpen ? Color.stateSuccess : Color.stateError)
                        .frame(width: 6, height: 6)
                    Text(store.isCurrentlyOpen ? "Open" : "Closed")
                        .font(AppFont.uiMicro)
                        .foregroundStyle(store.isCurrentlyOpen ? Color.stateSuccess : Color.stateError)
                }
            }
            .padding(AppLayout.spacingMedium)
        }
        .background(Color.bgPrimary)
        .overlay(
            Capsule()
                .strokeBorder(Color.border, lineWidth: 1)
        )
        .clipShape(Capsule())
        .frame(width: 180)
    }
}

// MARK: - Store Detail Sheet

struct StoreDetailSheet: View {
    let store: Store
    @EnvironmentObject var storeViewModel: StoreViewModel
    @State private var showBooking = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            Capsule()
                .fill(Color.textSecondary)
                .frame(width: 40, height: 4)
                .padding(.top, AppLayout.spacingMedium)
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.spacing) {
                    Text(store.name)
                        .font(AppFont.sectionHeader)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text(store.address)
                        .font(AppFont.body)
                        .foregroundStyle(Color.textSecondary)
                    
                    // Amenities (if available)
                    if let amenities = store.amenities, !amenities.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppLayout.spacingSmall) {
                                ForEach(amenities.prefix(3), id: \.self) { amenity in
                                    HStack(spacing: 4) {
                                        Image(systemName: amenity.iconName)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.accentPrimary)
                                        Text(amenity.displayName)
                                            .font(AppFont.uiMicro)
                                            .foregroundStyle(Color.textPrimary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.surfacePrimary)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, -AppLayout.spacing)
                        }
                    }
                    
                    Color.secondary.frame(height: 1)
                    
                    // Actions
                    Button {
                        showBooking = true
                    } label: {
                        Text(String(localized: "space_book_table"))
                            .font(AppFont.monoCTA)
                            .foregroundStyle(Color.bgPrimary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.accentPrimary)
                            .clipShape(Capsule())
                    }
                    
                    Button {
                        storeViewModel.selectedStore = nil
                    } label: {
                        Text(String(localized: "common_close"))
                            .font(AppFont.monoBody)
                            .foregroundStyle(Color.textSecondary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.border, lineWidth: 1)
                            )
                    }
                }
                .padding(AppLayout.spacing)
            }
        }
        .background(Color.bgPrimary)
        .clipShape(RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
        .sheet(isPresented: $showBooking) {
            EditorialBookingSheet(store: store, isPresented: $showBooking)
        }
    }
}

// MARK: - Rounded Corner Shape

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
