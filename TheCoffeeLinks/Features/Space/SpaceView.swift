//
//  SpaceView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
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
                        .overlay(Circle().strokeBorder(BaseViewColor.background, lineWidth: 1))
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
                        HStack(spacing: BaseViewLayout.spacing) {
                            ForEach(storeViewModel.stores) { store in
                                StoreCardCompact(store: store)
                                    .onTapGesture {
                                        storeViewModel.selectStore(store)
                                        region.center = CLLocationCoordinate2D(latitude: store.latitude ?? 0, longitude: store.longitude ?? 0)
                                    }
                            }
                        }
                        .padding(BaseViewLayout.spacing)
                    }
                }
                .background(
                    LinearGradient(
                        colors: [.clear, BaseViewColor.background.opacity(0.95)],
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
                .fill(BaseViewColor.surface)
                .frame(height: 80)
                .overlay(
                    Text(String(store.name.prefix(1)))
                        .font(BaseViewFont.displayTitle)
                        .foregroundStyle(BaseViewColor.textSecondary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(BaseViewFont.body)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .lineLimit(1)
                
                Text(store.address)
                    .font(BaseViewFont.uiCaption)
                    .foregroundStyle(BaseViewColor.textSecondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(store.isCurrentlyOpen ? BaseViewColor.semanticSuccess : BaseViewColor.semanticError)
                        .frame(width: 6, height: 6)
                    Text(store.isCurrentlyOpen ? "Open" : "Closed")
                        .font(BaseViewFont.uiMicro)
                        .foregroundStyle(store.isCurrentlyOpen ? BaseViewColor.semanticSuccess : BaseViewColor.semanticError)
                }
            }
            .padding(BaseViewLayout.spacingMedium)
        }
        .background(BaseViewColor.background)
        .overlay(
            Capsule()
                .strokeBorder(BaseViewColor.border, lineWidth: 1)
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
                .fill(BaseViewColor.textSecondary)
                .frame(width: 40, height: 4)
                .padding(.top, BaseViewLayout.spacingMedium)
            
            ScrollView {
                VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                    Text(store.name)
                        .font(BaseViewFont.sectionHeader)
                        .foregroundStyle(BaseViewColor.textPrimary)
                    
                    Text(store.address)
                        .font(BaseViewFont.body)
                        .foregroundStyle(BaseViewColor.textSecondary)
                    
                    // Amenities (if available)
                    if let amenities = store.amenities, !amenities.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: BaseViewLayout.spacingSmall) {
                                ForEach(amenities.prefix(3), id: \.self) { amenity in
                                    HStack(spacing: 4) {
                                        IconView(name: amenity.iconName)
                                            .font(.system(size: 12))
                                            .foregroundStyle(BaseViewColor.accent)
                                        Text(amenity.displayName)
                                            .font(BaseViewFont.uiMicro)
                                            .foregroundStyle(BaseViewColor.textPrimary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(BaseViewColor.surface)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, -BaseViewLayout.spacing)
                        }
                    }
                    
                    Color.secondary.frame(height: 1)
                    
                    // Actions
                    Button {
                        showBooking = true
                    } label: {
                        Text(String(localized: "space_book_table"))
                            .font(BaseViewFont.monoCTA)
                            .foregroundStyle(BaseViewColor.background)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(BaseViewColor.accent)
                            .clipShape(Capsule())
                    }
                    
                    Button {
                        storeViewModel.selectedStore = nil
                    } label: {
                        Text(String(localized: "common_close"))
                            .font(BaseViewFont.monoBody)
                            .foregroundStyle(BaseViewColor.textSecondary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                Capsule()
                                    .strokeBorder(BaseViewColor.border, lineWidth: 1)
                            )
                    }
                }
                .padding(BaseViewLayout.spacing)
            }
        }
        .background(BaseViewColor.background)
        .clipShape(RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
        .sheet(isPresented: $showBooking) {
            BaseViewBookingSheet(store: store, isPresented: $showBooking)
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
