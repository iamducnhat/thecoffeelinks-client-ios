# UI Source Of Truth

## Canonical Tokens

- Primary visual tokens: `BaseViewColor`, `BaseViewFont`, `BaseViewLayout`.
- Primary shared components: `App*` components under `TheCoffeeLinks/Core/DesignSystem/Components`.
- Canonical image placeholder: `BaseViewColor.placeholder`.
- Placeholder color: `#D9D9D9`.
- Shape borders: use `strokeBorder`.

## Rules

1. Before building new UI, check this file and reuse an existing component if one already fits.
2. If the UI pattern is reusable and missing, add a shared component under `TheCoffeeLinks/Core/DesignSystem/Components` first.
3. If a screen-only layout is not reusable, keep it private to the feature.
4. Use `BaseViewColor`, `BaseViewFont`, and `BaseViewLayout`; do not introduce `DesignSystemV2`, `Editorial`, `AppLayout`, `AppFont`, `AppSpacing`, `AppTypography`, or `AppRadius`.
5. Buttons, text fields, tabs, and other text-bearing controls should use padding plus `minHeight`, not fixed `.frame(height:)`.
6. Do not create another markdown UI audit. Update this file when the shared UI inventory changes.

## Component Inventory

| Component | Purpose | Notes |
| --- | --- | --- |
| `IconView` | Shared icon wrapper | Uses bundled Lucide asset when available, otherwise SF Symbols |
| `AppRemoteImage` | Single remote image wrapper for cached/native async loading | Default placeholder is `BaseViewColor.placeholder`; supports overlay, size, aspect ratio, loading, and placeholder initials |
| `AppButton` | Shared button primitive | Variants: `primary`, `secondary`, `ghost`, `underlined`, `destructive`, `icon`; supports loading, disabled, full-width, intrinsic |
| `AppCard` | Shared bordered surface container | Uses canonical card border and radius |
| `AppRow` | Shared row layout shell | Leading/trailing composition primitive |
| `AppListRow` | Shared list/navigation row | Supports icon, detail, chevron, badge, selection, button action |
| `AppSectionHeader` | Shared section heading row | Optional subtitle and trailing accessory |
| `AppNavigationHeader` | Shared top nav header | Back action plus optional trailing content |
| `AppEmptyState` | Shared empty state | Optional action CTA |
| `AppAuthPromptCard` | Shared auth-required prompt | Centered title/body plus full-width CTA for guest-gated features |
| `AppLoadingState` | Shared loading state | Shared `ProgressView` + message |
| `AppBadge` | Shared badge primitive | Accent, neutral, success, warning, destructive |
| `AppTextInput` | Shared labeled text input | Optional icon, secure mode, keyboard type; dynamic height via padding + `minHeight` |
| `AppSearchInput` | Shared search field | Search icon + clear button; dynamic height via padding + `minHeight` |
| `AppSegmentedPicker` | Shared segmented picker | Generic over selection type; text options use padding + `minHeight` |
| `AppToggleRow` | Shared settings toggle row | Uses canonical row styling |
| `AppSelectableRow` | Shared selectable row | For pickers and list selection |
| `AppStepper` | Shared increment/decrement control | Generic value display |
| `AppQuantityStepper` | Shared quantity stepper | Used by cart and receipt-style quantity controls |
| `AppProductCard` | Reusable product card | Used for Home-style product highlights |
| `AppProductRow` | Reusable product row | Image + name + price + optional quantity controls |
| `AppStoreCard` | Reusable store card | Variants: `rich`, `simple`, `compact` |
| `AppVoucherPassCard` | Reusable voucher pass card | Shared wallet/pass visual |
| `AppMembershipProgressCard` | Reusable membership progress card | Shared tier/progress presentation |
| `AppOrderSummaryCard` | Reusable order summary card | Summary lines + optional CTA |

## Transitional Wrappers

These names may exist only as thin wrappers while older feature code is simplified. New code should not add more wrappers.

| Wrapper | Shared Target |
| --- | --- |
| `BaseCTAButton` | `AppButton` |
| `ReceiptPrimaryButton` | `AppButton` |
| `ReceiptStepperButton` | `AppButton` icon variant |
| `ReceiptQuantityStepper` | `AppQuantityStepper` |
| `BaseListRow` | `AppListRow` |
| `BrandTextField` | `AppTextInput` |
| `SearchInput` | `AppSearchInput` |
| `EmptyStateView` | `AppEmptyState` |
| `LoadingView` | `AppLoadingState` |

## Image Placeholder Rule

- All remote images should go through `AppRemoteImage`.
- Default fallback must be `BaseViewColor.placeholder`.
- Do not introduce blue, tinted, or ad-hoc placeholder fills for missing images.
- Use `placeholderText` only when initials are part of the UX, such as avatars or search rows.

## Examples

```swift
AppRemoteImage(
    url: URL(string: product.displayImageUrl ?? ""),
    width: BaseViewLayout.productImageSize,
    height: BaseViewLayout.productImageSize,
    showsProgress: true
)
```

```swift
AppButton("browse_menu_button", style: .primary, fillsWidth: false) {
    onBrowse()
}
```

```swift
AppStoreCard(
    title: store.name,
    address: store.address,
    statusText: store.isCurrentlyOpen ? "Open" : "Closed",
    isSelected: isSelected,
    variant: .simple
)
```

## New UI Checklist

1. Check this file for an existing component match.
2. Use `BaseViewColor`, `BaseViewFont`, and `BaseViewLayout` instead of hardcoded values or legacy aliases.
3. Use `AppRemoteImage` for every remote image.
4. Prefer shared `App*` components over feature-local duplicates.
5. Keep text-bearing controls dynamic with padding plus `minHeight`.
6. Update this file if the shared inventory changes.
