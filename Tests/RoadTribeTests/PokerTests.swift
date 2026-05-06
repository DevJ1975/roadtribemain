//
//  PokerTests.swift
//  Road Tribe
//

import XCTest
@testable import RoadTribe

final class PlayingCardTests: XCTestCase {

    func test_pokerValue_progression() {
        XCTAssertEqual(PlayingCard.Rank.two.pokerValue,   2)
        XCTAssertEqual(PlayingCard.Rank.ten.pokerValue,   10)
        XCTAssertEqual(PlayingCard.Rank.jack.pokerValue,  11)
        XCTAssertEqual(PlayingCard.Rank.queen.pokerValue, 12)
        XCTAssertEqual(PlayingCard.Rank.king.pokerValue,  13)
        XCTAssertEqual(PlayingCard.Rank.ace.pokerValue,   14)
    }

    func test_pokerValues_areAllDistinct() {
        let values = PlayingCard.Rank.allCases.map(\.pokerValue)
        XCTAssertEqual(Set(values).count, values.count)
    }

    func test_suitColor() {
        XCTAssertEqual(PlayingCard.Suit.hearts.color,   "red")
        XCTAssertEqual(PlayingCard.Suit.diamonds.color, "red")
        XCTAssertEqual(PlayingCard.Suit.spades.color,   "black")
        XCTAssertEqual(PlayingCard.Suit.clubs.color,    "black")
    }

    func test_encodeAndDecode_roundTrip() {
        for suit in PlayingCard.Suit.allCases {
            for rank in PlayingCard.Rank.allCases {
                let card = PlayingCard(suit: suit, rank: rank)
                guard let decoded = PlayingCard.decode(card.encoded) else {
                    XCTFail("Failed to decode \(card.encoded)")
                    continue
                }
                XCTAssertEqual(decoded.suit, card.suit)
                XCTAssertEqual(decoded.rank, card.rank)
            }
        }
    }

    func test_decode_invalidString_returnsNil() {
        XCTAssertNil(PlayingCard.decode(""))
        XCTAssertNil(PlayingCard.decode("nonsense"))
        XCTAssertNil(PlayingCard.decode("?-A"))
    }
}

final class PokerHandEvaluatorTests: XCTestCase {

    private func card(_ rank: PlayingCard.Rank, _ suit: PlayingCard.Suit) -> PlayingCard {
        PlayingCard(suit: suit, rank: rank)
    }

    func test_incomplete_handLessThan5Cards() {
        XCTAssertEqual(PokerHandEvaluator.handName(for: []), "Incomplete Hand")
        XCTAssertEqual(PokerHandEvaluator.handName(for: [card(.ace, .spades)]), "Incomplete Hand")
    }

    func test_royalFlush() {
        let hand = [
            card(.ten, .hearts), card(.jack, .hearts), card(.queen, .hearts),
            card(.king, .hearts), card(.ace, .hearts),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "Royal Flush")
    }

    func test_straightFlush() {
        let hand = [
            card(.five, .clubs), card(.six, .clubs), card(.seven, .clubs),
            card(.eight, .clubs), card(.nine, .clubs),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "Straight Flush")
    }

    func test_wheelStraightFlush_isStraightFlushNotRoyal() {
        let hand = [
            card(.ace, .clubs), card(.two, .clubs), card(.three, .clubs),
            card(.four, .clubs), card(.five, .clubs),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "Straight Flush")
    }

    func test_fourOfAKind() {
        let hand = [
            card(.king, .clubs), card(.king, .hearts), card(.king, .spades),
            card(.king, .diamonds), card(.two, .clubs),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "Four of a Kind")
    }

    func test_fullHouse() {
        let hand = [
            card(.queen, .clubs), card(.queen, .hearts), card(.queen, .spades),
            card(.three, .diamonds), card(.three, .clubs),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "Full House")
    }

    func test_flush_notStraight() {
        let hand = [
            card(.two, .hearts), card(.five, .hearts), card(.seven, .hearts),
            card(.nine, .hearts), card(.queen, .hearts),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "Flush")
    }

    func test_standardStraight_notFlush() {
        let hand = [
            card(.four, .hearts), card(.five, .clubs), card(.six, .diamonds),
            card(.seven, .spades), card(.eight, .hearts),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "Straight")
    }

    func test_wheelStraight_notFlush() {
        let hand = [
            card(.ace, .hearts), card(.two, .clubs), card(.three, .diamonds),
            card(.four, .spades), card(.five, .hearts),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "Straight")
    }

    func test_threeOfAKind() {
        let hand = [
            card(.seven, .hearts), card(.seven, .clubs), card(.seven, .diamonds),
            card(.queen, .spades), card(.two, .hearts),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "Three of a Kind")
    }

    func test_twoPair() {
        let hand = [
            card(.king, .hearts), card(.king, .clubs),
            card(.three, .diamonds), card(.three, .spades),
            card(.queen, .hearts),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "Two Pair")
    }

    func test_onePair() {
        let hand = [
            card(.king, .hearts), card(.king, .clubs),
            card(.three, .diamonds), card(.queen, .spades), card(.two, .hearts),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "One Pair")
    }

    func test_highCard() {
        let hand = [
            card(.king, .hearts), card(.queen, .clubs),
            card(.three, .diamonds), card(.nine, .spades), card(.two, .hearts),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "High Card")
    }

    func test_threeOfAKindWithMatchingExtraSuit_isNotFlush() {
        // Five cards, four of which share a suit but ranks make it three of a kind.
        let hand = [
            card(.seven, .hearts), card(.seven, .clubs), card(.seven, .diamonds),
            card(.queen, .hearts), card(.two, .hearts),
        ]
        XCTAssertEqual(PokerHandEvaluator.handName(for: hand), "Three of a Kind")
    }
}
