//
//  ModelTests.swift
//  Road Tribe
//
//  Tests for SwiftData @Model classes — exercises computed properties and
//  validation logic, not persistence (those need a ModelContainer harness
//  and live in their own integration test).
//

import XCTest
import CoreLocation
@testable import RoadTribe

// MARK: - Motorcycle

final class MotorcycleTests: XCTestCase {

    func test_estimatedRange_normalCase() {
        let bike = Motorcycle(name: "Test", fuelCapacityGallons: 5, averageMPG: 40)
        XCTAssertEqual(bike.estimatedRange, 200, accuracy: 1e-9)
    }

    func test_estimatedRange_zeroFuelOrMPG_isZero() {
        XCTAssertEqual(Motorcycle(name: "A", fuelCapacityGallons: 0, averageMPG: 40).estimatedRange, 0)
        XCTAssertEqual(Motorcycle(name: "B", fuelCapacityGallons: 5, averageMPG: 0).estimatedRange, 0)
    }

    func test_estimatedRange_negativeInputs_isZero() {
        XCTAssertEqual(Motorcycle(name: "C", fuelCapacityGallons: -1, averageMPG: 40).estimatedRange, 0)
        XCTAssertEqual(Motorcycle(name: "D", fuelCapacityGallons: 5, averageMPG: -10).estimatedRange, 0)
    }

    func test_defaultYear_isCurrentYear() {
        let bike = Motorcycle(name: "Default")
        let currentYear = Calendar.current.component(.year, from: .now)
        XCTAssertEqual(bike.year, currentYear)
    }
}

// MARK: - RecordedRoute / RoutePoint

final class RecordedRouteTests: XCTestCase {

    private func makePoint(_ lat: Double, _ lon: Double, mps: Double = 0) -> RoutePoint {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            altitude: 0,
            horizontalAccuracy: 1,
            verticalAccuracy: 1,
            course: 0,
            speed: mps,
            timestamp: .now
        )
        return RoutePoint(from: location)
    }

    func test_distanceMiles_withFewerThanTwoPoints_isZero() {
        let route = RecordedRoute(title: "")
        XCTAssertEqual(route.distanceMiles, 0)

        route.points = [makePoint(0, 0)]
        XCTAssertEqual(route.distanceMiles, 0)
    }

    func test_distanceMiles_matchesCoordinatePathMath() {
        let route = RecordedRoute(title: "")
        route.points = [makePoint(0, 0), makePoint(0, 1), makePoint(0, 2)]
        let expected = CoordinatePathMath.distanceMiles(route.points.map(\.coordinate))
        XCTAssertEqual(route.distanceMiles, expected, accuracy: 1e-6)
    }

    func test_maxSpeedMPH_emptyRoute_isZero() {
        let route = RecordedRoute(title: "")
        XCTAssertEqual(route.maxSpeedMPH, 0)
    }

    func test_maxSpeedMPH_returnsHighestNonNegativeSample() {
        let route = RecordedRoute(title: "")
        route.points = [
            makePoint(0, 0, mps: 5),    // ~11 MPH
            makePoint(0, 1, mps: 30),   // ~67 MPH
            makePoint(0, 2, mps: -1),   // invalid → 0
        ]
        XCTAssertEqual(route.maxSpeedMPH, 30 * MeasurementConstants.mphPerMps, accuracy: 1e-6)
    }

    func test_avgSpeedMPH_excludesStoppedSamples() {
        let route = RecordedRoute(title: "")
        // 0 mps and 1 mps samples are below the moving threshold
        route.points = [
            makePoint(0, 0, mps: 0),
            makePoint(0, 1, mps: 1),    // ~2.2 MPH (below threshold)
            makePoint(0, 2, mps: 10),   // ~22.4 MPH
            makePoint(0, 3, mps: 20),   // ~44.7 MPH
        ]
        let movingMPHs = [10.0, 20.0].map { $0 * MeasurementConstants.mphPerMps }
        let expected = movingMPHs.reduce(0, +) / Double(movingMPHs.count)
        XCTAssertEqual(route.avgSpeedMPH, expected, accuracy: 1e-6)
    }

    func test_avgSpeedMPH_allStopped_isZero() {
        let route = RecordedRoute(title: "")
        route.points = [makePoint(0, 0, mps: 0), makePoint(0, 1, mps: 0)]
        XCTAssertEqual(route.avgSpeedMPH, 0)
    }

    func test_durationSeconds_withoutEndDate_isZero() {
        let route = RecordedRoute(title: "")
        XCTAssertEqual(route.durationSeconds, 0)
    }

    func test_durationSeconds_withEndDate_isPositive() {
        let route = RecordedRoute(title: "")
        route.endDate = route.startDate.addingTimeInterval(123)
        XCTAssertEqual(route.durationSeconds, 123, accuracy: 1e-9)
    }

    func test_formattedDuration_underAnHour_omitsHourComponent() {
        let route = RecordedRoute(title: "")
        route.endDate = route.startDate.addingTimeInterval(45 * 60) // 45 min
        XCTAssertEqual(route.formattedDuration, "45m")
    }

    func test_formattedDuration_overAnHour_includesHours() {
        let route = RecordedRoute(title: "")
        route.endDate = route.startDate.addingTimeInterval(2 * 3600 + 5 * 60) // 2h 5m
        XCTAssertEqual(route.formattedDuration, "2h 5m")
    }

    func test_formattedDuration_negativeDuration_clampsToZero() {
        let route = RecordedRoute(title: "")
        route.endDate = route.startDate.addingTimeInterval(-100)
        XCTAssertEqual(route.formattedDuration, "0m")
    }

    func test_pointsRoundTrip_throughEncoding() {
        let route = RecordedRoute(title: "")
        let original = [makePoint(1, 2, mps: 3), makePoint(4, 5, mps: 6)]
        route.points = original
        let recovered = route.points
        XCTAssertEqual(recovered.count, original.count)
        for (a, b) in zip(recovered, original) {
            XCTAssertEqual(a.latitude,  b.latitude,  accuracy: 1e-9)
            XCTAssertEqual(a.longitude, b.longitude, accuracy: 1e-9)
            XCTAssertEqual(a.speedMPS,  b.speedMPS,  accuracy: 1e-9)
        }
    }

    func test_invalidEncodedData_yieldsEmptyPoints() {
        let route = RecordedRoute(title: "")
        route.pointsData = Data([0xFF, 0x00, 0xAB])
        XCTAssertEqual(route.points.count, 0)
    }
}

