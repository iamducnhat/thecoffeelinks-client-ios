# Design System Audit & Refactor Proposal

**Date:** February 1, 2026  
**Scope:** TheCoffeeLinks iOS SwiftUI App  
**Author:** Senior iOS Architect Review

---

## Executive Summary

The current codebase has **three competing design paradigms**:
1. **Receipt-Editorial** (Checkout-derived, 4pt corners, 18pt grid)
2. **Editorial** (Magazine-style, mixed corners 0-12pt)
3. **LiquidGlass** (iOS 26 inspired, 12-20pt corners, material backgrounds)

This creates visual inconsistency and maintenance burden. This document proposes a **unified capsule-based, Apple-native design system** with dark mode support (black/grey/white only, no accent color).

---

## Part 1: Current State Analysis

### 1.1 Design System Files Identified

| File | Purpose | Issues |
|------|---------|--------|
| `Color+DesignSystem.swift` | Color tokens | Coffee-themed colors (espresso, cream) - needs neutral palette |
| `Font+DesignSystem.swift` | Typography | Custom fonts (Geologica, Noto Sans Mono) - good |
| `Layout+DesignSystem.swift` | Spacing/layout | 18pt grid, 4pt corners - needs capsule option |
| `Buttons.swift` | Button components | 5+ button styles, inconsistent |
| `DesignComponents.swift` | Legacy wrappers | Duplicates Editorial |
| `EditorialLayout.swift` | Compatibility layer | Wraps AppLayout - redundant |
| `LiquidGlassComponents.swift` | Glass effects | 12pt corners, conflicts with Receipt |
| `Inputs.swift` | Text fields | 12pt corners - inconsistent |
| `Components/AppButton.swift` | Generic button | Yet another button variant |
| `Components/AppCard.swift` | Card wrapper | Uses 4pt corners |
| `Components/AppInput.swift` | Input wrapper | Uses 4pt corners |

### 1.2 Inconsistencies Found

#### Corner Radius Chaos
```
Found values: 0pt, 2pt, 4pt, 8pt, 12pt, 16pt, 20pt
Should be: Unified (Capsule or single value)
```

#### Color System Conflicts
- `Color.primaryEspresso` (accent) vs `Color.accentColor` (system)
- `Editorial.Colors.*` duplicates `Color.*` extensions
- Coffee-themed colors don't support black/grey/white constraint

#### Button Proliferation
| Component | Location | Shape |
|-----------|----------|-------|
| `ReceiptPrimaryButton` | Buttons.swift | 4pt rounded |
| `ReceiptUtilityButton` | Buttons.swift | 4pt rounded |
| `ReceiptStepperButton` | Buttons.swift | 4pt rounded |
| `ReceiptIconButton` | Buttons.swift | 4pt rounded |
| `PrimaryButton` | Buttons.swift | 4pt rounded (legacy) |
| `SecondaryButton` | Buttons.swift | 4pt rounded (legacy) |
| `GhostButton` | Buttons.swift | 4pt rounded |
| `LiquidGlassButton` | LiquidGlassComponents.swift | 12pt rounded |
| `GlassPrimaryButton` | DesignComponents.swift | Wraps Editorial |
| `GlassSecondaryButton` | DesignComponents.swift | Wraps Editorial |
| `EditorialButton` | EditorialLayout.swift | Wraps Receipt |
| `EditorialSecondaryButton` | EditorialLayout.swift | 4pt rounded |
| `AppButton` | Components/AppButton.swift | 4pt rounded |

**13 button components for ~3 visual styles.**

#### Spacing Inconsistencies
- `AppLayout.spacing` = 18pt
- `Editorial.Spacing.gutter` = 12pt
- Hardcoded values: 4, 6, 8, 12, 16, 20, 24, 32, 48pt

---

## Part 2: Unified Design System Proposal

### 2.1 Design Principles

