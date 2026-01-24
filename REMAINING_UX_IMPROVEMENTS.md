# Remaining UX Improvements

**Date**: January 16, 2026  
**Priority**: High - User Experience Issues

---

## Issue 1: Missing Store Selection for Check-In ⚠️

### Current Problem

When user tries to check in at Connect tab:
1. Taps "Check In" button
2. CheckInSheet shows mode selection (Open/Focus)
3. User selects mode
4. **But no store selection happens!**
5. Code uses `"mock-store-id"` as placeholder

**Code Location**: `Features/Connect/ConnectView.swift:63-67`
```swift
Task {
    // TODO: Add store selection - for now using a mock storeId
    // Proper flow: Show store selector → then check in with selected store
    await viewModel.checkIn(storeId: "mock-store-id", mode: mode)
}
```

### Proper Flow Should Be

```
User taps "Check In"
  ↓
StoreSelectionSheet opens
  - Shows nearby stores
  - Sorts by distance
  - Shows: name, address, distance
  ↓
User selects a store
  ↓
CheckInSheet opens
  - Shows selected store name
  - Mode selector (Open/Focus)
  ↓
User selects mode → Checks in
```

### Implementation Needed

**1. Create StoreSelectionSheet**:
```swift
struct StoreSelectionSheet: View {
    let stores: [Store]
    let onSelect: (Store) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(stores) { store in
                StoreRowView(store: store)
                    .onTapGesture {
                        onSelect(store)
                        dismiss()
                    }
            }
            .navigationTitle("Select Store")
        }
    }
}

struct StoreRowView: View {
    let store: Store
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.name)
                .font(.brandSans(16, weight: .semibold))
            Text(store.address)
                .font(.brandSans(13))
                .foregroundStyle(.secondary)
            if let distance = store.distanceKm {
                Text("\(String(format: "%.1f", distance)) km away")
                    .font(.brandSans(12))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
```

**2. Add to ConnectView**:
```swift
@State private var showingStoreSelector = false
@State private var selectedStore: Store?
@State private var nearbyStores: [Store] = []

// In onAppear
Task {
    nearbyStores = try? await storeRepository.getNearbyStores()
}

// Update check-in flow
.sheet(isPresented: $showingStoreSelector) {
    StoreSelectionSheet(stores: nearbyStores) { store in
        selectedStore = store
        showingCheckIn = true
    }
}

.sheet(isPresented: $showingCheckIn) {
    CheckInSheet(
        storeName: selectedStore?.name,
        onCheckIn: { mode in
            Task {
                await viewModel.checkIn(
                    storeId: selectedStore?.id ?? "mock-store-id",
                    mode: mode
                )
            }
        }
    )
}

// Change button action
Button("Check In") {
    showingStoreSelector = true  // Not showingCheckIn!
}
```

**3. Update CheckInSheet to show store**:
```swift
struct CheckInSheet: View {
    let storeName: String?
    let onCheckIn: (ConnectionMode) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                if let storeName = storeName {
                    Text("Checking in at")
                        .font(.brandSans(14))
                        .foregroundStyle(.secondary)
                    Text(storeName)
                        .font(.brandSans(20, weight: .bold))
                }
                
                // Mode selection...
            }
        }
    }
}
```

---

## Issue 2: Missing iOS 26 Liquid Glass Design ⚠️

### Current Problem

App claims to use "iOS 26 Liquid Glass" design but lacks key visual elements:
1. ❌ No glass-morphic buttons
2. ❌ Tab bar is plain, not translucent
3. ❌ Text fields are standard, not premium
4. ❌ No blur effects on cards
5. ❌ Missing depth and layering

### What iOS 26 Liquid Glass Should Include

#### 1. Glass Buttons (Primary Actions)

**Current**:
```swift
Button("Check In") { ... }
    .font(.brandSans(16, weight: .semibold))
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, Spacing.md)
    .background(Color.forestCanopy, in: Capsule())
```

**Should Be**:
```swift
Button("Check In") { ... }
    .font(.brandSans(16, weight: .semibold))
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, Spacing.md)
    .background {
        // Liquid Glass effect
        ZStack {
            // Base layer
            Color.forestCanopy
            
            // Glass gradient overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.white.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Inner glow
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
    }
    .clipShape(Capsule())
    .shadow(color: Color.forestCanopy.opacity(0.4), radius: 12, y: 6)
```

#### 2. Tab Bar with Liquid Glass

**Current**: Plain tab bar  
**Should Be**: Translucent with blur

```swift
// In main app
TabView {
    // tabs...
}
.toolbarBackground(.ultraThinMaterial, for: .tabBar)
.toolbarBackground(.visible, for: .tabBar)
```

