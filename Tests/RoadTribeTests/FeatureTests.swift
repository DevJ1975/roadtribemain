//
//  FeatureTests.swift
//  Road Tribe
//
//  Tests for the quick-win feature additions:
//  - Motorcycle fuel tracking
//  - FuelAlertService.shouldWarn rule
//  - MaintenanceDueService
//  - RouteElevation gain calc
//  - QuickJournalCaptureView title builder
//

import XCTest
import CoreLocation
@testable import RoadTribe

// MARK: - Fuel tracking

final class MotorcycleFuelTrackingTests: XCTestCase {

    private func bike(mileage: Int = 10_000, mpg: Double = 40, capacity: Double = 5) -> Motorcycle {
        Motorcycle(
            name: "Test",
            currentMileage: mileage,
            fuelCapacityGallons: capacity,
            averageMPG: mpg
        )
    }

    func test_milesSinceFillUp_withoutFillUp_isZero() {
        XCTAssertEqual(bike().milesSinceFillUp(currentMileage: 12_000), 0)
    }

    func test_milesSinceFillUp_returnsDelta() {
        let m = bike()
        m.recordFillUp(at: 10_000)
        XCTAssertEqual(m.milesSinceFillUp(currentMileage: 10_125), 125)
    }

    func test_milesSinceFillUp_clampsBackwardsOdometer() {
        let m = bike()
        m.recordFillUp(at: 10_000)
        XCTAssertEqual(m.milesSinceFillUp(currentMileage: 9_500), 0)
    }

    func test_remainingRange_withoutFillUp_isFullEstimate() {
        let m = bike(mpg: 40, capacity: 5) // 200 mi range
        XCTAssertEqual(m.remainingRangeMiles(currentMileage: 10_000), 200, accuracy: 1e-9)
    }

    func test_remainingRange_decreasesAfterFillUp() {
        let m = bike(mpg: 40, capacity: 5) // 200 mi range
        m.recordFillUp(at: 10_000)
        XCTAssertEqual(m.remainingRangeMiles(currentMileage: 10_050), 150, accuracy: 1e-9)
    }

    func test_remainingRange_clampsToZero() {
        let m = bike(mpg: 40, capacity: 5) // 200 mi range
        m.recordFillUp(at: 10_000)
        XCTAssertEqual(m.remainingRangeMiles(currentMileage: 10_500), 0, accuracy: 1e-9)
    }

    func test_remainingRange_withZeroEstimatedRange_isZero() {
        let m = bike(mpg: 0, capacity: 5)
        m.recordFillUp(at: 10_000)
        XCTAssertEqual(m.remainingRangeMiles(currentMileage: 10_010), 0)
    }

    func test_remainingFuelFraction_withoutFillUp_isNil() {
        XCTAssertNil(bike().remainingFuelFraction(currentMileage: 10_000))
    }

    func test_remainingFuelFraction_isHalfAfterHalfTank() {
        let m = bike(mpg: 40, capacity: 5) // 200 mi
        m.recordFillUp(at: 10_000)
        XCTAssertEqual(m.remainingFuelFraction(currentMileage: 10_100) ?? 0, 0.5, accuracy: 1e-9)
    }

    func test_remainingFuelFraction_clampsToOneAndZero() {
        let m = bike(mpg: 40, capacity: 5)
        m.recordFillUp(at: 10_000)
        XCTAssertEqual(m.remainingFuelFraction(currentMileage: 10_000), 1, accuracy: 1e-9)
        XCTAssertEqual(m.remainingFuelFraction(currentMileage: 99_999), 0, accuracy: 1e-9)
    }

    func test_recordFillUp_defaultsToCurrentMileage() {
        let m = bike(mileage: 12_345)
        m.recordFillUp()
        XCTAssertEqual(m.lastFillUpMileage, 12_345)
        XCTAssertNotNil(m.lastFillUpDate)
    }
}

// MARK: - Fuel alert decision rule

final class FuelAlertServiceRuleTests: XCTestCase {

    func test_shouldWarn_zeroOrNegativeRange_isFalse() {
        XCTAssertFalse(FuelAlertService.shouldWarn(distanceToStationMiles: 5,
                                                   remainingRangeMiles: 0))
        XCTAssertFalse(FuelAlertService.shouldWarn(distanceToStationMiles: 5,
                                                   remainingRangeMiles: -10))
    }

