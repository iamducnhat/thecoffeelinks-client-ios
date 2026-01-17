# API Decode Error Fixes - Summary

**Date**: January 15, 2026  
**Status**: ✅ All decode paths implemented and ready for testing

---

## Overview

The app was experiencing decode errors because the backend API uses `snake_case` field naming while Swift models use `camelCase`. Additionally, some fields had different names or structures between API and client.

---

## Solution Implemented

### 1. API Response DTOs Created

Two main DTO types were created to handle API responses before converting to domain models:

#### `APIMenuResponse` (`Domain/Models/APIResponses.swift`)

Handles the `/api/menu` endpoint response:

```swift
struct APIMenuResponse: Codable {
    let categories: [APICategory]
    let products: [APIProduct]
    let toppings: [APITopping]
    
    struct APICategory: Codable {
        let id: String
        let name: String
        let type: String?
        let display_order: Int?
    }
    
    struct APIProduct: Codable {
        let id: String
        let name: String
        let description: String?
        let image: String?
        let category_id: String
        let category_name: String?
        let size_options: SizeOptionsJSON
        let available_toppings: [String]
        let is_available: Bool
        let is_deliverable: Bool?
        let best_in_store: Bool?
        let delivery_notes: String?
        let created_at: String?
    }
    
    struct APITopping: Codable {
        let id: String
        let name: String
        let price: Double
        let is_available: Bool
    }
}
```

**Key Features:**
- Uses `snake_case` to match API exactly
- Includes all optional fields from API
- Nested structs for complex objects
- Conversion methods to domain models

#### `APIOrdersResponse` (`Domain/Models/APIResponses.swift`)

Handles order-related endpoints:

```swift
struct APIOrdersResponse: Codable {
    let success: Bool
    let orders: [APIOrder]?
    let order: APIOrder?
    
    struct APIOrder: Codable {
        let id: String
        let user_id: String?
        let store_id: String
        let status: String
        let delivery_option: String
        let payment_method: String?
        let total_amount: Double
        let subtotal: Double?
        let delivery_fee: Double?
        let discount: Double?
        let source: String?
        let notes: String?
        let pending_until: String?
        let created_at: String
        let updated_at: String?
        let order_items: [APIOrderItem]
        let store: APIStore?
        let delivery_address: APIDeliveryAddress?
    }
    
    struct APIOrderItem: Codable {
        let id: String
        let product_id: String
        let product_name: String
        let quantity: Int
        let size: String
        let price: Double
        let final_price: Double
        let toppings: [APIItemTopping]?
        let notes: [String]?
        let is_favorite: Bool?
    }
}
```

**Key Features:**
- Handles both single order and order list responses
- Nested order items with full customization
- Store and address relationships
- Timestamp parsing

---

## 2. Field Mapping

### Size Options

**API Format** (JSONB in database):
```json
{
  "small": { "enabled": false, "price": 0 },
  "medium": { "enabled": true, "price": 45000 },
  "large": { "enabled": true, "price": 55000 }
}
```

**Client Model**:
```swift
struct SizeOption: Codable {
    let small: SizeDetails
    let medium: SizeDetails
    let large: SizeDetails
}

struct SizeDetails: Codable {
    let enabled: Bool
    let price: Double
}
```

### Toppings

**API**: Array of topping IDs as strings
```json
["uuid1", "uuid2", "uuid3"]
```

**Client**: Converted to `Topping` objects via lookup

### Order Items

**API**: Flat structure with customization fields
```json
{
  "size": "large",
  "toppings": [{"id": "uuid", "name": "Extra Shot", "price": 15000}],
  "notes": ["Less ice", "Extra hot"]
}
```

**Client**: Structured `ProductCustomization` object
```swift
struct ProductCustomization {
    let size: String
    let sugar: String
    let ice: String
    let toppings: [Topping]
    let notes: [String]
}
```

---

## 3. Smart Parsing Logic

### Date Parsing

Handles multiple ISO 8601 formats:
```swift
private static let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

// Fallback without fractional seconds
private static let fallbackDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()
```

### Topping Parsing

```swift
extension APIOrdersResponse.APIOrderItem {
    func toDomain(allToppings: [Topping]) -> OrderItem {
        let parsedToppings: [Topping] = (toppings ?? []).compactMap { apiTopping in
            // Try to find in known toppings first
            if let existing = allToppings.first(where: { $0.id == apiTopping.id }) {
                return existing
            }
            // Fallback: create from API data
            return Topping(
                id: apiTopping.id,
                name: apiTopping.name,
                price: apiTopping.price,
                isAvailable: true
            )
        }
        // ... rest of conversion
    }
}
```

### Customization Reconstruction

```swift
let customization = ProductCustomization(
    size: size,
    sugar: "100", // Default if not provided
    ice: "normal", // Default if not provided
    toppings: parsedToppings,
    notes: notes ?? []
)
```

---

## 4. Repository Updates

### ProductRepository

**Before**:
```swift
func getMenu() async throws -> (categories: [Category], products: [Product], toppings: [Topping]) {
    let data = try await networkService.fetch(endpoint: "/api/menu")
    let menu = try JSONDecoder().decode(MenuResponse.self, from: data)
    return (menu.categories, menu.products, menu.toppings)
}
```

**After**:
```swift
func getMenu() async throws -> (categories: [Category], products: [Product], toppings: [Topping]) {
    let data = try await networkService.fetch(endpoint: "/api/menu")
    let apiResponse = try JSONDecoder().decode(APIMenuResponse.self, from: data)
    
    // Convert to domain models
    let categories = apiResponse.categories.map { $0.toDomain() }
    let toppings = apiResponse.toppings.map { $0.toDomain() }
    let products = apiResponse.products.map { $0.toDomain(toppings: toppings) }
    
    return (categories, products, toppings)
}
```

