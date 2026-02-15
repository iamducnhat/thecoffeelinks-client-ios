# Production Runtime Audit — Implementation Report

**Date:** February 15, 2026  
**App:** TheCoffeeLinks iOS (SwiftUI)  
**Scope:** Deep runtime simulation, crash analysis, race condition investigation  
**Result:** 3 Critical, 8 High, 12 Medium, several Low issues identified → **18 fixes implemented (2 phases)**

---

## Todo List — Status

| # | Priority | Task | Status | Files Modified |
|---|----------|------|--------|----------------|
| 1 | **P0** | Fix App Attest key generation race condition | ✅ Done | `AppAttestService.swift`, `AuthRepository.swift` |
| 2 | **P0** | Prevent duplicate order placement | ✅ Done | `CheckoutViewModel.swift` |
| 3 | **P0** | Fix payment URL handling & app-killed-mid-payment | ✅ Done | `CheckoutViewModel.swift` |
| 4 | **P0** | Fix `setAuthSessionSync` not being synchronous | ✅ Done | `NetworkService.swift`, `DependencyContainer.swift` |
| 5 | **P1** | Fix CartService thread safety violations | ✅ Done | `CartService.swift` |
| 6 | **P1** | Remove debug `print()` from hot paths | ✅ Done | `CartModels.swift`, `OrderModels.swift` |
| 7 | **P1** | Fix `sendOTP()` duplicate token clearing | ✅ Done | `AuthViewModel.swift` |
| 8 | **P2** | Bound response cache (LRU eviction) | ✅ Done | `NetworkService.swift` |
| 9 | **P2** | Fix `CartOperation.add` silent data loss | ✅ Done | `CartOperation.swift` |
| 10 | **P2** | Guard SyncManager timer in guest mode | ✅ Done | `SyncManager.swift`, `DependencyContainer.swift` |

---

## Detailed Changes

### 1. App Attest Key Generation Race Condition (P0 — CRITICAL)

**Root Cause:** Three code paths (`AppFlowController.initializeSync()`, `AuthRepository.getCurrentUser()`, `verifyOTP()`) could concurrently call `generateKey()`, each creating a separate Apple key. Only one key gets registered with the server, but `currentKey` may point to a different (unregistered) key → subsequent assertions use the wrong key → server returns 403 "Device attestation required" on order creation.

**Fix (2 files):**

**`AppAttestService.swift`**
- Added `private var keyGenerationTask: Task<AppAttestKey, Error>?` property
- `generateKey()` now checks for `currentKey` first, then deduplicates via `keyGenerationTask` — concurrent callers await the same task instead of creating separate Apple keys
- Extracted `_generateKeyImpl()` as the single-execution implementation

**`AuthRepository.swift`**
- Removed fire-and-forget `Task { ensureRegistered(); registerKeyWithServer() }` from `getCurrentUser()`
- `getCurrentUser()` now only calls `loadKeyForUser()` — never generates or registers
- Registration happens exclusively in `verifyOTP()`, eliminating the race

---

### 2. Duplicate Order Placement (P0 — CRITICAL)

**Root Cause:** `placeOrder()` checked `isPlacingOrder` only for visual state — the function body still executed on rapid double-taps, creating duplicate orders.

**Fix:**

**`CheckoutViewModel.swift`**
- Added `guard !isPlacingOrder else { return nil }` at the top of `placeOrder()`
- Two rapid taps now result in exactly one order

---

### 3. Payment URL & App-Killed-Mid-Payment (P0 — CRITICAL)

**Root Cause:** (a) If server returned a malformed `paymentUrl`, `URL(string:)` returned `nil` and the code silently dropped the order. (b) If the user killed the app while VNPay webview was open, the payment callback never fired — payment captured but no order recorded client-side.

**Fix (3 sub-changes):**

**`CheckoutViewModel.swift`**
- **Malformed URL guard:** Added `guard let url = URL(string: urlString)` with explicit error surfacing
- **Pending payment persistence:** Before opening webview, saves `order.id` to `UserDefaults` under `"pendingPaymentOrderId"`
- **Recovery on relaunch:** Added `recoverPendingPaymentIfNeeded()` method — checks for pending order ID on launch, fetches status from server, shows result
- **Post-payment retry:** If `getOrder()` fails after VNPay success, retries once after 2 seconds before surfacing the error

---

### 4. `setAuthSessionSync` Not Synchronous (P0 — CRITICAL)

