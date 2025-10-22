# Shut the Box iOS

This repository contains a full SwiftUI implementation of the neon-inspired **Shut the Box** experience originally built with Vite + React. The native port mirrors the gameplay loop, theme controls, history tracking, and learning mini-games that exist in the web client, while adapting the interface for iPhone form factors.

## Project structure

```
ShutTheBoxApp.xcodeproj/    # Shared scheme and Xcode build settings
ShutTheBoxApp/
├── Models/                 # Codable models describing players, tiles, options, and learning games
├── Store/                  # `GameStore` observable object that replaces Zustand
├── Utilities/              # Dice logic, combination search, persistence, and theming helpers
├── Views/
│   ├── Header/             # Header status, action bar, and export controls
│   ├── Board/              # Dice tray, tile grid, progress cards, and end-turn bar
│   ├── History/            # Turn log panels and sheet presentation
│   ├── Settings/           # Settings form with theme/rule/player configuration
│   ├── Learning/           # Learning game switcher and mini-game content
│   └── Modals/             # Instruction and winner summaries
├── Resources/
│   ├── Assets.xcassets/    # App icon, accent colour, and neon palette assets
│   └── Info.plist          # Bundle metadata, orientation support, and versioning
└── ShutTheBoxAppApp.swift  # `@main` entry point bootstrapping the store and theme manager
```

> **Note:** The repository now includes a fully-configured Xcode 15 project and shared scheme so you can open the workspace and build immediately without manual setup.

## Core gameplay flow

- **Setup** – Configure options, add players, and keep the scoreboard from previous sessions thanks to `UserDefaults` persistence that mirrors the original web client's localStorage snapshot.
- **Turn loop** – Rolling defaults to two dice until the one-die rule unlocks the single-die toggle beneath the tray, so you can decide whether to throw one or two dice when the remainder is small. The first tap still kick-starts new rounds, and players build multi-tile selections whose totals must match the roll; valid sums now close the tiles instantly so the dice prompt the next roll without a confirmation bar.
- **Round resolution** – Rounds end once all players have no legal moves. The winner modal lists every player, highlights ties, and honours the instant-win-on-shut rule for zero scores. Solo practice now swaps the modal for a "Did not shut the box" status banner above the dice whenever tiles remain open, while perfect shuts trigger a neon trophy celebration and practice runs with leftover pips skip the winner label entirely so only flawless rounds count. The board now stays frozen at the end of a round so you can review the closed tiles, the dice keep the last roll's pip faces in the new mint accent until you tap them to reset for the next round, and the leftover score sits just beneath the tray for quick reference.
- **Instructions overlay** – "How to Play" opens an accessible modal that summarises the rules and assists new players without leaving the app.

## Rules & scoring configuration

All configuration knobs live inside the Settings panel:

| Option | Values | Behaviour |
| --- | --- | --- |
| Highest tile | 1–9, 1–10, 1–12 (cheat code unlocks 1–56) | Regenerates the tile strip outside active rounds. Hidden code `madness` enables the 56-tile stress test. |
| One-die rule | After top tiles shut · When remainder < 6 · Never | Controls when the tray unlocks the single-die toggle. Once active you can keep rolling two dice or drop to one using the inline switch. |
| Scoring mode | Lowest remainder · Cumulative target race · Instant win | Adapts scorekeeping. Target mode enables a configurable goal; instant mode forces instant-win behaviour. |
| Instant win on shut | Toggle | Awards victory immediately when a player clears the board (also implied by instant scoring). |
| Auto-retry on failure | Toggle | When paired with auto-play, restarts runs automatically after round summaries. |
| Show header details | Toggle | Expands the neon header with status chips for round, hints, and previous winners. |
| Show code tools | Toggle | Reveals an inline cheat-code text field for `full`, `madness`, and `takeover`. |
| Theme | Neon glow · Matrix grid · Classic wood · Tabletop felt | Applies SwiftUI themes and updates the app tint. |
| Show learning games | Toggle | Swaps the main board for the mini-game hub when active. |

Cheat codes perform extra tasks:

- `full` – Enables perfect-roll rigging for instant wins.
- `madness` – Raises `maxTile` to 56 for giant boards.
- `takeover` – Activates visible auto-play (following best-move hints), enables auto-retry, and restarts the round hands-free.

Double tapping tile 12 also primes a secret forced double-six on the next roll.

Hit the **Reset** header action at any time to clear all active cheat effects, disable auto-retry, hide the code tools, and restore the board to its default starting state.

## Player management & history

