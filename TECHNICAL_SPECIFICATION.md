# Technical Specification: App State & Delivery Optimization

## 1. STATE MACHINE SPECIFICATION

### State Diagram

```
┌─────────────┐
│  LAUNCHING  │ (Initial state)
└──────┬──────┘
       │
       ├─ No Token? ─┐
       │             │
       │         ┌───▼────────┐
       │         │ ONBOARDING │ (First launch only)
       │         └───┬────────┘
       │             │
       │             ├─ Skip/Complete
       │             │
       │         ┌───▼────────┐
       │         │ GUEST_READY│ (Browse without auth)
       │         └───┬────────┘
       │             │
       │             ├─ User taps login
       │             │
       ├─ Token? ────┤
       │             │
       │         ┌───▼────────┐
       │         │ LOGGING_IN │
       │         └───┬────────┘
       │             │
       ▼             ▼
┌─────────────┐   ┌──────────────────────┐
│CHECKING_AUTH│──►│PENDING_PHONE_VERIFY  │
└──────┬──────┘   └──────────┬───────────┘
       │                     │
       ├─ Verified? ─────────┘
       │
       ├─ Onboarding needed?
       │
       │         ┌───────────┐
       └────────►│   READY   │ (Main app)
                 └───────────┘
```

### State Persistence Strategy

| Data | Storage | Rationale |
|------|---------|-----------|
| Access Token | Keychain | Secure, survives app reinstall |
| Refresh Token | Keychain | Secure, survives app reinstall |
| User Profile | Local Storage | Fast offline access |
| Cart Items | Local Storage | Optimistic updates |
| Onboarding Flag | UserDefaults | Simple boolean persistence |
| Verification Cache | UserDefaults | Temporary cache (24h TTL) |

---

## 2. DELIVERY OPTIMIZATION ALGORITHM

### Mathematical Model

#### Input Parameters
- `S = {s₁, s₂, ..., sₙ}` - Set of available stores
- `C = {c₁, c₂, ..., cₘ}` - Set of cart items
- `A(s)` - Product availability function for store s
- `F(s)` - Delivery fee for store s
- `D(s, u)` - Distance from store s to user location u
- `E(s)` - Estimated delivery time for store s

#### Scoring Function

For each store `s`, calculate composite score:

```
Score(s) = w₁ · AvailabilityScore(s) 
         + w₂ · FeeScore(s) 
         + w₃ · DistanceScore(s) 
         + w₄ · ETAScore(s)
```

Where weights: `w₁=0.40, w₂=0.35, w₃=0.15, w₄=0.10`

#### Component Scores (normalized 0-1)

**1. Availability Score**
```
AvailabilityScore(s) = |A(s) ∩ C| / |C|
```
Where:
- `|A(s) ∩ C|` = number of cart items available at store s
- `|C|` = total cart items

**2. Fee Score**
```
FeeScore(s) = max(0, (F_max - F(s)) / F_max)
```
Where `F_max = 50,000 VND` (assumed max reasonable fee)

**3. Distance Score** (optional, if location available)
```
DistanceScore(s) = max(0, (D_max - D(s, u)) / D_max)
```
Where `D_max = 10,000 m` (10km)

**4. ETA Score** (optional, if ETA available)
```
ETAScore(s) = max(0, (E_max - E(s)) / E_max)
```
Where `E_max = 60 minutes`

#### Output

Ranked list of stores: `[s₁, s₂, ..., sₖ]` where `Score(s₁) ≥ Score(s₂) ≥ ... ≥ Score(sₖ)`

---

## 3. API CONTRACTS

### Required Backend Endpoints

#### Store Inventory
```http
GET /api/stores/{storeId}/inventory
```

**Response**:
```json
{
  "success": true,
  "inventory": [
    {
      "product_id": "uuid",
      "available": true,
      "quantity": 50,
      "last_updated": "2026-02-04T10:00:00Z"
    }
  ]
}
```

#### Delivery Fee Calculation
```http
POST /api/delivery/calculate-fee
```

**Request**:
```json
{
  "store_id": "uuid",
  "address_id": "uuid",
  "cart_items": [
    {
      "product_id": "uuid",
      "quantity": 2
    }
  ]
}
```

**Response**:
```json
{
  "success": true,
  "fee": 25000,
  "eta_minutes": 35,
  "available": true,
  "reason": null
}
```

---

## 4. DATA FLOW DIAGRAMS

### Fresh Install Flow

