# Xcode Target Membership Fix

## Issue
Files exist on disk but Xcode can't find types:
- ✅ `DesignSystemV2.swift` exists with all v2 components
- ❌ LoginView_v2 can't find `Color.bgPrimary`, `AppSpacing`, `CapsuleSegmentedPicker`
- ❌ APIModels.swift can't find `Menu`, `Product`, `Order` from other model files

## Root Cause
Files are not added to the correct Xcode build target, so Swift compiler doesn't compile them together.

## Fix Steps

### 1. Verify DesignSystemV2.swift Target Membership

In Xcode:
1. Select `DesignSystemV2.swift` in Project Navigator
2. Open File Inspector (⌘⌥1) on the right sidebar
3. Look for "Target Membership" section
4. **✅ Check "TheCoffeeLinks"** (main app target)
5. Build (⌘B) to confirm it compiles

### 2. Verify All Model Files Have Target Membership

Check these files have "TheCoffeeLinks" target checked:
- `TheCoffeeLinks/Domain/Models/ProductModels.swift`
- `TheCoffeeLinks/Domain/Models/OrderModels.swift`
- `TheCoffeeLinks/Domain/Models/APIModels.swift`
- `TheCoffeeLinks/Domain/Models/DeliveryModels.swift` (if exists)

### 3. Verify All v2 View Files Have Target Membership

Check these files:
- `TheCoffeeLinks/Features/Auth/LoginView_v2.swift`
- `TheCoffeeLinks/Features/Menu/MenuView_v2.swift`
- `TheCoffeeLinks/Features/Profile/ProfileView_v2.swift`
- `TheCoffeeLinks/Features/Stores/StoresView_v2.swift`

### 4. Clean Build Folder

After confirming target membership:
1. Product → Clean Build Folder (⇧⌘K)
2. Product → Build (⌘B)
3. All errors should resolve

## Expected Result

After adding all files to target:
- ✅ DesignSystemV2.swift compiles (already confirmed)
- ✅ All v2 views compile (MenuView_v2, ProfileView_v2, StoresView_v2 already work)
- ✅ LoginView_v2 should compile
- ✅ APIModels.swift should compile

## Files Status

### ✅ Working (no errors)
- `Core/DesignSystem/DesignSystemV2.swift` - 364 lines, all components consolidated
- `Features/Menu/MenuView_v2.swift`
- `Features/Profile/ProfileView_v2.swift`
- `Features/Stores/StoresView_v2.swift`

### ❌ Not Finding Dependencies
- `Features/Auth/LoginView_v2.swift` - can't find DesignSystemV2 types
- `Domain/Models/APIModels.swift` - can't find ProductModels/OrderModels types

## Alternative: Manual File Re-Add

If target membership is checked but still errors:

1. **Remove references** (keep files):
   - Right-click file → Delete → "Remove Reference" (NOT "Move to Trash")
   
2. **Re-add files**:
   - Right-click folder → Add Files to "TheCoffeeLinks"
   - Select files
   - ✅ Check "Copy items if needed"
   - ✅ Check "TheCoffeeLinks" under "Add to targets"
   - Click Add

3. **Clean and rebuild**:
   - ⇧⌘K (Clean Build Folder)
   - ⌘B (Build)

## Test After Fix

Run these in Xcode Previews to verify:
```swift
// Should preview successfully:
LoginView_v2()
MenuView_v2()
ProfileView_v2()
StoresView_v2()
```

## Notes

- ✅ v2 folder deleted (was causing duplicate definition errors)
- ✅ Using consolidated DesignSystemV2.swift (single file approach)
- ✅ Black/grey/white color palette
- ✅ Capsule-first UI components
- ✅ Liquid-glass primary button style

The code is correct - this is purely an Xcode project configuration issue.
