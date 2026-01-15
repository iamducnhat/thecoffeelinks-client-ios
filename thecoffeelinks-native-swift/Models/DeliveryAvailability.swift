//
//  DeliveryAvailability.swift
//  thecoffeelinks-native-swift
//
//  Response models for /api/delivery/availability endpoint
//

import Foundation

/// Response from /api/delivery/availability
struct DeliveryAvailabilityResponse: Codable {
    let available: Bool
    let needsAddressValidation: Bool?
    let eta: ETAInfo?
    let fee: FeeInfo?
    let distance: DistanceInfo?
    let zone: ZoneInfo?
    let minOrderAmount: Double?
    let message: String?
    let alternativeAction: String?
    let deliveryHours: DeliveryHours?
    let store: StoreInfo?
    
    enum CodingKeys: String, CodingKey {
        case available
        case needsAddressValidation
        case eta
        case fee
        case distance
        case zone
        case minOrderAmount
        case message
        case alternativeAction
        case deliveryHours
        case store
    }
    
    struct ETAInfo: Codable {
        let minutes: Int?
        let min: Int?
        let max: Int?
        let display: String?
        let arrivalBy: String?
    }
    
    struct FeeInfo: Codable {
        let amount: Double?
        let display: String?
        let surge: Bool?
        let surgeMultiplier: Double?
    }
    
    struct DistanceInfo: Codable {
        let km: Double?
        let display: String?
    }
    
    struct ZoneInfo: Codable {
        let id: String?
        let name: String?
    }
    
    struct DeliveryHours: Codable {
        let start: String?
        let end: String?
    }
    
    struct StoreInfo: Codable {
        let id: String?
        let name: String?
    }
}
