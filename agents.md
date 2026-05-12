# TheCoffeeLinks iOS Agent Guide

## Scope

This folder is the native iOS client for TheCoffeeLinks. Keep this directory focused on Swift, SwiftUI, Xcode project files, assets, tests, and these two agent docs. Do not add one-off Python scripts or extra markdown reports here; update `agents.md` or `claude.md` instead.

## Project Facts

- App: `TheCoffeeLinks`
- Platform: iOS 16+
- Language/UI: Swift, SwiftUI, async/await
- Architecture: MVVM with repository and service layers
- Project file: `TheCoffeeLinks.xcodeproj`
- Main scheme: `TheCoffeeLinks`
- Test targets: `TheCoffeeLinksTests`, `TheCoffeeLinksUITests`
- Main source root: `TheCoffeeLinks/`
- Unit/UI tests: `TheCoffeeLinksTests/`, `TheCoffeeLinksUITests/`

## Useful Commands

```bash
xcodebuild -list -project TheCoffeeLinks.xcodeproj
xcodebuild build -project TheCoffeeLinks.xcodeproj -scheme TheCoffeeLinks -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
xcodebuild test -project TheCoffeeLinks.xcodeproj -scheme TheCoffeeLinks -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
```

If that simulator is unavailable, run `xcodebuild -showdestinations -scheme TheCoffeeLinks -project TheCoffeeLinks.xcodeproj` and choose an installed iOS Simulator.

## Structure

- `TheCoffeeLinks/App`: app environment and app-level setup.
- `TheCoffeeLinks/Core`: dependency injection, networking, security, storage, design system, services, shared view models.
- `TheCoffeeLinks/Data`: concrete repositories.
- `TheCoffeeLinks/Domain`: models and protocols.
- `TheCoffeeLinks/Features`: feature-first SwiftUI screens and feature view models.
- `TheCoffeeLinks/Resources`: asset catalogs, localized strings, plist config, launch resources.

## Runtime Rules

- `DependencyContainer.shared` wires the current app graph. Prefer existing factory methods when creating view models.
- `initializeSync()` runs before UI routing and must stay synchronous for token/session setup.
- `initializeAsync()` is for background sync, subscriptions, and authenticated startup work.
- Auth tokens live in `KeychainManager`; do not put access or refresh tokens in `UserDefaults`.
- Guest mode is valid. Auth-dependent services must skip network work when there is no access token.
- App Attest registration should stay tied to authenticated OTP/login flows; avoid background key generation races.

## App Flow

The app starts in `AppFlowController` and routes through these states:

```text
launching -> onboarding or guestReady
launching -> checkingAuth -> ready
guestReady -> loggingIn -> ready
ready -> guestReady on logout or invalid auth
```

Onboarding is tracked in `UserDefaults`; secure auth state is tracked in Keychain. If token validation fails with auth errors, clear auth and fall back to guest mode. If validation fails due to transient network errors, prefer cached state and retry later.

## Design System

- Prefer semantic tokens from `Core/DesignSystem`.
- Use `DesignSystemV2.swift` and existing app components before creating new primitives.
- Avoid hardcoded colors, spacing, and repeated button styles.
- Use `strokeBorder` for shape borders.
- Keep cards and controls touch-friendly and consistent with the current SwiftUI style.
- The old docs identified design-system drift across receipt/editorial/liquid-glass styles. New UI work should reduce duplication, not add another visual dialect.

## Testing Expectations

- Add focused XCTest coverage for service, repository, and view model changes.
- Keep unit tests deterministic: no live network, no hardcoded personal credentials.
- UI tests should cover critical customer journeys only when the flow is stable.
- Existing live integration-style tests are risky; quarantine or refactor them before relying on full `xcodebuild test` in CI.

## Current Audit Notes

- Simulator build passed on 2026-05-13 with:
  `xcodebuild build -project TheCoffeeLinks.xcodeproj -scheme TheCoffeeLinks -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'`
- Remaining cleanup candidates:
  - Replace app `print()` calls with `debugLog`.
  - Remove or quarantine tests that call real APIs and contain hardcoded credentials.
  - Consolidate legacy design-system wrappers as features are touched.
  - Keep config values in `Config.plist` / `Config.template.plist`, not hardcoded in new code.