**Root Cause:** `setAuthSessionSync()` wrapped the token assignment in `Task { @MainActor in }`, which schedules work for the *next* run-loop tick. Subsequent requests in `initializeSync()` fired before the token was available → 401 errors.

**Fix (2 files):**

**`NetworkService.swift`**
- Removed `Task { @MainActor in }` wrapper
- Added `@MainActor` annotation to the method signature
- Token assignment is now direct: `self.authToken = accessToken`

**`DependencyContainer.swift`**
- Added `@MainActor` to `initializeSync()` so it runs on MainActor directly
- Removed `Task { @MainActor in appFlowController.initializeSync() }` — now calls `appFlowController.initializeSync()` directly since the caller is already `@MainActor`

---

### 5. CartService Thread Safety (P1 — HIGH)

**Root Cause:** `isSyncing`, `syncTask`, and `pendingOperations` are `nonisolated(unsafe)` with no protection. `scheduleSyncIfNeeded()` accessed `syncTask` (cancel + assign) without synchronization. `performSync()` read `isSyncing` outside the queue — concurrent mutations could corrupt state or crash.

**Fix:**

**`CartService.swift`**
- `scheduleSyncIfNeeded()` now wraps `syncTask?.cancel()` and `syncTask = Task { ... }` inside `syncQueue.async`
- `performSync()` uses `syncQueue.sync { () -> Bool in ... }` pattern to atomically check-and-set `isSyncing`
- `defer` block uses `syncQueue.sync { isSyncing = false }` to safely clear the flag

---

### 6. Debug `print()` in Hot Paths (P1 — HIGH)

**Root Cause:** `print(items)` in `Cart.addItem()` dumped the entire cart array on every add. `print(toppings)` in `OrderCustomization.toppingsTotal` fired on every render cycle (up to 540 calls/sec with 9 items at 60fps).

**Fix (2 files):**

**`CartModels.swift`**
- Removed `print(items)` from `addItem()`

**`OrderModels.swift`**
- Removed `print(toppings)` from `toppingsTotal` computed property

---

### 7. Duplicate Token Clearing in `sendOTP()` (P1)

**Root Cause:** The catch block in `sendOTP()` contained the same 3-line token clearing block (`deleteAccessToken` / `deleteRefreshToken` / `clearAuthToken`) duplicated twice consecutively — likely a copy-paste error.

**Fix:**

**`AuthViewModel.swift`**
- Removed the second duplicate copy of the 3-line token clearing block

---

### 8. Unbounded Response Cache (P2 — MEDIUM)

**Root Cause:** `NetworkService.responseCache: [String: Data]` grew without limit. With 50+ unique endpoints each caching up to 37KB (menu), memory pressure accumulated on older devices over extended sessions.

**Fix:**

**`NetworkService.swift`**
- Added `private let maxResponseCacheEntries = 100`
- After caching a new ETag response, checks if `responseCache.count > maxResponseCacheEntries`
- Evicts oldest entries (by `etagCache` timestamp) to bring count back under the limit
- Both `responseCache` and `etagCache` entries are removed together

---

### 9. `CartOperation.add` Silent Data Loss (P2 — MEDIUM)

**Root Cause:** When `Cart.applyOperation(.add)` couldn't find an existing item by key, the else branch only printed `"⚠️ Add operation requires product details"` and did nothing — silently dropping the item.

**Fix:**

**`CartOperation.swift`**
- Constructs a placeholder `Product` with available data (`productId`, `priceSnapshot`, empty name)
- Creates a full `CartItem` and appends it to `items`
- Product details will be hydrated during the next sync with the server

---

### 10. SyncManager Timer in Guest Mode (P2 — MEDIUM)

**Root Cause:** `Timer.publish(every: 60)` fired `triggerSync()` every 60 seconds, even when no user was logged in. This wasted battery and bandwidth with guaranteed-to-fail API calls in guest mode.

**Fix (2 files):**

**`SyncManager.swift`**
- Added `private let keychainManager: KeychainManager?` property
- `triggerSync()` now checks `keychainManager.getAccessToken() == nil` at entry — if no token, skips the sync entirely
- Init signature updated with optional `keychainManager` parameter

**`DependencyContainer.swift`**
- Passes `keychainManager: keychainManager` when constructing `SyncManager`

---

## Remaining Items — Phase 2 (All Implemented)