```
User Opens App
      │
      ▼
┌──────────────┐
│Launch Screen │
└──────┬───────┘
       │
       ├─ DependencyContainer.initializeSync()
       │  └─ Pre-warm services (no auth)
       │
       ├─ AppFlowController.initializeSync()
       │  ├─ Check Keychain for token
       │  │  └─ No token found
       │  └─ Check onboarding flag
       │     └─ Flag not set
       │
       ▼
┌──────────────┐
│  Onboarding  │ ← Show carousel
└──────┬───────┘
       │
       ├─ User skips or completes
       │
       ▼
┌──────────────┐
│  Guest Ready │ ← Browse menu (no auth)
└──────────────┘
       │
       ├─ No API calls to:
       │  - /api/cart
       │  - /api/user/profile
       │  - /api/orders
       │
       └─ Only fetch:
          - /api/menu (public)
          - /api/stores (public)
```

### Login Flow

```
User in Guest Mode
      │
      ▼
┌──────────────┐
│ Tap "Login"  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ LoginView    │
└──────┬───────┘
       │
       ├─ Enter phone + OTP
       │
       ▼
┌──────────────┐
│POST /auth/otp│
└──────┬───────┘
       │
       ├─ Success? Save tokens to Keychain
       │
       ▼
┌──────────────────┐
│ AppFlowController│
│.transitionTo     │
│LoggedIn()        │
└──────┬───────────┘
       │
       ├─ Fetch user profile
       ├─ Merge local cart with server cart
       ├─ Initialize realtime
       │
       ▼
┌──────────────┐
│  Ready State │
└──────────────┘
```

### Store Optimization Flow

```
User in Delivery Mode
      │
      ├─ Adds item to cart
      │
      ▼
┌───────────────────────┐
│ CartViewModel.addItem │
└───────────┬───────────┘
            │
            ├─ Debounce 500ms
            │
            ▼
┌────────────────────────────────┐
│ recomputeRecommendedStore()    │
└────────────┬───────────────────┘
             │
             ├─ Get user's delivery address
             ├─ Filter stores by delivery capability
             ├─ Sort by distance (top 5)
             │
             ▼
┌────────────────────────────────┐
│ Fetch availability in parallel │
│ for top 5 stores               │
└────────────┬───────────────────┘
             │
             ├─ GET /api/delivery/fee (×5)
             │
             ▼
┌────────────────────────────────┐
│ StoreScoreCalculator           │
│ .calculateScores()             │
└────────────┬───────────────────┘
             │
             ├─ Calculate composite scores
             ├─ Sort by score (descending)
             │
             ▼
┌────────────────────────────────┐
│ Display recommendation toast   │
│ "Optimal store: Store A"       │
│ "All items • ₫15k delivery"    │
└────────────────────────────────┘
             │
             ├─ User can accept or override
             │
             ▼
        [Cart updated]
```

---

## 5. ERROR HANDLING

### Network Errors

| Scenario | Detection | Recovery |
|----------|-----------|----------|
| **No Internet on Launch** | URLError timeout | Use cached state, show offline banner |
| **API 401/403** | Auth error response | Clear tokens → `.guestReady` |
| **API 500** | Server error | Retry with exponential backoff (3 attempts) |
| **Cart Sync Failed** | POST /api/cart error | Keep local cart, retry on next action |
| **Profile Fetch Failed** | GET /api/user/profile error | Use cached profile, mark as stale |

### State Corruption

| Scenario | Detection | Recovery |
|----------|-----------|----------|
| **Token exists but invalid** | Server returns 401 | Delete token → `.guestReady` |
| **Cache missing but token valid** | Profile = nil, token ≠ nil | Fetch from server |
| **Onboarding flag corrupted** | Invalid UserDefaults value | Reset to false → show onboarding |
| **Cart items orphaned** | Product IDs not in menu | Remove orphaned items, log warning |

---

## 6. PERFORMANCE BENCHMARKS

### Launch Performance

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Synchronous Init** | < 50ms | `AppFlowController.initializeSync()` duration |
| **Time to UI** | < 200ms | Launch to ContentView render |
| **First Paint** | < 500ms | Splash → first content frame |
| **Auth Validation** | < 1s | Background server check (non-blocking) |

### Store Optimization

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Score Calculation** | < 100ms | `StoreScoreCalculator.calculateScores()` |
| **Parallel Availability Fetch** | < 2s | 5 concurrent API calls |
| **Debounce Delay** | 500ms | Cart change → recompute trigger |

### Memory Usage

| Component | Target | Notes |
|-----------|--------|-------|
| **AppFlowController** | < 1MB | Singleton, persistent |
| **CartViewModel** | < 2MB | Holds cart items + delivery data |
| **StoreScoreCalculator** | < 500KB | Stateless, short-lived |

