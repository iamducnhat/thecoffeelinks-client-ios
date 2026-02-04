# UI Consistency Rules

## Mandatory Guidelines for All SwiftUI Views

### 1. Button Shapes

**Use Capsule for:**
- Primary CTAs (full-width action buttons)
- Pill-style badges/tags
- Floating action buttons
- Tab bar indicators

**Use RoundedRectangle for:**
- Cards and containers
- Input fields
- Secondary buttons within cards
- List items
- Modal sheets

**Parameters:**
```swift
RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
// AppRadius.medium = 12pt
// ALWAYS specify style: .continuous for smoother appearance
```

---

### 2. Stroke vs StrokeBorder

**ALWAYS use `strokeBorder`:**
- Strokes are drawn inward from the shape edge
- Prevents layout shifts and alignment issues
- Maintains precise frame dimensions

**NEVER use `stroke`:**
- Strokes are drawn centered on the shape edge (half inside, half outside)
- Causes visual misalignment with padding

**Correct usage:**
```swift
.overlay(
    Capsule().strokeBorder(Color.border, lineWidth: 1)
)
```

**Incorrect:**
```swift
.overlay(
    Capsule().stroke(Color.border, lineWidth: 1)  // ❌ Wrong
)
```

---

### 3. Icon System

**Use Lucide icons (bundled assets) by default:**
- `home`
- `bag`
- `store`
- `gift`
- `menu`
- `coffee`
- `circle`
- `check`
- `photo`
- `map_pin`
- `bell`
- `heart`
- `clock`

**Use SF Symbols ONLY for:**
- `plus` (add actions)
- `minus` (subtract actions)
- `xmark` (close/dismiss)
- `chevron.left`, `chevron.right`, `chevron.down`, `chevron.up` (navigation)
- `arrow.left`, `arrow.right`, `arrow.up`, `arrow.down` (directional)

**Implementation:**
```swift
// Preferred: Use bundled assets via Image()
Image("coffee")
    .font(.system(size: 20))

// Fallback: SF Symbols for listed exceptions only
Image(systemName: "plus")
    .font(.system(size: 16, weight: .medium))
```

**IconView wrapper** (auto-fallback):
```swift
IconView(name: "coffee")  // Tries bundled first, falls back to SF Symbols
```

---

### 4. Color System

**ALWAYS use semantic tokens:**
```swift
Color.backgroundPaper     // Off-white background (light mode)
Color.textInk            // Primary text (dark chocolate)
Color.primaryEspresso    // Accent color (moss green)
Color.border             // Warm gray borders
Color.surfaceCard        // Card backgrounds
Color.textMuted          // Secondary text
Color.semanticSuccess    // Success states
Color.semanticError      // Error states
```

**NEVER hardcode colors:**
```swift
// ❌ Wrong
Color(white: 0.94)
Color(red: 0.2, green: 0.3, blue: 0.1)

// ✅ Correct
Color.backgroundPaper
```

---

### 5. Typography Tokens

**Use AppFont for all text:**
```swift
AppFont.displayTitle     // 28pt Bold (page titles)
AppFont.sectionHeader    // 22pt Medium (section headings)
AppFont.headline         // 17pt Medium (card titles)
AppFont.body             // 17pt Regular (body text)
AppFont.monoBody         // 17pt Mono (prices, codes)
AppFont.monoCTA          // CTA buttons
AppFont.uiCaption        // 13pt (captions, metadata)
```

**NEVER use inline font definitions:**
```swift
// ❌ Wrong
.font(.system(size: 17, weight: .medium))

// ✅ Correct
.font(AppFont.headline)
```

---

### 6. Spacing Tokens

**Use AppSpacing for consistent gaps:**
```swift
AppSpacing.xs = 4pt
AppSpacing.sm = 8pt
AppSpacing.md = 12pt
AppSpacing.lg = 16pt
AppSpacing.xl = 24pt

AppLayout.spacing = 16pt      // Default VStack/HStack spacing
AppLayout.spacingXL = 24pt    // Large section gaps
```