| # | Priority | Item | Status | Files Modified |
|---|----------|------|--------|----------------|
| 11 | **P0** | Server-side price validation | ✅ Done | `thecoffeelinks-server/.../orders/route.ts` |
| 12 | **P1** | Disable dev bypass in production builds | ✅ Done | `AuthRepository.swift`, `AuthViewModel.swift` |
| 13 | **P1** | Fix Preferences `PUT 405` → `PATCH` | ✅ Done | `UserRepository.swift` |
| 14 | **P1** | Deduplicate API calls on launch | ✅ Done | `MainTabView.swift` |
| 15 | **P2** | Input sanitization on `staffNotes`/`deliveryNotes` | ✅ Done | `CheckoutViewModel.swift` |
| 16 | **P2** | Remove "Hacker Store" from production DB | ✅ Done | `supabase/migrations/20260215000000_remove_hacker_store.sql` |
| 17 | **P3** | Replace all `print()` with `debugLog()` | ✅ Done | `DebugLog.swift` + 159 files |
| 18 | **P3** | Client-side voucher brute-force throttle | ✅ Done | `CartViewModel.swift` |

### Remaining (Not Implemented)

| # | Priority | Item | Reason |
|---|----------|------|--------|
| — | P3 | `Config.plist` secrets migration | Architecture decision — move `SUPABASE_ANON_KEY` to xcconfig or server-fetched config |

---

## Verification Checklist

- [x] Build the project: `xcodebuild build -scheme TheCoffeeLinks -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` — **0 errors, warnings are pre-existing**
- [x] Migration pushed: `supabase db push` — **Hacker Store + related FK rows deleted from production DB**
- [x] `print()` → `debugLog()`: **158 debugLog calls, 0 user-level print() remaining** (1 internal print inside DebugLog.swift itself)
- [x] `debugLog()` is `nonisolated` — callable from any actor/isolation context
- [ ] Verify App Attest: Launch → check logs for exactly **one** "Generated local key" and **one** "Key registered with server"
- [ ] Test double-tap order: Rapidly tap "Place Order" → verify only one order created
- [ ] Test kill-during-payment: Open VNPay → force-kill app → relaunch → verify order status recovered
- [ ] Verify no duplicate API calls: Count `/api/stores`, `/api/user/profile` in launch logs
- [ ] Test guest mode: Verify SyncManager logs "Skipping periodic sync — not authenticated"
- [ ] Monitor memory: Run for 30+ minutes → verify `responseCache` stays bounded

---

## Files Modified Summary

### Phase 1 (10 fixes)

| File | Path | Lines Changed |
|------|------|---------------|
| `AppAttestService.swift` | `Core/Security/` | +35 |
| `AuthRepository.swift` | `Core/Repositories/` | -23 +3 |
| `CheckoutViewModel.swift` | `Features/Checkout/` | +55 |
| `NetworkService.swift` | `Core/Networking/` | +18 -5 |
| `DependencyContainer.swift` | `Core/DI/` | +4 -4 |
| `CartService.swift` | `Core/Services/` | +18 -12 |
| `SyncManager.swift` | `Core/Services/` | +9 |
| `AuthViewModel.swift` | `Core/ViewModels/` | -5 |
| `CartModels.swift` | `Domain/Models/` | -1 |
| `OrderModels.swift` | `Domain/Models/` | -1 |
| `CartOperation.swift` | `Domain/Models/` | +33 -3 |

### Phase 2 (8 fixes)

| File | Path | Lines Changed |
|------|------|---------------|
| `UserRepository.swift` | `Data/Repositories/` | PUT→PATCH |
| `MainTabView.swift` | `Features/Main/` | -12 +4 |
| `CheckoutViewModel.swift` | `Features/Checkout/` | +20 (sanitize) |
| `DebugLog.swift` | `Core/Utilities/` | +19 (new file) |
| 159 Swift files | Various | `print(` → `debugLog(` |
| `CartViewModel.swift` | `Features/Cart/` | +17 (rate limit) |
| `AuthRepository.swift` | `Core/Repositories/` | +3 (`#if !DEBUG`) |
| `AuthViewModel.swift` | `Core/ViewModels/` | +4 (`#if !DEBUG`) |
| `029_remove_hacker_store.sql` | `supabase/migrations/` | +46 (new file) |
| `orders/route.ts` | `thecoffeelinks-server/` | +70 (price validation) |
