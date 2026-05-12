# ☕ The Coffee Links - iOS Client

![Swift](https://img.shields.io/badge/Swift-5.10-FA7343?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%2016+-blue?style=flat-square&logo=apple)
![Architecture](https://img.shields.io/badge/Architecture-Clean%2F%20MVVM-green?style=flat-square)

## 📖 Overview

The **iOS Client** is a premium, native mobile application built for The Coffee Links customers. Emphasizing a "Connect for Success" vision, it merges high-speed coffee ordering with contextual professional networking, delivering a robust, dynamic, and personalized user experience.

---

## 📊 Features

| Feature | Description |
|---------|-------------|
| 🛒 **Ordering** | Browse menu, customize drinks, and real-time order tracking (Active/History). |
| 🚚 **Delivery** | Address management, delivery zone checks, and optimistic delivery mode toggles. |
| 📍 **Space & Maps**| Interactive store maps for booking tables and checking live seat availability. |
| 🤝 **Connect** | Professional intent badges (Hiring, Learning), check-in system, community board, and profile discovery. |
| 🧠 **Intelligence**| Local AI-driven "Your Usual" predictions engine for personalized recommendations. |

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Language** | Swift 5.10 |
| **Framework** | SwiftUI (iOS 16+ Deployment Target) |
| **Architecture** | MVVM + Dependency Injection + Repository Pattern (Clean Architecture) |
| **Concurrency** | Swift Async/Await |
| **Persistence** | Keychain (Secure), UserDefaults (Preferences), NSCache (Images) |

---

## 📁 Project Structure

```
TheCoffeeLinks/
├── App/                   # App Entry point and Global Environment
├── Core/                  # Core services
│   ├── DesignSystem/      # App-wide constants (colors, fonts, UI elements)
│   ├── Networking/        # API Client and Interceptors
│   └── Storage/           # Persistence (Keychain, UserDefaults)
├── Domain/                # Entities, Models, and Repository protocols
├── Features/              # UI screens organized by feature module
│   ├── Auth/
│   ├── Home/
│   ├── Menu/
│   ├── Checkout/
│   ├── Profile/
│   └── Connect/           # Professional networking features
└── Resources/             # Assets (Assets.xcassets), Info.plist, Localizable files
```

---

## 🚀 Quick Start & Setup

### Prerequisites

- **Xcode** 15 or later
- **iOS** 16.0 deployment target

### 1. Installation

```bash
# Clone the repository and navigate to the project directory
cd thecoffeelinks-client-ios
```

### 2. Configuration

- Open `thecoffeelinks-client-ios.xcodeproj` in Xcode.
- Ensure the appropriate **Signing Team** is selected in the Project Settings.
- **API Base URL:** Configured in `APIEndpoints.swift` (Default: `https://server-nu-three-90.vercel.app/api`).
- **Design Tokens:** Modify app-wide constants (colors, fonts) located in `Core/DesignSystem`.

### 3. Build and Run

- Select the target simulator or physical device.
- Press `Cmd + R` (Build and Run) to launch the application.

---

## 📦 Deployment

- **CI/CD:** Placeholder scripts for Bitrise/GitHub Actions are located in `.github/workflows`.
- **App Store:** Ensure all graphical assets in `Assets.xcassets` are fully populated before archiving for TestFlight or App Store distribution.

---

## 🤝 Contributing

1. Fork the repository.
2. Create a new feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 📄 License

This project is private and proprietary to The Coffee Links.