- Manage the hot-seat roster from **Settings → Players**, adding or removing participants, renaming them inline, and toggling per-player hints.
- Track each player's last score, cumulative totals (for target mode), and unfinished turns inside the roster.
- The History panel records every roll, move, bust, and celebration with colourful icons. It persists across launches alongside scores, rounds, previous winners, and the selected theme under the key `shut-the-box:scores`.
- Round history cards summarise each completed round with the total leftover pips, per-player results, and the winners for quick comparison. A highlights grid surfaces clever stats such as clean shut rate, win leaders, longest streak, momentum shifts, and the best round so far.
- The "Save Scores" header action exports the persisted snapshot as `shut-the-box-scores.json`, including the round number, current phase, totals, and active theme.

## Assistive & automated play

- Global hints illuminate legal tiles only when the header toggle is on. Players can still opt out individually from the roster (they default to receiving hints once the global toggle is active), while the best-move highlight recommends the strongest combination. Existing rosters from earlier builds automatically opt in again the next time you enable hints so you do not have to edit each player manually.
- Auto-play follows the best-move path, shows a dismissible banner, and cooperates with the auto-retry toggle for kiosk demos.
- Pending-turn toasts, restart countdowns, and end-turn acknowledgements keep multi-player sessions coordinated.
- Winner and instructions modals summarise the round and provide quick rule refreshers for new players.

## Learning mini games

Enable "Show learning games" and use the **More Games** button to swap out the main board. Each mini game reuses the app chrome and supports touch or mouse input:

- **Word sound builder** – Choose 2–6 letter words, tap tiles to hear phonetic playback, and optionally switch to the premium voice fallback. The system speech engine provides instant audio when offline.
- **Shape explorer** – Render regular polygons, custom quadrilaterals, circles, and ellipses. Tap glowing vertices to count corners; the UI tracks totals and supplies fun facts.
- **Dice dot detective** – Pick 1–6 dice, predict the total with tile-style buttons, then reveal animated dice for immediate feedback.
- **Secret dot flash** – Flash up to 36 non-overlapping dots for subitising practice. Adjustable difficulty controls dot ranges and flash timing.
- **Math mixer** – Generate arithmetic equations (addition, subtraction, multiplication, division) with Starter and harder difficulty levels; reveal answers inline once checked.

The active learning game persists so returning to the board is a single tap.

## User interface & responsiveness

- The mobile header condenses into a menu and status toggle while desktop keeps settings and history buttons inline.
- Dice tray animations react to rolls, the dice faces render classic pip layouts in the refreshed mint hue instead of numerals, and the dice themselves are now the roll trigger—your first tap starts the round, so there's no Start Game button to chase. When you do shut the box, a trophy celebration erupts above the tray and the multi-player winners modal echoes the moment with a confetti-backed highlight card.
- Neon attention glows wrap the dice tray when it's time to roll or restart and surround the tile grid while resolving the active combination so the next action is unmistakable.
- Status chips display round, phase, active player, roster size, previous winners, and hint status when enabled.
- Multi-player sessions surface a streamlined turn status card on the main board that highlights whose turn is next before a round begins and then gets out of the way once play starts. The active player's name also appears alongside the phase header for quick reference.
- Progress cards show tiles closed, selected totals, available combinations, and completion percentage, while toast notifications announce next turns.
- Multiple SwiftUI themes deliver neon, grid, wood, and felt aesthetics with a single toggle.

## Getting started

1. Open **Xcode 15 or newer** on macOS 14 or later.
2. Double-click `ShutTheBoxApp.xcodeproj` to open the project.
3. Update the bundle identifier and signing team if you plan to deploy to a physical device.
4. Select the **ShutTheBoxApp** scheme and build/run the app on the iOS Simulator or a connected device.
5. Optionally tweak the deployment target in the project settings if you need to support earlier OS versions.

The project relies exclusively on the standard SwiftUI and Foundation frameworks, so no extra dependencies are required.

## Continuous integration

GitHub Actions automatically builds the project on every push to `main` and on pull requests using Xcode 16.2. The workflow lives at [`.github/workflows/ios-build.yml`](.github/workflows/ios-build.yml) and runs `xcodebuild` against the shared **ShutTheBoxApp** scheme with code-signing disabled. Asset symbol generation remains disabled in the project settings, the CI command now pins `-sdk iphoneos` alongside `-destination 'generic/platform=iOS'` to ensure the device SDK is selected, and it passes `ENABLE_PREVIEWS=NO` plus `ASSETCATALOG_COMPILER_INCLUDE_SIMULATOR_PLATFORMS=NO`. Building directly against the device SDK avoids simulator runtime mismatches on GitHub-hosted runners while keeping the asset catalog valid for the iPhone-only target.

## Testing

Automated UI and unit tests are not included yet. Use the iOS Simulator to validate the gameplay flow and confirm that persistence, learning games, and theming behave as expected.

## License

This port follows the licensing terms of the original project. Update this section with a specific license if needed.