    func test_shouldWarn_stationWithinSafeMargin_isFalse() {
        // 50 mi range, station 10 mi away → 20% of range, safe.
        XCTAssertFalse(FuelAlertService.shouldWarn(distanceToStationMiles: 10,
                                                   remainingRangeMiles: 50))
    }

    func test_shouldWarn_stationConsumingMostOfRange_isTrue() {
        // 30 mi range, station 25 mi away → 83% of range, warn.
        XCTAssertTrue(FuelAlertService.shouldWarn(distanceToStationMiles: 25,
                                                  remainingRangeMiles: 30))
    }

    func test_shouldWarn_atExactlyThreshold_isTrue() {
        // 100 mi range, 60 mi station → exactly 60% → warn.
        XCTAssertTrue(FuelAlertService.shouldWarn(distanceToStationMiles: 60,
                                                  remainingRangeMiles: 100))
    }
}

// MARK: - Maintenance due service

final class MaintenanceDueServiceTests: XCTestCase {

    private func bike(mileage: Int) -> Motorcycle {
        Motorcycle(name: "Test", currentMileage: mileage)
    }

    private func record(_ type: ServiceType, at mileage: Int, on bike: Motorcycle) {
        let r = MaintenanceRecord(serviceType: type, mileage: mileage)
        r.motorcycle = bike
        bike.maintenanceRecords.append(r)
    }

    func test_dueItem_withNoHistory_isOverdueOnAnyMileageAboveInterval() {
        let m = bike(mileage: 5_000)
        let item = MaintenanceDueService.dueItem(for: .oilChange, bike: m)
        XCTAssertNotNil(item)
        // Oil change interval is 3,000 → due at 3,000, currently at 5,000 → 2,000 over.
        XCTAssertEqual(item?.dueAtMileage, 3_000)
        XCTAssertEqual(item?.milesUntilDue, -2_000)
        XCTAssertEqual(item?.isOverdue, true)
    }

    func test_dueItem_usesLatestServiceMileage() {
        let m = bike(mileage: 12_000)
        record(.oilChange, at: 5_000,  on: m)
        record(.oilChange, at: 11_000, on: m) // most recent
        let item = MaintenanceDueService.dueItem(for: .oilChange, bike: m)
        XCTAssertEqual(item?.lastDoneAtMileage, 11_000)
        XCTAssertEqual(item?.dueAtMileage, 14_000)
        XCTAssertEqual(item?.milesUntilDue, 2_000)
        XCTAssertEqual(item?.isOverdue, false)
    }

    func test_dueItem_serviceTypeWithoutInterval_returnsNil() {
        let m = bike(mileage: 0)
        XCTAssertNil(MaintenanceDueService.dueItem(for: .custom, bike: m))
        XCTAssertNil(MaintenanceDueService.dueItem(for: .recall, bike: m))
        XCTAssertNil(MaintenanceDueService.dueItem(for: .inspection, bike: m))
    }

    func test_dueItem_ignoresIncompleteRecords() {
        let m = bike(mileage: 10_000)
        let r = MaintenanceRecord(serviceType: .oilChange, mileage: 9_000, isCompleted: false)
        r.motorcycle = m
        m.maintenanceRecords.append(r)
        let item = MaintenanceDueService.dueItem(for: .oilChange, bike: m)
        XCTAssertNil(item?.lastDoneAtMileage)
    }

    func test_upcomingServices_areSortedByMilesUntilDue() {
        let m = bike(mileage: 10_000)
        record(.oilChange, at: 9_500, on: m)         // due in 2_500
        record(.airFilter, at: 0,     on: m)         // due in 12k - 10k = 2k
        let services = MaintenanceDueService.upcomingServices(for: m)
        let oil = services.first { $0.serviceType == .oilChange }
        let air = services.first { $0.serviceType == .airFilter }
        XCTAssertNotNil(oil)
        XCTAssertNotNil(air)
        // Air filter should come before oil change (smaller miles-until-due).
        let oilIndex = services.firstIndex(where: { $0.serviceType == .oilChange })!
        let airIndex = services.firstIndex(where: { $0.serviceType == .airFilter })!
        XCTAssertLessThan(airIndex, oilIndex)
    }

