//
//  UserProfile.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// The current user's profile and preferences.
@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var email: String
    var avatarImageName: String?
    var bio: String
    var joinDate: Date
    var preferences: UserPreferences
    var tripIDs: [UUID]
    var tribeIDs: [UUID]

    // MARK: - Phase 2 fields
    var veteranProfileID: UUID?
    var goldTierExpiry: Date?
    var totalXP: Int

    var isGoldActive: Bool {
        guard let expiry = goldTierExpiry else { return false }
        return expiry > .now
    }

    var currentRank: RankTier { RankTier.tier(for: totalXP) }

    init(
        id: UUID = UUID(),
        displayName: String,
        email: String = "",
        avatarImageName: String? = nil,
        bio: String = "",
        preferences: UserPreferences = UserPreferences(),
        tripIDs: [UUID] = [],
        tribeIDs: [UUID] = [],
        veteranProfileID: UUID? = nil,
        goldTierExpiry: Date? = nil,
        totalXP: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.avatarImageName = avatarImageName
        self.bio = bio
        self.joinDate = .now
        self.preferences = preferences
        self.tripIDs = tripIDs
        self.tribeIDs = tribeIDs
        self.veteranProfileID = veteranProfileID
        self.goldTierExpiry = goldTierExpiry
        self.totalXP = totalXP
    }
}

/// User-configurable preferences for the app experience.
struct UserPreferences: Codable {
    var distanceUnit: DistanceUnit
    var mapStyle: MapStylePreference
    var notificationsEnabled: Bool
    var offlineMapsEnabled: Bool

    init(
        distanceUnit: DistanceUnit = .miles,
        mapStyle: MapStylePreference = .standard,
        notificationsEnabled: Bool = true,
        offlineMapsEnabled: Bool = false
    ) {
        self.distanceUnit = distanceUnit
        self.mapStyle = mapStyle
        self.notificationsEnabled = notificationsEnabled
        self.offlineMapsEnabled = offlineMapsEnabled
    }
}

enum DistanceUnit: String, Codable, CaseIterable {
    case miles
    case kilometers

    var abbreviation: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }
}

enum MapStylePreference: String, Codable, CaseIterable {
    case standard
    case satellite
    case hybrid
}
