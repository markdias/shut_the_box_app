# Shut the Box iOS

This repository contains a full SwiftUI implementation of the neon-inspired **Shut the Box** experience originally built with Vite + React. The native port mirrors the gameplay loop, theme controls, history tracking, and learning mini-games that exist in the web client, while adapting the interface for iPhone and iPad form factors.

## Project structure

```
ShutTheBoxApp.xcodeproj/    # Shared scheme and Xcode build settings
ShutTheBoxApp/
├── Models/                 # Codable models describing players, tiles, options, and learning games
├── Store/                  # `GameStore` observable object that replaces Zustand
├── Utilities/              # Dice logic, combination search, persistence, and theming helpers
├── Views/
│   ├── Header/             # Header status, action bar, and export controls
│   ├── Board/              # Dice tray, tile grid, and progress cards
│   ├── Players/            # Player management hot-seat tools
│   ├── History/            # Turn log panels and sheet presentation
│   ├── Settings/           # Settings form with theme/rule configuration
│   ├── Learning/           # Learning game switcher and mini-game content
│   └── Modals/             # Instruction and winner summaries
├── Resources/
│   ├── Assets.xcassets/    # App icon, accent colour, and neon palette assets
│   └── Info.plist          # Bundle metadata, orientation support, and versioning
└── ShutTheBoxAppApp.swift  # `@main` entry point bootstrapping the store and theme manager
```

> **Note:** The repository now includes a fully-configured Xcode 15 project and shared scheme so you can open the workspace and build immediately without manual setup.

## Features

- **Complete gameplay loop** – roll dice, toggle tiles, confirm moves, and automatically detect round wins.
- **Bust detection** – unplayable rolls automatically score the remaining tiles so rounds conclude without manual bookkeeping.
- **Persistent state** – user defaults snapshots keep options, players, rounds, and previous winners between launches.
- **Neon UI theme** – layered gradients, glowing buttons, and responsive grids inspired by the React version, with a centralized theme manager updating accent colours app-wide.
- **Adaptive layout** – dice tray controls stack on compact iPhone widths while progress cards become a horizontal carousel for a comfortable handheld experience.
- **Learning mini-games** – switcher for Shapes, Dice, Dots, Math, and Word practice activities.
- **Score export** – share sheet exports player scores as JSON, mirroring the browser download flow.
- **Hot-seat controls** – manage multiple players, toggle hints, and adjust scoring modes from the native settings sheet.

## Getting started

1. Open **Xcode 15 or newer** on macOS 14 or later.
2. Double-click `ShutTheBoxApp.xcodeproj` to open the project.
3. Update the bundle identifier and signing team if you plan to deploy to a physical device.
4. Select the **ShutTheBoxApp** scheme and build/run the app on the iOS Simulator or a connected device.
5. Optionally tweak the deployment target in the project settings if you need to support earlier OS versions.

The project relies exclusively on the standard SwiftUI and Foundation frameworks, so no extra dependencies are required.

## Continuous integration

GitHub Actions automatically builds the project on every push to `main` and on pull requests using Xcode 16.2. The workflow lives at [`.github/workflows/ios-build.yml`](.github/workflows/ios-build.yml) and runs `xcodebuild` against the shared **ShutTheBoxApp** scheme with code-signing disabled. Asset symbol generation remains disabled in the project settings and the CI command passes `ENABLE_PREVIEWS=NO` plus `ASSETCATALOG_COMPILER_INCLUDE_SIMULATOR_PLATFORMS=NO` so GitHub-hosted runners are not required to install an iOS simulator runtime that matches the iOS 17.0 SDK bundled with Xcode 16.2.

## Testing

Automated UI and unit tests are not included yet. Use the iOS Simulator to validate the gameplay flow and confirm that persistence, learning games, and theming behave as expected.

## License

This port follows the licensing terms of the original project. Update this section with a specific license if needed.
