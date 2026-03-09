# ⏱️ Focus

A beautifully crafted **Pomodoro timer** for iOS, built entirely with **SwiftUI** and **Swift 6**. Focus helps you stay productive with customizable focus modes, automatic Pomodoro cycles, session tracking, and detailed statistics — all wrapped in a sleek dark interface with Liquid Glass effects.

<p align="center">
  <img src="https://github.com/user-attachments/assets/b8a0e822-b957-417e-8578-b4401ed3ea1b" width="200" />
  <img src="https://github.com/user-attachments/assets/5a421ca4-a8e4-4afc-a7bb-16e48adde545" width="200" />
  <img src="https://github.com/user-attachments/assets/184a7dc6-1004-4450-af27-5a588dd4adfd" width="200" />
  <img src="https://github.com/user-attachments/assets/5ba1ab05-9311-4d17-80ac-cf703d774d89" width="200" />
</p>

---

## ✨ Features

- **Full-screen Pomodoro Timer** — Large MM:SS display with smooth rolling animations and real-time countdown
- **Automatic Pomodoro Cycles** — Focus → Short Break → Focus → … → Long Break, with smart duration calculation (short break = 20%, long break = 60% of focus time)
- **Custom Focus Modes** — Create, rename, and manage your own modes (Study, Work, Fitness, Read, Code…) with unique icons and colors
- **Session History & Calendar** — Browse completed sessions on a weekly timeline, visualized by hour and color-coded by mode
- **Statistics & Analytics** — Track your productivity with period filters (Day / Week / Month / Year), mode breakdowns, trend comparisons, and stacked bar charts
- **Hold-to-Stop Gesture** — Intuitive full-screen drag to stop the timer with visual progress feedback
- **Haptic Feedback** — Tactile responses throughout the interface for a polished experience
- **Liquid Glass UI** — iOS 26+ native glass effects with graceful fallback to `.ultraThinMaterial` on older versions
- **Dark Mode Only** — A focused, distraction-free dark theme designed for deep work

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Language** | Swift 6.0 |
| **UI Framework** | SwiftUI (pure declarative, no UIKit) |
| **Architecture** | MVVM with Observable Stores |
| **State Management** | `@Observable` macro + `@Environment` injection |
| **Persistence** | UserDefaults with JSON Codable encoding |
| **Animations** | `.numericText()` rolling transitions, `.snappy()` spring animations |
| **Haptics** | `UIImpactFeedbackGenerator` / `UISelectionFeedbackGenerator` |
| **Minimum Target** | iOS 17.0 / macOS 14.0 |
| **Build System** | Swift Package Manager + [xtool](https://github.com/nicklama/xtool) |
| **CI/CD** | GitHub Actions (Xcode build + test on simulator) |

---

## 📱 Built with xtool

This project was created and is built using **[xtool](https://github.com/nicklama/xtool)** — a command-line tool that lets you build, run, and deploy Swift apps directly from a `Package.swift` definition, without needing to open Xcode.

The project is structured as a **Swift Package Manager library** that xtool turns into a full iOS application:

```swift
// swift-tools-version: 6.0
// Package.swift
let package = Package(
    name: "Focus",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // An xtool project contains exactly one library product,
        // representing the main app.
        .library(name: "Focus", targets: ["Focus"])
    ],
    targets: [
        .target(name: "Focus", path: "Focus", resources: [
            .process("Assets.xcassets")
        ])
    ]
)
```

The `xtool.yml` configuration provides the app metadata:

```yaml
version: 1
bundleID: com.marcodignoti.Focus
iconPath: Focus/Assets.xcassets/AppIcon.appiconset/AppIcon_1024x1024.png
```

### Building & Running

```bash
# Install xtool (if not already installed)
brew install nicklama/tap/xtool

# Build the app
xtool build

# Run on iOS Simulator
xtool run --device "iPhone 16 Pro"

# Install on a physical device
xtool install
```

> xtool reads `Package.swift` and `xtool.yml` to compile, sign, and deploy the app — no `.xcodeproj` required for development.

---

## 🏗️ Architecture

The app follows the **MVVM pattern** with dedicated **Stores** as state containers:

```
Focus/
├── FocusApp.swift               # App entry point, store injection
├── ContentView.swift            # Root navigation (paged scroll)
│
├── Models/
│   ├── FocusMode.swift          # Mode definition + PomodoroState
│   └── FocusSession.swift       # Completed session record
│
├── Stores/
│   ├── FocusModesStore.swift    # Modes CRUD + Pomodoro state machine
│   ├── FocusHistoryStore.swift  # Session persistence (UserDefaults)
│   └── UIStateStore.swift       # Sheet/modal visibility flags
│
├── ViewModels/
│   └── StatsViewModel.swift     # Stats aggregation & chart data
│
├── Views/
│   ├── Timer/                   # Home screen timer interface
│   ├── Calendar/                # Session history timeline
│   ├── Stats/                   # Analytics dashboard
│   ├── Modes/                   # Mode management sheets
│   └── Components/              # Reusable UI (GlassCard)
│
└── Utils/
    ├── Constants.swift          # Icon/color mappings
    ├── Color+Hex.swift          # Hex ↔ Color conversion
    └── HapticManager.swift      # Haptic feedback engine
```

### Navigation Flow

The app uses a **vertical paged scroll** layout:

1. **Home** — Horizontal `TabView` with the Timer and Calendar views
2. **Stats** — Scroll down from Home to reveal the full analytics dashboard

---

## 🎨 Focus Modes

The app ships with **5 default modes** and lets users create unlimited custom ones:

| Icon | Mode | Default Duration |
|---|---|---|
| 📖 | Study | 35 min |
| 💼 | Work | 45 min |
| 🎯 | Focus | 15 min |
| 🏋️ | Fitness | 45 min |
| 📚 | Read | 20 min |

Each mode includes a curated **SF Symbol** icon and a distinct **color** from a palette of 16 options (book, briefcase, barbell, code, laptop, moon, café, leaf, music, pencil, brush, calculator, game controller, and more).

---

## 🔄 Pomodoro Cycle

```
┌─────────┐     ┌─────────────┐     ┌─────────┐     ┌──────────────┐
│  FOCUS   │ ──▶ │ SHORT BREAK │ ──▶ │  FOCUS   │ ──▶ │  LONG BREAK  │
│ (35 min) │     │   (7 min)   │     │ (35 min) │     │  (21 min)    │
└─────────┘     └─────────────┘     └─────────┘     └──────────────┘
                                                       ↑ after 4 sessions
```

- **Short Break** = 20% of focus duration
- **Long Break** = 60% of focus duration (every 4 sessions)
- Phases transition automatically with haptic notifications

---

## 📋 Requirements

- **iOS 17.0+** or **macOS 14.0+**
- **Swift 6.0**
- **Xcode 16+** (for direct Xcode builds) or **xtool** (for CLI builds)

---

## 📄 License

This project is open source. See the repository for license details.
