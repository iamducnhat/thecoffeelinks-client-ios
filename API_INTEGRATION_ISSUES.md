# API Integration Issues & Solutions

**Date**: January 16, 2026  
**Status**: ⚠️ API Server Not Responding

---

## Current Issues

### 1. Menu API Returns 404 ❌

**Error Displayed**: "The requested resource was not found"

**What's Happening**:
```
Client Request: GET https://server-nu-three-90.vercel.app/api/menu
Server Response: 404 Not Found
```

**Root Cause**: The API server at `https://server-nu-three-90.vercel.app/` either:
1. Is not deployed/running
2. Doesn't have the `/api/menu` endpoint
3. Has different endpoint paths

---

## Configuration

### Current API Base URL
```
https://server-nu-three-90.vercel.app/
```

**Configured In**:
- `thecoffeelinks-client-ios/Config.plist` (hardcoded)
- `Core/DI/DependencyContainer.swift` (fallback default)

### Supabase Configuration
```
URL: https://ggikmpqyhkfhctwqbytk.supabase.co
Anon Key: eyJhbGci... (valid JWT token present)
```

---

## How API Calls Work

### 1. URL Construction

```swift
// DependencyContainer.swift
let baseURL = URL(string: "https://server-nu-three-90.vercel.app/")!

// NetworkService.swift
func buildRequest(endpoint: String, ...) {
    let url = baseURL.appendingPathComponent(endpoint)
    // Result: https://server-nu-three-90.vercel.app/api/menu
}
```

### 2. Request Flow

```
MenuViewModel.load()
  → ProductRepository.getMenu()
    → NetworkService.get("api/menu")
      → Constructs URL: https://server-nu-three-90.vercel.app/api/menu
      → Sends HTTP GET request
      → Receives 404 response
      → Throws NetworkError.notFound
      → Error displayed: "The requested resource was not found"
```

---

## Expected vs Actual

### Expected Endpoint
According to `BACKEND_GUIDE.md`:
```http
GET /api/menu
```

**Expected Response**:
```json
{
  "categories": [...],
  "products": [...],
  "toppings": [...]
}
```

### Actual Response
```
HTTP/1.1 404 Not Found
```

---

## Possible Solutions

### Solution 1: Check Server Deployment ✅ **RECOMMENDED**

Verify the backend server is actually running:

```bash
# Test the API endpoint
curl https://server-nu-three-90.vercel.app/api/menu

# Or with browser:
open https://server-nu-three-90.vercel.app/api/menu
```

**If 404**: The server needs to be deployed or the URL is wrong.

---

### Solution 2: Update API Base URL

If the server moved or has a different URL:

**Option A: Update Config.plist**
```xml
<key>API_BASE_URL</key>
<string>https://your-actual-server.com/</string>
```

**Option B: Update DependencyContainer.swift**
```swift
static var `default`: AppConfiguration {
    return AppConfiguration(
        apiBaseURL: URL(string: "https://your-actual-server.com/")!,
        webSocketURL: URL(string: "wss://your-actual-server.com/ws")!,
        environment: .development
    )
}
```

---

### Solution 3: Use Mock Data (Temporary)

For development/testing without backend:

**Create MockProductRepository**:
```swift
final class MockProductRepository: ProductRepositoryProtocol {
    func getMenu() async throws -> Menu {
        // Return hardcoded test data
        let categories = [
            Category(id: "1", name: "Coffee", type: "beverages", displayOrder: 1)
        ]
        let products = [
            Product(
                id: "1", 
                name: "Cappuccino",
                description: "Rich espresso with milk foam",
                // ... full product data
            )
        ]
        let toppings = [
            Topping(id: "1", name: "Extra Shot", price: 15000, isAvailable: true)
        ]
        return Menu(categories: categories, products: products, toppings: toppings)
    }
    // ... other methods with mock data
}
```

**Wire in DependencyContainer**:
```swift
#if DEBUG
private(set) lazy var productRepository: ProductRepositoryProtocol = {
    // MockProductRepository(networkService: networkService, cacheService: cacheService)
    ProductRepository(networkService: networkService, cacheService: cacheService)
}()
#endif
```

---

### Solution 4: Check Server Logs

If you have access to the Vercel deployment:

1. Go to Vercel Dashboard
2. Find project: `server-nu-three-90`
3. Check deployment logs
4. Look for errors in the `/api/menu` endpoint
5. Verify the API route is deployed

---

## Decode Error Investigation

