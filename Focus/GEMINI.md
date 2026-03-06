# Focus Project Overview

Focus is a productivity-oriented timer application for iOS and macOS, built using **SwiftUI** and **Combine**. It allows users to manage custom focus modes, use a Pomodoro-style timer with automated phases, and track their focus sessions through a calendar-based history view.

## Architecture & Tech Stack

- **Framework:** SwiftUI for the user interface.
- **State Management:** Uses a store-based approach with `ObservableObject`, `@Published`, and `@EnvironmentObject`.
    - `FocusModesStore`: Manages custom and default focus modes, Pomodoro state, and timer logic.
    - `FocusHistoryStore`: Manages the persistence and retrieval of completed focus sessions.
    - `UIStateStore`: Handles global UI states and navigation flags.
- **Persistence:** Data is persisted locally using `UserDefaults` by encoding/decoding models to JSON.
- **Models:**
    - `FocusMode`: Represents a specific focus activity (e.g., Study, Work) with a name, duration, and icon key.
    - `FocusSession`: Represents a completed focus activity with timing and metadata.
    - `PomodoroState`: Tracks the current phase (focus, short break, long break) and session count.

## Project Structure

- `Focus/Models/`: Data structures and enums.
- `Focus/Stores/`: Logic for data persistence and state management.
- `Focus/Views/`:
    - `Timer/`: The main timer interface, mode selection, and start controls.
    - `Calendar/`: Session history and calendar visualizations.
    - `Modes/`: Interfaces for creating, renaming, and selecting focus modes.
    - `Components/`: Reusable UI elements like `GlassCard`.
- `Focus/Utils/`: Utility extensions (e.g., `Color+Hex`) and global constants (`Constants.swift`).

## Building and Running

- **Requirements:** macOS with Xcode installed.
- **Opening the project:** Open `Focus.xcodeproj` in Xcode.
- **Running:** Select a target (iOS Simulator or Device) and press `Cmd + R`.
- **Testing:** No explicit test suite was found; manual testing via Xcode is the current practice.

## Development Conventions

- **Icons & Colors:** Do not hardcode SF Symbol names or colors directly in views. Use the mapping functions in `Constants.swift` (`sfSymbol(for:)`, `getIconColor(_:)`) which translate internal icon keys (like "book" or "cafe") to system symbols and theme-consistent colors.
- **Persistence:** When adding new fields to `FocusMode` or `FocusSession`, ensure they are `Codable` and that the persistence containers in the respective Stores are updated.
- **UI State:** Favor using `UIStateStore` for cross-view UI logic (like triggering sheets or overlays) to keep view logic clean.
- **Environment:** The app relies on `EnvironmentObject` for its stores; ensure any new view hierarchies have these objects injected at the root (usually done in `FocusApp.swift`).
