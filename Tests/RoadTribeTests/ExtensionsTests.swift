//
//  ExtensionsTests.swift
//  Road Tribe
//

import XCTest
import CoreLocation
import MapKit
@testable import RoadTribe

final class CLLocationCoordinate2DExtTests: XCTestCase {

    func test_equatable_sameValuesAreEqual() {
        let a = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let b = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        XCTAssertEqual(a, b)
    }

    func test_equatable_differentLatitudeIsNotEqual() {
        let a = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let b = CLLocationCoordinate2D(latitude: 1.000_001, longitude: 2)
        XCTAssertNotEqual(a, b)
    }

    func test_distance_betweenIdenticalCoordinatesIsZero() {
        let c = CLLocationCoordinate2D.sanFrancisco
        XCTAssertEqual(c.distance(to: c), 0, accuracy: 1e-6)
    }

    func test_distance_isSymmetric() {
        let a = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let b = CLLocationCoordinate2D(latitude: 1, longitude: 1)
        XCTAssertEqual(a.distance(to: b), b.distance(to: a), accuracy: 1e-3)
    }

    func test_region_isCenteredOnCoordinateWithGivenSpan() {
        let c = CLLocationCoordinate2D.sanFrancisco
        let r = c.region(span: 0.1)
        XCTAssertEqual(r.center.latitude, c.latitude, accuracy: 1e-9)
        XCTAssertEqual(r.center.longitude, c.longitude, accuracy: 1e-9)
        XCTAssertEqual(r.span.latitudeDelta, 0.1, accuracy: 1e-9)
        XCTAssertEqual(r.span.longitudeDelta, 0.1, accuracy: 1e-9)
    }

    func test_sanFranciscoConstant_isInExpectedBounds() {
        let sf = CLLocationCoordinate2D.sanFrancisco
        XCTAssertEqual(sf.latitude, 37.7749, accuracy: 1e-4)
        XCTAssertEqual(sf.longitude, -122.4194, accuracy: 1e-4)
    }

    func test_extractCoordinates_emptyPolylineReturnsEmpty() {
        let polyline = MKPolyline(coordinates: [], count: 0)
        XCTAssertTrue(polyline.extractCoordinates().isEmpty)
    }

    func test_extractCoordinates_returnsAllPoints() {
        let pts = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 2, longitude: 2),
        ]
        let polyline = pts.withUnsafeBufferPointer { buf in
            MKPolyline(coordinates: buf.baseAddress!, count: pts.count)
        }
        let extracted = polyline.extractCoordinates()
        XCTAssertEqual(extracted.count, pts.count)
        for (i, p) in extracted.enumerated() {
            XCTAssertEqual(p.latitude, pts[i].latitude, accuracy: 1e-9)
            XCTAssertEqual(p.longitude, pts[i].longitude, accuracy: 1e-9)
        }
    }
}

final class DateExtTests: XCTestCase {

    func test_isToday_trueForNow_falseForYesterday() {
        XCTAssertTrue(Date.now.isToday)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        XCTAssertFalse(yesterday.isToday)
    }

    func test_isPast_andIsFuture_areOpposites() {
        let past = Date.distantPast
        let future = Date.distantFuture
        XCTAssertTrue(past.isPast)
        XCTAssertFalse(past.isFuture)
        XCTAssertFalse(future.isPast)
        XCTAssertTrue(future.isFuture)
    }

    func test_days_until_returnsZeroForSameDay() {
        let a = Date.now
        XCTAssertEqual(a.days(until: a), 0)
    }

    func test_days_until_returnsExpectedDelta() {
        let a = Calendar.current.startOfDay(for: .now)
        let b = Calendar.current.date(byAdding: .day, value: 7, to: a)!
        XCTAssertEqual(a.days(until: b), 7)
    }

    func test_startOfDay_hasZeroTime() {
        let start = Date.now.startOfDay
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(comps.hour, 0)
        XCTAssertEqual(comps.minute, 0)
        XCTAssertEqual(comps.second, 0)
    }

    func test_oneWeekFromNow_isWithinSevenDays() {
        let interval = Date.oneWeekFromNow.timeIntervalSinceNow
        XCTAssertGreaterThan(interval, 0)
        XCTAssertLessThan(interval, 8 * 24 * 60 * 60)
    }
}