// MARK: - RoutePoint

final class RoutePointTests: XCTestCase {

    func test_speedMPH_negativeMPS_isZero() {
        let location = CLLocation(
            coordinate: .init(latitude: 0, longitude: 0),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 0, speed: -1, timestamp: .now
        )
        XCTAssertEqual(RoutePoint(from: location).speedMPH, 0)
    }

    func test_speedMPH_positiveMPS_convertsToMPH() {
        let location = CLLocation(
            coordinate: .init(latitude: 0, longitude: 0),
            altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1,
            course: 0, speed: 10, timestamp: .now
        )
        XCTAssertEqual(RoutePoint(from: location).speedMPH,
                       10 * MeasurementConstants.mphPerMps,
                       accuracy: 1e-6)
    }

    func test_codable_roundTrip() throws {
        let location = CLLocation(
            coordinate: .init(latitude: 1, longitude: 2),
            altitude: 100, horizontalAccuracy: 5, verticalAccuracy: 5,
            course: 0, speed: 12, timestamp: .now
        )
        let original = RoutePoint(from: location)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RoutePoint.self, from: data)
        XCTAssertEqual(decoded.latitude, original.latitude, accuracy: 1e-9)
        XCTAssertEqual(decoded.longitude, original.longitude, accuracy: 1e-9)
        XCTAssertEqual(decoded.altitude, original.altitude, accuracy: 1e-9)
        XCTAssertEqual(decoded.speedMPS, original.speedMPS, accuracy: 1e-9)
    }
}

// MARK: - Trip

final class TripTests: XCTestCase {

    func test_totalDistanceMiles_withFewerThanTwoWaypoints_isZero() {
        let trip = Trip(title: "X")
        XCTAssertEqual(trip.totalDistanceMiles, 0)
        let only = Waypoint(name: "only", latitude: 0, longitude: 0, sortOrder: 0)
        trip.waypoints = [only]
        XCTAssertEqual(trip.totalDistanceMiles, 0)
    }

