//
//  Post.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// A social feed post — text, photos, ride shares, or status updates.
@Model
final class Post {
    @Attribute(.unique) var id: UUID
    var authorID: UUID
    var content: String
    var photoDataItems: [Data]
    var sharedTripID: UUID?
    var sharedJournalEntryID: UUID?
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var postType: PostType
    var createdAt: Date
    var likeCount: Int
    var commentCount: Int

    init(
        id: UUID = UUID(),
        authorID: UUID,
        content: String,
        photoDataItems: [Data] = [],
        sharedTripID: UUID? = nil,
        sharedJournalEntryID: UUID? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil,
        postType: PostType = .status,
        likeCount: Int = 0,
        commentCount: Int = 0
    ) {
        self.id = id
        self.authorID = authorID
        self.content = content
        self.photoDataItems = photoDataItems
        self.sharedTripID = sharedTripID
        self.sharedJournalEntryID = sharedJournalEntryID
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.postType = postType
        self.createdAt = .now
        self.likeCount = likeCount
        self.commentCount = commentCount
    }
}

/// The type of social post.
enum PostType: String, Codable, CaseIterable {
    case status
    case photo
    case rideShare
    case journalShare
    case milestone

    var iconName: String {
        switch self {
        case .status: return "text.bubble"
        case .photo: return "photo"
        case .rideShare: return "motorcycle.fill"
        case .journalShare: return "book.fill"
        case .milestone: return "trophy.fill"
        }
    }
}
