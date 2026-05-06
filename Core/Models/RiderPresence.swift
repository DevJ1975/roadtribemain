//
//  RiderPresence.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// Ephemeral location broadcast for the Rider Radar — nearby active riders on the map.
@Model
final class RiderPresence {
    @Attribute(.unique) var id: UUID
    var riderID: UUID
    var latitude: Double
    var longitude: Double
    var heading: Double
    var speedMPH: Double
    var lastUpdated: Date
    var isActive: Bool
    /// Display name cached locally to avoid profile lookups at render time.
    var displayName: String
    var avatarImageName: String?

    init(
        id: UUID = UUID(),
        riderID: UUID,
        displayName: String,
        latitude: Double = 0,
        longitude: Double = 0,
        heading: Double = 0,
        speedMPH: Double = 0,
        avatarImageName: String? = nil
    ) {
        self.id = id
        self.riderID = riderID
        self.displayName = displayName
        self.latitude = latitude
        self.longitude = longitude
        self.heading = heading
        self.speedMPH = speedMPH
        self.lastUpdated = .now
        self.isActive = true
        self.avatarImageName = avatarImageName
    }

    /// Whether this presence record is recent enough to display (< 5 minutes old).
    var isStale: Bool {
        Date.now.timeIntervalSince(lastUpdated) > 300
    }
}