    func test_totalDistanceMiles_usesSortOrderNotInsertionOrder() {
        let trip = Trip(title: "X")
        let a = Waypoint(name: "a", latitude: 0, longitude: 0, sortOrder: 0)
        let c = Waypoint(name: "c", latitude: 0, longitude: 2, sortOrder: 2)
        let b = Waypoint(name: "b", latitude: 0, longitude: 1, sortOrder: 1)
        trip.waypoints = [c, a, b] // intentionally out of order
        let expected = CoordinatePathMath.distanceMiles([a.coordinate, b.coordinate, c.coordinate])
        XCTAssertEqual(trip.totalDistanceMiles, expected, accuracy: 1e-6)
    }

    func test_formattedDistance_zeroDistance_isDash() {
        let trip = Trip(title: "X")
        XCTAssertEqual(trip.formattedDistance, "—")
    }
}

// MARK: - JournalMood

final class JournalMoodTests: XCTestCase {

    func test_displayName_capitalizesRawValue() {
        XCTAssertEqual(JournalMood.excited.displayName, "Excited")
        XCTAssertEqual(JournalMood.adventurous.displayName, "Adventurous")
    }

    func test_emoji_isNonEmptyForEveryMood() {
        for mood in JournalMood.allCases {
            XCTAssertFalse(mood.emoji.isEmpty, "\(mood) emoji is empty")
        }
    }
}

// MARK: - Conversation

final class ConversationTests: XCTestCase {

    func test_otherParticipantID_returnsTheOther() {
        let me = UUID()
        let them = UUID()
        let conv = Conversation(participantIDs: [me, them])
        XCTAssertEqual(conv.otherParticipantID(currentUserID: me), them)
        XCTAssertEqual(conv.otherParticipantID(currentUserID: them), me)
    }

    func test_otherParticipantID_returnsNilWhenSelfMissing() {
        let me = UUID()
        let other = UUID()
        let conv = Conversation(participantIDs: [other])
        XCTAssertEqual(conv.otherParticipantID(currentUserID: me), other)
    }

    func test_otherParticipantID_emptyParticipants_isNil() {
        let conv = Conversation(participantIDs: [])
        XCTAssertNil(conv.otherParticipantID(currentUserID: UUID()))
    }
}

// MARK: - VoiceChannel

final class VoiceChannelTests: XCTestCase {

    func test_isFull_isTrueAtMaxParticipants() {
        let participants = (0..<VoiceChannel.maxParticipants).map { _ in UUID() }
        let channel = VoiceChannel(tripID: UUID(), participantIDs: participants)
        XCTAssertTrue(channel.isFull)
    }

    func test_isFull_isFalseBelowMax() {
        let channel = VoiceChannel(tripID: UUID(), participantIDs: [UUID()])
        XCTAssertFalse(channel.isFull)
    }

    func test_participantCount_matchesArrayCount() {
        let ids = [UUID(), UUID(), UUID()]
        let channel = VoiceChannel(tripID: UUID(), participantIDs: ids)
        XCTAssertEqual(channel.participantCount, ids.count)
    }
}

// MARK: - PreRideCheck

final class PreRideCheckTests: XCTestCase {

    func test_flaggedCount_countsFalseValues() {
        let check = PreRideCheck(motorcycleID: UUID(), results: [
            "t_pressure": true, "t_tread": false, "c_levers": false, "l_head": true,
        ])
        XCTAssertEqual(check.flaggedCount, 2)
    }

    func test_flaggedCount_emptyResults_isZero() {
        let check = PreRideCheck(motorcycleID: UUID())
        XCTAssertEqual(check.flaggedCount, 0)
    }

    func test_tclocsCategory_items_areUniqueByID() {
        for category in TclocsCategory.allCases {
            let ids = category.items.map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count, "\(category) has duplicate item IDs")
        }
    }
}

// MARK: - PackingList

final class PackingListTests: XCTestCase {

