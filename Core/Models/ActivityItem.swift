//
//  ActivityItem.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// An activity notification item (like, follow, comment, RSVP, etc.).
@Model
final class ActivityItem {
    @Attribute(.unique) var id: UUID
    var actorID: UUID
    var targetUserID: UUID
    var activityType: ActivityType
    var referenceID: UUID?
    var message: String
    var isRead: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        actorID: UUID,
        targetUserID: UUID,
        activityType: ActivityType,
        referenceID: UUID? = nil,
        message: String,
        isRead: Bool = false
    ) {
        self.id = id
        self.actorID = actorID
        self.targetUserID = targetUserID
        self.activityType = activityType
        self.referenceID = referenceID
        self.message = message
        self.isRead = isRead
        self.createdAt = .now
    }
}

/// Types of activity notifications.
enum ActivityType: String, Codable, CaseIterable {
    case like
    case comment
    case follow
    case rsvp
    case tribeInvite
    case tripInvite

    var iconName: String {
        switch self {
        case .like: return "heart.fill"
        case .comment: return "bubble.left.fill"
        case .follow: return "person.badge.plus"
        case .rsvp: return "calendar.badge.checkmark"
        case .tribeInvite: return "person.3.fill"
        case .tripInvite: return "motorcycle.fill"
        }
    }
}
