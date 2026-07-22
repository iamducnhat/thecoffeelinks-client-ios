# Agent guide — iOS Lite

## Scope

Work on the `lite` branch as a loyalty-only iOS app. Ordering, menu, cart, checkout, delivery, stores, vouchers, social, networking, prediction, location and onboarding carousel features belong to the full app on `main` and must not be restored here.

## Invariants

- Target/scheme/display name: `TheCoffeeLinks` / **The Coffee Links**.
- Bundle ID: `vn.thecoffeelinks.thecoffeelinks`.
- iOS 16+, SwiftUI, Swift 6, Apple frameworks only.
- REST goes through `APIClient`; never connect the app directly to Supabase.
- Access/refresh tokens and App Attest identifiers stay in Keychain.
- Shared accounts mean account deletion affects the full app too; preserve the explicit warning and fresh-OTP confirmation.
- A member QR is server-issued and signed. Never construct a locally trusted QR or extend its expiry on-device.
- On offline fallback, cached profile/history may be read, but an expired QR must disappear.

## Structure

- `App`: composition and the single `AppSession` state machine.
- `Core`: URLSession, security, cache and the compact design system.
- `Domain`: dependency-free value models and repository protocols.
- `Data`: REST repository implementations.
- `Features`: only `Auth`, `Member`, `History`, and `Account`.

Keep repository DTO mapping close to the repository. Add shared UI only when it clearly fits one of `AppButton`, `AppCard`, `AppTextField`, `AppRow`, `AppBadge`, `AppStateView` or `IconView`.

## Verification

Run a clean simulator build after dependency or file-graph changes. Add deterministic XCTest coverage for OTP/session, QR expiry, cache/offline behavior, history pagination and account deletion. UI tests use `-ui-testing` repositories and must never call production services.

Do not stage or delete `TheCoffeeLinks.xcodeproj/xcshareddata/xcodecloud/` unless the user explicitly requests it.
