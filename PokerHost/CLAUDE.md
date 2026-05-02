# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode project — there is no Swift Package Manager manifest. Open and build via:

```
open ../PokerStack.xcodeproj
# or
xcodebuild -project ../PokerStack.xcodeproj -scheme PokerStack -destination 'platform=iOS Simulator,name=iPhone 15'
```

There are no unit or UI test targets. All validation is manual.

## Architecture

Single-screen SwiftUI utility app. Not MVVM — state lives directly in `CashSetupView` (@State), and logic is purely functional (no ViewModels).

**Data flow:**
1. User edits fields in `Views/CashSetupView.swift` → @State updates → auto-save via `CashSetupStore`
2. "Calculate Stacks" → `calculate()` runs `ChipAllocator` off-main-thread via `Task.detached`
3. Results populate a modal sheet (`Views/ResultsSheetsView.swift`)

**Key layers:**
- `Logic/ChipAllocator.swift` — pure enum with static methods; the entire allocation algorithm lives here
- `Models/ChipType.swift` — single domain model (`id`, `colorName`, `denominationCents`, `quantity`)
- `Persistence/` — `UserDefaults`-backed JSON stores; no Core Data
- `Design/AppColors.swift` + `Design/CardView.swift` — dark poker-table palette with gold accent; all UI should use these

## Important Quirks

- **`ContentView.swift` is unused.** The app launches `CashSetupView` directly; `ContentView.swift` is a SwiftUI template stub.
- **`AutoDenominationAssigner.swift` is superseded.** The active auto-denomination flow goes through `ChipAllocator.optimizeAuto(...)`, not that file.
- **Denomination `200` → `100` coercion.** When loading saved setups, any `denominationCents == 200` is patched to `100`. This is an intentional backwards-compatibility fix — preserve it carefully.
- **`removeChipRow(id:)` exists in `CashSetupView` but is not wired to any UI element.**
- **Naming leftovers:** The app struct was once named `YourAppNameApp`; some file headers reference old filenames. The UI says "Poker Stack" but the project/folder says "PokerHostHelper".
- **git status has substantial churn** — staged renames and new files are in progress. Avoid reverting or resetting unless asked.

## Persistence Keys

- `PokerStack.savedCashSetup` — current game setup
- `PokerStack.savedChipSets` — named chip set presets (array, sorted newest-first)

## Allocation Algorithm (`Logic/ChipAllocator.swift`)

**Manual mode** (`allocate(...)`): DFS/backtracking to find exact per-player chip combination. Applies reserve % by subtracting `Int(Double(quantity) * reservePercent)` per color. Validates small-blind exactness. Scores by small-blind coverage, low/medium chips, and blind posts; penalizes oversized denominations and stacks far from ~28 chips.

**Auto mode** (`optimizeAuto(...)`): Builds a denomination pool from blind level + buy-in, tries all unique assignments across chip colors, calls manual `allocate(...)` for each, returns highest-scoring result.

## Emerging Features

`Views/TournamentSetupView.swift` and `Persistence/TournamentSetupStore.swift` exist but are incomplete. Treat as work-in-progress.