1. **Capsule-First**: All interactive elements use capsule (pill) shape
2. **Black/Grey/White Only**: Neutral dark mode palette
3. **One Primary Per Screen**: Single liquid-glass primary button
4. **Apple-Native Components**: Prefer system components where possible
5. **Minimal Custom Tokens**: Only what SwiftUI doesn't provide

### 2.2 Color Palette (Dark Mode)

```swift
// PROPOSED: Neutral palette
extension Color {
    // Backgrounds
    static let bgPrimary = Color.black           // #000000
    static let bgSecondary = Color(white: 0.1)   // #1A1A1A
    static let bgTertiary = Color(white: 0.15)   // #262626
    
    // Surfaces (Cards, Sheets)
    static let surfacePrimary = Color(white: 0.12)  // #1F1F1F
    static let surfaceElevated = Color(white: 0.18) // #2E2E2E
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)    // #B3B3B3
    static let textTertiary = Color(white: 0.5)     // #808080
    static let textDisabled = Color(white: 0.35)    // #595959
    
    // Borders
    static let borderPrimary = Color(white: 0.25)   // #404040
    static let borderSecondary = Color(white: 0.15) // #262626
    
    // States (Keep minimal semantic colors)
    static let stateError = Color.red
    static let stateSuccess = Color.green
}
```

### 2.3 Typography (Keep Current)

Current Geologica + Noto Sans Mono setup is good. Simplify tokens:

```swift
struct AppTypography {
    // Display
    static let displayLarge = Font.custom("GeologicaThinRoman-Bold", size: 28)
    static let displayMedium = Font.custom("GeologicaThinRoman-Medium", size: 22)
    
    // Body
    static let bodyLarge = Font.custom("GeologicaThinRoman-Regular", size: 17)
    static let bodyMedium = Font.custom("GeologicaThinRoman-Regular", size: 15)
    static let bodySmall = Font.custom("GeologicaThinRoman-Regular", size: 13)
    
    // Mono (Prices, Codes)
    static let monoLarge = Font.custom("NotoSansMono-Medium", size: 22)
    static let monoMedium = Font.custom("NotoSansMono-Regular", size: 17)
    static let monoSmall = Font.custom("NotoSansMono-Regular", size: 13)
    
    // Labels
    static let labelLarge = Font.custom("GeologicaThinRoman-Medium", size: 17)
    static let labelMedium = Font.custom("GeologicaThinRoman-Medium", size: 15)
    static let labelSmall = Font.custom("GeologicaThinRoman-Medium", size: 12)
}
```

### 2.4 Layout & Spacing

```swift
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    
    static let screenPadding: CGFloat = 16
    static let sectionGap: CGFloat = 24
}

struct AppRadius {
    static let small: CGFloat = 8       // Chips, tags
    static let medium: CGFloat = 12     // Cards, inputs
    static let large: CGFloat = 16      // Sheets
    static let capsule: CGFloat = 9999  // Buttons (full capsule)
}
```

### 2.5 Button Hierarchy (Capsule-Based)

```swift
// PROPOSED: 3 button types only
enum CapsuleButtonStyle {
    case primary    // Liquid glass, white text, one per screen
    case secondary  // Bordered capsule, grey outline
    case ghost      // Text only, no background
}

struct CapsuleButton: View {
    let title: String
    let style: CapsuleButtonStyle
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            content
                .frame(height: 48)
                .frame(maxWidth: style == .ghost ? nil : .infinity)
                .background(background)
                .clipShape(Capsule())
                .overlay(border)
        }
        .disabled(isLoading)
    }
    
    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            // Liquid glass effect
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(Color.white.opacity(0.15))
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        case .secondary:
            Color.clear
        case .ghost:
            Color.clear
        }
    }
    
    @ViewBuilder
    private var border: some View {
        if style == .secondary {
            Capsule().stroke(Color.borderPrimary, lineWidth: 1)
        }
    }
}
```

### 2.6 Card Component

```swift
struct AppCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppSpacing.lg
    
    var body: some View {
        content
            .padding(padding)
            .background(Color.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .stroke(Color.borderSecondary, lineWidth: 0.5)
            )
    }
}
```

