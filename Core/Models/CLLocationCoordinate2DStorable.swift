//
//  CLLocationCoordinate2DStorable.swift
//  Road Tribe
//

import Foundation
import CoreLocation

/// Codable coordinate wrapper for SwiftData storage (CLLocationCoordinate2D is not Codable).
struct CLLocationCoordinate2DStorable: Codable, Equatable {
    var latitude: Double
    var longitude: Double

    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
