//
//  Follow.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// A follow relationship from one user to another.
@Model
final class Follow {
    @Attribute(.unique) var id: UUID
    var followerID: UUID
    var followingID: UUID
    var createdAt: Date

    init(
        id: UUID = UUID(),
        followerID: UUID,
        followingID: UUID
    ) {
        self.id = id
        self.followerID = followerID
        self.followingID = followingID
        self.createdAt = .now
    }
}
