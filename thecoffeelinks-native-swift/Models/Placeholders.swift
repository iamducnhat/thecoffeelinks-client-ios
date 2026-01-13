//
//  Placeholders.swift
//  thecoffeelinks-native-swift
//

import Foundation

extension Product {
    static let placeholder = Product(
        id: "placeholder",
        name: "Delicious Coffee",
        description: "A placeholder description for the skeleton loader.",
        basePrice: 45000,
        category: .coffee,
        categoryId: nil,
        image: nil,
        imageUrl: nil,
        isPopular: true,
        isNew: false,
        isActive: true,
        isAvailable: true
    )
}

extension Order {
    static let placeholder = Order(
        id: "placeholder",
        userId: "user",
        status: "received",
        totalAmount: 125000,
        type: "dine_in",
        tableId: "T12",
        createdAt: "2026-01-01T12:00:00Z",
        deliveryAddress: nil,
        orderItems: []
    )
}

extension Voucher {
    static let placeholder = Voucher(
        _id: "placeholder",
        code: "WELCOME50",
        type: "discount",
        value: 50000,
        description: "50% Off First Order",
        minSpend: 0,
        expiresAt: Date(),
        isUsed: false,
        imageUrl: nil
    )
}

extension Event {
    static let placeholder = Event(
        id: "placeholder",
        title: "Coffee Workshop",
        description: "Learn to brew.",
        date: Date(),
        imageUrl: nil,
        hostName: "Barista",
        location: "Main St",
        type: "workshop"
    )
}

extension User {
    static let placeholder = User(
        id: "placeholder",
        email: "guest@example.com",
        fullName: "Guest User",
        name: "Guest",
        avatarUrl: nil,
        points: 0,
        jobTitle: "Coffee Lover",
        industry: "Tech",
        bio: "Just here for the coffee.",
        linkedinUrl: nil,
        isOpenToNetworking: true
    )
}

extension CheckIn {
    static let placeholder = CheckIn(
        id: "placeholder",
        userId: "placeholder",
        locationId: "main_store",
        checkedInAt: "2026-01-01T12:00:00Z",
        user: .placeholder
    )
}

extension Store {
    static let placeholder = Store(
        id: "placeholder",
        name: "Main Street Coffee",
        address: "123 Coffee Lane, Brew City",
        latitude: 37.7749,
        longitude: -122.4194,
        imageUrl: nil,
        phoneNumber: "+1 555-0102",
        openingHours: "8:00 AM - 8:00 PM"
    )
}
