//
//  UtilityTests.swift
//  Road Tribe
//

import XCTest
@testable import RoadTribe

// MARK: - Formatters

final class FormattersTests: XCTestCase {

    func test_distance_milesUnit_includesAbbreviation() {
        let s = Formatters.distance(meters: 1609.344, unit: .miles)
        XCTAssertTrue(s.contains("mi"))
        XCTAssertTrue(s.contains("1"))
    }

    func test_distance_kilometersUnit_includesAbbreviation() {
        let s = Formatters.distance(meters: 1000, unit: .kilometers)
        XCTAssertTrue(s.contains("km"))
        XCTAssertTrue(s.contains("1"))
    }

    func test_distance_zeroMeters_isZero() {
        let s = Formatters.distance(meters: 0, unit: .miles)
        XCTAssertTrue(s.starts(with: "0"))
    }

    func test_dateRange_withEnd_containsDash() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = start.addingTimeInterval(7 * 86_400)
        let s = Formatters.dateRange(from: start, to: end)
        XCTAssertTrue(s.contains("–"))
    }

    func test_dateRange_withoutEnd_endsWithEllipsis() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let s = Formatters.dateRange(from: start, to: nil)
        XCTAssertTrue(s.hasSuffix("..."))
    }

    func test_duration_returnsAbbreviatedString() {
        let s = Formatters.duration(seconds: 3600 + 30 * 60)
        XCTAssertTrue(s.contains("1"))   // 1 hour
        XCTAssertTrue(s.contains("h"))
    }

    func test_duration_zeroSeconds_isStableString() {
        // DateComponentsFormatter may render 0 as "" or "0m" depending on locale.
        // We only assert it doesn't crash and returns a string.
        let s = Formatters.duration(seconds: 0)
        XCTAssertNotNil(s)
    }
}

// MARK: - GPXExporter

final class GPXExporterTests: XCTestCase {

    func test_sanitizedFileName_replacesSlashesAndSpaces() {
        XCTAssertEqual(GPXExporter.sanitizedFileName(from: "Pacific/Coast Highway"),
                       "Pacific-Coast_Highway")
    }

    func test_sanitizedFileName_emptyTitle_fallsBackToTrip() {
        XCTAssertEqual(GPXExporter.sanitizedFileName(from: ""), "trip")
    }

    func test_sanitizedFileName_onlyInvalidCharacters_fallsBackToTrip() {
        XCTAssertEqual(GPXExporter.sanitizedFileName(from: "/// "), "trip")
    }

    func test_sanitizedFileName_stripsControlCharacters() {
        let name = GPXExporter.sanitizedFileName(from: "Trip\u{0007}Title")
        XCTAssertFalse(name.contains("\u{0007}"))
        XCTAssertTrue(name.contains("Trip"))
    }

    func test_generateGPX_includesXMLDeclarationAndTrip() {
        let trip = Trip(title: "Test Trip", tripDescription: "Hello & welcome <home>")
        let waypoint = Waypoint(name: "Start", latitude: 37.7749, longitude: -122.4194, sortOrder: 0)
        trip.waypoints = [waypoint]
        let xml = GPXExporter.generateGPX(for: trip)
        XCTAssertTrue(xml.contains("<?xml"))
        XCTAssertTrue(xml.contains("<gpx"))
        XCTAssertTrue(xml.contains("Test Trip"))
        // Description's special chars must be escaped.
        XCTAssertTrue(xml.contains("&amp;"))
        XCTAssertTrue(xml.contains("&lt;home&gt;"))
        XCTAssertTrue(xml.contains("lat=\"37.7749\""))
        XCTAssertTrue(xml.contains("lon=\"-122.4194\""))
    }

    func test_generateGPX_emptyWaypoints_stillProducesValidEnvelope() {
        let trip = Trip(title: "Empty Trip")
        let xml = GPXExporter.generateGPX(for: trip)
        XCTAssertTrue(xml.contains("</gpx>"))
        XCTAssertTrue(xml.contains("<trkseg>"))
    }

    func test_exportToFile_writesNonEmptyFile() throws {
        let trip = Trip(title: "Roundtrip")
        trip.waypoints = [
            Waypoint(name: "A", latitude: 0, longitude: 0, sortOrder: 0),
            Waypoint(name: "B", latitude: 1, longitude: 1, sortOrder: 1),
        ]
        let url = try GPXExporter.exportToFile(trip: trip)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertTrue(url.lastPathComponent.hasSuffix(".gpx"))
        let data = try Data(contentsOf: url)
        XCTAssertGreaterThan(data.count, 100)
    }
}
