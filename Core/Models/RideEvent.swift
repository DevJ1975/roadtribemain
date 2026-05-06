//
//  RideEvent.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// A community ride event that riders can RSVP to.
@Model
final class RideEvent {
    @Attribute(.unique) var id: UUID
    var title: String
    var eventDescription: String
    var organizerID: UUID
    var startDate: Date
    var meetupLocationName: String
    var meetupLatitude: Double
    var meetupLongitude: Double
    var estimatedDistanceMiles: Double
    var difficulty: RideDifficulty
    var rsvpIDs: [UUID]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        eventDescription: String = "",
        organizerID: UUID,
        startDate: Date,
        meetupLocationName: String = "",
        meetupLatitude: Double = 0,
        meetupLongitude: Double = 0,
        estimatedDistanceMiles: Double = 0,
        difficulty: RideDifficulty = .moderate,
        rsvpIDs: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.eventDescription = eventDescription
        self.organizerID = organizerID
        self.startDate = startDate
        self.meetupLocationName = meetupLocationName
        self.meetupLatitude = meetupLatitude
        self.meetupLongitude = meetupLongitude
        self.estimatedDistanceMiles = estimatedDistanceMiles
        self.difficulty = difficulty
        self.rsvpIDs = rsvpIDs
        self.createdAt = .now
    }
}

/// Difficulty rating for a ride event.
enum RideDifficulty: String, Codable, CaseIterable {
    case easy
    case moderate
    case challenging
    case expert

    var displayName: String { rawValue.capitalized }

    var iconName: String {
        switch self {
        case .easy: return "figure.wave"
        case .moderate: return "figure.outdoor.cycle"
        case .challenging: return "figure.climbing"
        case .expert: return "flame.fill"
        }
    }
}
