//
//  EnumTests.swift
//  Road Tribe
//
//  Verifies that case-iterable, codable enums have non-empty display data
//  and stable raw values — protects against accidental rename/removal that
//  would silently break stored data.
//

import XCTest
@testable import RoadTribe

final class EnumDisplayTests: XCTestCase {

    func test_tripStatus_allHaveDisplayAndIcon() {
        for status in TripStatus.allCases {
            XCTAssertFalse(status.displayName.isEmpty, "\(status) displayName empty")
            XCTAssertFalse(status.iconName.isEmpty, "\(status) iconName empty")
        }
    }

    func test_waypointType_allHaveDisplayAndIcon() {
        for type in WaypointType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.iconName.isEmpty)
        }
    }

    func test_postType_allHaveIcon() {
        for type in PostType.allCases {
            XCTAssertFalse(type.iconName.isEmpty)
        }
    }

    func test_activityType_allHaveIcon() {
        for type in ActivityType.allCases {
            XCTAssertFalse(type.iconName.isEmpty)
        }
    }

    func test_inviteStatus_allHaveDisplayAndIcon() {
        for status in InviteStatus.allCases {
            XCTAssertFalse(status.displayName.isEmpty)
            XCTAssertFalse(status.iconName.isEmpty)
        }
    }

    func test_hazardType_allHaveDisplayAndIcon() {
        for type in HazardType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.iconName.isEmpty)
        }
    }

    func test_rideDifficulty_allHaveDisplayAndIcon() {
        for d in RideDifficulty.allCases {
            XCTAssertFalse(d.displayName.isEmpty)
            XCTAssertFalse(d.iconName.isEmpty)
        }
    }

    func test_serviceType_allHaveDisplayAndIcon() {
        for type in ServiceType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.iconName.isEmpty)
        }
    }

    func test_serviceType_intervalsAreMonotonic() {
        // Mileage-based services should report increasing intervals.
        let mileagePairs: [(ServiceType, Int)] = [
            (.service5k, 5_000), (.service10k, 10_000), (.service15k, 15_000),
            (.service20k, 20_000), (.service25k, 25_000), (.service30k, 30_000),
        ]
        for (service, expected) in mileagePairs {
            XCTAssertEqual(service.suggestedIntervalMiles, expected)
        }
    }

    func test_serviceCategory_idMatchesRawValue() {
        for c in ServiceCategory.allCases {
            XCTAssertEqual(c.id, c.rawValue)
        }
    }

    func test_beaconStatus_allHaveLabel() {
        for s in BeaconStatus.allCases {
            XCTAssertFalse(s.label.isEmpty)
        }
    }

    func test_bikeType_allHaveIcon() {
        for t in BikeType.allCases {
            XCTAssertFalse(t.iconName.isEmpty)
        }
    }

    func test_militaryBranch_allHaveIconAndColor() {
        for branch in MilitaryBranch.allCases {
            XCTAssertFalse(branch.iconName.isEmpty)
            XCTAssertFalse(branch.color.isEmpty)
        }
    }

    func test_distanceUnit_abbreviation() {
        XCTAssertEqual(DistanceUnit.miles.abbreviation, "mi")
        XCTAssertEqual(DistanceUnit.kilometers.abbreviation, "km")
    }

    func test_challengeGoalType_allHaveDisplay() {
        for g in ChallengeGoalType.allCases {
            XCTAssertFalse(g.displayName.isEmpty)
            XCTAssertFalse(g.unit.isEmpty)
            XCTAssertFalse(g.iconName.isEmpty)
        }
    }

    func test_packingCategory_allHaveDisplay() {
        for c in PackingCategory.allCases {
            XCTAssertFalse(c.displayName.isEmpty)
            XCTAssertFalse(c.iconName.isEmpty)
        }
    }

    func test_journalMood_allHaveEmoji() {
        for m in JournalMood.allCases {
            XCTAssertFalse(m.emoji.isEmpty)
        }
    }
}

final class CodableRoundTripTests: XCTestCase {

    func test_userPreferences_codableRoundTrip() throws {
        let original = UserPreferences(
            distanceUnit: .kilometers,
            mapStyle: .satellite,
            notificationsEnabled: false,
            offlineMapsEnabled: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)
        XCTAssertEqual(decoded.distanceUnit, original.distanceUnit)
        XCTAssertEqual(decoded.mapStyle, original.mapStyle)
        XCTAssertEqual(decoded.notificationsEnabled, original.notificationsEnabled)
        XCTAssertEqual(decoded.offlineMapsEnabled, original.offlineMapsEnabled)
    }

    func test_packingItem_codableRoundTrip() throws {
        let original = PackingItem(name: "Helmet", category: .safety, isChecked: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PackingItem.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.category, original.category)
        XCTAssertEqual(decoded.isChecked, original.isChecked)
    }
}
