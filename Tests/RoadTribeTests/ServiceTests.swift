//
//  ServiceTests.swift
//  Road Tribe
//

import XCTest
import SwiftData
@testable import RoadTribe

// MARK: - RTXPService

@MainActor
final class RTXPServiceTests: XCTestCase {

    func test_initialState_hasZeroXPAndProspectRank() {
        let service = RTXPService()
        XCTAssertEqual(service.currentXP, 0)
        XCTAssertEqual(service.currentRank, .prospect)
    }

    func test_streakMultiplier_increasesWithStreak() {
        let no = RTXPService(initialStreak: 0)
        let small = RTXPService(initialStreak: 3)
        let big = RTXPService(initialStreak: 30)
        XCTAssertEqual(no.streakMultiplier, 1.0)
        XCTAssertEqual(small.streakMultiplier, 1.2, accuracy: 1e-9)
        XCTAssertEqual(big.streakMultiplier, 2.0)
    }

    func test_progressToNextRank_atTopRank_isOne() {
        let service = RTXPService(initialXP: RankTier.legend.xpRequired)
        XCTAssertEqual(service.currentRank, .legend)
        XCTAssertEqual(service.progressToNextRank, 1.0)
        XCTAssertEqual(service.xpToNextRank, 0)
    }

    func test_progressToNextRank_betweenTiers_isFraction() {
        // Halfway between roadDog (100) and recruit (250) → 175 XP
        let service = RTXPService(initialXP: 175)
        XCTAssertEqual(service.currentRank, .roadDog)
        XCTAssertEqual(service.progressToNextRank, 0.5, accuracy: 1e-9)
        XCTAssertEqual(service.xpToNextRank, 75)
    }

    func test_progressToNextRank_atTierFloor_isZero() {
        let service = RTXPService(initialXP: RankTier.recruit.xpRequired)
        XCTAssertEqual(service.currentRank, .recruit)
        XCTAssertEqual(service.progressToNextRank, 0.0, accuracy: 1e-9)
    }

    func test_addXP_withoutMultiplier_incrementsXP() async {
        let service = RTXPService(initialXP: 0, initialStreak: 0)
        await service.addXP(100, source: .roadRatingAdded)
        XCTAssertEqual(service.currentXP, 100)
        XCTAssertEqual(service.xpHistory.count, 1)
        XCTAssertEqual(service.xpHistory.first?.xpAwarded, 100)
        XCTAssertEqual(service.xpHistory.first?.streakMultiplierApplied, 1.0)
    }

    func test_addXP_withStreakMultiplier_appliesMultiplier() async {
        let service = RTXPService(initialXP: 0, initialStreak: 7) // 1.3x
        await service.addXP(100, source: .roadRatingAdded)
        XCTAssertEqual(service.currentXP, 130)
    }

    func test_addXP_crossingRankBoundary_setsRankUpFlags() async {
        let service = RTXPService(initialXP: 99, initialStreak: 0) // just below roadDog
        XCTAssertEqual(service.currentRank, .prospect)
        await service.addXP(2, source: .socialEngagement)
        XCTAssertEqual(service.currentRank, .roadDog)
        XCTAssertEqual(service.rankUpFromTier, .prospect)
        XCTAssertEqual(service.rankUpToTier, .roadDog)
        XCTAssertTrue(service.showRankUp)
    }

    func test_sync_withProfile_copiesXP() {
        let service = RTXPService(initialXP: 0)
        let profile = UserProfile(displayName: "Test", totalXP: 1234)
        service.sync(with: profile)
        XCTAssertEqual(service.currentXP, 1234)
    }
}

// MARK: - XPSource

final class XPSourceTests: XCTestCase {

    func test_baseXP_rideCompleted_isAtLeastTen() {
        XCTAssertEqual(XPSource.rideCompleted(miles: 0).baseXP, 10)
        XCTAssertEqual(XPSource.rideCompleted(miles: 5).baseXP, 10)
        XCTAssertEqual(XPSource.rideCompleted(miles: 50).baseXP, 50)
    }

