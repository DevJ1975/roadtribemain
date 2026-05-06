//
//  RiderRadarConfig.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// Per-user settings controlling visibility on the Rider Radar map layer.
@Model
final class RiderRadarConfig {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    /// Whether this rider broadcasts their presence to others.
    var isEnabled: Bool
    /// Radius in miles within which this rider sees others (and is seen).
    var visibilityRadiusMiles: Double
    /// Include heading arrow in the broadcast.
    var shareHeading: Bool
    /// Include speed in the broadcast.
    var shareSpeed: Bool
    /// Show veteran badge holders with a distinct pin style.
    var highlightVeterans: Bool
    /// Show distress beacons from other riders.
    var showDistressBeacons: Bool

    init(
        id: UUID = UUID(),
        userID: UUID,
        isEnabled: Bool = true,
        visibilityRadiusMiles: Double = 25,
        shareHeading: Bool = true,
        shareSpeed: Bool = false,
        highlightVeterans: Bool = true,
        showDistressBeacons: Bool = true
    ) {
        self.id = id
        self.userID = userID
        self.isEnabled = isEnabled
        self.visibilityRadiusMiles = visibilityRadiusMiles
        self.shareHeading = shareHeading
        self.shareSpeed = shareSpeed
        self.highlightVeterans = highlightVeterans
        self.showDistressBeacons = showDistressBeacons
    }
}
