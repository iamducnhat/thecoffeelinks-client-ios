//
//  APIModels.swift
//  TheCoffeeLinks
//
//  API Response Models that match server contract exactly
//  These models handle decoding from server and convert to domain models
//

import Foundation

// MARK: - Standard Response Wrapper

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
    let message: String?
}

// MARK: - Menu API Models

struct APIMenuResponse: Codable {
    let products: [APIProduct]
    let categories: [APICategory]
    let toppings: [APITopping]
    let sizes: [String: APISizeModifier]
    let sugar_options: [APIOption]
    let ice_options: [APIOption]
    
    func toMenu() -> Menu {
        // Convert API sizes to domain SizeOptions
        let sizeDefaults: [ProductSize: Double] = [
            .small: sizes["S"]?.price ?? 0,
            .medium: sizes["M"]?.price ?? 5000,
            .large: sizes["L"]?.price ?? 10000
        ]
        
        return Menu(
            categories: categories.map { $0.toDomain() },
            products: products.map { $0.toDomain(sizeDefaults: sizeDefaults) },
            toppings: toppings.map { $0.toDomain() },
            lastUpdated: Date()
        )
    }
}

struct APIProduct: Codable {
    let id: String
    let name: String
    let description: String?
    let category: String?
    let category_id: String
    let image: String?
    let is_popular: Bool
    let is_new: Bool
    let is_available: Bool
    let is_hot_supported: Bool?
    let is_deliverable: Bool?
    let available_toppings: [String]
    let size_options: APISizeOptionsObject?
    
    func toDomain(sizeDefaults: [ProductSize: Double]) -> Product {
        // Parse size_options from server (object format)
        let sizeOptions: [SizeOption]
        if let apiSizeOpts = size_options {
            sizeOptions = apiSizeOpts.toSizeOptions()
        } else {
            // Fallback to defaults
            sizeOptions = [
                SizeOption(size: .small, price: sizeDefaults[.small] ?? 0, isEnabled: true),
                SizeOption(size: .medium, price: sizeDefaults[.medium] ?? 5000, isEnabled: true),
                SizeOption(size: .large, price: sizeDefaults[.large] ?? 10000, isEnabled: true)
            ]
        }
        
        // Resolve image URL
        let resolvedImageUrl: String?
        if let img = image, !img.isEmpty {
            if img.hasPrefix("http://") || img.hasPrefix("https://") {
                resolvedImageUrl = img
            } else if img.hasPrefix("/") {
                resolvedImageUrl = Config.apiBaseURL + img
            } else {
                resolvedImageUrl = Config.apiBaseURL + "/" + img
            }
        } else {
            resolvedImageUrl = nil
        }
        
        return Product(
            id: id,
            name: name,
            description: description,
            categoryId: category_id,
            categoryName: category,
            imageUrl: resolvedImageUrl,
            basePrice: sizeOptions.first?.price ?? 0,
            sizeOptions: sizeOptions,
            availableToppings: available_toppings,
            isPopular: is_popular,
            isNew: is_new,
            isActive: is_available,
            isHotSupported: is_hot_supported ?? false,
            isDeliverable: is_deliverable ?? true,
            deliveryPrepMinutes: nil,
            tags: [],
            nutritionInfo: nil,
            allergens: []
        )
    }
}

struct APISizeOptionsObject: Codable {
    let small: APISizeOption
    let medium: APISizeOption
    let large: APISizeOption
    
    func toSizeOptions() -> [SizeOption] {
        var options: [SizeOption] = []
        if small.enabled {
            options.append(SizeOption(size: .small, price: small.price, isEnabled: true))
        }
        if medium.enabled {
            options.append(SizeOption(size: .medium, price: medium.price, isEnabled: true))
        }
        if large.enabled {
            options.append(SizeOption(size: .large, price: large.price, isEnabled: true))
        }
        return options
    }
}

struct APISizeOption: Codable {
    let enabled: Bool
    let price: Double
}

struct APISizeModifier: Codable {
    let price: Double
    let label: String
}

struct APICategory: Codable {
    let id: String
    let name: String
    
    func toDomain() -> ProductCategory {
        ProductCategory(
            id: id,
            name: name,
            displayName: name.capitalized.replacingOccurrences(of: "_", with: " "),
            iconName: nil,
            imageUrl: nil,
            sortOrder: 0,
            isActive: true,
            productCount: nil
        )
    }
}

struct APITopping: Codable {
    let id: String
    let name: String
    let price: Double
    let is_available: Bool?
    
    func toDomain() -> Topping {
        Topping(
            id: id,
            name: name,
            price: price,
            isAvailable: is_available ?? true,
            maxQuantity: 10,
            categoryId: nil
        )
    }
}

