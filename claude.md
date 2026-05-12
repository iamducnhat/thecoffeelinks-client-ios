# Claude Working Notes

## Prime Directive

This iOS repo was cleaned so future agents do not need to parse old generated reports. Keep context here concise and current. When you learn something durable about the app, update this file or `agents.md`; do not create another standalone markdown audit.

## What Was Consolidated

Old reports covered:

- build target membership fixes for Swift files,
- app state and onboarding redesign,
- production runtime audit fixes,
- design-system inconsistencies,
- product-card redesign ideas,
- test-suite rewrite notes,
- launch/logo Python automation.

Those files were intentionally removed. The operational parts now live in `agents.md`; the risk/backlog parts live below.

## Verified Baseline

Last known build check:

```bash
xcodebuild build -project TheCoffeeLinks.xcodeproj -scheme TheCoffeeLinks -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
```

Result on 2026-05-13: build succeeded.

## Known Risks To Watch

- `TheCoffeeLinksTests/LoginIntegrationTests.swift` and `TheCoffeeLinksTests/NetworkCheckInIntegrationTests.swift` include hardcoded credentials and live API behavior. Treat them as unsafe for CI until rewritten or quarantined.
- App code still has direct `print()` calls in startup/profile sync paths. Prefer `debugLog`, which is stripped in Release.
- `AppEnvironment.apiBaseURL` and `DependencyContainer` contain fallback URLs. New work should flow through `Config.plist` and `Config.template.plist`.
- `DependencyContainer` is still a singleton. It has factory methods, but deeper protocol injection remains partial.
- Design-system files still contain legacy compatibility layers. Prefer reducing duplicated components when modifying related screens.

## High-Value Refactors

1. Replace live-network tests with protocol-backed mocks.
2. Move remaining hardcoded environment values behind config.
3. Convert direct app `print()` calls to `debugLog`.
4. Continue extracting protocols where view models still depend on concrete singletons.
5. Remove legacy design-system wrappers only when nearby feature work gives enough test coverage.

## Implementation Guardrails

- Preserve guest mode behavior.
- Do not clear tokens on transient network failures.
- Keep `initializeSync()` truly synchronous.
- Avoid fire-and-forget auth/App Attest tasks that can race startup.
- Keep payment/order flows idempotent; rapid taps should not create duplicate orders.
- Use existing repositories and services before adding new app-wide dependencies.

## Files Worth Reading First

- `TheCoffeeLinks/TheCoffeeLinksApp.swift`
- `TheCoffeeLinks/ContentView.swift`
- `TheCoffeeLinks/Core/DI/DependencyContainer.swift`
- `TheCoffeeLinks/Core/Services/AppFlowController.swift`
- `TheCoffeeLinks/Core/Networking/NetworkService.swift`
- `TheCoffeeLinks/Core/Security/AppAttestService.swift`
- `TheCoffeeLinks/Core/DesignSystem/DesignSystemV2.swift`

