//
//  RankTier.swift
//  Road Tribe
//

import Foundation
import SwiftUI

/// Rider rank tiers driven by lifetime XP.
///
/// Tier raw values are persisted in `RTRankEvent.fromRank` / `toRank`,
/// so adding new tiers must preserve existing raw values.
enum RankTier: Int, CaseIterable, Comparable {
    case prospect = 0
    case roadDog  = 1
    case recruit  = 2
    case rider    = 3
    case warrior  = 4
    case iron     = 5
    case legend   = 6

    /// Minimum XP required to reach this tier.
    var xpRequired: Int {
        switch self {
        case .prospect: return 0
        case .roadDog:  return 100
        case .recruit:  return 250
        case .rider:    return 1_000
        case .warrior:  return 2_500
        case .iron:     return 5_000
        case .legend:   return 10_000
        }
    }

    /// User-facing tier name.
    var displayName: String {
        switch self {
        case .prospect: return "Prospect"
        case .roadDog:  return "Road Dog"
        case .recruit:  return "Recruit"
        case .rider:    return "Rider"
        case .warrior:  return "Warrior"
        case .iron:     return "Iron"
        case .legend:   return "Legend"
        }
    }

    /// SF Symbol used in rank badges.
    var iconName: String {
        switch self {
        case .prospect: return "circle"
        case .roadDog:  return "pawprint.fill"
        case .recruit:  return "shield"
        case .rider:    return "motorcycle.fill"
        case .warrior:  return "shield.lefthalf.filled"
        case .iron:     return "flame.fill"
        case .legend:   return "crown.fill"
        }
    }

    /// Brand colour used in rank badges and celebrations.
    var color: Color {
        switch self {
        case .prospect: return .gray
        case .roadDog:  return .brown
        case .recruit:  return .green
        case .rider:    return .blue
        case .warrior:  return .orange
        case .iron:     return .red
        case .legend:   return .purple
        }
    }

    /// The next tier above this one, or `nil` if already at the top.
    var next: RankTier? {
        let nextRaw = rawValue + 1
        return RankTier(rawValue: nextRaw)
    }

    /// Returns the highest tier whose `xpRequired` does not exceed `xp`.
    /// Negative XP is clamped to `.prospect`.
    static func tier(for xp: Int) -> RankTier {
        let clamped = max(0, xp)
        return allCases.last { clamped >= $0.xpRequired } ?? .prospect
    }

    static func < (lhs: RankTier, rhs: RankTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
