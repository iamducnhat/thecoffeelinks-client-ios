//
//  StoreDetailView.swift
//  thecoffeelinks-client-ios
//
//  Receipt-Editorial Design
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
            Color.backgroundPaper.ignoresSafeArea()
            
            // Fixed Navigation Header
            HStack(alignment: .center, spacing: AppLayout.spacing) {
                Button { dismiss() } label: {
                    Image("xmark")
                        .font(AppFont.navIcon)
                        .foregroundStyle(Color.textInk)
                        .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                        .background {
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .fill(Color.backgroundPaper)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.textInk, lineWidth: min(66.6, max(scrollOffset, 0.0)) / 66.6)
                                .opacity(min(88.8, max(scrollOffset, 0.0)) / 99.9)
                        }
                }
                
                Text(store.name)
                    .font(AppFont.displayTitle)
                    .lineLimit(1)
                    .foregroundStyle(Color.textInk)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hidden()
            }
            .frame(minHeight: AppLayout.touchTarget)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, AppLayout.spacing)
            
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    // Navigation Header (Scrollable)
                    HStack(alignment: .center, spacing: AppLayout.spacing) {
                        Image("xmark")
                            .font(AppFont.navIcon)
                            .foregroundStyle(Color.textInk)
                            .frame(minWidth: AppLayout.touchTarget, minHeight: AppLayout.touchTarget)
                            .hidden()
                        
                        Text(store.name)
                            .font(AppFont.displayTitle)
                            .lineLimit(1)
                            .foregroundStyle(Color.textInk)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: AppLayout.touchTarget)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, AppLayout.spacing)
                    .overlay(alignment: .bottom) {
                        Color.secondary.frame(height: 1, alignment: .top)
                    }
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }
                    
                    LazyVStack(spacing: AppLayout.spacingXL) {
                        // Store Header
                        VStack(spacing: AppLayout.spacing) {
                            // CHANGED: Using CachedAsyncImage
                            CachedAsyncImage(url: URL(string: store.imageUrl ?? "")) { phase in // CHANGED
                                switch phase { // CHANGED
                                case .empty: // CHANGED
                                    Rectangle() // CHANGED
                                        .fill(Color.surfaceCard) // CHANGED
                                        .overlay { // CHANGED
                                            ProgressView() // CHANGED
                                                .tint(Color.primaryEspresso) // CHANGED
                                        } // CHANGED
                                case .success(let image): // CHANGED
                                    image // CHANGED
                                        .resizable() // CHANGED
                                        .aspectRatio(contentMode: .fill) // CHANGED
                                case .failure: // CHANGED
                                    Rectangle() // CHANGED
                                        .fill(Color.surfaceCard) // CHANGED
                                        .overlay { // CHANGED
                                            Text(String(store.name.prefix(1))) // CHANGED
                                                .font(AppFont.displayTitle) // CHANGED
                                                .foregroundStyle(Color.textMuted) // CHANGED
                                        } // CHANGED
                                @unknown default: // CHANGED
                                    EmptyView() // CHANGED
                                } // CHANGED
                            } // CHANGED
                            .frame(height: 200)
                            .clipped()
                            
                            Text(store.address)
                                .font(AppFont.body)
                                .foregroundStyle(Color.textMuted)
                                .multilineTextAlignment(.center)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        .padding(.horizontal, AppLayout.spacing)
                        
                        // Map
                        Map(coordinateRegion: .constant(region), annotationItems: [store]) { store in
                            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude)) {
                                Rectangle()
                                    .fill(Color.primaryEspresso)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image("coffee")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.backgroundPaper)
                                    )
                            }
                        }
                        .frame(height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                        .padding(.horizontal, AppLayout.spacing)
                        
                        // Store Info
                        VStack(spacing: 0) {
                            // Phone
                            if let phone = store.phone {
                                HStack {
                                    Image("phone")
                                        .foregroundStyle(Color.primaryEspresso)
                                    Text(phone)
                                        .font(AppFont.body)
                                        .foregroundStyle(Color.textInk)
                                    Spacer()
                                    Button {
                                        if let url = URL(string: "tel://\(phone.filter("0123456789".contains))") {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        Text("store_call")
                                            .font(AppFont.monoBody)
                                            .foregroundStyle(Color.primaryEspresso)
                                    }
                                }
                                .padding(AppLayout.spacing)
                                
                                Color.secondary.frame(height: 1)
                            }
                            
                            // Hours
                            HStack {
                                Image("clock")
                                    .foregroundStyle(Color.primaryEspresso)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.isCurrentlyOpen ? String(localized: "store_open_now") : String(localized: "store_closed"))
                                        .font(AppFont.body)
                                        .foregroundStyle(store.isCurrentlyOpen ? Color.semanticSuccess : Color.semanticError)
                                    
                                    if let hours = store.openingHours?.first(where: { $0.dayOfWeek == Calendar.current.component(.weekday, from: Date()) }) {
                                        Text("\(hours.openTime) - \(hours.closeTime)")
                                            .font(AppFont.uiCaption)
                                            .foregroundStyle(Color.textMuted)
                                    }
                                }
                                Spacer()
                            }
                            .padding(AppLayout.spacing)
                        }
                        .background(Color.backgroundPaper)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                .stroke(Color.border, lineWidth: 1)
                        )
                        .padding(.horizontal, AppLayout.spacing)
                        
                        // Amenities
                        if let amenities = store.amenities, !amenities.isEmpty {
                            VStack(alignment: .leading, spacing: AppLayout.spacing) {
                                Text("store_amenities_section")
                                    .textCase(.uppercase)
                                    .font(AppFont.sectionHeader)
                                    .foregroundStyle(Color.textInk)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppLayout.spacingMedium) {
                                    ForEach(amenities, id: \.self) { amenity in
                                        HStack(spacing: 4) {
                                            Image(amenity.iconName)
                                                .foregroundStyle(Color.primaryEspresso)
                                                .font(.system(size: 14))
                                            Text(amenity.displayName)
                                                .font(AppFont.uiCaption)
                                                .foregroundStyle(Color.textInk)
                                            Spacer()
                                        }
                                        .padding(AppLayout.spacingMedium)
                                        .background(Color.surfaceCard)
                                    }
                                }
                            }
                            .padding(.horizontal, AppLayout.spacing)
                        }
                        
                        // Action Buttons
                        VStack(spacing: AppLayout.spacing) {
                            Text("store_order_options_section")
                                .textCase(.uppercase)
                                .font(AppFont.sectionHeader)
                                .foregroundStyle(Color.textInk)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: AppLayout.spacing) {
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
                                                .font(AppFont.uiCaption)
                                        }
                                        .foregroundStyle(Color.backgroundPaper)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 72)
                                        .background(Color.accentColor)
                                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
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
                                                .font(AppFont.uiCaption)
                                        }
                                        .foregroundStyle(Color.backgroundPaper)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 72)
                                        .background(Color.accentColor)
                                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                                    }
                                }
                            }
                            
                            // Check In
                            Button {
                                viewModel.selectStore(store)
                                showingCheckIn = true
                            } label: {
                                Text("store_check_in")
                                    .font(AppFont.monoCTA)
                                    .foregroundStyle(Color.backgroundPaper)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle))
                            }
                            
                            // Get Directions
                            Button {
                                let url = URL(string: "maps://?daddr=\(store.latitude),\(store.longitude)")!
                                UIApplication.shared.open(url)
                            } label: {
                                HStack {
                                    Image("arrow.triangle.turn.up.right.circle")
                                        .font(.system(size: 16))
                                    Text("store_get_directions")
                                        .font(AppFont.monoBody)
                                }
                                .foregroundStyle(Color.primaryEspresso)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: AppLayout.cornerStyle)
                                        .stroke(Color.primaryEspresso, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, AppLayout.spacing)
                    }
                    .padding(.top, AppLayout.spacing)
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
