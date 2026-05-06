//
//  TripInvite.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// An invitation for a rider to join a trip.
@Model
final class TripInvite {
    @Attribute(.unique) var id: UUID
    var tripID: UUID
    var senderID: UUID
    var recipientID: UUID
    var status: InviteStatus
    var createdAt: Date

    init(
        id: UUID = UUID(),
        tripID: UUID,
        senderID: UUID,
        recipientID: UUID,
        status: InviteStatus = .pending
    ) {
        self.id = id
        self.tripID = tripID
        self.senderID = senderID
        self.recipientID = recipientID
        self.status = status
        self.createdAt = .now
    }
}

/// Status of a trip invitation.
enum InviteStatus: String, Codable, CaseIterable {
    case pending
    case accepted
    case declined

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock.fill"
        case .accepted: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        }
    }
}
