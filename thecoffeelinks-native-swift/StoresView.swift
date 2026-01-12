import SwiftUI
import MapKit

struct StoresView: View {
    @StateObject private var viewModel = StoresViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Our Locations")
                .font(.brandSerif(32))
                .foregroundStyle(Color.coffeeDark)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.viewState == .loading && viewModel.stores.isEmpty {
                        ProgressView("Finding stores...")
                            .padding(.top, 40)
                    } else if viewModel.stores.isEmpty {
                        Text("No stores found nearby.")
                            .font(.brandSans(14))
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(viewModel.stores) { store in
                            NavigationLink(destination: StoreMapView(store: store)) {
                                StoreRow(store: store)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()
            }
        }
        .task {
            viewModel.requestLocation()
            await viewModel.fetchStores()
        }
        .navigationBarTitleDisplayMode(.inline)
//        .navigationTitle("Stores") // Hide title to keep it clean as per request
    }
}

// MARK: - Store Map View (Full Screen)
struct StoreMapView: View {
    let store: Store
    @StateObject private var viewModel = StoresViewModel()
    @State private var selectedDetent: PresentationDetent = .fraction(0.12)
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Native Map with internal routing
            InternalMapView(
                region: $viewModel.region,
                route: viewModel.route,
                annotation: store
            )
            .ignoresSafeArea()
            
            // Navigation Guidance Overlay
            if viewModel.isNavigating {
                VStack {
                    HStack {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
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
                            Image(systemName: "xmark.circle.fill")
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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.brandAccent)
                    
                    VStack(spacing: 8) {
                        Text("You've Arrived!")
                            .font(.brandSerif(32))
                            .foregroundStyle(Color.coffeeDark)
                        Text(store.name)
                            .font(.brandSans(18))
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        viewModel.destinationReached = false
                        dismiss()
                    } label: {
                        Text("Finish")
                            .font(.brandSans(18))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.coffeeDark)
                            .cornerRadius(16)
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
        .sheet(isPresented: .init(get: { !viewModel.isNavigating && !viewModel.destinationReached }, set: { _ in })) {
            StoreDetailView(store: store, detent: selectedDetent) {
            } onNavigate: {
                viewModel.startNavigation()
            }
            .presentationDetents([.fraction(0.12), .medium, .large], selection: $selectedDetent)
            .presentationBackground(.clear)
            .presentationDragIndicator(selectedDetent == .fraction(0.12) ? .hidden : .visible)
            .background {
                if #available(iOS 16.4, *) {
                    Color.clear
                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                }
            }
            .interactiveDismissDisabled()
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
    
    var body: some View {
        VStack(spacing: 0) {
            if detent == .fraction(0.12) {
                // Capsule/Minimal State
                HStack {
                    Spacer()
                    Text(store.name)
                        .font(.brandSans(18))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.coffeeDark)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                    Spacer()
                }
                .padding(.top, 12)
                Spacer()
            } else {
                // Detailed States (Medium/Large)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.name)
                                    .font(.brandSerif(28))
                                    .foregroundStyle(Color.coffeeDark)
                                Text("Cafe • Bakery")
                                    .font(.brandSans(14))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 24)
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            ActionButton(title: "Drive", subtitle: "Directions", icon: "car.fill", color: Color.brandAccent, action: onNavigate)
                            ActionButton(title: "Call", subtitle: "Store", icon: "phone.fill", color: .blue.opacity(0.1), textColor: .blue, iconColor: .blue, action: {
                                if let phone = store.phoneNumber {
                                    URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))").map { UIApplication.shared.open($0) }
                                }
                            })
                            ActionButton(title: "Website", subtitle: "Menu", icon: "globe", color: .green.opacity(0.1), textColor: .green, iconColor: .green, action: {})
                        }
                        .padding(.horizontal)
                        
                        // Info Grid
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                            GridRow {
                                InfoItem(label: "Hours", value: store.openingHours ?? "Open", valueColor: .green)
                                InfoItem(label: "Distance", value: formatDistance(store.distance))
                            }
                            GridRow {
                                InfoItem(label: "Ratings", value: "93%", icon: "hand.thumbsup.fill")
                                InfoItem(label: "Accepts", value: "Apple Pay", icon: "applelogo")
                            }
                        }
                        .padding(.horizontal)
                        
                        // Image Carousel
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<3) { _ in
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.coffeeRich.opacity(0.05))
                                        .frame(width: 250, height: 180)
                                        .overlay {
                                            if let url = store.imageUrl, !url.isEmpty {
                                                AsyncImage(url: URL(string: url)) { img in
                                                    img.resizable().aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    ProgressView()
                                                }
                                            } else {
                                                Image(systemName: "photo")
                                                    .font(.largeTitle)
                                                    .foregroundStyle(Color.coffeeRich.opacity(0.1))
                                            }
                                        }
                                        .clipped()
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.brandSerif(20))
                                .foregroundStyle(Color.coffeeDark)
                            Text("The Coffee Links is your premium destination for the finest beans and a luxurious atmosphere. Located in the heart of the city, we offer a unique experience for coffee lovers.")
                                .font(.brandSans(14))
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 50)
                    }
                }
                .background(Color.white)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
    
    private func formatDistance(_ distance: Double?) -> String {
        guard let d = distance else { return "-- km" }
        if d < 1000 {
            return "\(Int(d))m"
        } else {
            return String(format: "%.1f km", d / 1000).replacingOccurrences(of: ".", with: ",")
        }
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
                Image(systemName: icon)
                    .font(.system(size: 20))
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
                    Image(systemName: icon)
                        .font(.caption2)
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
        HStack(spacing: 12) {
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
                        Image(systemName: "building.2.fill")
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
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.coffeeRich.opacity(0.3))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
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
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
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
                annotationView?.glyphImage = UIImage(systemName: "cup.and.saucer.fill")
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