**Usage:**
```swift
VStack(spacing: AppLayout.spacing) {
    // Content
}
.padding(AppSpacing.lg)
```

---

### 7. Button Components

**Use design system components:**

**Primary CTA:**
```swift
CapsuleButton("Continue", style: .primary) {
    // Action
}
```

**Secondary:**
```swift
CapsuleButton("Cancel", style: .secondary) {
    // Action
}
```

**Ghost (text only):**
```swift
CapsuleButton("Skip", style: .ghost) {
    // Action
}
```

**Icon button:**
```swift
ReceiptIconButton(icon: "arrow.left", showBorder: true) {
    // Back action
}
```

**AVOID inline button styling:**
```swift
// ❌ Wrong - scattered styling
Button("Submit") { }
    .font(.system(size: 16, weight: .semibold))
    .foregroundColor(.white)
    .padding()
    .background(Color.blue)
    .cornerRadius(8)

// ✅ Correct - use component
CapsuleButton("Submit", style: .primary) { }
```

---

### 8. Card Layout Pattern

**Standard card structure:**
```swift
VStack(alignment: .leading, spacing: AppSpacing.md) {
    // Image (optional)
    // Title
    // Subtitle/metadata
    // Price/CTA
}
.padding(AppSpacing.lg)
.background(Color.surfaceCard)
.clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
        .strokeBorder(Color.border, lineWidth: 1)
)
```

---

### 9. Animation Consistency

**Standard durations:**
```swift
.animation(.easeInOut(duration: 0.3), value: state)  // Default
.animation(.spring(response: 0.3), value: state)     // Spring for natural feel
```

**Transitions:**
```swift
.transition(.opacity)                                // Fade
.transition(.move(edge: .trailing))                  // Slide
.transition(.asymmetric(
    insertion: .move(edge: .trailing),
    removal: .move(edge: .leading)
))
```

---

### 10. Shadow System

**Use semantic shadow tokens:**
```swift
.shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)  // Subtle card lift
.shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)   // Medium elevation
.shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8) // High elevation (modals)
```

---

### 11. Common Anti-Patterns to Avoid

**❌ Mixing shape styles:**
```swift
// Inconsistent corner radius
.cornerRadius(10)  // Some views
.cornerRadius(12)  // Other views
```

**❌ Direct padding values:**
```swift
.padding(24)  // Use AppSpacing.xl instead
```

**❌ Inline color definitions:**
```swift
.foregroundColor(Color(red: 0.1, green: 0.5, blue: 0.2))
```

**❌ Hardcoded font sizes:**
```swift
.font(.system(size: 20, weight: .bold))
```

**❌ Inconsistent icon sources:**
```swift
Image(systemName: "heart")   // Some screens
Image("heart")               // Other screens (bundled)
```

---

## Enforcement Checklist

Before committing any view code:

- [ ] All buttons use CapsuleButton or ReceiptIconButton
- [ ] All shapes use `strokeBorder` not `stroke`
- [ ] All icons follow Lucide-first, SF Symbols exceptions only
- [ ] All colors use semantic tokens (no hardcoded RGB)
- [ ] All fonts use AppFont tokens
- [ ] All spacing uses AppSpacing/AppLayout tokens
- [ ] Cards use RoundedRectangle with `.continuous` style
- [ ] CTAs use Capsule shape
- [ ] Corner radius = AppRadius.medium (12pt) unless specified otherwise

---

## Quick Reference

| Element | Rule | Example |
|---------|------|---------|
| CTA Button | Capsule | `CapsuleButton("Submit", style: .primary)` |
| Card | RoundedRect 12pt | `RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)` |
| Border | strokeBorder | `.overlay(Capsule().strokeBorder(Color.border, lineWidth: 1))` |
| Icon | Lucide first | `Image("coffee")` or `IconView(name: "coffee")` |
| Color | Semantic | `Color.primaryEspresso` |
| Font | Token | `AppFont.headline` |
| Spacing | Token | `AppSpacing.lg` |

