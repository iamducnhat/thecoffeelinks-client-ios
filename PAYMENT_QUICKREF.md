# Payment System - Swift Quick Reference

## Current Status: ✅ BYPASS MODE ACTIVE

The server-side payment verification is currently bypassing all validation for development.
Orders will always succeed regardless of payment method selection.

---

## Payment Flow in the App

```
CheckoutView.swift
    │
    ▼
OrderService.verifyPayment()  ←── Calls /api/payments/verify
    │
    ▼ Returns mock token "PAY_XXXX..."
    │
OrderService.createOrder()    ←── Creates order with token
    │
    ▼
Order Success Screen
```

---

## Key Files

| File | Purpose |
|------|---------|
| `Views/Order/CheckoutView.swift` | UI for payment method selection |
| `Services/API/OrderService.swift` | Payment verification + order creation |
| `Models/PaymentMethod.swift` | PaymentMethod enum (if exists) |

---

## Supported Payment Methods

```swift
enum PaymentMethod: String, CaseIterable {
    case cash = "cash"
    case card = "card"
    case momo = "momo"
    case zalopay = "zalopay"
}
```

---

## How to Test Payments

### Currently (Bypass Mode)
1. Select any payment method in checkout
2. Place order
3. Order will succeed (no real payment processed)

### When Production Mode Enabled
Different payment methods will require:

| Method   | Flow                                   |
|----------|----------------------------------------|
| Cash     | Direct order creation                  |
| Card     | Stripe PaymentSheet integration        |
| MoMo     | Deep link to MoMo app → return URL     |
| ZaloPay  | Deep link to ZaloPay app → return URL  |

---

## Future Integration Points

### 1. Stripe (Card Payments)

Will need to add:
```swift
// Podfile or Package.swift
// StripePaymentSheet SDK

// Handle client secret from server
func presentStripePaymentSheet(clientSecret: String) async throws
```

### 2. MoMo / ZaloPay (E-Wallets)

Will need to add:
- Deep link handler in AppDelegate/SceneDelegate
- URL scheme: `thecoffeelinks://`
- Payment result callback handling

```swift
// AppDelegate.swift
func application(_ app: UIApplication, open url: URL, options: ...) -> Bool {
    if url.scheme == "thecoffeelinks" {
        // Handle payment callback
        handlePaymentCallback(url)
        return true
    }
    return false
}
```

---

## Server Reference

See full integration guide at:
`thecoffeelinks-server/PAYMENT_INTEGRATION_GUIDE.md`

### Bypass Toggle Location
```typescript
// thecoffeelinks-server/src/app/api/payments/verify/route.ts
const BYPASS_PAYMENT_VALIDATION = true;  // Set to false for production
```

---

## Common Issues

### "Payment method is required"
- **Cause**: Server bypass mode was disabled but client isn't sending paymentMethod
- **Fix**: Ensure bypass mode is enabled, or verify `selectedPaymentMethod.rawValue` is being sent

### Order fails after payment verified
- **Cause**: Token validation issue or order creation error
- **Check**: Console logs for detailed error messages

---

## Quick Test Checklist

- [x] Cash payment works
- [x] Card payment works (bypassed)
- [x] MoMo payment works (bypassed)
- [x] ZaloPay payment works (bypassed)
- [ ] Real Stripe integration (TODO)
- [ ] Real MoMo integration (TODO)
- [ ] Real ZaloPay integration (TODO)
