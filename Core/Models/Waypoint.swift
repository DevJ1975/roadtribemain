//
//  Waypoint.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import SwiftData
import CoreLocation

/// A stop or point of interest along a trip route.
@Model
final class Waypoint {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var waypointType: WaypointType
    var notes: String
    var photoNames: [String]
    var sortOrder: Int
    var arrivalDate: Date?
    var departureDate: Date?

    var trip: Trip?

    /// Convenience computed property for CoreLocation coordinate.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        waypointType: WaypointType = .stop,
        notes: String = "",
        photoNames: [String] = [],
        sortOrder: Int = 0,
        arrivalDate: Date? = nil,
        departureDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.waypointType = waypointType
        self.notes = notes
        self.photoNames = photoNames
        self.sortOrder = sortOrder
        self.arrivalDate = arrivalDate
        self.departureDate = departureDate
    }
}

/// Categorizes what kind of waypoint this is.
enum WaypointType: String, Codable, CaseIterable {
    case start
    case stop
    case destination
    case gasStation
    case restaurant
    case hotel
    case scenic
    case attraction

    var displayName: String {
        switch self {
        case .start: return "Start"
        case .stop: return "Stop"
        case .destination: return "Destination"
        case .gasStation: return "Gas Station"
        case .restaurant: return "Restaurant"
        case .hotel: return "Hotel"
        case .scenic: return "Scenic Point"
        case .attraction: return "Attraction"
        }
    }

    var iconName: String {
        switch self {
        case .start: return "flag.fill"
        case .stop: return "mappin"
        case .destination: return "flag.checkered"
        case .gasStation: return "fuelpump.fill"
        case .restaurant: return "fork.knife"
        case .hotel: return "bed.double.fill"
        case .scenic: return "binoculars.fill"
        case .attraction: return "star.fill"
        }
    }
}
