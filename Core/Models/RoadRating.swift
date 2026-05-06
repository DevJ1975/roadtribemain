//
//  RoadRating.swift
//  Road Tribe
//

import Foundation
import SwiftData
import CoreLocation
import SwiftUI

/// A rider-submitted rating for a road or route stretch.
@Model
final class RoadRating {
    @Attribute(.unique) var id: UUID
    var latitude: Double
    var longitude: Double
    var routeName: String
    /// Twist/curves rating 1–5
    var twistRating: Int
    /// Scenery rating 1–5
    var sceneryRating: Int
    /// Road surface quality rating 1–5
    var qualityRating: Int
    var notes: String
    var authorID: UUID
    var timestamp: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var averageRating: Double {
        Double(twistRating + sceneryRating + qualityRating) / 3.0
    }

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        routeName: String,
        twistRating: Int,
        sceneryRating: Int,
        qualityRating: Int,
        notes: String = "",
        authorID: UUID
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.routeName = routeName
        self.twistRating = twistRating
        self.sceneryRating = sceneryRating
        self.qualityRating = qualityRating
        self.notes = notes
        self.authorID = authorID
        self.timestamp = .now
    }
}