Or custom tab bar:
```swift
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background {
            // Liquid Glass background
            ZStack {
                .ultraThinMaterial
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .overlay(alignment: .top) {
            // Top edge highlight
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 0.5)
        }
        .ignoresSafeArea()
    }
}
```

#### 3. Premium Text Fields

**Current**: Standard TextField  
**Should Be**: Liquid glass with floating label

```swift
struct LiquidGlassTextField: View {
    let title: String
    @Binding var text: String
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.brandSans(12, weight: .medium))
                .foregroundStyle(isFocused ? Color.forestCanopy : .secondary)
                .offset(y: text.isEmpty && !isFocused ? 24 : 0)
                .animation(.spring(duration: 0.3), value: isFocused)
            
            TextField("", text: $text)
                .font(.brandSans(16))
                .focused($isFocused)
                .padding()
                .background {
                    ZStack {
                        // Glass background
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                        
                        // Border
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isFocused ?
                                    LinearGradient(
                                        colors: [
                                            Color.forestCanopy.opacity(0.6),
                                            Color.forestCanopy.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.2)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                lineWidth: isFocused ? 2 : 1
                            )
                    }
                }
        }
    }
}
```

#### 4. Card Components with Glass Effect

**Current**: Plain backgrounds  
**Should Be**: Layered glass with depth

```swift
struct LiquidGlassCard<Content: View>: View {
    let content: () -> Content
    
    var body: some View {
        content()
            .padding(Spacing.md)
            .background {
                ZStack {
                    // Base glass
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                    
                    // Gradient overlay
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Edge highlight
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
    }
}
```

### Files That Need Updating

1. **Core/DesignSystem/LiquidGlassComponents.swift** (NEW):
   - LiquidGlassButton
   - LiquidGlassCard
   - LiquidGlassTextField
   - LiquidGlassTabBar

2. **App/thecoffeelinks_client_iosApp.swift**:
   - Add custom tab bar with liquid glass
   - Or apply `.toolbarBackground(.ultraThinMaterial)`

3. **Features/Connect/ConnectView.swift**:
   - Replace plain buttons with LiquidGlassButton
   - Apply glass effect to status cards

4. **Features/Menu/MenuView.swift**:
   - Product cards with glass effect
   - Category pills with glass

5. **Features/Cart/CartView.swift**:
   - Cart items with glass cards
   - Checkout button with liquid glass

6. **Features/Auth/LoginView.swift**:
   - Text fields with liquid glass
   - Login button with glass effect

### Design System Color Updates

The Sequoia Forest palette exists but needs glass overlay colors:

```swift
// Add to DesignSystem.swift
extension Color {
    // Liquid Glass overlays
    static let glassHighlight = Color.white.opacity(0.3)
    static let glassMidtone = Color.white.opacity(0.15)
    static let glassShadow = Color.black.opacity(0.1)
    
    // Glass borders
    static let glassBorderLight = Color.white.opacity(0.4)
    static let glassBorderDark = Color.white.opacity(0.2)
}
```

---

## Priority & Effort

| Issue | Priority | Effort | Impact |
|-------|----------|--------|--------|
| Store Selection | 🔴 High | Medium | Users can't actually check in |
| Liquid Glass Design | 🟡 Medium | High | Visual polish, brand differentiation |

### Recommended Approach

**Phase 1 (Critical)**:
1. Implement StoreSelectionSheet
2. Wire to ConnectView check-in flow
3. Test end-to-end check-in

**Phase 2 (Polish)**:
1. Create LiquidGlassComponents.swift
2. Update primary buttons
3. Add glass tab bar
4. Update text fields
5. Apply to all cards

---

## Testing Checklist

### Store Selection
- [ ] "Check In" shows store list
- [ ] Can select store
- [ ] Store name shows in CheckInSheet
- [ ] Check-in works with selected store
- [ ] Nearby users load for that store

### Liquid Glass
- [ ] Buttons have glass gradient
- [ ] Tab bar is translucent
- [ ] Cards have depth and blur
- [ ] Text fields have glass border
- [ ] Animations feel smooth (60fps)
- [ ] Dark mode looks good
- [ ] Accessibility not broken

---

## Notes

Both issues are **user-facing** and affect the app's:
1. **Functionality** (store selection is broken)
2. **Brand perception** (claims iOS 26 design but looks basic)

The store selection is a **blocker** for the Connect feature.  
The liquid glass is **polish** but important for premium feel.

---

*Created: 2026-01-16 00:45 UTC*  
*Status: Documented, awaiting implementation*
