//
//  DeliveryModels.swift
//  thecoffeelinks-client-ios
//
//  Domain models for delivery - NO SwiftUI imports
//

import Foundation

// MARK: - Delivery Address

// MARK: - Delivery Address

struct DeliveryAddress: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var label: String
    var streetAddress: String
    var buildingInfo: String?
    var city: String
    var district: String?
    var coordinates: Coordinates?
    var isDefault: Bool
    var usageCount: Int
    var lastUsedAt: Date?
    let createdAt: Date
    
    struct Coordinates: Codable, Hashable, Sendable {
        let latitude: Double
        let longitude: Double
    }
    
    enum CodingKeys: String, CodingKey {
        case id, label
        case streetAddress = "street_address"
        case buildingInfo = "building_info"
        case city, district, coordinates
        case isDefault = "is_default"
        case usageCount = "usage_count"
        case lastUsedAt = "last_used_at"
        case createdAt = "created_at"
    }
    
    var fullAddress: String {
        var parts = [streetAddress]
        if let building = buildingInfo, !building.isEmpty { parts.append(building) }
        if let district = district, !district.isEmpty { parts.append(district) }
        parts.append(city)
        return parts.joined(separator: ", ")
    }
    
    var shortAddress: String {
        if let building = buildingInfo, !building.isEmpty {
            return "\(streetAddress), \(building)"
        }
        return streetAddress
    }
    
    static func == (lhs: DeliveryAddress, rhs: DeliveryAddress) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Delivery Zone

struct DeliveryZone: Codable, Identifiable, Sendable {
    let id: String
    let storeId: String
    let name: String
    let polygon: [Coordinates]
    let baseFee: Double
    let perKmFee: Double
    let estimatedMinutes: Int
    let isActive: Bool
    
    struct Coordinates: Codable, Sendable {
        let latitude: Double
        let longitude: Double
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, polygon
        case storeId = "store_id"
        case baseFee = "base_fee"
        case perKmFee = "per_km_fee"
        case estimatedMinutes = "estimated_minutes"
        case isActive = "is_active"
    }
    
    func contains(latitude: Double, longitude: Double) -> Bool {
        let point = (latitude, longitude)
        var inside = false
        var j = polygon.count - 1
        
        for i in 0..<polygon.count {
            let xi = polygon[i].latitude
            let yi = polygon[i].longitude
            let xj = polygon[j].latitude
            let yj = polygon[j].longitude
            
            if ((yi > point.1) != (yj > point.1)) &&
                (point.0 < (xj - xi) * (point.1 - yi) / (yj - yi) + xi) {
                inside = !inside
            }
            j = i
        }
        return inside
    }
}

// MARK: - Delivery Availability

struct DeliveryAvailability: Codable, Sendable {
    let available: Bool
    let storeId: String
    let zone: DeliveryZone?
    let fee: DeliveryFee?
    let eta: DeliveryETA?
    let minOrderAmount: Double?
    let unavailableReason: UnavailableReason?
    let unavailableProducts: [String]?
    
    enum CodingKeys: String, CodingKey {
        case available, zone, fee, eta
        case storeId = "store_id"
        case minOrderAmount = "min_order_amount"
        case unavailableReason = "unavailable_reason"
        case unavailableProducts = "unavailable_products"
    }
    
    enum UnavailableReason: String, Codable, Sendable {
        case outOfZone = "out_of_zone"
        case storeClosed = "store_closed"
        case tooFar = "too_far"
        case noDrivers = "no_drivers"
        case temporarilyUnavailable = "temporarily_unavailable"
        
        var message: String {
            switch self {
            case .outOfZone: return String(localized: "delivery_unavailable_out_of_zone")
            case .storeClosed: return String(localized: "delivery_unavailable_store_closed")
            case .tooFar: return String(localized: "delivery_unavailable_too_far")
            case .noDrivers: return String(localized: "delivery_unavailable_no_drivers")
            case .temporarilyUnavailable: return String(localized: "delivery_unavailable_temp_unavailable")
            }
        }
    }
}

// MARK: - Delivery Fee

struct DeliveryFee: Codable, Sendable {
    let amount: Double
    let baseFee: Double
    let distanceFee: Double
    let surgeFee: Double?
    let isSurge: Bool
    let surgeMultiplier: Double?
    