The original issue mentioned "failed to decode" but the current error is 404. Once the API returns 200, check for decode errors:

### Common Decode Issues

1. **Field Name Mismatch**
   - API uses `snake_case`
   - Client expects `camelCase`
   - **Solution**: Already handled by `keyDecodingStrategy = .convertFromSnakeCase`

2. **Missing Fields**
   - API response missing required fields
   - **Solution**: Make fields optional in DTO

3. **Type Mismatch**
   - API sends string, client expects number (or vice versa)
   - **Solution**: Custom decoder or type conversion

4. **Nested Structure**
   - API wraps in `{"success": true, "data": {...}}`
   - **Solution**: Create wrapper DTO

### How to Debug Decode Errors

**Enable Detailed Logging**:
```swift
// In NetworkService.execute()
do {
    let decoded = try decoder.decode(T.self, from: data)
    return decoded
} catch let DecodingError.keyNotFound(key, context) {
    print("❌ Missing key: \(key.stringValue)")
    print("   Context: \(context.debugDescription)")
    print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
    throw NetworkError.decodingFailed
} catch let DecodingError.typeMismatch(type, context) {
    print("❌ Type mismatch for: \(type)")
    print("   Context: \(context.debugDescription)")
    print("   Expected: \(type)")
    throw NetworkError.decodingFailed
} catch let DecodingError.dataCorrupted(context) {
    print("❌ Data corrupted")
    print("   Context: \(context.debugDescription)")
    throw NetworkError.decodingFailed
} catch {
    print("❌ Decode error: \(error)")
    // Print raw JSON for debugging
    if let json = String(data: data, encoding: .utf8) {
        print("   Raw JSON: \(json)")
    }
    throw NetworkError.decodingFailed
}
```

---

## Testing Checklist

### Step 1: Verify Server is Running
- [ ] Open `https://server-nu-three-90.vercel.app/` in browser
- [ ] Check if any response is returned
- [ ] Verify it's the correct server

### Step 2: Test API Endpoint
- [ ] Open `https://server-nu-three-90.vercel.app/api/menu`
- [ ] Check response status (should be 200)
- [ ] Verify JSON structure matches expectations
- [ ] Copy response and validate against APIMenuResponse

### Step 3: Test in App
- [ ] Launch app in simulator
- [ ] Navigate to Home or Menu tab
- [ ] Check if data loads
- [ ] If error, read exact error message
- [ ] Check Xcode console for detailed logs

### Step 4: If Still Failing
- [ ] Add print statements in ProductRepository.getMenu()
- [ ] Log the exact URL being called
- [ ] Log the raw response data
- [ ] Check if authentication header is needed
- [ ] Verify Supabase integration isn't required

---

## Current Implementation Status

### ✅ Client-Side Ready
- APIMenuResponse DTO created
- Proper snake_case handling
- Error handling in place
- UI shows errors to user
- Retry functionality works

### ⏳ Server-Side Unknown
- Can't verify endpoint exists
- Can't verify response format
- Can't test decode logic
- Need access to live API

---

## Quick Fix Commands

### Test API from Command Line
```bash
# Test if server responds
curl -I https://server-nu-three-90.vercel.app/

# Test menu endpoint
curl https://server-nu-three-90.vercel.app/api/menu

# Test with verbose output
curl -v https://server-nu-three-90.vercel.app/api/menu

# Save response to file
curl https://server-nu-three-90.vercel.app/api/menu > menu_response.json

# Pretty print JSON
curl https://server-nu-three-90.vercel.app/api/menu | python3 -m json.tool
```

### Verify URL in Swift
```swift
// Add to ProductRepository.getMenu()
print("📡 Requesting: \(networkService.baseURL)api/menu")
```

---

## Related Documentation

- **Server API**: `/Users/nguyenducnhat/appcafe/thecoffeelinks-server/BACKEND_API_GUIDE.md`
- **Client Guide**: `BACKEND_GUIDE.md`  
- **Decode Fixes**: `DECODE_FIXES_SUMMARY.md`

---

## Recommendation

**Immediate Action**: Verify the backend server at `https://server-nu-three-90.vercel.app/` is:
1. Actually deployed
2. Running the correct code
3. Has the `/api/menu` endpoint implemented

**Alternative**: If backend isn't ready, use MockProductRepository to develop and test the iOS app independently.

---

*Last Updated: 2026-01-16 00:15 UTC*  
*Status: Waiting for backend verification*  
*Blocker: API returns 404*
