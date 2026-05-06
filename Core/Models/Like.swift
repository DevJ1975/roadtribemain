//
//  Like.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// A like on a post from a user.
@Model
final class Like {
    @Attribute(.unique) var id: UUID
    var postID: UUID
    var userID: UUID
    var createdAt: Date

    init(
        id: UUID = UUID(),
        postID: UUID,
        userID: UUID
    ) {
        self.id = id
        self.postID = postID
        self.userID = userID
        self.createdAt = .now
    }
}
