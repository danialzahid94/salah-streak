# SalahStreak

An iOS app to track daily prayer completion with streaks, badges, and notifications.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Key Components](#key-components)
- [Building & Running](#building--running)
- [Testing](#testing)
- [Known Issues & TODOs](#known-issues--todos)

## Overview

SalahStreak is an iOS 18.6+ app that helps Muslims track their five daily prayers (Fajr, Dhuhr, Asr, Maghrib, Isha) with features including:

- **Prayer time calculations** using the Adhan library
- **Streak tracking** with current/best streaks and streak freezes
- **Badges system** with unlockable achievements
- **Smart notifications** with cascade reminders and snooze functionality
- **Home screen & lock screen widgets** with interactive "Mark Done" actions
- **Stats & analytics** with weekly activity grid and prayer breakdowns

## Architecture

### MVVM Pattern

The app uses the **Model-View-ViewModel (MVVM)** architecture pattern:

- **Models**: SwiftData entities (`@Model`) and domain models
- **Views**: SwiftUI views that observe ViewModels
- **ViewModels**: `@Observable` classes that manage view state and business logic

### Concurrency Strategy

The codebase uses modern Swift concurrency features:

- **async/await**: For asynchronous operations (location requests, notifications, onboarding flow)
- **Combine**: Available for future reactive bindings (currently imported but not actively used)
- **@MainActor**: Used on async functions that update UI state
- **@Observable**: Swift 6 macro for observable state (replaces `@Published` + `ObservableObject`)

### Dependency Injection

All services are registered in `DependencyContainer.shared`:
- `PrayerTimeService`: Calculates prayer times using Adhan library
- `NotificationService`: Manages local notifications with cascade reminders
- `LocationService`: Handles location permissions and geocoding
- `StreakService`: Computes streaks and processes day-end logic
- `BadgeService`: Awards badges based on achievements

Each service is defined by a protocol (`*ServiceProtocol`) for testability.

## Project Structure

```
SalahStreak/
├── Core/
│   ├── Models/
│   │   ├── Data/                 # SwiftData @Model entities
│   │   │   ├── PrayerEntry.swift
│   │   │   ├── DailyLog.swift
│   │   │   ├── UserStats.swift
│   │   │   └── UserSettings.swift
│   │   ├── Domain/              # Plain Swift structs/enums
│   │   │   ├── Badge.swift
│   │   │   ├── CellStatus.swift # Activity grid cell status
│   │   │   └── PrayerWindow.swift
│   │   └── Enums/               # App-wide enums
│   │       ├── PrayerType.swift
│   │       ├── PrayerStatus.swift
│   │       ├── MadhabType.swift
│   │       └── CalculationMethodType.swift
│   ├── Repositories/            # SwiftData data access layer
│   │   ├── DailyLogRepository.swift
│   │   └── UserStatsRepository.swift
│   └── Services/                # Business logic services
│       ├── Protocols/           # Service protocol definitions
│       ├── PrayerTimeService.swift
│       ├── NotificationService.swift
│       ├── LocationService.swift
│       ├── StreakService.swift
│       └── BadgeService.swift
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── DashboardViewModel.swift
│   ├── Badges/
│   │   ├── BadgesView.swift
│   │   └── BadgesViewModel.swift
│   ├── Stats/
│   │   ├── StatsView.swift
│   │   └── StatsViewModel.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsViewModel.swift
│   └── Onboarding/
│       ├── OnboardingContainerView.swift
│       ├── OnboardingViewModel.swift
│       ├── LocationPermissionView.swift
│       ├── MadhabSelectionView.swift
│       └── GoalSelectionView.swift
├── Navigation/
│   ├── MainTabCoordinator.swift # @Observable tab coordinator
│   └── Route.swift              # Navigation route enum
├── Shared/
│   ├── Theme/
│   │   └── Theme.swift          # Colors, spacing, styling
│   └── WidgetPrayerData.swift   # Shared data model for widgets
└── App/
    ├── SalahStreakApp.swift     # App entry point
    └── AppDelegate.swift        # Notification action handling

SalahStreakWidget/
├── SalahStreakWidget.swift          # Widget entry point
├── SalahStreakWidgetProvider.swift  # Timeline provider
├── SalahStreakWidgetView.swift      # Widget UI
├── MarkDoneIntent.swift             # Interactive "Mark Done" intent
└── WidgetPrayerData.swift           # Duplicate of shared data model

SalahStreakTests/
├── PrayerTimeServiceTests.swift
├── StreakServiceTests.swift
├── BadgeServiceTests.swift
├── PrayerTypeTests.swift
└── WidgetPrayerDataTests.swift
```

## Key Components

### ViewModels

All feature ViewModels follow a consistent pattern:

```swift
@Observable
final class FeatureViewModel {
    // MARK: - Published State
    var property: Type = defaultValue

    // MARK: - Private
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
    func onAppear(context: ModelContext) {
        self.modelContext = context
        loadData()
    }

    // MARK: - Data Loading
    private func loadData() {
        // Fetch from SwiftData
        // Compute derived state
    }

    // MARK: - Actions
    func actionName() {
        // Handle user interactions
    }
}
```

**Key ViewModels:**
- `DashboardViewModel`: Manages prayer cards, live timer (60s updates), streak display
- `BadgesViewModel`: Computes badge unlock status from UserStats
- `StatsViewModel`: Builds weekly activity grid and prayer breakdown
- `SettingsViewModel`: Handles settings changes, notification permissions
- `OnboardingViewModel`: Manages 3-step onboarding flow with async actions

### Data Models

**SwiftData Entities** (`@Model`):
- `PrayerEntry`: Represents a single prayer instance (prayer type, status, times)
- `DailyLog`: Container for all 5 prayer entries for a given day
- `UserStats`: Stores streaks, total prayers, badges, freezes
- `UserSettings`: Stores user preferences (madhab, calculation method, location, notifications)

**Domain Models**:
- `Badge`: Identifiable struct for badge display
- `CellStatus`: Enum for activity grid cell states (done/missed/upcoming/noData)
- `PrayerWindow`: Prayer timing window (start/end/scheduled time)
- `Coordinate`: Location coordinate (latitude/longitude)

### Services

**PrayerTimeService**:
- Uses Adhan library v1.4.0
- Calculates prayer times based on coordinates, date, calculation method, madhab
- Returns `PrayerWindow` array for all 5 daily prayers

**NotificationService**:
- Schedules cascade notifications: at time, -10min, -5min
- Handles notification permissions
- Processes "Mark Done" and "Snooze 20m" actions via AppDelegate

**LocationService**:
- Manages CLLocationManager with delegate pattern
- Requests location permission and one-time location
- Geocodes coordinates to city name with fallback chain (City → Municipality → SubAdministrativeArea)

**StreakService**:
- Computes current/best streaks based on DailyLog history
- Processes day-end logic (auto-miss pending prayers, decrement freezes)

**BadgeService**:
- Awards badges based on achievements:
  - First Prayer: Complete first prayer
  - Perfect Day: All 5 prayers in one day
  - Week Warrior: 7-day streak
  - Month Master: 30-day streak
  - Early Bird: 10 Fajr on time (not yet implemented)
  - Consistent: 50 total prayers

### Widget Extension

**Home Screen Widgets**:
- Small: Shows current/next prayer with countdown
- Medium: Shows 2-3 upcoming prayers with times

**Lock Screen Widgets**:
- Inline: Text-only current prayer info
- Circular: Completion count in circular progress view

**Interactive Intent**:
- `MarkDoneIntent`: AppIntents-based action to mark prayer done from widget
- Updates App Group UserDefaults (`WidgetPrayerData.shared`)
- Reloads all widget timelines

### Navigation

**MainTabCoordinator** (`@Observable`):
- Manages tab selection and per-tab navigation stacks
- Supports `.sheet()` and `.fullScreenCover()` routes
- Navigate via `coordinator.navigate(to: .route)` or `coordinator.showSheet(.route)`

**Route enum**:
```swift
enum Route: Hashable {
    case dashboard
    case badges
    case stats
    case settings
    case onboarding
}
```

## Building & Running

### Prerequisites

- **Xcode 16+** (project uses objectVersion 77 with PBXFileSystemSynchronizedRootGroup)
- **iOS 18.6+** deployment target
- **Development Team**: AYEH6C5B8A

### Manual Setup Required

1. **Add Adhan SPM Package** (must be done in Xcode):
   - File > Add Package Dependencies
   - URL: `https://github.com/batoulapps/adhan-swift`
   - Version: 1.4.0

2. **Enable App Group Entitlement** (Signing & Capabilities tab in Xcode):
   - Main target: Add App Groups capability → `group.com.danial.SalahStreak`
   - Widget target: Add App Groups capability → `group.com.danial.SalahStreak`

3. **Add Location Permission Key**:
   - In Info.plist (or Info tab), add:
     - Key: `NSLocationWhenInUseUsageDescription`
     - Value: "SalahStreak needs your location to calculate accurate prayer times for your area."

### Build Commands

```bash
# Build main app
xcodebuild -scheme SalahStreak -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild test -scheme SalahStreak -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Running in Simulator

1. Open `SalahStreak.xcodeproj` in Xcode
2. Select "SalahStreak" scheme and iPhone simulator
3. Cmd+R to build and run
4. On first launch, complete the 3-step onboarding:
   - Location permission
   - Madhab selection
   - Calculation method & notification setup

## Testing

### Unit Tests

All core services have unit test coverage:

- `PrayerTimeServiceTests`: Validates prayer time calculations
- `StreakServiceTests`: Tests streak computation logic
- `BadgeServiceTests`: Verifies badge awarding rules
- `PrayerTypeTests`: Enum helpers and sorting
- `WidgetPrayerDataTests`: App Group UserDefaults persistence

Run tests:
```bash
xcodebuild test -scheme SalahStreak -destination 'platform=iOS Simulator,name=iPhone 16'
```

Or in Xcode: Cmd+U

### Manual Testing

**Dashboard**:
- Tap prayer card to mark done (only when active/warning state)
- Tap again to undo
- Verify live timer updates every 60s
- Check future prayers are non-interactive

**Badges**:
- Complete prayers to unlock badges
- Tap badge to see detail sheet

**Stats**:
- Weekly grid shows 7 days × 5 prayers
- Color coding: green (done), red (missed), gray (upcoming/no data)
- Prayer breakdown shows total count per prayer type

**Settings**:
- Toggle notifications (prompts for permission if not granted)
- Change calculation method or madhab (prayer times update immediately)

**Widgets**:
- Add widget to home screen via long-press
- Tap "Mark Done" button (only on pending prayers)
- Verify widget updates after marking prayer done in app

## Known Issues & TODOs

### Not Yet Implemented

1. **Adhan SPM Package**: Must be added manually in Xcode (see Building & Running section)
2. **App Group Entitlement**: Must be enabled in Xcode signing settings
3. **Location Permission Key**: Must be added to Info.plist
4. **Day Rollover Logic**: `StreakService.processDayEnd()` needs to be called at midnight or on next app open
5. **Early Bird Badge**: Always shows as locked (needs fajr-on-time counter in UserStats)
6. **watchOS Target**: Deferred (not in MVP scope)

### Areas for Improvement

1. **Error Handling**: Most async operations use `try?` — should present user-facing errors
2. **Loading States**: No loading indicators during data fetches
3. **Empty States**: No empty state UI when no prayers logged yet
4. **Accessibility**: Limited VoiceOver support and dynamic type
5. **Localization**: Hardcoded English strings, no localization support
6. **Widget Refresh**: Widget only updates when app opens or after mark done action

### Build Warnings

No known build warnings. All Swift 6 concurrency checks pass.

### Technical Debt

- **Combine imports**: Combine framework is imported in ViewModels but not actively used (can be removed)
- **Duplicate WidgetPrayerData**: Widget target requires duplicate file (Xcode limitation)
- **Hardcoded values**: App version "1.0.0" hardcoded in SettingsViewModel
- **Location refresh logic**: `hasRefreshedLocationThisLaunch` static flag is brittle

## Git Repository

- **Repo**: https://github.com/danialzahid94/salah-streak
- **Auth**: SSH (danialzahid94)
- **Branch**: main

### Commit History

1. Initial Xcode project scaffold
2. Core app: MVVM structure, models, services, all features
3. Widget extension with interactive Mark Done intent
4. Unit tests for core services and data layer
5. Fix all compilation errors (clean build confirmed)
6. Fix onboarding (button visibility, progress bar, madhab selection)
7. Fix notification permissions, prayer time refresh, city geocoding, stats activity grid

### Recent Refactor

The codebase was recently refactored to:
- Extract ViewModels from Views into separate files
- Move ViewModels to correct feature directories (Badges/, Onboarding/, Settings/, Stats/)
- Use `@Observable` instead of `ObservableObject`
- Remove duplicate Coordinate struct definition
- Extract CellStatus enum to shared file

## Development Notes

### Swift 6 Strict Concurrency

The project uses Swift 6 with strict concurrency checking enabled:
- All ViewModels use `@Observable` macro
- Async functions that update state are marked `@MainActor`
- Services are accessed via `DependencyContainer.shared`

### SwiftData Best Practices

- Models use `@Model` macro (no manual `init()` needed unless all properties have defaults)
- Enum defaults in `@Model` classes must be fully qualified (e.g., `.shafi` not `MadhabType.shafi`)
- Repositories pattern used for data access to keep ViewModels clean
- `@Query` macro used in views for live data updates

### AppIntents for Widgets

- `MarkDoneIntent` uses AppIntents framework (not Intents framework)
- `@Parameter` properties have backing storage provided by attribute (don't set defaults manually)
- Must provide both `init() {}` and `init(param: T)` for parameters
- Widget data shared via App Group UserDefaults (not app-to-widget IPC)

### Common Pitfalls

- **CLGeocoder**: Callback-based, wrap in `withCheckedContinuation` for async/await
- **Timer.scheduledTimer**: `repeats:` parameter is required
- **NavigationPath**: No `.removeAll()` method — assign `= NavigationPath()` instead
- **ForEach enums**: Must conform to `Identifiable` with `var id: String { rawValue }`
- **SwiftUI ButtonStyle**: Default style overrides `.background()` — use `.buttonStyle(.plain)` or apply styling in `label:` closure
- **Optional chaining precedence**: `optional?.prop == .value ?? false` parses incorrectly — use `(optional?.prop == .value) ?? false`

## Resources

- **Adhan Swift**: https://github.com/batoulapps/adhan-swift
- **SwiftData Documentation**: https://developer.apple.com/documentation/swiftdata
- **AppIntents Documentation**: https://developer.apple.com/documentation/appintents
- **WidgetKit Documentation**: https://developer.apple.com/documentation/widgetkit

## License

[Add license information here]

## Contributors

- Danial Zahid (@danialzahid94)
- Built with assistance from Claude Code (Anthropic)

---

*Last updated: 2026-02-05*
