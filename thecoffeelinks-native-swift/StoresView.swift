import SwiftUI
import MapKit

struct StoresView: View {
    @StateObject private var viewModel = StoresViewModel()
    
    var body: some View {
        List {
            if viewModel.viewState == .loading && viewModel.stores.isEmpty {
                Section {
                    ProgressView("Finding stores...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            } else {
                let nearbyStores = viewModel.stores.filter { ($0.distance ?? Double.infinity) < 5000 }
                
                // Nearby Section
                Section {
                    if !nearbyStores.isEmpty {
                        ForEach(nearbyStores) { store in
                            NavigationLink(destination: StoreMapView(store: store)) {
                                StoreRow(store: store)
                            }
                            .listRowBackground(Color.white)
                        }
                    } else if viewModel.locationAuthStatus == .authorizedWhenInUse || viewModel.locationAuthStatus == .authorizedAlways {
                        // Authorized but no stores
                        Text("No nearby store found")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        // Location disabled
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable location services to see stores near you.")
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundStyle(Color.accent)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Nearby")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.secondary)
                }
                
                // All Stores Section
                Section {
                    ForEach(viewModel.stores) { store in
                        NavigationLink(destination: StoreMapView(store: store)) {
                            StoreRow(store: store)
                        }
                        .listRowBackground(Color.white)
                    }
                } header: {
                    Text("All stores")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
        .refreshable {
            viewModel.requestLocation()
            await viewModel.fetchStores()
        }
        .task {
            viewModel.requestLocation()
            await viewModel.fetchStores()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Store Map View (Full Screen)
struct StoreMapView: View {
    let store: Store
    @StateObject private var viewModel = StoresViewModel()
    @State private var selectedDetent: PresentationDetent = .medium
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Native Map with internal routing
                InternalMapView(
                    region: $viewModel.region,
                    route: viewModel.route,
                    annotation: store,
                    bottomPadding: viewModel.isNavigating ? 260 : (proxy.size.height * 0.5)
                )
                .ignoresSafeArea()
            
            // Navigation Guidance Overlay
                if viewModel.isNavigating {
                    VStack {
                        HStack {
                            Image("arrow_right_circle")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(.white)
                                .rotationEffect(.degrees(-45))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Follow Route")
                                    .font(.brandSans(24))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Text("Destination: \(store.name)")
                                    .font(.brandSans(14))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer()
                            Button {
                                viewModel.isNavigating = false
                            } label: {
                                Text("✕")
                                    .font(.title)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .padding()
                        .background(Color.coffeeDark.opacity(0.9))
                        .cornerRadius(16)
                    .padding()
                    
                    Spacer()
                    
                    // Bottom Navigation Info
                    HStack {
                        VStack(alignment: .leading) {
                            Text(formatTime(viewModel.travelTime))
                                .font(.brandSans(24))
                                .fontWeight(.bold)
                            Text("\(formatDistance(viewModel.distanceRemaining)) • \(arrivalTime(viewModel.travelTime))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            viewModel.isNavigating = false
                        } label: {
                            Text("End")
                            .font(.brandSans(18))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 44)
                            .background(Color.red)
                            .cornerRadius(22)
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .shadow(radius: 10)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            
            // Arrival Overlay
            if viewModel.destinationReached {
                VStack(spacing: 24) {
                    Image("badge_check")
                        .resizable()
                        .renderingMode(.template) 
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundStyle(Color.brandAccent)
                    
                    VStack(spacing: 8) {
                        Text("You've Arrived!")
                        .font(.brandSerif(32))
                        .foregroundStyle(Color.coffeeDark)
                        Text(store.name)
                        .font(.brandSans(18))
                        .foregroundStyle(.secondary)
                    }
                    
                    LiquidGlassPrimaryButton("Finish", icon: "badge_check") {
                        viewModel.destinationReached = false
                        dismiss()
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            viewModel.userLocation = CLLocationManager().location // Seed user location
            viewModel.selectStore(store)
            
            // Automatically start showing directions in-app
            viewModel.startNavigation()
        }
        .navigationBarBackButtonHidden(viewModel.isNavigating) // Hide back when navigating
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: .init(get: { !viewModel.isNavigating && !viewModel.destinationReached }, set: { _ in })) {
            StoreDetailView(store: store, detent: selectedDetent) {
            } onNavigate: {
                viewModel.startNavigation()
            }
            .presentationDetents([.medium, .large], selection: $selectedDetent)
            .presentationDragIndicator(.visible)
            .background {
                if #available(iOS 16.4, *) {
                    Color.clear
                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                }
            }
            .interactiveDismissDisabled()
        }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval?) -> String {
        guard let s = seconds else { return "-- min" }
        let minutes = Int(s / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            return "\(minutes / 60) hr \(minutes % 60) min"
        }
    }
    
    private func formatDistance(_ meters: Double?) -> String {
        guard let m = meters else { return "-- km" }
        if m < 1000 {
            return "\(Int(m))m"
        } else {
            return String(format: "%.1f km", m / 1000).replacingOccurrences(of: ".", with: ",")
        }
    }
    
    private func arrivalTime(_ travelTime: TimeInterval?) -> String {
        guard let t = travelTime else { return "--:--" }
        let arrival = Date().addingTimeInterval(t)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: arrival)
    }
}

// Extension for corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Store Detail View
struct StoreDetailView: View {
    let store: Store
    let detent: PresentationDetent
    let onClose: () -> Void
    let onNavigate: () -> Void
    
    @State private var showOrderSheet = false
    @State private var showBookingSheet = false // Added booking state
    @ObservedObject private var cartManager = CartManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Detailed States (Medium/Large)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with premium copy
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.name)
                            .font(.brandSerif(28))
                            .foregroundStyle(Color.forestCanopy)
                        
                        HStack(spacing: 8) {
                            // Availability badge (for MVP - always show as available)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.successGreen)
                                    .frame(width: 8, height: 8)
                                Text("Seats available")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.successGreen)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.successGreen.opacity(0.1))
                            .cornerRadius(12)
                            
                            Text("•")
                                .foregroundStyle(Color.neutral400)
                            
                            Text(formatDistance(store.distance))
                                .font(.caption)
                                .foregroundStyle(Color.neutral600)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Primary CTAs - Order from here + Navigate + Book
                    HStack(spacing: 8) {
                        // BOOK SPACE - Blueprint P1
                        Button {
                            showBookingSheet = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 20))
                                Text("Book")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(Color.forestCanopy)
                            .frame(width: 70, height: 60)
                            .background(Color.sunRay.opacity(0.15))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.sunRay.opacity(0.5), lineWidth: 1)
                            )
                        }
                        
                        // ORDER FROM HERE - Primary CTA
                        Button {
                            // Set this store for order
                            cartManager.selectedStoreId = store.id
                            
                            // Start session tracking
                            RefillPromptService.shared.startSession(storeId: store.id)
                            
                            showOrderSheet = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Order from here")
                                        .font(.subheadline.bold())
                                    Text("Ready in ~5 min")
                                        .font(.caption2)
                                        .opacity(0.8)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.forestCanopy.gradient)
                            .cornerRadius(14)
                        }
                        
                        // Navigate - Secondary
                        Button(action: onNavigate) {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    .font(.system(size: 20))
                                Text("Go")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(Color.forestCanopy)
                            .frame(width: 70, height: 60)
                            .background(Color.filteredLight.opacity(0.3))
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quick Info
                    HStack(spacing: 16) {
                        InfoPill(icon: "clock", text: store.openingHours ?? "Open now", color: .successGreen)
                        InfoPill(icon: "star.fill", text: "4.8", color: .sunRay)
                        InfoPill(icon: "creditcard", text: "Apple Pay", color: .neutral600)
                    }
                    .padding(.horizontal)
                    
                    // Image Carousel
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<3) { _ in
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.neutral100)
                                    .frame(width: 220, height: 150)
                                    .overlay {
                                        if let url = store.imageUrl, !url.isEmpty {
                                            AsyncImage(url: URL(string: url)) { img in
                                                img.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                ProgressView()
                                            }
                                        } else {
                                            Image(systemName: "photo")
                                                .font(.title)
                                                .foregroundStyle(Color.neutral300)
                                        }
                                    }
                                    .clipped()
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // About Section with premium copy
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this space")
                            .font(.headline)
                            .foregroundStyle(Color.forestCanopy)
                        
                        Text("A premium workspace designed for focus. High-speed WiFi, comfortable seating, and the perfect atmosphere for your productive hours.")
                            .font(.subheadline)
                            .foregroundStyle(Color.neutral600)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    
                    // Call Store
                    if store.phoneNumber != nil {
                        Button {
                            if let phone = store.phoneNumber {
                                URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))").map { UIApplication.shared.open($0) }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Call store")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundStyle(Color.forestCanopy)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.forestCanopy.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .cornerRadius(24, corners: [.topLeft, .topRight])
            .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showOrderSheet) {
            SearchView(enableInternalSearch: true)
        }
        .sheet(isPresented: $showBookingSheet) {
            BookingSheet(storeName: store.name)
        }
    }
    
    private func formatDistance(_ distance: Double?) -> String {
        guard let d = distance else { return "Nearby" }
        if d < 1000 {
            return "\(Int(d))m away"
        } else {
            return String(format: "%.1f km away", d / 1000).replacingOccurrences(of: ".", with: ",")
        }
    }
}

// MARK: - Info Pill Component
struct InfoPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(text)
                .font(.caption)
                .foregroundStyle(Color.neutral700)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.neutral100)
        .cornerRadius(8)
    }
}

// MARK: - Subviews
struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var textColor: Color = .white
    var iconColor: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(icon)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.brandSans(14))
                    .fontWeight(.bold)
                    .foregroundStyle(textColor)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(textColor.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(12)
        }
    }
}

