//
//  VoiceChannel.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// A voice communication channel for a trip, supporting up to 6 participants.
@Model
final class VoiceChannel {
    @Attribute(.unique) var id: UUID
    var tripID: UUID
    var participantIDs: [UUID]
    var isActive: Bool
    var createdAt: Date

    static let maxParticipants = 6

    init(
        id: UUID = UUID(),
        tripID: UUID,
        participantIDs: [UUID] = [],
        isActive: Bool = true
    ) {
        self.id = id
        self.tripID = tripID
        self.participantIDs = participantIDs
        self.isActive = isActive
        self.createdAt = .now
    }

    var isFull: Bool {
        participantIDs.count >= Self.maxParticipants
    }

    var participantCount: Int {
        participantIDs.count
    }
}
