//
//  CLLocationCoordinate2D+Ext.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import CoreLocation
import MapKit

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension CLLocationCoordinate2D {

    /// Distance in meters to another coordinate.
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: latitude, longitude: longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return from.distance(from: to)
    }

    /// Create a map region centered on this coordinate with the given span in degrees.
    func region(span: Double = 0.05) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: self,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
    }

    /// A default coordinate (San Francisco) for previews and fallbacks.
    static let sanFrancisco = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
}

// MARK: - MKPolyline Coordinate Extraction

extension MKPolyline {
    /// Extract all coordinates from the polyline for use with SwiftUI MapPolyline.
    func extractCoordinates() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
