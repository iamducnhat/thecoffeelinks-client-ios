import Foundation
import CoreLocation

struct Store: Decodable, Identifiable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let imageUrl: String?
    let phoneNumber: String?
    let openingHours: String?
    
    var distance: Double? = nil
    
    // Computed property for MapKit
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
