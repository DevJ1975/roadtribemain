//
//  Trip.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import SwiftData
import CoreLocation

/// Represents a road trip with waypoints, members, and metadata.
@Model
final class Trip {
    @Attribute(.unique) var id: UUID
    var title: String
    var tripDescription: String
    var startDate: Date
    var endDate: Date?
    var status: TripStatus
    var coverImageName: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Waypoint.trip)
    var waypoints: [Waypoint]

    @Relationship(deleteRule: .cascade, inverse: \JournalEntry.trip)
    var journalEntries: [JournalEntry]

    var memberIDs: [UUID]

    init(
        id: UUID = UUID(),
        title: String,
        tripDescription: String = "",
        startDate: Date = .now,
        endDate: Date? = nil,
        status: TripStatus = .planning,
        coverImageName: String? = nil,
        memberIDs: [UUID] = [],
        waypoints: [Waypoint] = [],
        journalEntries: [JournalEntry] = []
    ) {
        self.id = id
        self.title = title
        self.tripDescription = tripDescription
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.coverImageName = coverImageName
        self.createdAt = .now
        self.updatedAt = .now
        self.memberIDs = memberIDs
        self.waypoints = waypoints
        self.journalEntries = journalEntries
    }

    /// Total route distance in miles, calculated from sequential waypoint coordinates.
    var totalDistanceMiles: Double {
        let sorted = waypoints.sorted { $0.sortOrder < $1.sortOrder }
        guard sorted.count >= 2 else { return 0 }

        var total: Double = 0
        for i in 1..<sorted.count {
            let from = CLLocation(latitude: sorted[i - 1].latitude, longitude: sorted[i - 1].longitude)
            let to = CLLocation(latitude: sorted[i].latitude, longitude: sorted[i].longitude)
            total += to.distance(from: from)
        }
        // Convert meters to miles
        return total / 1609.344
    }

    /// Formatted distance string (e.g., "1,243 mi").
    var formattedDistance: String {
        let miles = totalDistanceMiles
        guard miles > 0 else { return "—" }
        return "\(Int(miles).formatted()) mi"
    }
}

/// The current status of a trip.
enum TripStatus: String, Codable, CaseIterable {
    case planning
    case active
    case paused
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .active: return "On the Road"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var iconName: String {
        switch self {
        case .planning: return "map"
        case .active: return "motorcycle.fill"
        case .paused: return "pause.circle"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}
