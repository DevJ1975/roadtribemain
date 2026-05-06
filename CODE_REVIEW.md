# Code Review — `claude/review-swift-code-6MzqQ`

Audit, refactor, and test pass over the uploaded Swift source set.

## TL;DR

- **72 Swift files, ~8,500 LOC** were reviewed end-to-end.
- **One real crash**, **one logic bug**, and a handful of hardening fixes were
  applied — all on the working branch.
- A duplicated meters-to-miles haversine helper was factored into a shared
  utility (`MeasurementConstants` + `CoordinatePathMath`).
- **Critical gap surfaced**: `RankTier`, `DesignSystem`, several SwiftUI
  views, and a few helpers referenced throughout the source were *not in the
  uploaded files*. The codebase as uploaded does not compile. `RankTier` and a
  placeholder `DesignSystem` were added; the missing SwiftUI views are listed
  below as TODOs (not stubbed because they involve too many design decisions).
- ~150 unit tests added across 9 XCTest files under `Tests/RoadTribeTests/`.
- Branch state: `main`, `claude/review-swift-code-6MzqQ`, and both `origin/*`
  branches all started at the same commit (`84a617d`) — there were no
  divergent branches to merge.

## Bugs fixed

### 1. `Dictionary(uniqueKeysWithValues:)` crash on duplicate profile IDs

**File**: `Core/Services/SocialService.swift`

Original code traps if any two profiles share an ID — possible during SwiftData
syncs or when inserting mock data alongside a live record:

```swift
Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
```

Replaced with the uniqueing-keys variant that keeps the first profile.

### 2. Wheel straight (A-2-3-4-5) misclassified by `PokerHandEvaluator`

**File**: `Core/Models/PokerRun.swift`

With ranks sorted descending, A-2-3-4-5 became `[14, 5, 4, 3, 2]`, and the
strict consecutive-difference check rejected it as a non-straight. Added an
explicit wheel-straight branch and tightened the standard-straight test to
also require five distinct ranks (so something like `[14, 5, 5, 4, 3]` doesn't
slip through). The Royal Flush check was narrowed to the high (10-J-Q-K-A)
straight — the wheel suited still resolves to "Straight Flush".

### 3. Negative-duration formatter

**File**: `Core/Models/RecordedRoute.swift`

`formattedDuration` produced "-1m" if `endDate < startDate`. Now clamps to
zero. The underlying `durationSeconds` value is unchanged.

## Hardening / edge-case fixes

| File | Change |
| ---- | ------ |
| `Core/Models/Motorcycle.swift` | `estimatedRange` returns `0` for non-positive capacity or MPG instead of producing a negative or zero range silently. |
| `Core/Services/NotificationService.swift` | `scheduleMaintenanceReminder` clamps `averageDailyMiles` to `>= 1` before dividing — protects against zero or negative values from a corrupt/fresh model. |
| `Core/Services/FuelAlertService.swift` | Guards on `estimatedRange == 0`. The threshold logic was confusing (`> warningThreshold * 0.75`) — rewritten to a single intuitive rule: warn when the nearest gas station is more than 15% of the bike's full-tank range away. |
| `Core/Services/RTBeaconService.swift` | Elapsed-timer task now captures `[weak self]`. |
| `Core/Models/RoadHazard.swift` | Magic 86400 replaced with a named `expirationInterval` constant. Uses `Date.now` consistently. |
| `Core/Models/RiderPresence.swift` | Magic 300-second stale window replaced with a named `staleAfter` constant. |
| `Core/Utilities/GPXExporter.swift` | Filename sanitiser strips control characters and the full set of filesystem-reserved chars, and falls back to `"trip"` when the title sanitises to empty (otherwise the file would have been hidden as `.gpx`). |

## Refactor — deduplicated math

A new file `Core/Utilities/MeasurementConstants.swift` introduces:

- `MeasurementConstants.metersPerMile`, `mphPerMps`, `secondsPerDay`,
  `movingSpeedThresholdMPH`
- Convenience `Double` extensions: `.metersToMiles`, `.milesToMeters`,
  `.mpsToMph`
- `CoordinatePathMath.distanceMeters([CLLocationCoordinate2D])` /
  `.distanceMiles([CLLocationCoordinate2D])`

These replace the duplicated haversine-via-`CLLocation.distance` loops and
hard-coded `1609.344` / `2.23694` constants in:

- `Core/Models/Trip.swift` (`totalDistanceMiles`)
- `Core/Models/RecordedRoute.swift` (`distanceMiles`, `RoutePoint.speedMPH`,
  `avgSpeedMPH` threshold)
- `Core/Services/LocationService.swift` (`currentSpeedMPH`)
- `Core/Services/FuelAlertService.swift` (distance conversion)
- `Core/Services/NotificationService.swift` (seconds-per-day)

## New files

