//
//  DirectMessage.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// A single direct message within a conversation.
@Model
final class DirectMessage {
    @Attribute(.unique) var id: UUID
    var senderID: UUID
    var content: String
    var timestamp: Date
    var isRead: Bool

    var conversation: Conversation?

    init(
        id: UUID = UUID(),
        senderID: UUID,
        content: String,
        timestamp: Date = .now,
        isRead: Bool = false
    ) {
        self.id = id
        self.senderID = senderID
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
    }
}