### 2.7 Input Component

```swift
struct CapsuleTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(Color.textTertiary)
            }
            TextField(placeholder, text: $text)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 48)
        .background(Color.surfacePrimary)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.borderPrimary, lineWidth: 0.5))
    }
}
```

---

## Part 3: Screen Refactor Priority

### Priority 1: Critical Path (User-Facing Flow)
| Screen | File | Issues | Effort |
|--------|------|--------|--------|
| **Checkout** | CheckoutView.swift | Reference screen, already Receipt style | Low |
| **Cart** | CartView.swift | Matches Checkout | Low |
| **Menu** | MenuView.swift | Dashed borders, 4pt corners | Medium |
| **Product Detail** | ProductDetailSheet | Mixed button styles | Medium |
| **Login/Signup** | LoginView.swift | Tab switcher, form inputs | High |

### Priority 2: Main Tabs
| Screen | File | Issues | Effort |
|--------|------|--------|--------|
| **Home** | HomeView.swift | Section headers, promotions | Medium |
| **Stores** | StoresView.swift | List/Map toggle, store cards | Medium |
| **Profile** | ProfileView.swift | Section rows, metric boxes | Medium |
| **Promotions** | PromotionsView.swift | Member card, guest state | Medium |

### Priority 3: Secondary Screens
| Screen | File | Issues | Effort |
|--------|------|--------|--------|
| Orders | OrdersView.swift | Tab buttons, order rows | Low |
| Order Detail | OrderDetailView.swift | Receipt layout | Low |
| Store Detail | StoreDetailView.swift | Full-screen cover | Medium |
| Settings | SecurityView.swift, NotificationsView.swift | List rows | Low |

### Priority 4: Onboarding
| Screen | File | Issues | Effort |
|--------|------|--------|--------|
| Carousel | ValuePropositionCarousel.swift | Custom design | High |
| Setup | InitialSetupView.swift | Permission tiles, quiz | Medium |

---

## Part 4: Component Extraction Suggestions

### 4.1 Delete/Deprecate (Redundant)

```
❌ DesignComponents.swift → GlassCard, GlassPrimaryButton, GlassSecondaryButton
❌ EditorialLayout.swift → Editorial struct (use Color/AppLayout directly)
❌ Buttons.swift → Legacy wrappers (PrimaryButton, SecondaryButton)
❌ LiquidGlassComponents.swift → LiquidGlassCard, LiquidGlassButton (merge into new system)
```

### 4.2 Consolidate Into New Components

| New Component | Replaces | Location |
|---------------|----------|----------|
| `CapsuleButton` | ReceiptPrimaryButton, EditorialButton, AppButton, LiquidGlassButton | `Core/DesignSystem/Components/` |
| `CapsuleTextField` | EditorialTextField, AppInput, BrandTextField, AuthTextField | `Core/DesignSystem/Components/` |
| `CapsuleSegmentedPicker` | tabSwitcher, OrderTabButton, StoreViewMode toggle | `Core/DesignSystem/Components/` |
| `SectionHeader` | Various inline headers | `Core/DesignSystem/Components/` |
| `ListRow` | ProfileRow, SelectableRow, PermissionTile | `Core/DesignSystem/Components/` |
| `MetricCard` | MetricBox | `Core/DesignSystem/Components/` |

### 4.3 Keep & Refactor

| Component | Action |
|-----------|--------|
| `AppCard` | Update to use `AppRadius.medium` |
| `QuantityStepper` | Keep, update colors |
| `Badge` | Keep, update to capsule shape |
| `SkeletonView` | Keep, update colors |
| `EmptyStateView` | Keep, minor styling |

---

## Part 5: Implementation Roadmap

### Phase 1: Foundation (Week 1)
1. Create `Core/DesignSystem/v2/` directory
2. Implement new color palette (`Colors.swift`)
3. Implement unified spacing/radius (`Tokens.swift`)
4. Create `CapsuleButton`, `CapsuleTextField`

