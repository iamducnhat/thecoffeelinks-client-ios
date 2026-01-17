import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var clAuthorizationStatus: CLAuthorizationStatus?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        self.clAuthorizationStatus = manager.authorizationStatus
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.clAuthorizationStatus = status
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - LocationServiceProtocol
extension LocationManager: LocationServiceProtocol {
    // Protocol requires async property, but checking authorizationStatus is sync on CLLocationManager property.
    // We wrap it to satisfy the protocol requirement.
    var authorizationStatus: LocationAuthorizationStatus {
        get async {
            let status = manager.authorizationStatus
            switch status {
            case .authorizedAlways: return .authorizedAlways
            case .authorizedWhenInUse: return .authorizedWhenInUse
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .notDetermined
            }
        }
    }
    
    var currentLocation: (latitude: Double, longitude: Double)? {
        get async {
            guard let loc = manager.location else { return nil }
            return (loc.coordinate.latitude, loc.coordinate.longitude)
        }
    }
    
    func requestAuthorization() async {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() async {
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() async {
        manager.stopUpdatingLocation()
    }
    
    func geocodeAddress(_ address: String) async throws -> (latitude: Double, longitude: Double) {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        if let location = placemarks.first?.location {
            return (location.coordinate.latitude, location.coordinate.longitude)
        }
        throw URLError(.badURL)
    }
    
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        if let placemark = placemarks.first {
            return [placemark.thoroughfare, placemark.locality].compactMap { $0 }.joined(separator: ", ")
        }
        return "Unknown Location"
    }
}