| Path | Purpose |
| ---- | ------- |
| `Core/Models/RankTier.swift` | Full implementation of the rider rank system (Prospect → Legend) inferred from `RTRankEvent`/`RTXPService`/`UserProfile` callsites. Persistent raw values are explicit and ordered. |
| `Core/DesignSystem/DesignSystem.swift` | **Placeholder** for `DesignSystem.Spacing`, `Colors`, `Icons`, `Haptics` plus `Spacing` / `CornerRadius` typealiases and `Font.rt*` extensions. Replace with the project's authoritative tokens before shipping. |
| `Core/Utilities/MeasurementConstants.swift` | Shared distance/speed/time constants and helpers. |
| `Tests/RoadTribeTests/*.swift` | ~150 unit tests across 9 files. See `Tests/RoadTribeTests/README.md` for setup. |

## Missing types — not stubbed

These are referenced by the uploaded code but have no definition in the
uploaded files. They were likely outside the upload scope. If they don't exist
in the wider project, they need to be created — they are too view-design-dependent
for me to invent. The reference sites are listed so they're easy to track down.

| Symbol | Referenced from |
| ------ | --------------- |
| `AppDelegate` (with `locationService`, `voiceChannelService`, `rideTrackingService` properties) | `App/CarPlaySceneDelegate.swift` |
| `CommunityDestination` (enum with `.publicProfile(UserProfile)`) | `App/AppRouter.swift` |
| `RTTabBar(selectedTab:)` | `ContentView.swift` |
| `RTSOSPill` | `ContentView.swift` |
| `RTCallForHelpView` | `ContentView.swift` |
| `RTRankUpCelebrationView(fromRank:toRank:totalXP:)` | `ContentView.swift` |
| `VoiceChannelOverlay`, `RideBannerOverlay` | `ContentView.swift` |
| `SocialFeedView`, `TripMapView`, `CommunityHubView`, `ProfileView` | `ContentView.swift` |

## Notable findings I did *not* change

- `Core/Services/SupabaseService.swift` exposes a Supabase URL and a
  *publishable* key. The publishable key is intended to be public, so this is
  fine — but consider moving them to an `Info.plist` value or build-time
  configuration so the URL isn't tied to source.
- `Core/Services/PersistenceService.swift` deletes the entire on-disk store
  when migration fails. Acceptable during development, but ship-blocker
  before a public release — replace with proper `SchemaMigrationPlan`.
- `Core/Services/MockDataSeeder.swift` is wired to run automatically inside
  `seed(context:)` whenever the database is empty, including in production.
  Consider gating with a debug flag.
- `RTXPService.addXP(_:source:profile:context:)` accepts `amount` but never
  reads `XPSource.baseXP` — callers must pass the value explicitly. A
  `addXP(from source: XPSource)` convenience that pulls `source.baseXP`
  would prevent drift between the source's base value and the awarded amount.
- `RiderRadarService.loadNearbyPresences` auto-seeds mock presence data when
  empty — fine for previews/early demos, but should be gated before launch so
  it doesn't seed real users' devices.

## Quick-win features (added in a follow-up commit)

### 1. Fuel-level tracking
- `Motorcycle` gained `lastFillUpMileage` / `lastFillUpDate`, plus
  `milesSinceFillUp(currentMileage:)`, `remainingRangeMiles(currentMileage:)`,
  `remainingFuelFraction(currentMileage:)`, and `recordFillUp(at:on:)`.
- `FuelAlertService.evaluate` now uses real remaining range when a fill-up has
  been recorded (falls back to full-tank estimate otherwise).
- Decision rule extracted as `FuelAlertService.shouldWarn(distanceToStationMiles:remainingRangeMiles:)`
  for clean unit testing — warns when the station is ≥ 60% of remaining range away.

### 2. Maintenance due dashboard
- New `Core/Services/MaintenanceDueService.swift` — pure-logic. `upcomingServices(for:)`
  returns `[MaintenanceDueItem]` sorted by miles-until-due, with overdue / upcoming
  flags. `reminderTriples(from:)` adapts the result to the shape
  `NotificationService.scheduleReminders(for:upcomingServices:)` already accepts.
- New `Features/Maintenance/MaintenanceDueView.swift` — list view with Overdue / Coming
  Up / On the Horizon sections and a "Remind Me" toolbar action that funnels through
  the existing `NotificationService`.

### 3. Trip stats summary
- `RouteElevation.gainMeters(altitudes:)` added to `MeasurementConstants.swift` —
  sums positive altitude deltas only.
- `RecordedRoute` exposes `elevationGainMeters` / `elevationGainFeet`.
- New `Features/Rides/RideStatsCard.swift` — drop-in summary card showing
  distance, duration, max & avg speed, elevation gain, and point count.

### 4. Quick journal capture
- `CreateJournalEntryView` accepts an optional `JournalEntryPrefill` (title,
  content, mood, trip, location/coords, weather string). Existing call sites
  using `CreateJournalEntryView()` continue to work.
- New `Features/Journal/QuickJournalCaptureView.swift` — sheet content for the
  ride banner. Pulls active trip from `RideTrackingService`, current GPS &
  reverse-geocoded location from `LocationService`, and current conditions from
  `RoadWeatherService`. Title-suggestion logic is a static pure helper for tests.

