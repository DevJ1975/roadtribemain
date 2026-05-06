//
//  Conversation.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// A direct message conversation between two users.
@Model
final class Conversation {
    @Attribute(.unique) var id: UUID
    var participantIDs: [UUID]
    var lastMessageText: String
    var lastMessageDate: Date
    var unreadCount: Int

    @Relationship(deleteRule: .cascade, inverse: \DirectMessage.conversation)
    var messages: [DirectMessage]

    init(
        id: UUID = UUID(),
        participantIDs: [UUID],
        lastMessageText: String = "",
        lastMessageDate: Date = .now,
        unreadCount: Int = 0,
        messages: [DirectMessage] = []
    ) {
        self.id = id
        self.participantIDs = participantIDs
        self.lastMessageText = lastMessageText
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
        self.messages = messages
    }

    /// The other participant's ID given the current user.
    func otherParticipantID(currentUserID: UUID) -> UUID? {
        participantIDs.first { $0 != currentUserID }
    }
}
