//
//  DistressBeacon.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// An active distress signal broadcast by a rider who needs roadside assistance.
@Model
final class DistressBeacon {
    @Attribute(.unique) var id: UUID
    var riderID: UUID
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var status: BeaconStatus
    var bikeType: BikeType
    var message: String
    var resolvedAt: Date?
    var acknowledgedByIDs: [UUID]

    init(
        id: UUID = UUID(),
        riderID: UUID,
        latitude: Double,
        longitude: Double,
        message: String = "",
        bikeType: BikeType = .other
    ) {
        self.id = id
        self.riderID = riderID
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = .now
        self.status = .active
        self.bikeType = bikeType
        self.message = message
        self.resolvedAt = nil
        self.acknowledgedByIDs = []
    }
}

enum BeaconStatus: String, Codable, CaseIterable {
    case active
    case acknowledged
    case resolved
    case cancelled

    var label: String {
        switch self {
        case .active: return "Needs Help"
        case .acknowledged: return "Help On The Way"
        case .resolved: return "Resolved"
        case .cancelled: return "Cancelled"
        }
    }
}

enum BikeType: String, Codable, CaseIterable {
    case cruiser = "Cruiser"
    case sportbike = "Sportbike"
    case adventure = "Adventure"
    case touring = "Touring"
    case dirtBike = "Dirt Bike"
    case scooter = "Scooter"
    case other = "Other"

    var iconName: String {
        switch self {
        case .cruiser: return "motorcycle"
        case .sportbike: return "motorcycle"
        case .adventure: return "mountain.2.fill"
        case .touring: return "road.lanes"
        case .dirtBike: return "leaf.fill"
        case .scooter: return "scooter"
        case .other: return "questionmark.circle"
        }
    }
}
