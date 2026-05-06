//
//  Comment.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// A comment on a social post.
@Model
final class Comment {
    @Attribute(.unique) var id: UUID
    var postID: UUID
    var authorID: UUID
    var content: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        postID: UUID,
        authorID: UUID,
        content: String
    ) {
        self.id = id
        self.postID = postID
        self.authorID = authorID
        self.content = content
        self.createdAt = .now
    }
}
