# The CoffeeLinks (Native iOS)

## Overview
The CoffeeLinks is a premium coffee ordering and professional networking application built with **SwiftUI**, **MVVM**, and **Clean Architecture**. It emphasizes a "Connect for Success" vision, merging high-speed coffee ordering with contextual professional discovery.

## Features
*   **Ordering**: Browse menu, customize drinks, real-time order tracking (Active/History), AI-driven "Your Usual" predictions.
*   **Delivery**: Address management, delivery zone checks, optimistic delivery mode toggle.
*   **Space**: Interactive store maps for booking tables and checking seat availability.
*   **Connect**: Professional intent badges (Hiring, Learning), check-in system, community board, and profile discovery.
*   **Intelligence**: Local AI prediction engine for personalized recommendations.

## Tech Stack
*   **Language**: Swift 5.10
*   **Framework**: SwiftUI (iOS 16+)
*   **Architecture**: MVVM + Dependency Injection + Repository Pattern
*   **Concurrency**: Swift Async/Await
*   **Persistence**: Keychain (Secure), UserDefaults (Preferences), NSCache (Images)

## Setup Instructions

### Prerequisites
*   Xcode 15 or later
*   iOS 16.0 deployment target

### Installation
1.  Clone the repository.
   ```bash
   git clone <repo-url>
   ```
2.  Open `thecoffeelinks-client-ios.xcodeproj`.
3.  Ensure the Signing Team is selected in Project Settings.
4.  Build and Run (Cmd+R).

### Configuration
*   **API Base URL**: Configured in `APIEndpoints.swift` (Default: `https://server-nu-three-90.vercel.app/api`).
*   **Constants**: App-wide constants (colors, fonts) are in `Core/DesignSystem`.

## Deployment
*   **CI/CD**: (Placeholder) Scripts for Bitrise/GitHub Actions are located in `.github/workflows`.
*   **App Store**: Ensure all assets in `Assets.xcassets` are populated before archiving.

## Contributing
1.  Fork the repo.
2.  Create a feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit changes (`git commit -m 'Add AmazingFeature'`).
4.  Push to branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

## License
Private Property of The CoffeeLinks.
