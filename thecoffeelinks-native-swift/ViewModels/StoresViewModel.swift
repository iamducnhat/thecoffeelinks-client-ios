import Foundation
import MapKit
import Combine
import SwiftUI

@MainActor
class StoresViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var stores: [Store] = []
    @Published var viewState: ViewState = .idle
    @Published var selectedStore: Store?
    @Published var userLocation: CLLocation?
    @Published var route: MKRoute?
    @Published var isNavigating = false
    @Published var destinationReached = false
    @Published var travelTime: TimeInterval?
    @Published var distanceRemaining: Double?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default SF
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    
    private let storeService = StoreService()
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func fetchStores() async {
        viewState = .loading
        do {
            let fetchedStores = try await storeService.getStores()
            self.stores = fetchedStores
            
            updateDistancesAndSort()
            
            // Adjust region to fit stores if available and we don't have user location
            if userLocation == nil, let firstStore = fetchedStores.first {
                self.region = MKCoordinateRegion(
                    center: firstStore.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
            
            viewState = .loaded
        } catch {
            print("Error fetching stores: \(error)")
            viewState = .error(error.localizedDescription)
        }
    }
    
    private func updateDistancesAndSort() {
        guard let userLoc = userLocation else { return }
        
        var updatedStores = stores.map { store -> Store in
            var mutableStore = store
            let storeLoc = CLLocation(latitude: store.latitude, longitude: store.longitude)
            mutableStore.distance = userLoc.distance(from: storeLoc)
            return mutableStore
        }
        
        updatedStores.sort { (s1, s2) -> Bool in
            let d1 = s1.distance ?? Double.infinity
            let d2 = s2.distance ?? Double.infinity
            return d1 < d2
        }
        
        self.stores = updatedStores
    }
    
    func selectStore(_ store: Store) {
        selectedStore = store
        withAnimation {
            region = MKCoordinateRegion(
                center: store.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        // Calculate route if we have user location
        Task {
            await calculateRoute(to: store)
        }
    }
    
    func calculateRoute(to store: Store) async {
        guard let userLoc = userLocation else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLoc.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: store.coordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            if let firstRoute = response.routes.first {
                self.route = firstRoute
                self.travelTime = firstRoute.expectedTravelTime
            }
        } catch {
            print("Error calculating route: \(error)")
        }
    }
    
    func openInMaps(store: Store) {
        let placemark = MKPlacemark(coordinate: store.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = store.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    func startNavigation() {
        guard route != nil else { return }
        isNavigating = true
        destinationReached = false
        
        // Tilt and zoom for navigation if we have user location
        if let userLoc = userLocation {
            withAnimation {
                region = MKCoordinateRegion(
                    center: userLoc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
        
        // Update distances and sort when location changes
        updateDistancesAndSort()
        
        // Handle navigation updates
        if isNavigating, let store = selectedStore {
            let storeLoc = CLLocation(latitude: store.latitude, longitude: store.longitude)
            let distance = location.distance(from: storeLoc)
            self.distanceRemaining = distance
            
            // Check if reached destination (e.g., 50m)
            if distance < 50 && !destinationReached {
                destinationReached = true
                isNavigating = false
                // Trigger arrival notification/UI
            }
            
            // Auto-follow user during navigation if needed
            withAnimation {
                region.center = location.coordinate
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationAuthStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
