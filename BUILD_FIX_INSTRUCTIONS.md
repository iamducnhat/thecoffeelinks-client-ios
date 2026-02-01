# Build Fix Instructions

## Issue Summary

The new Design System v2 components have been created but are not yet added to the Xcode project target, causing build errors.

## Files Created (Not Yet in Target)

The following files exist but need to be added to the TheCoffeeLinks target:

```
TheCoffeeLinks/Core/DesignSystem/v2/
├── Colors.swift
├── Tokens.swift
├── CapsuleButton.swift
├── CapsuleTextField.swift
├── CapsuleSegmentedPicker.swift
├── SectionHeader.swift
└── ListRow.swift
```

## Refactored View Files (Already in Target)

These files exist and should already be in the target:

```
TheCoffeeLinks/Features/Auth/LoginView_v2.swift
TheCoffeeLinks/Features/Menu/MenuView_v2.swift
TheCoffeeLinks/Features/Profile/ProfileView_v2.swift
TheCoffeeLinks/Features/Stores/StoresView_v2.swift
```

## How to Fix in Xcode

### Option 1: Add Files to Project (Recommended)

1. Open `TheCoffeeLinks.xcodeproj` in Xcode
2. In Project Navigator, right-click on `Core/DesignSystem`
3. Select "Add Files to TheCoffeeLinks..."
4. Navigate to `TheCoffeeLinks/Core/DesignSystem/v2/`
5. Select all `.swift` files
6. **IMPORTANT**: Check "Add to targets: TheCoffeeLinks"
7. Click "Add"
8. Build the project (⌘B)

### Option 2: Drag and Drop

1. Open Finder and navigate to the `v2` folder
2. Open Xcode with the project
3. Drag the `v2` folder into the Project Navigator under `Core/DesignSystem`
4. In the dialog:
   - ✅ Check "Copy items if needed" (NO - files are already in place)
   - ✅ Check "Create groups"
   - ✅ Check "Add to targets: TheCoffeeLinks"
5. Click "Finish"
6. Build the project (⌘B)

## Expected Result

After adding the files, the build should succeed with no errors. The v2 components will then be available for use throughout the app.

## Migration Plan

Once the v2 components build successfully:

1. **Test the v2 views** in Xcode Previews
2. **Gradually migrate** existing views to use v2 components
3. **Replace** old view files once v2 versions are tested:
   - `LoginView.swift` → `LoginView_v2.swift`
   - `MenuView.swift` → `MenuView_v2.swift`
   - `ProfileView.swift` → `ProfileView_v2.swift`
   - `StoresView.swift` → `StoresView_v2.swift`

## Quick Verification

Run this in terminal to verify files exist:
```bash
cd /Users/nguyenducnhat/appcafe/thecoffeelinks-client-ios
ls -l TheCoffeeLinks/Core/DesignSystem/v2/*.swift
ls -l TheCoffeeLinks/Features/*/​*_v2.swift
```

## Additional Notes

- The v2 design system follows the capsule-based, Apple-native design principles
- Dark mode colors: black/grey/white only (no accent colors)
- All components include SwiftUI previews for quick iteration
- Components are designed to replace 13+ button variants and multiple input styles with 3 unified patterns
