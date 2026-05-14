//
//  StoreDetailView.swift
//  thecoffeelinks-client-ios
//
//  BaseView Design
//  Aligned with canonical CheckoutView.swift
//

import SwiftUI
import MapKit
import CachedAsyncImage // CHANGED

struct StoreDetailView: View {
    let store: Store
    @ObservedObject var viewModel: StoresViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset = CGFloat.zero
    @State private var region: MKCoordinateRegion
    @State private var showingCheckIn = false
    
    init(store: Store, viewModel: StoresViewModel) {
        self.store = store
        self.viewModel = viewModel
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            BaseViewColor.background.ignoresSafeArea()
            
            // Fixed Navigation Header
            HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(BaseViewColor.textPrimary)
                        .padding(12)
                        .background {
                            Circle()
                                .fill(BaseViewColor.background)
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(BaseViewColor.border, lineWidth: 1)
                                .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                        }
                }
                
                Text(store.name)
                    .font(BaseViewFont.sectionTitle)
                    .lineLimit(1)
                    .foregroundStyle(BaseViewColor.textPrimary)
                    .fixedSize()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .hidden()
            }
            .frame(minHeight: BaseViewLayout.touchTarget)
            .padding(.horizontal, BaseViewLayout.spacing)
            .padding(.top, 8)
            .zIndex(1)
            .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Navigation Header (Scrollable)
                    VStack(spacing: BaseViewLayout.marginCompact) {
                        HStack(alignment: .center, spacing: BaseViewLayout.spacing) {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(BaseViewColor.textPrimary)
                                .padding(12)
                                .hidden()
                            
                            Text(store.name)
                                .font(BaseViewFont.sectionTitle)
                                .lineLimit(1)
                                .foregroundColor(BaseViewColor.textPrimary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
                        
                        Divider()
                            .background(BaseViewColor.borderSecondary)
                            .padding(.horizontal, -BaseViewLayout.spacing)
                    }
                    .padding(.horizontal, BaseViewLayout.spacing)
                    .padding(.top, BaseViewLayout.spacingCompact)
                    .background(BaseViewColor.background)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    LazyVStack(spacing: BaseViewLayout.spacingXL) {
                        // Store Header
                        VStack(spacing: BaseViewLayout.spacing) {
                            AppRemoteImage(
                                url: URL(string: store.imageUrl ?? ""),
                                width: nil,
                                height: 200,
                                backgroundColor: BaseViewColor.surface,
                                showsProgress: true,
                                placeholderIcon: nil,
                                placeholderText: String(store.name.prefix(1))
                            )
                            
                            Text(store.address)
                                .font(BaseViewFont.body)
                                .foregroundStyle(BaseViewColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .overlay(
                            Rectangle()
                                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
                        )
                        .background(BaseViewColor.elevatedSurface)
                        .padding(.horizontal, BaseViewLayout.spacing)
                        
                        // Map
                        Map(coordinateRegion: .constant(region), annotationItems: [store]) { store in
                            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude)) {
                                Rectangle()
                                    .fill(BaseViewColor.accent)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image("coffee")
                                            .font(.system(size: 12))
                                            .foregroundStyle(BaseViewColor.accentForeground)
                                    )
                            }
                        }
                        .frame(height: 200)
                        .overlay(
                            Rectangle()
                                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: BaseViewLayout.radiusMedium, style: .continuous))
                        .padding(.horizontal, BaseViewLayout.spacing)
                        
                        // Store Info
                        VStack(spacing: 0) {
                            // Phone
                            if let phone = store.phone {
                                HStack {
                                    Image("phone")
                                        .foregroundStyle(BaseViewColor.accent)
                                    Text(phone)
                                        .font(BaseViewFont.body)
                                        .foregroundStyle(BaseViewColor.textPrimary)
                                    Spacer()
                                    Button {
                                        if let url = URL(string: "tel://\(phone.filter("0123456789".contains))") {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        BaseCTAButton(title: String(localized: "store_call"), style: .outlined, action: {})
                                    }
                                }
                                .padding(BaseViewLayout.spacing)
                                
                                Color.secondary.frame(height: 1)
                            }
                            
                            // Hours
                            HStack {
                                Image("clock")
                                    .foregroundStyle(BaseViewColor.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.isCurrentlyOpen ? String(localized: "store_open_now") : String(localized: "store_closed"))
                                        .font(BaseViewFont.body)
                                        .foregroundStyle(store.isCurrentlyOpen ? BaseViewColor.semanticSuccess : BaseViewColor.semanticError)
                                    
                                    if let hours = store.openingHours?.first(where: { $0.dayOfWeek == Calendar.current.component(.weekday, from: Date()) }) {
                                        Text("\(hours.openTime) - \(hours.closeTime)")
                                            .font(BaseViewFont.label)
                                            .foregroundStyle(BaseViewColor.textSecondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(BaseViewLayout.spacing)
                        }
                        .background(BaseViewColor.elevatedSurface)
                        .overlay(
                            Rectangle()
                                .stroke(BaseViewColor.border, lineWidth: BaseViewLayout.cardBorderWidth)
                        )
                        .padding(.horizontal, BaseViewLayout.spacing)
                        
                        // Amenities
                        if let amenities = store.amenities, !amenities.isEmpty {
                            VStack(alignment: .leading, spacing: BaseViewLayout.spacing) {
                                Text("store_amenities_section")
                                    .textCase(.uppercase)
                                    .font(BaseViewFont.labelStrong)
                                    .foregroundStyle(BaseViewColor.textPrimary)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: BaseViewLayout.spacingMedium) {
                                    ForEach(amenities, id: \.self) { amenity in
                                        HStack(spacing: 4) {
                                            IconView(name: amenity.iconName)
                                                .foregroundStyle(BaseViewColor.accent)
                                                .font(.system(size: 14))
                                            Text(amenity.displayName)
                                                .font(BaseViewFont.label)
                                                .foregroundStyle(BaseViewColor.textPrimary)
                                            Spacer()
                                        }
                                        .padding(BaseViewLayout.spacingMedium)
                                        .background(BaseViewColor.elevatedSurface)
                                    }
                                }
                            }
                            .padding(.horizontal, BaseViewLayout.spacing)
                        }
                        
                        // Action Buttons
                        VStack(spacing: BaseViewLayout.spacing) {
                            Text("store_order_options_section")
                                .textCase(.uppercase)
                                .font(BaseViewFont.labelStrong)
                                .foregroundStyle(BaseViewColor.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: BaseViewLayout.spacing) {
                                // Dine-In
                                if store.dineInAvailable ?? true {
                                    Button {
                                        viewModel.selectStore(store)
                                        dismiss()
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image("fork.knife")
                                                .font(.system(size: 20))
                                            Text("store_dine_in")
                                                .font(BaseViewFont.label)
                                        }
                                        .foregroundStyle(BaseViewColor.accentForeground)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 72)
                                        .background(BaseViewColor.accent)
                                        .clipShape(Capsule())
                                    }
                                }
                                
                                // Take-Away
                                if store.pickupAvailable ?? true {
                                    Button {
                                        viewModel.selectStore(store)
                                        dismiss()
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image("bag")
                                                .font(.system(size: 20))
                                            Text("store_take_away")
                                                .font(BaseViewFont.label)
                                        }
                                        .foregroundStyle(BaseViewColor.accentForeground)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 72)
                                        .background(BaseViewColor.accent)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            
                            // Check In
                            Button {
                                viewModel.selectStore(store)
                                showingCheckIn = true
                            } label: {
                                Text("store_check_in")
                                    .font(BaseViewFont.bodyStrong)
                                    .foregroundStyle(BaseViewColor.accentForeground)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(BaseViewColor.accent)
                                    .clipShape(Capsule())
                            }
                            
                            // Get Directions
                            Button {
                                let url = URL(string: "maps://?daddr=\(store.latitude),\(store.longitude)")!
                                UIApplication.shared.open(url)
                            } label: {
                                HStack {
                                    Image("map")
                                        .font(.system(size: 16))
                                    Text("store_get_directions")
                                        .font(BaseViewFont.body)
                                }
                                .foregroundStyle(BaseViewColor.accent)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(BaseViewColor.accent, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, BaseViewLayout.spacing)
                    }
                    .padding(.top, BaseViewLayout.spacing)
                    .padding(.bottom, 100)
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.hidden)
            }
            .zIndex(-Double.infinity)
        }
        .fullScreenCover(isPresented: $showingCheckIn) {
            QRCheckInView()
        }
    }
}
