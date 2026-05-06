//
//  MeasurementConstantsTests.swift
//  Road Tribe
//

import XCTest
import CoreLocation
@testable import RoadTribe

final class MeasurementConstantsTests: XCTestCase {

    func test_metersToMiles_roundTripsThroughMilesToMeters() {
        let miles = 100.0
        let meters = miles.milesToMeters
        XCTAssertEqual(meters, 160_934.4, accuracy: 0.01)
        XCTAssertEqual(meters.metersToMiles, miles, accuracy: 1e-9)
    }

    func test_mpsToMph_matchesKnownConversion() {
        XCTAssertEqual(0.0.mpsToMph, 0.0, accuracy: 1e-9)
        XCTAssertEqual(10.0.mpsToMph, 22.369_362_9, accuracy: 1e-6)
    }

    func test_movingSpeedThreshold_isPositive() {
        XCTAssertGreaterThan(MeasurementConstants.movingSpeedThresholdMPH, 0)
    }

    func test_secondsPerDay_isExactlyOneDay() {
        XCTAssertEqual(MeasurementConstants.secondsPerDay, 86_400)
    }

    // MARK: - CoordinatePathMath

    func test_distanceMeters_emptyAndSingleCoordinate_returnsZero() {
        XCTAssertEqual(CoordinatePathMath.distanceMeters([]), 0)
        XCTAssertEqual(CoordinatePathMath.distanceMeters([.init(latitude: 0, longitude: 0)]), 0)
    }

    func test_distanceMeters_twoCoords_matchesCLLocationDistance() {
        let a = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // SF
        let b = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437) // LA
        let expected = CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
        XCTAssertEqual(CoordinatePathMath.distanceMeters([a, b]), expected, accuracy: 0.001)
    }

    func test_distanceMeters_isSumOfSegments() {
        let p0 = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let p1 = CLLocationCoordinate2D(latitude: 0, longitude: 1)
        let p2 = CLLocationCoordinate2D(latitude: 0, longitude: 2)
        let twoSegments = CoordinatePathMath.distanceMeters([p0, p1, p2])
        let firstSegment = CoordinatePathMath.distanceMeters([p0, p1])
        let secondSegment = CoordinatePathMath.distanceMeters([p1, p2])
        XCTAssertEqual(twoSegments, firstSegment + secondSegment, accuracy: 0.001)
    }

    func test_distanceMiles_isMetersDividedByMileLength() {
        let p0 = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let p1 = CLLocationCoordinate2D(latitude: 0, longitude: 1)
        let meters = CoordinatePathMath.distanceMeters([p0, p1])
        XCTAssertEqual(CoordinatePathMath.distanceMiles([p0, p1]),
                       meters / MeasurementConstants.metersPerMile,
                       accuracy: 1e-6)
    }
}
