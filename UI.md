# Lite UI language

The visual character is quiet, tactile and editorial: warm paper behind dark ink, with espresso and moss accents. The interface should feel like a useful membership card, not a storefront.

## Tokens

- Horizontal screen margin: **23pt**.
- Major section gap: **40pt**; compact content gap: **8pt**.
- Card and row inset: **13pt**.
- Text fields and rows are **49pt** high; CTA buttons are **38pt** high. Icon-only controls retain a 44pt tap target.
- Corner radius: **0pt**. Components use crisp rectangular geometry.
- Border: **1pt**, semantic `Border` color.
- Main text: `TextInk`; supporting text: `TextMuted`.
- Background: `BackgroundPaper`; cards: white or `SurfaceCard`.
- Primary accent: `PrimaryEspresso`; use semantic success/warning/error colors for status only.

Use values from `Core/Design/DesignTokens.swift`; do not repeat raw values in feature views.

## Typography

- `Be Vietnam Pro` is the interface family. Vietnamese screen headings use Bold or SemiBold.
- `Noto Sans Mono` is reserved for points, member codes, invoice codes, rates and other numeric evidence.
- Geologica is not part of Lite.
- Keep labels direct and short. Vietnamese and English strings live in `Localizable.xcstrings`.
- Default hierarchy is 22pt for screen/section headings, 18pt for body/card titles and 14pt for labels/CTA text.

## Components

The entire shared kit is intentionally small: `AppButton`, `AppCard`, `AppTextField`, `AppRow`, `AppBadge`, `AppStateView` and `IconView`. Generic icons use SF Symbols. Only app icon, logos, palette and launch identity remain as assets.

Prefer one clear hierarchy per screen. Borders define groups; avoid glass, neomorphism, large shadows, rounded cards and ornamental motion. Interactions may use a restrained 120ms press animation. QR expiry and offline states must remain legible without relying on color alone.

Do not turn every section or row into its own card. Totals may sit directly on the paper background; repeating rows share one bordered container with internal hairlines. Keep the dashboard header in the content flow so iOS toolbar glass does not become the strongest visual element.

## Dashboard rules

The main screen presents, in order: available points, member QR/manual code, then recent history. Tier is deliberately hidden in V1 even when the API returns a nullable tier. Never show an expired QR. The manual member code must remain selectable and accessible when offline.
