# Product Card UI Redesign Proposal

## Current State Analysis

### List-Style Card (Popular Section - HomeView)
**Current Implementation:**
```
┌─────────────────────────────────────────────┐
│ [80x80 Image]  Product Name (18pt Bold)    │
│                                             │
│                12.000₫ (17pt Mono)          │
│                                        [+]  │
└─────────────────────────────────────────────┘
```

**Issues:**
- Button placement feels tacked on, not integrated
- Price and name compete for attention equally
- No clear visual weight/hierarchy
- Spacing between image and text could be more intentional
- The "+" button lacks emphasis despite being primary action

### Grid-Style Card (Menu Section - MenuView)
**Current Implementation:**
```
┌─────────────────┐
│                 │
│  [Square Image] │
│                 │
├─────────────────┤
│ Product Name    │
│ (17pt Medium)   │
│                 │
│ 12.000₫         │
│ (17pt Mono)     │
└─────────────────┘
```

**Issues:**
- Generic catalog feel - could be any e-commerce grid
- No differentiation from generic product listings
- Price given equal weight to name
- No clear touch affordance (where to tap?)
- Lacks personality of a coffee ordering experience

---

## Redesign Proposal

### Design Principles
1. **Image as emotional anchor** (especially grid)
2. **Name is hero, price is supporting**
3. **Actions feel intentional, not generic**
4. **Touch-friendly without being heavy**
5. **Consistent shape language: soft rounded rectangles (4pt radius)**

---

## List-Style Card (Popular) - Redesigned

### Purpose
Quick-scan browsing with **fast add** functionality. Optimized for speed and efficiency.

### Layout Structure
```
┌──────────────────────────────────────────────────────────┐
│  ┌───────┐                                               │
│  │       │  Product Name                           [Add] │
│  │ Image │  (18pt Bold, Black)                      CTA  │
│  │ 80x80 │                                               │
│  │       │  12.000₫                                      │
│  └───────┘  (15pt Mono, Grey/60%)                        │
└──────────────────────────────────────────────────────────┘
       ↑ 4pt radius            ↑ Clear hierarchy    ↑ Capsule
```

### Key Changes

#### 1. Visual Hierarchy
- **Product name**: Bold, 18pt (Geologica Bold) - Primary focus
- **Price**: 15pt mono (reduced from 17pt), grey @ 60% opacity - Supporting info
- Clear visual separation between name and price (tighter leading)

#### 2. Image Treatment
- Keep 80x80 square
- 4pt corner radius (aligned with receipt aesthetic)
- 12pt spacing to text (increased from implicit spacing)

#### 3. Add Button Redesign
**From:** Generic "+" in circle
**To:** Capsule button with intentional feel

```
┌─────────────┐
│    Add      │  ← Capsule shape
│  (Icon+Text)│  ← Black bg / White text
└─────────────┘  ← 4pt padding inside
```

- **Style**: Capsule (9999pt radius)
- **Background**: Black (80% opacity in light mode)
- **Text**: "Add" + optional plus icon
- **Font**: 15pt Geologica Medium
- **Padding**: 12pt horizontal, 8pt vertical
- **Size**: Auto-width capsule (not fixed circle)

#### 4. Spacing & Padding
- **Card padding**: 18pt (AppLayout.spacing)
- **Image → Text gap**: 12pt
- **Name → Price gap**: 4pt (tight stack)
- **Between cards**: Divider with 18pt vertical padding

---

## Grid-Style Card (Menu) - Redesigned

### Purpose
Browsing with **visual discovery**. Image is hero, tap-to-detail.

### Layout Structure
```
┌────────────────────┐
│                    │
│                    │
│   [Square Image]   │
│   (Fills width)    │
│                    │
├────────────────────┤  ← Subtle divider or tight spacing
│                    │
│  Product Name      │
│  (17pt Bold)       │
│                    │
│  12.000₫           │
│  (15pt Mono, Grey) │
│                    │
└────────────────────┘
    ↑ 4pt radius on card
```

### Key Changes