### Phase 2: Core Components (Week 2)
1. Create `CapsuleSegmentedPicker`
2. Create `SectionHeader`, `ListRow`
3. Update `AppCard` to new system
4. Create view modifiers for common patterns

### Phase 3: Critical Path Migration (Week 3)
1. Refactor CheckoutView (reference implementation)
2. Refactor CartView
3. Refactor LoginView
4. Refactor MenuView

### Phase 4: Full Migration (Week 4-5)
1. Migrate remaining screens
2. Delete deprecated components
3. Update preview providers
4. Documentation

---

## Part 6: File Structure Proposal

```
Core/DesignSystem/
├── Tokens/
│   ├── Colors.swift          // Neutral black/grey/white palette
│   ├── Typography.swift      // Font tokens (keep current)
│   └── Spacing.swift         // Unified spacing + radius
├── Components/
│   ├── CapsuleButton.swift   // Primary/Secondary/Ghost
│   ├── CapsuleTextField.swift
│   ├── CapsuleSegmentedPicker.swift
│   ├── AppCard.swift         // Updated
│   ├── SectionHeader.swift
│   ├── ListRow.swift
│   ├── MetricCard.swift
│   └── QuantityStepper.swift // Updated
├── Modifiers/
│   ├── CardModifier.swift
│   └── SectionModifier.swift
└── Legacy/                   // Temporary during migration
    ├── Buttons.swift
    ├── DesignComponents.swift
    └── EditorialLayout.swift
```

---

## Part 7: Quick Reference Card

### Button Usage

```swift
// Primary CTA (ONE per screen) - Liquid glass capsule
CapsuleButton("Place Order", style: .primary) { placeOrder() }

// Secondary actions - Bordered capsule
CapsuleButton("Add Voucher", style: .secondary) { showVouchers() }

// Tertiary/inline - Ghost text
CapsuleButton("Cancel", style: .ghost) { dismiss() }
```

### Spacing Rules

```swift
// Screen edge padding
.padding(.horizontal, AppSpacing.screenPadding)  // 16pt

// Between sections
VStack(spacing: AppSpacing.sectionGap)  // 24pt

// Within sections
VStack(spacing: AppSpacing.md)  // 12pt

// Tight groups
HStack(spacing: AppSpacing.sm)  // 8pt
```

### Color Rules

```swift
// Backgrounds
Color.bgPrimary      // Screen background (black)
Color.surfacePrimary // Cards, sheets

// Text
Color.textPrimary    // Main content (white)
Color.textSecondary  // Labels, descriptions
Color.textTertiary   // Placeholders, disabled

// Borders
Color.borderPrimary  // Active elements
Color.borderSecondary // Subtle separators
```

---

## Appendix: Current Screen Audit

### HomeView.swift
- ✅ Uses AppLayout.spacing
- ✅ Uses Color.backgroundPaper
- ⚠️ Uses Color.primaryEspresso (accent)
- ⚠️ AI modal has custom blur overlay

### CheckoutView.swift
- ✅ Reference Receipt-Editorial implementation
- ⚠️ Uses 4pt corners throughout
- ⚠️ Custom scroll offset header animation

### LoginView.swift
- ⚠️ Custom tab switcher (should be CapsuleSegmentedPicker)
- ⚠️ Uses Color.primaryEspresso for active tab
- ⚠️ AuthTextField is screen-specific

### MenuView.swift
- ⚠️ Dashed border search field
- ⚠️ CategoryNode uses 4pt corners
- ⚠️ ProductCard image has 4pt corners

### ProfileView.swift
- ✅ Good section structure
- ⚠️ MetricBox should be unified
- ⚠️ ProfileRow duplicates ListRow pattern

### StoresView.swift
- ⚠️ View mode toggle should use CapsuleSegmentedPicker
- ⚠️ Search field duplicates MenuView pattern

---

**End of Design System Audit**