### 5. GPX share sheet
- New `Features/Rides/GPXShareLink.swift` — wraps `ShareLink` with
  `GPXExporter.exportToFile`. Provides `ExportedGPX: Transferable` and a
  convenience initialiser for the standard "Share GPX" label.

### Tests
- `Tests/RoadTribeTests/FeatureTests.swift` covers the testable surface of
  every feature above (~30 cases). The SwiftUI views themselves are not unit
  tested — preview-driven manual verification only.

### Wiring into existing host views

- **`RidesHubView`** — added `@Environment(RideTrackingService.self)` and
  `@Query Motorcycle` lookups. Toolbar now shows:
  - a **Quick Note** button (top-leading) while `rideTracking.isRiding`,
    presenting `QuickJournalCaptureView`
  - a **wrench icon** (top-trailing) navigating to
    `MaintenanceDueView(motorcycle:)` when a bike is on file
  - the existing `+` action is preserved
- **`MaintenanceDestination`** enum added so the Rides hub's
  `NavigationStack` can route to the maintenance dashboard.
- **`RecordedRouteView`** — replaced the inline 4-cell stats row with
  `RideStatsCard(route:)` (gains elevation), and the inline elevation-gain
  calc now reads `route.elevationGainFeet`. Toolbar gained `GPXShareLink(route:)`,
  disabled when the track has no points.
- **`MaintenanceDueView`** — summary header now shows fuel status (% tank /
  miles remaining since last fill-up, or "No fill-up recorded") and offers
  a **Record Fill-up** button presenting `RecordFillUpSheet` — a compact
  odometer + date form that calls `motorcycle.recordFillUp(at:on:)`.
- **`GPXExporter`** — gained `generateGPX(for: RecordedRoute)` (with
  `<ele>` and `<time>` per trkpt) and `exportToFile(route:)`.
- **`GPXShareLink`** — overloaded init accepts either a `Trip` or a
  `RecordedRoute`.

## Missing-symbol fill-in (commit `<this>`)

Every type previously listed under "Missing types — not stubbed" now has an
implementation in the uploaded source:

| Symbol | New file |
| ------ | -------- |
| `RTTabBar` | `Features/Shared/RTTabBar.swift` — custom tab bar with material background, brand-tinted selection, light haptic on switch. |
| `RTSOSPill` | `Features/Shared/RTSOSPill.swift` — red capsule that flips to "Beacon Active" with pulsing wave icon and elapsed time when a beacon is running. |
| `RTCallForHelpView` | `Features/Shared/RTCallForHelpView.swift` — full-screen distress beacon flow (form → active state with cancel/resolve), wired to `RTBeaconService`. |
| `RTRankUpCelebrationView` | `Features/Shared/RTRankUpCelebrationView.swift` — rank-tier-coloured gradient, animated badge, "Keep Riding" dismiss. |
| `VoiceChannelOverlay` | `Features/Shared/VoiceChannelOverlay.swift` — top-floating capsule with current speaker, mic level meter, mute toggle. |
| `RideBannerOverlay` | `Features/Shared/RideBannerOverlay.swift` — top-floating ride-in-progress banner with elapsed time, distance, quick-journal button, end-ride confirmation. |
| `SocialFeedView` | `Features/Feed/SocialFeedView.swift` — chronological post feed with author lookup and like state. |
| `TripMapView` | `Features/Map/TripMapView.swift` — live rider radar, distress beacons, road hazards, memorials on a `MapKit` map. |
| `CommunityHubView` + `CommunityDestination` + `PublicProfileView` | `Features/Community/CommunityHubView.swift` — segmented Tribes / Events / People with follow toggle on profile detail. |
| `ProfileView` | `Features/Profile/ProfileView.swift` — current-user header, rank progress bar, garage list, sign-out. |
| `TripDetailView` | `Features/Trips/TripDetailView.swift` — header, map with polyline, stats, waypoints, journal entries, Start/End ride action, GPX share toolbar. |
| `CreateTripView` | `Features/Trips/CreateTripView.swift` — title/description/date form. |
| `TripCardView` | `Features/Trips/TripCardView.swift` — card row used by `RidesHubView`. |
| `RideWeatherView` | `Features/Weather/RideWeatherView.swift` — current conditions, hourly forecast, alerts, driven by `RoadWeatherService`. |
| `AppDelegate` | `App/AppDelegate.swift` — `UIApplicationDelegate` stub with shared service properties; routes the CarPlay scene to `CarPlaySceneDelegate`. |
| `MaintenanceDestination` | already shipped with the maintenance dashboard. |

These are minimum-viable implementations that compile and exercise the
existing models and services. Visual polish, animations, and asset-cataloged
colours are deliberately left to the project's design pass.

## Branch sync

All four refs (`main`, `claude/review-swift-code-6MzqQ`,
`origin/main`, `origin/claude/review-swift-code-6MzqQ`) pointed at commit
`84a617d` before this work — there was nothing to merge. After committing the
review work, the working branch is fast-forwardable into `main` cleanly.