### OrderRepository

**Before**: Direct decode of domain models
**After**: Decode API response then convert

```swift
func getOrders() async throws -> [Order] {
    let data = try await networkService.fetch(endpoint: "/api/orders", authenticated: true)
    let apiResponse = try JSONDecoder().decode(APIOrdersResponse.self, from: data)
    
    guard let apiOrders = apiResponse.orders else {
        return []
    }
    
    // Get toppings for proper conversion
    let (_, _, toppings) = try await productRepository.getMenu()
    
    return apiOrders.map { $0.toDomain(allToppings: toppings) }
}
```

---

## 5. Error Handling

All decode operations wrapped in proper error handling:

```swift
do {
    let apiResponse = try JSONDecoder().decode(APIMenuResponse.self, from: data)
    return apiResponse.products.map { $0.toDomain(toppings: toppings) }
} catch let DecodingError.keyNotFound(key, context) {
    throw NetworkError.decodingFailed("Missing key: \(key.stringValue) - \(context.debugDescription)")
} catch let DecodingError.typeMismatch(type, context) {
    throw NetworkError.decodingFailed("Type mismatch for \(type): \(context.debugDescription)")
} catch {
    throw NetworkError.decodingFailed("Decode failed: \(error.localizedDescription)")
}
```

---

## 6. Testing Checklist

### Menu Endpoint (`/api/menu`)
- ✅ DTO created (`APIMenuResponse`)
- ✅ Conversion to domain models implemented
- ✅ ProductRepository updated
- ⏳ Test with real API

**Expected Fields**:
```json
{
  "categories": [...],
  "products": [{
    "id": "uuid",
    "name": "Product Name",
    "category_id": "uuid",
    "size_options": {...},
    "available_toppings": ["uuid1", "uuid2"],
    "is_available": true
  }],
  "toppings": [...]
}
```

### Orders Endpoint (`/api/orders`)
- ✅ DTO created (`APIOrdersResponse`)
- ✅ Conversion to domain models implemented
- ✅ OrderRepository updated
- ⏳ Test with real API

**Expected Fields**:
```json
{
  "success": true,
  "orders": [{
    "id": "uuid",
    "status": "placed",
    "delivery_option": "pickup",
    "total_amount": 145000,
    "order_items": [{
      "product_id": "uuid",
      "quantity": 2,
      "size": "large",
      "toppings": [...]
    }]
  }]
}
```

### Popular Products (`/api/products/popular`)
- ✅ DTO created (reuses `APIMenuResponse.APIProduct`)
- ✅ Conversion implemented
- ✅ ProductRepository updated
- ⏳ Test with real API

---

## 7. Known Field Differences

| API Field | Client Field | Notes |
|-----------|--------------|-------|
| `category_id` | `categoryId` | Auto-converted |
| `category_name` | `categoryName` | Auto-converted |
| `size_options` | `sizeOptions` | Auto-converted |
| `available_toppings` | `availableToppings` | Auto-converted, converted to Topping objects |
| `is_available` | `isAvailable` | Auto-converted |
| `is_deliverable` | `isDeliverable` | Auto-converted |
| `best_in_store` | `bestInStore` | Auto-converted |
| `delivery_notes` | `deliveryNotes` | Auto-converted |
| `created_at` | `createdAt` | Auto-converted, parsed to Date |
| `order_items` | `orderItems` | Auto-converted |

---

## 8. Fallback Strategies

### Missing Fields
- Optional fields handle nil gracefully
- Defaults provided for customization (sugar: "100", ice: "normal")
- Empty arrays for missing collections

### Unknown Toppings
- If topping ID not in known list, create from API data
- Allows for new toppings without app update

### Date Parsing
- Try with fractional seconds first
- Fallback to standard ISO 8601
- Graceful handling of invalid dates

---

## 9. Files Modified

| File | Purpose | Status |
|------|---------|--------|
| `Domain/Models/APIResponses.swift` | DTOs for API responses | ✅ Created |
| `Data/Repositories/ProductRepository.swift` | Menu/product fetching | ✅ Updated |
| `Data/Repositories/OrderRepository.swift` | Order fetching | ✅ Updated |
| `Domain/Models/Product.swift` | Domain model | ✅ Verified |
| `Domain/Models/Order.swift` | Domain model | ✅ Verified |
| `Domain/Models/Topping.swift` | Domain model | ✅ Verified |

---

## 10. Next Steps for Testing

1. **Unit Tests**:
   - Test DTO parsing with sample JSON
   - Test conversion to domain models
   - Test error cases

2. **Integration Tests**:
   - Test with real API endpoints
   - Verify all fields decode correctly
   - Test with various product configurations

3. **Edge Cases**:
   - Products with no toppings
   - Products with only one size
   - Orders with no customization
   - Orders with multiple notes
   - Missing optional fields

---

## 11. Backend Guide References

- **Server API**: `/Users/nguyenducnhat/appcafe/thecoffeelinks-server/BACKEND_API_GUIDE.md`
- **Client Guide**: `/Users/nguyenducnhat/appcafe/thecoffeelinks-native-swift/BACKEND_GUIDE.md`

Both guides are comprehensive and include:
- Complete endpoint documentation
- Request/response formats
- Field naming conventions
- Error codes
- Rate limits

---

## Summary

✅ **All decode error fixes implemented**:
- API DTOs handle snake_case → camelCase
- Smart parsing for complex fields
- Proper error handling
- Fallback strategies

⏳ **Ready for testing**:
- Build succeeds
- Code compiles without errors
- Ready to test with real API

🚀 **Next action**: Integration testing with live API endpoints

---

*Last Updated: 2026-01-15 23:30 UTC*  
*Status: Implementation Complete, Testing Pending*
