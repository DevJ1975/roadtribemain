# RoadTribeTests

XCTest unit tests for the Core layer.

## Setup in Xcode

These tests are written as standard `XCTest` cases targeting the same module the
app code lives in (`@testable import RoadTribe`). They are *not* wired into a
`Package.swift` because the project uses SwiftData, MapKit, SwiftUI, and UIKit
APIs that are tied to the iOS application target.

To run them:

1. In Xcode, **File → New → Target → Unit Testing Bundle**.
   - Product Name: `RoadTribeTests`
   - Target to be Tested: `RoadTribe` (the iOS app target)
2. Delete the auto-generated stub test file Xcode creates.
3. Drag every `*.swift` file in this `Tests/RoadTribeTests/` directory into the
   new test bundle group, and verify the **Target Membership** check on the
   right-hand inspector points only at `RoadTribeTests`.
4. Run with `⌘ U`.

If the app target's product module name is something other than `RoadTribe`,
update the `@testable import` line in each test file to match.

## What's covered

| Suite | File |
| ----- | ---- |
| `MeasurementConstants` & `CoordinatePathMath` | `MeasurementConstantsTests.swift` |
| `CLLocationCoordinate2D+Ext` & `Date+Ext`     | `ExtensionsTests.swift` |
| `RankTier` (XP boundaries, ordering, next)    | `RankTierTests.swift` |
| Models — `Motorcycle`, `RecordedRoute`, `Trip`, `Conversation`, `VoiceChannel`, `PreRideCheck`, `PackingList`, `RoadHazard`, `RiderPresence`, `RideChallenge` | `ModelTests.swift` |
| `PlayingCard` codec & `PokerHandEvaluator`    | `PokerTests.swift` |
| `Formatters` & `GPXExporter`                  | `UtilityTests.swift` |
| `RTXPService`, `XPSource`, `SocialService`, `RTBeaconService`, `RideTrackingService` | `ServiceTests.swift` |
| Enum display/icon/color metadata, `Codable` round-trips | `EnumTests.swift` |
| `AppRouter`, `AppTab`, `TripDestination`      | `AppRouterTests.swift` |

## What's not covered

Excluded by design — these need integration tests, simulator-only frameworks,
or live network access:

- SwiftUI view bodies (`Features/**` views, `ContentView`)
- CarPlay scene/template flow (`App/CarPlayMapManager`, `CarPlaySceneDelegate`)
- `LocationService` GPS streams (requires `CLLocationManager` mocking)
- `WeatherService` / WeatherKit calls (requires entitlements + network)
- `MapService` MapKit search (requires network)
- `NotificationService` actual `UNUserNotificationCenter` scheduling
- `AuthService` Sign-in-with-Apple + Supabase round-trip
- `VoiceChannelService` AVAudioEngine VAD (requires mic + simulator audio)
- Persistence — round-trip through `ModelContainer` for every `@Model` (the
  beacon test exercises one path; full coverage would require an in-memory
  container per test class)

For these, prefer UI tests (`XCUITest`) or dedicated integration suites with
mocked services.
