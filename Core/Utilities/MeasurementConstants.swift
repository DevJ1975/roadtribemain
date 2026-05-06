//
//  MeasurementConstants.swift
//  Road Tribe
//
//  Shared constants and helpers for distance / speed / time conversions
//  so models and services don't sprinkle magic numbers like 1609.344
//  through the codebase.
//

import Foundation
import CoreLocation

enum MeasurementConstants {
    /// Meters in one statute mile.
    static let metersPerMile: Double = 1609.344
    /// Miles per hour per metre per second.
    static let mphPerMps: Double = 2.23693629
    /// Seconds in a day.
    static let secondsPerDay: TimeInterval = 86_400

    /// Speed below which a sample is treated as "stopped" when computing
    /// average riding speed.
    static let movingSpeedThresholdMPH: Double = 3
}

extension Double {
    /// Convert a meters value to miles.
    var metersToMiles: Double { self / MeasurementConstants.metersPerMile }
    /// Convert a miles value to meters.
    var milesToMeters: Double { self * MeasurementConstants.metersPerMile }
    /// Convert a metres-per-second value to miles-per-hour.
    var mpsToMph: Double { self * MeasurementConstants.mphPerMps }
}

enum CoordinatePathMath {
    /// Total path length in metres for a sequence of coordinates.
    /// Returns 0 for fewer than two points.
    static func distanceMeters(_ coordinates: [CLLocationCoordinate2D]) -> CLLocationDistance {
        guard coordinates.count >= 2 else { return 0 }
        var total: CLLocationDistance = 0
        for i in 1..<coordinates.count {
            let a = CLLocation(latitude: coordinates[i - 1].latitude, longitude: coordinates[i - 1].longitude)
            let b = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            total += b.distance(from: a)
        }
        return total
    }

    /// Total path length in miles for a sequence of coordinates.
    static func distanceMiles(_ coordinates: [CLLocationCoordinate2D]) -> Double {
        distanceMeters(coordinates).metersToMiles
    }
}