#### 1. Card Container
- **Background**: White card with 4pt corner radius
- **Border**: 1pt solid border (Color.borderPrimary)
- **Shadow**: Subtle elevation (optional: 0.5pt radius, black @ 5%)

#### 2. Visual Hierarchy
- **Image**: Full-width, aspect ratio 1:1, top-aligned
- **Name**: Bold, 17pt (Geologica Bold) - **upgraded from Medium to Bold**
- **Price**: 15pt mono (reduced from 17pt), grey @ 60%

#### 3. Content Padding
- **Image**: No padding (edge-to-edge in card top)
- **Text section**: 12pt padding all sides
- **Name → Price gap**: 6pt

#### 4. Add Action - Subtle, Non-Distracting
**Key Insight**: Grid cards are tap-to-detail, so add button should be secondary

**Option A: No visible button**
- Entire card is tappable → opens detail sheet
- Sheet has prominent "Add to Cart" action
- Keeps card clean, image-focused

**Option B: Subtle corner indicator** (if add-from-grid is required)
```
┌────────────────────┐
│  [Image]        ⊕  │  ← Small plus in corner
│                    │     (appears on press/hover)
└────────────────────┘
```
- Small 24pt circle, black bg, white "+"
- Position: Top-right corner, 8pt inset
- Opacity: 0 normally, appears on long-press
- Non-intrusive, doesn't compete with image

**Recommendation**: Option A (tap-to-detail) for cleaner, more premium feel

---

## Typography Scale Adjustments

### Current → Proposed

| Element | Current | Proposed | Reasoning |
|---------|---------|----------|-----------|
| **List Name** | 18pt Bold | 18pt Bold | Keep - already strong |
| **List Price** | 17pt Mono | 15pt Mono | Reduce - de-emphasize |
| **Grid Name** | 17pt Medium | 17pt Bold | Upgrade - needs more weight |
| **Grid Price** | 17pt Mono | 15pt Mono | Reduce - supporting role |

**Color Adjustments:**
- **Name**: Always `Color.textPrimary` (black/white)
- **Price**: `Color.textSecondary` at 0.6 opacity (softer grey)

---

## Implementation Notes

### 1. Spacing Constants (Already Defined)
```swift
AppLayout.spacing              // 18pt - standard gaps
AppLayout.spacingMedium        // 12pt - image-to-text
AppLayout.spacingCompact       // 8pt - button padding
AppLayout.spacingSmall         // 6pt - name-to-price
AppLayout.cornerRadius         // 4pt - all rounded corners
```

### 2. Shape Consistency
- **Cards**: RoundedRectangle(4pt, .continuous)
- **Images**: RoundedRectangle(4pt, .continuous)
- **Buttons**: Capsule() only
- **Never mix**: No circles + rounded rectangles in same component

### 3. Color Palette
```swift
// Backgrounds
.surfacePrimary          // Card background
.bgPrimary               // Screen background

// Text
.textPrimary             // Product name (black/white)
.textSecondary           // Price (grey)

// Actions
Color.black.opacity(0.8) // Add button bg (light mode)
.white                   // Add button text

// Borders
.borderPrimary           // Card stroke (1pt)
```

### 4. Touch Targets
- **Minimum**: 44pt (AppLayout.touchTarget)
- **List add button**: ~48pt height (capsule)
- **Grid card**: Entire card tappable

---

## Visual Consistency Rules

### Between List & Grid Cards

| Aspect | List Card | Grid Card | Consistency |
|--------|-----------|-----------|-------------|
| **Shape** | 4pt rounded | 4pt rounded | ✅ Same |
| **Name Weight** | Bold | Bold | ✅ Same |
| **Price Size** | 15pt | 15pt | ✅ Same |
| **Price Color** | Grey/60% | Grey/60% | ✅ Same |
| **Image Radius** | 4pt | 4pt | ✅ Same |
| **Action Style** | Capsule button | Tap-to-detail | ⚠️ Different purpose |

### Purposeful Differences
- **List**: Horizontal layout, prominent add button (quick action)
- **Grid**: Vertical layout, tap-to-detail (discovery first)

---

## SwiftUI Implementation Outline

