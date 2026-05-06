//
//  RoadHazard.swift
//  Road Tribe
//

import Foundation
import SwiftData
import CoreLocation
import SwiftUI

/// A rider-reported road hazard that appears on the map.
@Model
final class RoadHazard {
    @Attribute(.unique) var id: UUID
    var latitude: Double
    var longitude: Double
    var hazardType: HazardType
    var reportedByID: UUID
    var timestamp: Date
    var hazardDescription: String
    var upvotes: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Hazards expire after 24 hours.
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 86400
    }

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        hazardType: HazardType,
        reportedByID: UUID,
        hazardDescription: String = "",
        upvotes: Int = 0
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.hazardType = hazardType
        self.reportedByID = reportedByID
        self.timestamp = .now
        self.hazardDescription = hazardDescription
        self.upvotes = upvotes
    }
}

/// Types of road hazards riders can report.
enum HazardType: String, Codable, CaseIterable, Identifiable {
    case gravel
    case pothole
    case animal
    case police
    case construction
    case debris

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gravel: return "Gravel"
        case .pothole: return "Pothole"
        case .animal: return "Animal"
        case .police: return "Police"
        case .construction: return "Construction"
        case .debris: return "Debris"
        }
    }

    var iconName: String {
        switch self {
        case .gravel: return "mountain.2.fill"
        case .pothole: return "circle.dashed"
        case .animal: return "hare.fill"
        case .police: return "shield.lefthalf.filled"
        case .construction: return "cone.fill"
        case .debris: return "exclamationmark.triangle.fill"
        }
    }

    var markerColor: Color {
        switch self {
        case .gravel: return .brown
        case .pothole: return .red
        case .animal: return .green
        case .police: return .blue
        case .construction: return .orange
        case .debris: return .yellow
        }
    }
}
