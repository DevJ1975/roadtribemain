//
//  VeteranProfile.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// Military veteran badge attached to a rider's profile.
@Model
final class VeteranProfile {
    @Attribute(.unique) var id: UUID
    var userID: UUID
    var branch: MilitaryBranch
    var yearsOfService: Int
    var bio: String
    var badgeStyle: VetBadgeStyle
    var verifiedAt: Date?
    var isVerified: Bool

    init(
        id: UUID = UUID(),
        userID: UUID,
        branch: MilitaryBranch,
        yearsOfService: Int = 0,
        bio: String = "",
        badgeStyle: VetBadgeStyle = .standard
    ) {
        self.id = id
        self.userID = userID
        self.branch = branch
        self.yearsOfService = yearsOfService
        self.bio = bio
        self.badgeStyle = badgeStyle
        self.verifiedAt = nil
        self.isVerified = false
    }
}

enum MilitaryBranch: String, Codable, CaseIterable {
    case army = "Army"
    case navy = "Navy"
    case airForce = "Air Force"
    case marines = "Marines"
    case coastGuard = "Coast Guard"
    case spaceForce = "Space Force"
    case nationalGuard = "National Guard"

    var iconName: String {
        switch self {
        case .army: return "star.fill"
        case .navy: return "anchor.fill"
        case .airForce: return "airplane"
        case .marines: return "shield.fill"
        case .coastGuard: return "water.waves"
        case .spaceForce: return "sparkles"
        case .nationalGuard: return "flag.fill"
        }
    }

    var color: String {
        switch self {
        case .army: return "armyGreen"
        case .navy: return "navyBlue"
        case .airForce: return "airForceBlue"
        case .marines: return "marineRed"
        case .coastGuard: return "coastGuardOrange"
        case .spaceForce: return "spaceForceBlack"
        case .nationalGuard: return "guardGold"
        }
    }
}

enum VetBadgeStyle: String, Codable, CaseIterable {
    /// Standard service acknowledgment badge.
    case standard
    /// Combat veteran with service under fire.
    case honor
    /// Medal or citation recipient.
    case valor
}
