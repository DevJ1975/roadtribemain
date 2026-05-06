//
//  RankTierTests.swift
//  Road Tribe
//

import XCTest
@testable import RoadTribe

final class RankTierTests: XCTestCase {

    func test_tier_atZeroXP_isProspect() {
        XCTAssertEqual(RankTier.tier(for: 0), .prospect)
    }

    func test_tier_atNegativeXP_clampsToProspect() {
        XCTAssertEqual(RankTier.tier(for: -100), .prospect)
    }

    func test_tier_atBoundaryXP_isThatTier() {
        XCTAssertEqual(RankTier.tier(for: RankTier.roadDog.xpRequired), .roadDog)
        XCTAssertEqual(RankTier.tier(for: RankTier.recruit.xpRequired), .recruit)
        XCTAssertEqual(RankTier.tier(for: RankTier.rider.xpRequired),   .rider)
        XCTAssertEqual(RankTier.tier(for: RankTier.warrior.xpRequired), .warrior)
        XCTAssertEqual(RankTier.tier(for: RankTier.iron.xpRequired),    .iron)
        XCTAssertEqual(RankTier.tier(for: RankTier.legend.xpRequired),  .legend)
    }

    func test_tier_oneBelowBoundary_isPreviousTier() {
        XCTAssertEqual(RankTier.tier(for: RankTier.roadDog.xpRequired - 1), .prospect)
        XCTAssertEqual(RankTier.tier(for: RankTier.legend.xpRequired - 1),  .iron)
    }

    func test_tier_atVeryHighXP_isLegend() {
        XCTAssertEqual(RankTier.tier(for: 10_000_000), .legend)
    }

    func test_xpRequired_isMonotonicallyIncreasing() {
        let allCases = RankTier.allCases
        for (a, b) in zip(allCases, allCases.dropFirst()) {
            XCTAssertLessThan(a.xpRequired, b.xpRequired,
                              "xpRequired must increase from \(a) to \(b)")
        }
    }

    func test_next_returnsNextTierExceptForLegend() {
        XCTAssertEqual(RankTier.prospect.next, .roadDog)
        XCTAssertEqual(RankTier.warrior.next,  .iron)
        XCTAssertNil(RankTier.legend.next)
    }

    func test_comparable_orderingMatchesRawValue() {
        XCTAssertLessThan(RankTier.prospect, RankTier.legend)
        XCTAssertGreaterThan(RankTier.iron, RankTier.recruit)
    }

    func test_allCases_areUnique() {
        let raws = RankTier.allCases.map(\.rawValue)
        XCTAssertEqual(Set(raws).count, raws.count)
    }

    func test_displayName_isNonEmptyForEveryTier() {
        for tier in RankTier.allCases {
            XCTAssertFalse(tier.displayName.isEmpty, "\(tier) display name is empty")
        }
    }
}