struct InfoItem: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var icon: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .foregroundStyle(valueColor == .primary ? Color.coffeeDark : valueColor)
                }
                Text(value)
                    .font(.brandSans(14))
                    .fontWeight(.bold)
                    .foregroundStyle(valueColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StoreRow: View {
    let store: Store
    
    var body: some View {
        HStack(spacing: 16) {
            // Image Placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.coffeeRich.opacity(0.1))
                .frame(width: 70, height: 70)
                .overlay {
                    if let url = store.imageUrl, !url.isEmpty {
                        AsyncImage(url: URL(string: url)) { img in
                            img.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Image("home")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundStyle(Color.coffeeRich.opacity(0.3))
                    }
                }
                .clipped()
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(.brandSans(16))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.coffeeDark)
                
                Text(store.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let d = store.distance {
                        Text(formatDistance(d))
                            .font(.caption2.bold())
                            .foregroundStyle(Color.brandAccent)
                    }
                    
                    if let hours = store.openingHours {
                        Text(hours)
                            .font(.caption2)
                            .foregroundStyle(Color.sage)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1f km", distance / 1000).replacingOccurrences(of: ".", with: ",")
        }
    }
}

// MARK: - Native Map Wrapper for Internal Routing
struct InternalMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var route: MKRoute?
    var annotation: Store?
    var bottomPadding: CGFloat = 0
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Adjust layout margins to offset the center
        uiView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: bottomPadding, right: 0)
        
        // Only update region if it changed significantly to avoid jitter
        uiView.setRegion(region, animated: true)
        
        // Handle Overlays
        uiView.removeOverlays(uiView.overlays)
        if let route = route {
            uiView.addOverlay(route.polyline)
        }
        
        // Handle Annotations
        uiView.removeAnnotations(uiView.annotations)
        if let annotation = annotation {
            let point = MKPointAnnotation()
            point.coordinate = annotation.coordinate
            point.title = annotation.name
            uiView.addAnnotation(point)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            
            let identifier = "StorePin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.markerTintColor = .orange
                annotationView?.glyphImage = UIImage(named: "coffee")
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }
}

#Preview {
    StoresView()
}

