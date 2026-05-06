//
//  RecordedRoute.swift
//  Road Tribe
//

import Foundation
import SwiftData
import CoreLocation

/// A GPS-recorded route captured during an active ride.
@Model
final class RecordedRoute {
    @Attribute(.unique) var id: UUID
    var tripID: UUID?
    var title: String
    var startDate: Date
    var endDate: Date?

    /// Encoded route points — stored as Data to keep the SwiftData model flat.
    var pointsData: Data

    init(tripID: UUID? = nil, title: String) {
        self.id = UUID()
        self.tripID = tripID
        self.title = title
        self.startDate = .now
        self.endDate = nil
        self.pointsData = Data()
    }

    // MARK: - Computed

    var points: [RoutePoint] {
        get { (try? JSONDecoder().decode([RoutePoint].self, from: pointsData)) ?? [] }
        set { pointsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    /// Total distance in miles.
    var distanceMiles: Double {
        let pts = points
        guard pts.count >= 2 else { return 0 }
        var total: CLLocationDistance = 0
        for i in 1..<pts.count {
            let a = CLLocation(latitude: pts[i-1].latitude, longitude: pts[i-1].longitude)
            let b = CLLocation(latitude: pts[i].latitude, longitude: pts[i].longitude)
            total += b.distance(from: a)
        }
        return total / 1609.344
    }

    /// Max speed recorded in MPH.
    var maxSpeedMPH: Double {
        points.map(\.speedMPH).max() ?? 0
    }

    /// Average speed in MPH (excluding stopped points).
    var avgSpeedMPH: Double {
        let moving = points.filter { $0.speedMPH > 3 }.map(\.speedMPH)
        guard !moving.isEmpty else { return 0 }
        return moving.reduce(0, +) / Double(moving.count)
    }

    /// Duration in seconds.
    var durationSeconds: TimeInterval {
        guard let end = endDate else { return 0 }
        return end.timeIntervalSince(startDate)
    }

    var formattedDistance: String {
        String(format: "%.1f mi", distanceMiles)
    }

    var formattedDuration: String {
        let h = Int(durationSeconds) / 3600
        let m = (Int(durationSeconds) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

/// A single GPS sample captured during a ride.
struct RoutePoint: Codable {
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let altitude: Double    // meters
    let speedMPS: Double    // meters per second (negative = invalid)

    var speedMPH: Double {
        speedMPS > 0 ? speedMPS * 2.23694 : 0
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(from location: CLLocation) {
        self.timestamp = location.timestamp
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.speedMPS = location.speed
    }
}