---

## 7. SECURITY CONSIDERATIONS

### Token Management

- **Storage**: Keychain (AES-256 encrypted)
- **Transmission**: HTTPS only
- **Rotation**: Refresh token on every app open (foreground/launch) and on 401 fallback
- **Expiry**: Access token 1 hour, refresh token 6 months

### Guest Mode Limitations

- **No PII stored**: Guest cart has no user identifiers
- **Local only**: Cart not synced to server
- **Session-based**: Cleared on app reinstall
- **Upgrade path**: Merge local cart on login

---

## 8. ANALYTICS & MONITORING

### Key Metrics

| Metric | Definition | Target |
|--------|------------|--------|
| **Guest Mode Adoption** | % users browsing without login | > 40% |
| **Onboarding Completion** | % users completing full onboarding | > 60% |
| **Onboarding Skip Rate** | % users skipping onboarding | < 50% |
| **Login Conversion** | Guest → authenticated rate | > 20% |
| **Store Recommendation Acceptance** | % users accepting optimal store | > 70% |
| **Fresh Install 401 Errors** | Count of auth errors on first launch | 0 |

### Events to Track

```swift
// Analytics events
analytics.track("onboarding_started")
analytics.track("onboarding_completed", properties: ["skipped": false])
analytics.track("onboarding_skipped", properties: ["step": 1])
analytics.track("guest_mode_entered")
analytics.track("login_initiated", properties: ["source": "guest_mode"])
analytics.track("store_recommended", properties: [
    "store_id": storeId,
    "score": score,
    "reason": reason
])
analytics.track("store_recommendation_accepted")
analytics.track("store_recommendation_overridden")
```

---

## 9. TESTING STRATEGY

### Unit Tests

```swift
class AppFlowControllerTests: XCTestCase {
    func testFreshInstall_NoToken_TransitionsToOnboarding()
    func testFreshInstall_OnboardingComplete_TransitionsToGuestReady()
    func testValidToken_TransitionsToReady()
    func testExpiredToken_TransitionsToGuestReady()
    func testLogout_ClearsTokens_TransitionsToGuestReady()
    func testPhoneVerificationPending_TransitionsCorrectly()
}

class StoreScoreCalculatorTests: XCTestCase {
    func testFullAvailability_LowestFee_HighestScore()
    func testPartialAvailability_PenalizesScore()
    func testHighDeliveryFee_LowersScore()
    func testNoDistanceData_UsesNeutralScore()
}
```

### Integration Tests

```swift
class OnboardingFlowTests: XCTestCase {
    func testSkipCarousel_JumpsToPermissions()
    func testSkipPermissions_CompletesOnboarding()
    func testCompleteOnboarding_SetsFlags()
    func testOnboardingKilled_ResumesFromStart()
}

class CartOptimizationTests: XCTestCase {
    func testAddItemInDeliveryMode_TriggersOptimization()
    func testOptimalStoreSelected_ShowsToast()
    func testUserOverridesRecommendation_PersistsChoice()
}
```

### UI Tests

```swift
class GuestModeUITests: XCTestCase {
    func testFreshInstall_ShowsOnboarding()
    func testSkipOnboarding_CanBrowseMenu()
    func testGuestAddToCart_NoAPICall()
    func testGuestCheckout_ShowsLoginPrompt()
}
```

---

## 10. ROLLBACK PLAN

### Feature Flags

```swift
enum FeatureFlags {
    static var enableGuestMode: Bool {
        RemoteConfig.shared.bool(forKey: "enable_guest_mode")
    }
    
    static var enableStoreOptimization: Bool {
        RemoteConfig.shared.bool(forKey: "enable_store_optimization")
    }
    
    static var enableSkippableOnboarding: Bool {
        RemoteConfig.shared.bool(forKey: "enable_skippable_onboarding")
    }
}
```

### Rollback Procedure

1. **Disable guest mode**: Set `enable_guest_mode = false`
   - All users transition to `.loggedOut` on next launch
   - Requires login to browse

2. **Disable store optimization**: Set `enable_store_optimization = false`
   - Manual store selection only
   - No recommendation toasts

3. **Revert onboarding**: Set `enable_skippable_onboarding = false`
   - Full onboarding required (no skip)

4. **Emergency rollback**: Deploy previous app version
   - Via App Store "phased release" pause
   - Or force update prompt

---

**Document Version**: 1.0  
**Last Updated**: February 4, 2026  
**Status**: Implementation Complete  
**Next Review**: Post-Beta Feedback