// MARK: - Booking Sheet (Mock)
struct BookingSheet: View {
    let storeName: String
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate = Date()
    @State private var selectedSlot = "09:00 AM"
    @State private var peopleCount = 1
    @State private var isBooked = false
    
    let slots = ["09:00 AM", "11:00 AM", "02:00 PM", "04:00 PM"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if !isBooked {
                    // Form
                    VStack(alignment: .leading, spacing: 20) {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .tint(Color.forestCanopy)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Time Slot")
                                .font(.headline)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(slots, id: \.self) { slot in
                                        Button {
                                            selectedSlot = slot
                                        } label: {
                                            Text(slot)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(selectedSlot == slot ? Color.forestCanopy : Color.neutral100)
                                                .foregroundStyle(selectedSlot == slot ? .white : .primary)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Stepper("People: \(peopleCount)", value: $peopleCount, in: 1...10)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button {
                        // Mock Booking Action
                        withAnimation {
                            isBooked = true
                        }
                    } label: {
                        Text("Confirm Booking")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.forestCanopy)
                            .cornerRadius(16)
                    }
                    .padding()
                } else {
                    // Success State
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.successGreen)
                        Text("Booking Confirmed!")
                            .font(.title2.bold())
                        Text("You're booked at \(storeName)")
                            .foregroundStyle(.secondary)
                        
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Reserve Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if #available(iOS 26, *) {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
