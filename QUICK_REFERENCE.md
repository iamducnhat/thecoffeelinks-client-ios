# Quick Reference: State Management & UI Rules

## State Machine Cheat Sheet

```swift
// State Check
if appFlowController.currentState.requiresAuth {
    // User is authenticated
} else {
    // Guest mode or unauthenticated
}

// Auth Guard Pattern
guard KeychainManager.shared.getAccessToken() != nil else {
    // Return empty state or skip operation
    return
}

// Transitions
appFlowController.transitionToLoggedIn(user)
appFlowController.transitionToLoggedOut()
appFlowController.markPhoneVerified()
appFlowController.markOnboardingCompleted()
```

---

## Persistent Flags

| Key | Type | Purpose | Set When |
|-----|------|---------|----------|
| `isOnboardingCompleted` | Bool | Onboarding done | User completes or skips onboarding |
| `isInitialSetupCompleted` | Bool | Setup done | User completes or skips setup |
| `hasCompletedOnboarding` | Bool | First launch | Onboarding finished |
| Access Token | Keychain | Auth state | Login success |

---

## UI Component Quick Reference

### Buttons
```swift
// Primary CTA
CapsuleButton("Continue", style: .primary) { }

// Secondary
CapsuleButton("Cancel", style: .secondary) { }

// Ghost
CapsuleButton("Skip", style: .ghost) { }

// Icon
ReceiptIconButton(icon: "arrow.left") { }
```

### Shapes
```swift
// Cards
RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)

// Buttons
Capsule()

// Borders (ALWAYS use strokeBorder)
.overlay(Capsule().strokeBorder(Color.border, lineWidth: 1))
```

### Icons
```swift
// Lucide (preferred)
Image("coffee")

// SF Symbols (exceptions only)
Image(systemName: "plus")      // ✅
Image(systemName: "minus")     // ✅
Image(systemName: "xmark")     // ✅
Image(systemName: "chevron.left") // ✅

// Fallback wrapper
IconView(name: "coffee")  // Auto-tries bundled first
```

### Colors
```swift
Color.backgroundPaper     // Off-white bg
Color.textInk            // Primary text
Color.primaryEspresso    // Accent (green)
Color.border             // Warm gray
Color.surfaceCard        // Card bg
Color.textMuted          // Secondary text
```

### Typography
```swift
Text("Title")
    .font(AppFont.displayTitle)    // 28pt Bold

Text("Heading")
    .font(AppFont.sectionHeader)   // 22pt Medium

Text("Body")
    .font(AppFont.body)            // 17pt Regular

Text("₫45,000")
    .font(AppFont.monoBody)        // 17pt Mono
```

### Spacing
```swift
VStack(spacing: AppSpacing.md) {  // 12pt
    Text("Item 1")
    Text("Item 2")
}
.padding(AppSpacing.lg)           // 16pt

// Quick reference
AppSpacing.xs  // 4pt
AppSpacing.sm  // 8pt
AppSpacing.md  // 12pt
AppSpacing.lg  // 16pt
AppSpacing.xl  // 24pt
```

---

## Guest Mode Boundaries

### ✅ Available Without Login
- Browse menu
- View products
- Search
- View stores
- Add to local cart
- View events/promotions

### ❌ Requires Login
- Checkout
- Order history
- Saved addresses
- Loyalty points
- Favorites
- Profile management
- Cart sync

---

## Store Optimization

### Trigger
```swift
// Auto-triggers when:
// 1. Cart items change
// 2. User is in delivery mode
// 3. Delivery address selected
// 4. Debounced 500ms

// Manual trigger:
await cartViewModel.recomputeRecommendedStore(for: address)
```

### Access Results
```swift
if let recommended = cartViewModel.recommendedStore {
    print("Store: \(recommended.store.name)")
    print("Score: \(recommended.score)")
    print("Delivery: ₫\(recommended.deliveryFee)")
    print("Available: \(recommended.availableProducts)")
    print("Reason: \(recommended.reason)")
}
```

---

## Common Patterns

### Auth-Gated API Call
```swift
func fetchData() async {
    guard KeychainManager.shared.getAccessToken() != nil else {
        print("⏭️ Skipping - no auth")
        return
    }
    
    // Proceed with API call
    let data = try await repository.fetch()
}
```

### Check State Before Action
```swift
func performAction() {
    guard appFlowController.currentState == .ready ||
          appFlowController.currentState == .guestReady else {
        print("❌ Cannot perform action in state: \(appFlowController.currentState)")
        return
    }
    
    // Proceed
}
```

### Store Conflict Handling
```swift
// Detect conflict
if let currentStoreId = cart.storeId,
   currentStoreId != newProduct.storeId,
   !cart.isEmpty {
    showStoreConflictAlert = true
    return
}

// Resolve: Clear cart and switch
cartViewModel.switchStore(to: newStore)
```

---

## Debugging

### Enable Logs
```swift
// State changes
print("🎯 [AppFlowController] State: \(currentState)")

// Auth checks
print("🔑 Token exists: \(keychainManager.getAccessToken() != nil)")

// Cache validity
print("📦 Cache valid: \(isCacheValid)")

// Store scores
print("⭐ Store score: \(score), reason: \(reason)")
```

### Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| **401 errors on fresh install** | API calls before auth | Add auth guard |
| **Onboarding loops** | Flag not persisted | Check UserDefaults save |
| **Guest cart lost** | Not saved locally | Use CartStorage.saveCart() |
| **Wrong store selected** | Not using recommendation | Enable `recomputeRecommendedStore` |
| **UI inconsistency** | Inline styling | Use design system components |

---

## Testing Checklist

- [ ] Fresh install → Onboarding shown
- [ ] Skip onboarding → Guest mode works
- [ ] Guest mode → No 401 errors
- [ ] Guest checkout → Login prompt
- [ ] Login → Cart merges
- [ ] Logout → Transitions to guest
- [ ] Token expiry → Graceful logout
- [ ] Store optimization → Toast shown
- [ ] Manual override → Persists choice
- [ ] All buttons use CapsuleButton
- [ ] All borders use strokeBorder
- [ ] All icons follow Lucide-first

---

## File Locations

| Component | File |
|-----------|------|
| State Machine | `TheCoffeeLinks/Core/Services/AppFlowController.swift` |
| Cart Service | `TheCoffeeLinks/Core/Services/CartService.swift` |
| Profile ViewModel | `TheCoffeeLinks/Core/ViewModels/ProfileViewModel.swift` |
| DI Container | `TheCoffeeLinks/Core/DI/DependencyContainer.swift` |
| Content Router | `TheCoffeeLinks/ContentView.swift` |
| Onboarding | `TheCoffeeLinks/Features/Onboarding/OnboardingFlowView.swift` |
| Store Optimizer | `TheCoffeeLinks/Features/Cart/StoreScoreCalculator.swift` |
| UI Rules | `TheCoffeeLinks/Core/DesignSystem/UIConsistencyRules.md` |

---

## Emergency Contacts

| Issue | Contact | Action |
|-------|---------|--------|
| **State machine bug** | @architecture-team | Check AppFlowController logs |
| **401 spam** | @backend-team | Add auth guard |
| **Store optimization error** | @delivery-team | Check availability API |
| **UI inconsistency** | @design-team | Review UIConsistencyRules.md |

---

**Print this page for quick desk reference**  
**Last Updated**: February 4, 2026
