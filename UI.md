# Lite UI language

The visual character is quiet, tactile and editorial: warm paper behind dark ink, with espresso and moss accents. The interface should feel like a useful membership card, not a storefront.

## Tokens

- Horizontal screen margin: **23pt**.
- Card padding: **16pt**.
- Corner radius: **4pt**.
- Border: **0.75pt**, semantic `Border` color.
- Main text: `TextInk`; supporting text: `TextMuted`.
- Background: `BackgroundPaper`; cards: white or `SurfaceCard`.
- Primary accent: `PrimaryEspresso`; use semantic success/warning/error colors for status only.

Use values from `Core/Design/DesignTokens.swift`; do not repeat raw values in feature views.

## Typography

- `Be Vietnam Pro` is the interface family. Vietnamese screen headings use Bold or SemiBold.
- `Noto Sans Mono` is reserved for points, member codes, invoice codes, rates and other numeric evidence.
- Geologica is not part of Lite.
- Keep labels direct and short. Vietnamese and English strings live in `Localizable.xcstrings`.

## Components

The entire shared kit is intentionally small: `AppButton`, `AppCard`, `AppTextField`, `AppRow`, `AppBadge`, `AppStateView` and `IconView`. Generic icons use SF Symbols. Only app icon, logos, palette and launch identity remain as assets.

Prefer one clear hierarchy per screen. Borders define groups; avoid glass, neomorphism, large shadows and ornamental motion. Interactions may use a restrained 120ms press animation. QR expiry and offline states must remain legible without relying on color alone.

## Dashboard rules

The main screen presents, in order: available points, member QR/manual code, then recent history. Tier is deliberately hidden in V1 even when the API returns a nullable tier. Never show an expired QR. The manual member code must remain selectable and accessible when offline.
