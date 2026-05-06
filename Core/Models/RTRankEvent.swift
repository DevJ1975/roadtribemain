//
//  RTRankEvent.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// Records a rank advancement event for the XP history log.
@Model
final class RTRankEvent {
    @Attribute(.unique) var id: UUID
    var userID: String
    var fromRank: Int          // RankTier.rawValue
    var toRank: Int            // RankTier.rawValue
    var xpAtEvent: Int
    var timestamp: Date

    init(
        id: UUID = UUID(),
        userID: String,
        fromRank: Int,
        toRank: Int,
        xpAtEvent: Int,
        timestamp: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.fromRank = fromRank
        self.toRank = toRank
        self.xpAtEvent = xpAtEvent
        self.timestamp = timestamp
    }

    var fromTier: RankTier { RankTier(rawValue: fromRank) ?? .prospect }
    var toTier: RankTier   { RankTier(rawValue: toRank)   ?? .prospect }
}
