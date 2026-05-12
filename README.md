# The Coffee Links - iOS Client

## Overview

The iOS Client is a premium, native mobile application built for The Coffee Links customers. It combines fast coffee ordering with contextual professional networking, delivering a dynamic and personalized customer experience.

## Features

| Feature | Description |
|---------|-------------|
| Ordering | Browse menu, customize drinks, and track orders. |
| Delivery | Address management, delivery zone checks, and delivery mode toggles. |
| Space & Maps | Store maps for booking tables and checking seat availability. |
| Connect | Professional intent badges, check-ins, community board, and profile discovery. |
| Intelligence | Local prediction engine for personalized recommendations. |

## Tech Stack

| Category | Technology |
|----------|------------|
| Language | Swift 5.10 |
| Framework | SwiftUI, iOS 16+ |
| Architecture | MVVM, dependency injection, repository pattern |
| Concurrency | Swift async/await |
| Persistence | Keychain, UserDefaults, NSCache |

## Project Structure

```text
TheCoffeeLinks/
├── App/                   # App entry point and global environment
├── Core/                  # Core services
│   ├── DesignSystem/      # App-wide UI tokens and components
│   ├── Networking/        # API client and realtime networking
│   ├── Security/          # Keychain and App Attest
│   └── Storage/           # Local persistence
├── Data/                  # Concrete repositories
├── Domain/                # Models and protocols
├── Features/              # SwiftUI screens by feature module
└── Resources/             # Assets, Info.plist, localization, config
```

## Quick Start

### Prerequisites

- Xcode 15 or later
- iOS 16.0 deployment target

### Build

```bash
cd thecoffeelinks-client-ios
xcodebuild build -project TheCoffeeLinks.xcodeproj -scheme TheCoffeeLinks -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
```

If that simulator is unavailable:

```bash
xcodebuild -showdestinations -scheme TheCoffeeLinks -project TheCoffeeLinks.xcodeproj
```

Then choose an installed simulator destination.

### Run in Xcode

1. Open `TheCoffeeLinks.xcodeproj`.
2. Select the `TheCoffeeLinks` scheme.
3. Choose a simulator or physical device.
4. Press `Cmd + R`.

## Configuration

- Runtime config lives in `TheCoffeeLinks/Config.plist`.
- Use `TheCoffeeLinks/Config.template.plist` as the template for local setup.
- Keep secrets and environment-specific values out of source code.

## Agent Notes

Operational guidance for AI coding agents lives in:

- `agents.md`
- `claude.md`

Update those files instead of adding new one-off audit reports.

## License

This project is private and proprietary to The Coffee Links.