    func test_baseXP_streakBonus_scalesWithDays() {
        XCTAssertEqual(XPSource.streakBonus(days: 0).baseXP, 0)
        XCTAssertEqual(XPSource.streakBonus(days: 7).baseXP, 350)
    }

    func test_baseXP_isPositiveForFixedSources() {
        let fixed: [XPSource] = [
            .challengeCompleted, .eventAttended, .roadRatingAdded,
            .hazardReported, .beaconResponded, .pokerRunCompleted,
            .badgeEarned, .swagPurchase, .socialEngagement,
        ]
        for source in fixed {
            XCTAssertGreaterThan(source.baseXP, 0, "\(source) should award positive XP")
        }
    }
}

// MARK: - SocialService

@MainActor
final class SocialServiceTests: XCTestCase {

    private let alice = UUID()
    private let bob = UUID()
    private let carol = UUID()

    private func service() -> SocialService {
        let s = SocialService()
        s.configure(userID: alice)
        return s
    }

    func test_followerAndFollowingCounts() {
        let follows = [
            Follow(followerID: bob,   followingID: alice),
            Follow(followerID: carol, followingID: alice),
            Follow(followerID: alice, followingID: bob),
        ]
        let s = service()
        XCTAssertEqual(s.followerCount(for: alice, follows: follows), 2)
        XCTAssertEqual(s.followingCount(for: alice, follows: follows), 1)
    }

    func test_isFollowing() {
        let follows = [Follow(followerID: alice, followingID: bob)]
        let s = service()
        XCTAssertTrue(s.isFollowing(targetID: bob, follows: follows))
        XCTAssertFalse(s.isFollowing(targetID: carol, follows: follows))
    }

    func test_isLiked() {
        let postID = UUID()
        let likes = [Like(postID: postID, userID: alice)]
        let s = service()
        XCTAssertTrue(s.isLiked(postID: postID, likes: likes))
        XCTAssertFalse(s.isLiked(postID: UUID(), likes: likes))
    }

    func test_unreadActivityCount_onlyCountsForCurrentUser() {
        let activities = [
            ActivityItem(actorID: bob, targetUserID: alice, activityType: .like, message: "", isRead: false),
            ActivityItem(actorID: bob, targetUserID: alice, activityType: .comment, message: "", isRead: true),
            ActivityItem(actorID: bob, targetUserID: carol, activityType: .like, message: "", isRead: false),
        ]
        let s = service()
        XCTAssertEqual(s.unreadActivityCount(activities: activities), 1)
    }

    func test_unreadMessageCount_sumsAcrossConversations() {
        let conversations = [
            Conversation(participantIDs: [alice, bob],   unreadCount: 2),
            Conversation(participantIDs: [alice, carol], unreadCount: 3),
        ]
        XCTAssertEqual(service().unreadMessageCount(conversations: conversations), 5)
    }

    func test_profileLookup_handlesDuplicateIDsWithoutCrashing() {
        let id = UUID()
        let p1 = UserProfile(id: id, displayName: "First")
        let p2 = UserProfile(id: id, displayName: "Second")
        let lookup = service().profileLookup(from: [p1, p2])
        XCTAssertEqual(lookup.count, 1)
        // First-wins keeps the original profile.
        XCTAssertEqual(lookup[id]?.displayName, "First")
    }

    func test_profileFor_returnsMatch() {
        let p = UserProfile(id: alice, displayName: "Alice")
        XCTAssertEqual(service().profileFor(alice, in: [p])?.displayName, "Alice")
        XCTAssertNil(service().profileFor(UUID(), in: [p]))
    }
}

// MARK: - RTBeaconService