    enum CodingKeys: String, CodingKey {
        case amount
        case baseFee = "base_fee"
        case distanceFee = "distance_fee"
        case surgeFee = "surge_fee"
        case isSurge = "is_surge"
        case surgeMultiplier = "surge_multiplier"
    }
    
    var displayAmount: String { amount.formattedVND }
    
    var breakdown: [(String, Double)] {
        var items: [(String, Double)] = [(String(localized: "delivery_fee_base"), baseFee), (String(localized: "delivery_fee_distance"), distanceFee)]
        if let surge = surgeFee, surge > 0 { items.append((String(localized: "delivery_fee_surge"), surge)) }
        return items
    }
}

// MARK: - Delivery ETA

struct DeliveryETA: Codable, Sendable {
    let minutes: Int
    let minMinutes: Int
    let maxMinutes: Int
    let prepMinutes: Int
    let transitMinutes: Int
    let calculatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case minutes
        case minMinutes = "min_minutes"
        case maxMinutes = "max_minutes"
        case prepMinutes = "prep_minutes"
        case transitMinutes = "transit_minutes"
        case calculatedAt = "calculated_at"
    }
    
    var displayRange: String { String(localized: "eta_range_format \(minMinutes) \(maxMinutes)") }
    
    var estimatedArrival: Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: calculatedAt) ?? calculatedAt
    }
    
    var estimatedArrivalDisplay: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return String(localized: "eta_arrival_format \(formatter.string(from: estimatedArrival))")
    }
}

// MARK: - Delivery Tracking

struct DeliveryTracking: Codable, Identifiable, Sendable {
    let id: String
    let orderId: String
    let driverName: String?
    let driverPhone: String?
    let driverPhoto: String?
    let vehicleType: VehicleType
    let currentLocation: Location?
    let status: DeliveryTrackingStatus
    let updates: [TrackingUpdate]
    let estimatedArrival: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, status, updates
        case orderId = "order_id"
        case driverName = "driver_name"
        case driverPhone = "driver_phone"
        case driverPhoto = "driver_photo"
        case vehicleType = "vehicle_type"
        case currentLocation = "current_location"
        case estimatedArrival = "estimated_arrival"
    }
    
    struct Location: Codable, Sendable {
        let latitude: Double
        let longitude: Double
        let heading: Double?
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case latitude, longitude, heading
            case updatedAt = "updated_at"
        }
    }
    
    enum VehicleType: String, Codable, Sendable {
        case bike
        case motorbike
        case car
    }
}

enum DeliveryTrackingStatus: String, Codable, Sendable {
    case assigned
    case pickedUp
    case enRoute = "en_route"
    case nearBy = "near_by"
    case arrived
    case delivered
    
    var displayName: String {
        switch self {
        case .assigned: return String(localized: "tracking_status_assigned")
        case .pickedUp: return String(localized: "tracking_status_picked_up")
        case .enRoute: return String(localized: "tracking_status_en_route")
        case .nearBy: return String(localized: "tracking_status_near_by")
        case .arrived: return String(localized: "tracking_status_arrived")
        case .delivered: return String(localized: "tracking_status_delivered")
        }
    }
}

struct TrackingUpdate: Codable, Identifiable, Sendable {
    let id: String
    let status: DeliveryTrackingStatus
    let message: String
    let timestamp: Date
    
    // Note: 'timestamp' is generic, aligning with 'created_at' is safer if server uses that
    // but assuming 'timestamp' for now if API uses that. 
    // If standard supabase timestamps, it's usually created_at.
}

// MARK: - API Responses

struct DeliveryAvailabilityResponse: Codable, Sendable {
    let success: Bool
    let availability: DeliveryAvailability
}

struct DeliveryZonesResponse: Codable, Sendable {
    let success: Bool
    let zones: [DeliveryZone]
}

struct AddressesResponse: Codable, Sendable {
    let success: Bool
    let addresses: [DeliveryAddress]
}

struct SaveAddressResponse: Codable, Sendable {
    let success: Bool
    let address: DeliveryAddress
    let alreadyExists: Bool?
    
    enum CodingKeys: String, CodingKey {
        case success, address
        case alreadyExists = "already_exists"
    }
}

struct DeliveryTrackingResponse: Codable, Sendable {
    let success: Bool
    let tracking: DeliveryTracking
}
