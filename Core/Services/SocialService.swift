//
//  SocialService.swift
//  Road Tribe
//

import Foundation
import SwiftData
import UIKit

/// Centralized social operations: follow counts, like checks, feed generation.
@Observable
final class SocialService {
    private(set) var currentUserID: UUID = MockDataSeeder.kevinID

    /// Update the current user identity after sign-in or profile creation.
    func configure(userID: UUID) {
        currentUserID = userID
    }

    func followerCount(for userID: UUID, follows: [Follow]) -> Int {
        follows.filter { $0.followingID == userID }.count
    }

    func followingCount(for userID: UUID, follows: [Follow]) -> Int {
        follows.filter { $0.followerID == userID }.count
    }

    func isFollowing(targetID: UUID, follows: [Follow]) -> Bool {
        follows.contains { $0.followerID == currentUserID && $0.followingID == targetID }
    }

    func isLiked(postID: UUID, likes: [Like]) -> Bool {
        likes.contains { $0.postID == postID && $0.userID == currentUserID }
    }

    func unreadActivityCount(activities: [ActivityItem]) -> Int {
        activities.filter { $0.targetUserID == currentUserID && !$0.isRead }.count
    }

    func unreadMessageCount(conversations: [Conversation]) -> Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    func toggleFollow(targetID: UUID, follows: [Follow], context: ModelContext) {
        if let existing = follows.first(where: {
            $0.followerID == currentUserID && $0.followingID == targetID
        }) {
            context.delete(existing)
        } else {
            let follow = Follow(followerID: currentUserID, followingID: targetID)
            context.insert(follow)
        }
    }

    func toggleLike(postID: UUID, likes: [Like], post: Post, context: ModelContext) {
        if let existing = likes.first(where: {
            $0.postID == postID && $0.userID == currentUserID
        }) {
            context.delete(existing)
            post.likeCount = max(0, post.likeCount - 1)
        } else {
            let like = Like(postID: postID, userID: currentUserID)
            context.insert(like)
            post.likeCount += 1
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func profileFor(_ userID: UUID, in profiles: [UserProfile]) -> UserProfile? {
        profiles.first { $0.id == userID }
    }

    /// Build a UUID → UserProfile dictionary for O(1) lookups in ForEach.
    /// Duplicate IDs (which can happen briefly during SwiftData syncs) keep
    /// the first profile rather than trapping.
    func profileLookup(from profiles: [UserProfile]) -> [UUID: UserProfile] {
        Dictionary(profiles.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