@MainActor
final class RTBeaconServiceTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        try PersistenceService.previewContainer()
    }

    func test_initialState_isInactive() {
        let service = RTBeaconService()
        XCTAssertFalse(service.isBeaconActive)
        XCTAssertNil(service.activeBeacon)
        XCTAssertEqual(service.beaconElapsedSeconds, 0)
    }

    func test_activateBeacon_setsStateAndInsertsBeacon() throws {
        let container = try makeContainer()
        let service = RTBeaconService()
        service.activateBeacon(
            riderID: UUID(),
            bikeType: .cruiser,
            message: "Need fuel",
            latitude: 1, longitude: 2,
            in: container.mainContext
        )
        XCTAssertTrue(service.isBeaconActive)
        XCTAssertEqual(service.activeBeacon?.message, "Need fuel")
        XCTAssertEqual(service.activeBeacon?.status, .active)
    }

    func test_resolveBeacon_clearsActive() throws {
        let container = try makeContainer()
        let service = RTBeaconService()
        service.activateBeacon(
            riderID: UUID(), bikeType: .other, message: "",
            latitude: 0, longitude: 0, in: container.mainContext
        )
        service.resolveBeacon(in: container.mainContext)
        XCTAssertFalse(service.isBeaconActive)
        XCTAssertNil(service.activeBeacon)
    }

    func test_cancelBeacon_marksAsCancelled() throws {
        let container = try makeContainer()
        let service = RTBeaconService()
        service.activateBeacon(
            riderID: UUID(), bikeType: .other, message: "",
            latitude: 0, longitude: 0, in: container.mainContext
        )
        let beacon = service.activeBeacon
        service.cancelBeacon(in: container.mainContext)
        XCTAssertEqual(beacon?.status, .cancelled)
        XCTAssertNotNil(beacon?.resolvedAt)
        XCTAssertFalse(service.isBeaconActive)
    }

    func test_resolveOrCancel_withoutActive_isNoOp() throws {
        let container = try makeContainer()
        let service = RTBeaconService()
        service.cancelBeacon(in: container.mainContext)   // no crash
        service.resolveBeacon(in: container.mainContext)  // no crash
        XCTAssertFalse(service.isBeaconActive)
    }
}

// MARK: - RideTrackingService

@MainActor
final class RideTrackingServiceTests: XCTestCase {

    func test_initialState_isNotRiding() {
        let service = RideTrackingService()
        XCTAssertFalse(service.isRiding)
        XCTAssertNil(service.activeTrip)
    }

    func test_startRide_setsActiveTrip() {
        let service = RideTrackingService()
        let trip = Trip(title: "X")
        service.startRide(trip: trip)
        XCTAssertTrue(service.isRiding)
        XCTAssertEqual(service.activeTrip?.id, trip.id)
    }

    func test_endRide_clearsActiveTripAndMarksCompleted() {
        let service = RideTrackingService()
        let trip = Trip(title: "X")
        service.startRide(trip: trip)
        let _ = service.endRide()
        XCTAssertFalse(service.isRiding)
        XCTAssertNil(service.activeTrip)
        XCTAssertEqual(trip.status, .completed)
        XCTAssertNotNil(trip.endDate)
    }

    func test_pauseRide_setsTripStatusToPaused() {
        let service = RideTrackingService()
        let trip = Trip(title: "X")
        service.startRide(trip: trip)
        service.pauseRide()
        XCTAssertEqual(trip.status, .paused)
    }

    func test_formattedElapsedTime_underAnHour() {
        let service = RideTrackingService()
        // Direct access to elapsedSeconds is allowed because it's @Observable var.
        service.elapsedSeconds = 5 * 60 + 12
        XCTAssertEqual(service.formattedElapsedTime, "5:12")
    }

    func test_formattedElapsedTime_overAnHour_includesHours() {
        let service = RideTrackingService()
        service.elapsedSeconds = 3 * 3600 + 7 * 60 + 9
        XCTAssertEqual(service.formattedElapsedTime, "3:07:09")
    }
}