    func test_isUpcoming_withinFiveHundredMiles_isTrue() {
        let m = bike(mileage: 2_700)
        record(.oilChange, at: 0, on: m) // due at 3,000 → in 300 mi
        let item = MaintenanceDueService.dueItem(for: .oilChange, bike: m)!
        XCTAssertTrue(item.isUpcoming)
        XCTAssertFalse(item.isOverdue)
    }

    func test_reminderTriples_mapsItemsToTuples() {
        let item = MaintenanceDueItem(
            serviceType: .oilChange,
            lastDoneAtMileage: 3_000,
            dueAtMileage: 6_000,
            milesUntilDue: 100
        )
        let triples = MaintenanceDueService.reminderTriples(from: [item])
        XCTAssertEqual(triples.count, 1)
        XCTAssertEqual(triples[0].serviceType, .oilChange)
        XCTAssertEqual(triples[0].dueMileage, 6_000)
        XCTAssertEqual(triples[0].milesUntilDue, 100)
    }
}

// MARK: - Route elevation

final class RouteElevationTests: XCTestCase {

    func test_gainMeters_emptyAndSingle_isZero() {
        XCTAssertEqual(RouteElevation.gainMeters(altitudes: []), 0)
        XCTAssertEqual(RouteElevation.gainMeters(altitudes: [100]), 0)
    }

    func test_gainMeters_sumsOnlyPositiveDeltas() {
        // 100 → 150 → 120 → 200 → 180
        // Positive deltas: +50, +80 = 130
        XCTAssertEqual(RouteElevation.gainMeters(altitudes: [100, 150, 120, 200, 180]),
                       130, accuracy: 1e-9)
    }

    func test_gainMeters_descendingOnly_isZero() {
        XCTAssertEqual(RouteElevation.gainMeters(altitudes: [500, 400, 300, 100]), 0)
    }

    func test_gainMeters_flat_isZero() {
        XCTAssertEqual(RouteElevation.gainMeters(altitudes: [200, 200, 200]), 0)
    }

    func test_recordedRoute_elevationGainFeet_convertsFromMeters() {
        let route = RecordedRoute(title: "T")
        let pts = [10.0, 20.0, 5.0, 30.0].map { altitude -> RoutePoint in
            let location = CLLocation(
                coordinate: .init(latitude: 0, longitude: 0),
                altitude: altitude,
                horizontalAccuracy: 1, verticalAccuracy: 1,
                course: 0, speed: 0, timestamp: .now
            )
            return RoutePoint(from: location)
        }
        route.points = pts
        // gain meters = +10 + +25 = 35
        XCTAssertEqual(route.elevationGainMeters, 35, accuracy: 1e-9)
        XCTAssertEqual(route.elevationGainFeet, 35 * 3.280_839_895, accuracy: 1e-6)
    }
}

// MARK: - Quick journal capture

final class QuickJournalCaptureTitleTests: XCTestCase {

    func test_suggestedTitle_withTripAndElapsedTime() {
        let title = QuickJournalCaptureView.suggestedTitle(
            tripTitle: "Route 66", elapsedSeconds: 90 * 60
        )
        XCTAssertEqual(title, "Route 66 — 1:30")
    }

    func test_suggestedTitle_withoutTrip_usesQuickNote() {
        let title = QuickJournalCaptureView.suggestedTitle(
            tripTitle: nil, elapsedSeconds: 12 * 60
        )
        XCTAssertEqual(title, "Quick note at 12m")
    }

    func test_suggestedTitle_emptyTripTitle_usesQuickNote() {
        let title = QuickJournalCaptureView.suggestedTitle(
            tripTitle: "", elapsedSeconds: 5 * 60
        )
        XCTAssertEqual(title, "Quick note at 5m")
    }

    func test_suggestedTitle_clampsNegativeElapsedTime() {
        let title = QuickJournalCaptureView.suggestedTitle(
            tripTitle: nil, elapsedSeconds: -100
        )
        XCTAssertEqual(title, "Quick note at 0m")
    }
}