struct APIOption: Codable {
    let value: String
    let label: String
}

// MARK: - Order API Models

struct APIOrderResponse: Codable {
    let success: Bool
    let order: APIOrder?
    let orders: [APIOrder]?
    let totalCount: Int?
    let hasMore: Bool?
    let error: String?
    let message: String?
    
    func toOrder() -> Order? {
        order?.toDomain()
    }
    
    func toOrders() -> [Order] {
        orders?.compactMap { $0.toDomain() } ?? []
    }
}

struct APIOrder: Codable {
    let id: String
    let user_id: String?
    let store_id: String?
    let status: String
    let type: String?
    let delivery_option: String?
    let mode: String?
    let payment_method: String
    let payment_status: String?
    let total_amount: Double
    let discount: Double?
    let delivery_fee: Double?
    let table_id: String?
    let delivery_address_id: String?
    let delivery_address: String?
    let notes: String?
    let delivery_notes: String?
    let created_at: String
    let updated_at: String?
    let estimated_ready_at: String?
    let completed_at: String?
    let cancelled_at: String?
    let cancellation_reason: String?
    let pending_until: String?
    let items: [APIOrderItem]?
    let order_items: [APIOrderItem]?
    let payment_url: String?
    
    func toDomain() -> Order {
        let orderItems = items ?? order_items ?? []
        
        // Parse mode from either delivery_option or mode field
        let modeString = mode ?? delivery_option ?? type ?? "pickup"
        let orderMode: OrderingMode
        switch modeString {
        case "delivery": orderMode = .delivery
        case "dine_in", "dine-in": orderMode = .dineIn
        default: orderMode = .pickup
        }
        
        // Parse status
        let orderStatus = OrderStatus(rawValue: status) ?? .pending
        
        // Parse payment method
        let paymentMethodEnum = PaymentMethod(rawValue: payment_method) ?? .cash
        
        // Parse dates
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdDate = iso8601Formatter.date(from: created_at) ?? Date()
        let updatedDate = updated_at.flatMap { iso8601Formatter.date(from: $0) } ?? createdDate
        let estimatedReadyDate = estimated_ready_at.flatMap { iso8601Formatter.date(from: $0) }
        let completedDate = completed_at.flatMap { iso8601Formatter.date(from: $0) }
        let cancelledDate = cancelled_at.flatMap { iso8601Formatter.date(from: $0) }
        
        // Map delivery address if exists
        var deliveryAddr: DeliveryAddress? = nil
        if let addrId = delivery_address_id, let addrText = delivery_address {
            deliveryAddr = DeliveryAddress(
                id: addrId,
                label: "Delivery Address",
                streetAddress: addrText,
                buildingInfo: nil,
                city: "City",
                district: nil,
                coordinates: nil,
                isDefault: false,
                usageCount: 1,
                lastUsedAt: createdDate,
                createdAt: createdDate
            )
        }
        
        return Order(
            id: id,
            userId: user_id ?? "",
            storeId: store_id ?? "",
            status: orderStatus,
            mode: orderMode,
            paymentMethod: paymentMethodEnum,
            items: orderItems.map { $0.toDomain() },
            subtotal: total_amount - (delivery_fee ?? 0) + (discount ?? 0),
            deliveryFee: delivery_fee ?? 0,
            discount: discount ?? 0,
            totalAmount: total_amount,
            tableId: table_id,
            deliveryAddress: deliveryAddr,
            deliveryNotes: delivery_notes,
            staffNotes: notes,
            createdAt: createdDate,
            updatedAt: updatedDate,
            estimatedReadyAt: estimatedReadyDate,
            completedAt: completedDate,
            cancelledAt: cancelledDate,
            cancellationReason: cancellation_reason,
            paymentUrl: payment_url,
            tax: nil,
            taxRate: nil,
            pointsUsed: nil,
            voucherSnapshot: nil,
            storeSnapshot: nil
        )
    }
}

struct APIOrderItem: Codable {
    let id: String?
    let order_id: String?
    let product_id: String?
    let product_name: String
    let quantity: Int
    let final_price: Double
    let options_snapshot_json: OrderCustomization?
    
    func toDomain() -> OrderItem {
        OrderItem(
            id: id ?? UUID().uuidString,
            orderId: order_id ?? "",
            productId: product_id ?? "",
            productName: product_name,
            productImage: nil,
            quantity: quantity,
            unitPrice: final_price,
            finalPrice: final_price,
            customization: options_snapshot_json ?? .default
        )
    }
}

// MARK: - Configuration Helper

enum Config {
    static var apiBaseURL: String {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let urlString = config["API_BASE_URL"] as? String {
            return urlString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return "https://api.thecoffeelinks.vn"
    }
}
