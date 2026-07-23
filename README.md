# The Coffee Links — Lite iOS

This `lite` branch is the focused member app for The Coffee Links. It keeps the existing target, scheme, display name, account system and bundle ID (`vn.thecoffeelinks.thecoffeelinks`), while limiting the product to:

- phone OTP and session recovery;
- point balance and recent activity;
- a signed, short-lived member QR plus a manual member code;
- paginated point history with store, invoice, eligible value and rate snapshots;
- basic account details, sign-out and OTP-confirmed account deletion.

The full ordering/social app remains on `main`. Both apps use the same production accounts, point balance and ledger.

## Architecture

```text
TheCoffeeLinks/
├── App/       # entry point, container, session state and root routing
├── Core/      # URLSession, Keychain, App Attest, cache and small UI kit
├── Domain/    # Member, MemberQR, PointTransaction and repository protocols
├── Data/      # REST-backed auth and loyalty repositories
├── Features/  # Auth, Member, History and Account
└── Resources/ # brand assets, semantic colors and vi/en strings
```

The app uses Apple frameworks only. Do not add Supabase, Realtime or remote-image packages to this branch. `Config.plist` uses `API_BASE_URL_DEBUG` for Debug builds and `API_BASE_URL` for Release builds; authentication still reaches the shared Supabase account indirectly through the backend REST API.

## Build and test

```bash
xcodebuild -project TheCoffeeLinks.xcodeproj \
  -scheme TheCoffeeLinks \
  -sdk iphonesimulator \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build

xcodebuild test -project TheCoffeeLinks.xcodeproj \
  -scheme TheCoffeeLinks \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO
```

The deployment target is iOS 16. The current release is `0.7.0 (102)`. Physical production builds require the App Attest entitlement and the backend signing configuration.

## Server contract

- `GET /api/loyalty/me`
- `POST /api/loyalty/member-qr`
- `POST /api/auth/otp/send`
- `POST /api/auth/otp/verify`
- `POST /api/auth/refresh`
- `PUT /api/user/profile`
- `DELETE /api/user/account`

Member QR payloads use `TCLM1`, expire after 120 seconds and refresh after 60 seconds. If an expired QR cannot be refreshed offline, the UI exposes only the manual member code.
