//
//  RTXPService.swift
//  Road Tribe
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - XP Source

enum XPSource {
    case rideCompleted(miles: Double)
    case challengeCompleted
    case eventAttended
    case roadRatingAdded
    case hazardReported
    case beaconResponded
    case pokerRunCompleted
    case streakBonus(days: Int)
    case badgeEarned
    case swagPurchase
    case socialEngagement

    var baseXP: Int {
        switch self {
        case .rideCompleted(let miles): return max(10, Int(miles))
        case .challengeCompleted:       return 350
        case .eventAttended:            return 150
        case .roadRatingAdded:          return 25
        case .hazardReported:           return 30
        case .beaconResponded:          return 100
        case .pokerRunCompleted:        return 75
        case .streakBonus(let days):    return 50 * days
        case .badgeEarned:              return 100
        case .swagPurchase:             return 25
        case .socialEngagement:         return 5
        }
    }

    var iconName: String {
        switch self {
        case .rideCompleted:    return "motorcycle.fill"
        case .challengeCompleted: return DesignSystem.Icons.challenge
        case .eventAttended:    return DesignSystem.Icons.event
        case .roadRatingAdded:  return DesignSystem.Icons.rating
        case .hazardReported:   return DesignSystem.Icons.hazard
        case .beaconResponded:  return DesignSystem.Icons.sos
        case .pokerRunCompleted: return "suit.spade.fill"
        case .streakBonus:      return DesignSystem.Icons.streak
        case .badgeEarned:      return DesignSystem.Icons.badge
        case .swagPurchase:     return DesignSystem.Icons.receipt
        case .socialEngagement: return DesignSystem.Icons.feed
        }
    }

    var description: String {
        switch self {
        case .rideCompleted(let miles):
            return String(format: "Completed %.0f-mile ride", miles)
        case .challengeCompleted:
            return "Completed a ride challenge"
        case .eventAttended:
            return "Attended a ride event"
        case .roadRatingAdded:
            return "Rated a road"
        case .hazardReported:
            return "Reported a road hazard"
        case .beaconResponded:
            return "Responded to a distress beacon"
        case .pokerRunCompleted:
            return "Completed a poker run"
        case .streakBonus(let days):
            return "\(days)-day ride streak milestone"
        case .badgeEarned:
            return "Earned a badge"
        case .swagPurchase:
            return "Swag store purchase"
        case .socialEngagement:
            return "Social engagement"
        }
    }
}

// MARK: - XP Event Record (in-memory)

struct XPEventRecord: Identifiable {
    let id: UUID
    let source: XPSource
    let xpAwarded: Int
    let streakMultiplierApplied: Double
    let timestamp: Date

    init(source: XPSource, xpAwarded: Int, multiplier: Double, timestamp: Date = .now) {
        self.id = UUID()
        self.source = source
        self.xpAwarded = xpAwarded
        self.streakMultiplierApplied = multiplier
        self.timestamp = timestamp
    }
}

// MARK: - RTXPService

@Observable
@MainActor
final class RTXPService {

    private(set) var currentXP: Int
    private(set) var currentStreak: Int
    private(set) var xpHistory: [XPEventRecord] = []

    // Rank-up celebration trigger
    var showRankUp: Bool = false
    private(set) var rankUpFromTier: RankTier = .prospect
    private(set) var rankUpToTier: RankTier = .roadDog

    var currentRank: RankTier { RankTier.tier(for: currentXP) }

    var xpToNextRank: Int {
        guard let next = currentRank.next else { return 0 }
        return max(0, next.xpRequired - currentXP)
    }

    var progressToNextRank: Double {
        guard let next = currentRank.next else { return 1.0 }
        let bandTotal = next.xpRequired - currentRank.xpRequired
        guard bandTotal > 0 else { return 1.0 }
        return min(1.0, Double(currentXP - currentRank.xpRequired) / Double(bandTotal))
    }

    var streakMultiplier: Double {
        switch currentStreak {
        case ..<3:    return 1.0
        case 3..<7:   return 1.2
        case 7..<14:  return 1.3
        case 14..<30: return 1.5
        default:      return 2.0
        }
    }

    init(initialXP: Int = 0, initialStreak: Int = 0) {
        self.currentXP = initialXP
        self.currentStreak = initialStreak
    }

    // MARK: - Public API

    /// Add XP from a source. Updates UserProfile and saves rank events to SwiftData.
    func addXP(_ amount: Int, source: XPSource, profile: UserProfile? = nil, context: ModelContext? = nil) async {
        let multiplied = Int(Double(amount) * streakMultiplier)
        let oldRank = currentRank

        currentXP += multiplied
        xpHistory.insert(XPEventRecord(source: source, xpAwarded: multiplied, multiplier: streakMultiplier), at: 0)

        // Persist to profile
        if let profile {
            profile.totalXP = currentXP
            try? context?.save()
        }

        // Check rank-up
        let newRank = currentRank
        if newRank != oldRank {
            if let ctx = context {
                let event = RTRankEvent(
                    userID: profile?.id.uuidString ?? "",
                    fromRank: oldRank.rawValue,
                    toRank: newRank.rawValue,
                    xpAtEvent: currentXP
                )
                ctx.insert(event)
                try? ctx.save()
            }
            rankUpFromTier = oldRank
            rankUpToTier = newRank

            // Haptic sequence
            DesignSystem.Haptics.heavy()
            try? await Task.sleep(for: .milliseconds(300))
            DesignSystem.Haptics.success()
            try? await Task.sleep(for: .milliseconds(300))
            DesignSystem.Haptics.success()

            showRankUp = true
        }
    }

    /// Sync service state from a UserProfile (called on view appear).
    func sync(with profile: UserProfile) {
        if profile.totalXP != currentXP {
            currentXP = profile.totalXP
        }
    }
}