### List Card (PopularProductCard)

```swift
struct PopularProductCard: View {
    let product: PopularProduct
    var showDivider: Bool = true
    @EnvironmentObject var cartViewModel: CartViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppLayout.spacingMedium) { // 12pt gap
                // Image
                CachedAsyncImage(url: URL(string: product.product.displayImageUrl ?? "")) { phase in
                    // ... image loading states
                }
                .frame(width: AppLayout.productImageSize, height: AppLayout.productImageSize)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous))
                
                // Text Stack
                VStack(alignment: .leading, spacing: AppLayout.spacingSmall) { // 6pt gap
                    Text(product.product.name)
                        .font(.custom("GeologicaThinRoman-Bold", size: 18))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                    
                    Text(product.product.price(for: .medium).toVND())
                        .font(.custom("NotoSansMono-Regular", size: 15))
                        .foregroundStyle(Color.textSecondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Add Button
                Button {
                    cartViewModel.addItem(product: product.product, quantity: 1, customization: .default)
                } label: {
                    Text("Add")
                        .font(.custom("GeologicaThinRoman-Medium", size: 15))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppLayout.spacingMedium)
                        .padding(.vertical, AppLayout.spacingCompact)
                        .background(Color.black.opacity(0.8))
                        .clipShape(Capsule())
                }
            }
            .padding(AppLayout.spacing)
            
            if showDivider {
                Divider()
                    .padding(.horizontal, AppLayout.spacing)
            }
        }
    }
}
```

### Grid Card (ProductCard)

```swift
struct ProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image (full-width, edge-to-edge)
            GeometryReader { geo in
                let size = geo.size.width
                AsyncImage(url: URL(string: product.displayImageUrl ?? "")) { phase in
                    // ... image loading states
                }
                .frame(width: size, height: size)
                .clipped()
            }
            .aspectRatio(1, contentMode: .fit)
            
            // Text Content
            VStack(alignment: .leading, spacing: AppLayout.spacingSmall) { // 6pt gap
                Text(product.name)
                    .font(.custom("GeologicaThinRoman-Bold", size: 17))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                
                if let mediumPrice = product.sizeOptions.first(where: { $0.size == .medium })?.price {
                    Text(mediumPrice.formattedVND)
                        .font(.custom("NotoSansMono-Regular", size: 15))
                        .foregroundStyle(Color.textSecondary.opacity(0.6))
                }
            }
            .padding(AppLayout.spacingMedium)
        }
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius, style: .continuous)
                .strokeBorder(Color.borderPrimary, lineWidth: 1)
        )
    }
}
```

---

## Before & After Summary

### List Card (Popular)

**Before:**
- Generic "+" button
- Equal visual weight for name/price
- Loose spacing

**After:**
- Intentional "Add" capsule button
- Clear hierarchy: Bold name → muted price
- Tighter, more premium spacing
- 4pt rounded corners (receipt aesthetic)

### Grid Card (Menu)

**Before:**
- Medium weight name (too light)
- Price same size as name
- Generic catalog feel

**After:**
- Bold name (proper hierarchy)
- Reduced, muted price
- Card container with subtle border
- Image-first, tap-to-detail
- Premium, coffee-focused aesthetic

---

## Success Metrics

✅ **Clarity**: Name is undisputed hero, price is supporting
✅ **Consistency**: 4pt radius everywhere, no mixed shapes
✅ **Intentionality**: Add button feels designed, not generic
✅ **Touch-friendly**: 44pt+ targets, clear tap areas
✅ **Premium feel**: Upgraded from catalog to branded experience
✅ **No accent colors**: Black, grey, white only (as requested)
✅ **Existing data**: No new fields required

---

## Next Steps

1. **Approve design direction** (List vs Grid button approaches)
2. **Implement List Card** (PopularProductCard in HomeView.swift)
3. **Implement Grid Card** (ProductCard in MenuView.swift)
4. **Test on device** (spacing, touch targets, readability)
5. **Iterate** (adjust weights/sizes if needed)

Would you like me to proceed with the implementation?