    func test_isComplete_emptyList_isFalse() {
        let list = PackingList(title: "Empty", items: [])
        XCTAssertFalse(list.isComplete)
    }

    func test_isComplete_allChecked_isTrue() {
        let items = [
            PackingItem(name: "A", category: .safety, isChecked: true),
            PackingItem(name: "B", category: .tools,  isChecked: true),
        ]
        let list = PackingList(title: "X", items: items)
        XCTAssertTrue(list.isComplete)
    }

    func test_isComplete_partial_isFalse() {
        let items = [
            PackingItem(name: "A", category: .safety, isChecked: true),
            PackingItem(name: "B", category: .tools,  isChecked: false),
        ]
        let list = PackingList(title: "X", items: items)
        XCTAssertFalse(list.isComplete)
    }

    func test_checkedCount_matchesCheckedItems() {
        let items = [
            PackingItem(name: "A", category: .safety, isChecked: true),
            PackingItem(name: "B", category: .tools,  isChecked: false),
            PackingItem(name: "C", category: .comfort, isChecked: true),
        ]
        let list = PackingList(title: "X", items: items)
        XCTAssertEqual(list.checkedCount, 2)
        XCTAssertEqual(list.totalCount, 3)
    }

    func test_defaultItems_areUniqueByName() {
        let names = PackingList.defaultItems.map(\.name)
        XCTAssertEqual(Set(names).count, names.count)
    }
}

// MARK: - RoadHazard

final class RoadHazardTests: XCTestCase {

    func test_isExpired_freshHazard_isFalse() {
        let h = RoadHazard(latitude: 0, longitude: 0, hazardType: .pothole, reportedByID: UUID())
        XCTAssertFalse(h.isExpired)
    }

    func test_isExpired_olderThanADay_isTrue() {
        let h = RoadHazard(latitude: 0, longitude: 0, hazardType: .pothole, reportedByID: UUID())
        h.timestamp = Date.now.addingTimeInterval(-(RoadHazard.expirationInterval + 60))
        XCTAssertTrue(h.isExpired)
    }
}

// MARK: - RiderPresence

final class RiderPresenceTests: XCTestCase {

    func test_isStale_recentRecord_isFalse() {
        let p = RiderPresence(riderID: UUID(), displayName: "X")
        XCTAssertFalse(p.isStale)
    }

    func test_isStale_oldRecord_isTrue() {
        let p = RiderPresence(riderID: UUID(), displayName: "X")
        p.lastUpdated = Date.now.addingTimeInterval(-(RiderPresence.staleAfter + 1))
        XCTAssertTrue(p.isStale)
    }
}

// MARK: - RideChallenge

final class RideChallengeTests: XCTestCase {

    func test_isActive_betweenStartAndEnd_isTrue() {
        let c = RideChallenge(
            title: "X",
            goalType: .totalMiles,
            targetValue: 100,
            startDate: .now.addingTimeInterval(-3600),
            endDate: .now.addingTimeInterval(3600)
        )
        XCTAssertTrue(c.isActive)
        XCTAssertFalse(c.isUpcoming)
        XCTAssertFalse(c.isFinished)
    }

    func test_isUpcoming_beforeStart_isTrue() {
        let c = RideChallenge(
            title: "X",
            goalType: .totalMiles,
            targetValue: 100,
            startDate: .now.addingTimeInterval(3600),
            endDate: .now.addingTimeInterval(7200)
        )
        XCTAssertTrue(c.isUpcoming)
        XCTAssertFalse(c.isActive)
    }

    func test_isFinished_afterEnd_isTrue() {
        let c = RideChallenge(
            title: "X",
            goalType: .totalMiles,
            targetValue: 100,
            startDate: .now.addingTimeInterval(-7200),
            endDate: .now.addingTimeInterval(-3600)
        )
        XCTAssertTrue(c.isFinished)
        XCTAssertFalse(c.isActive)
    }

    func test_daysRemaining_isClampedAtZero() {
        let c = RideChallenge(
            title: "X",
            goalType: .totalMiles,
            targetValue: 100,
            startDate: .now.addingTimeInterval(-7200),
            endDate: .now.addingTimeInterval(-3600)
        )
        XCTAssertEqual(c.daysRemaining, 0)
    }
}
