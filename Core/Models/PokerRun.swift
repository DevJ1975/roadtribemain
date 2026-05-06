//
//  PokerRun.swift
//  Road Tribe
//

import Foundation
import SwiftData
import CoreLocation

/// A community poker run event — riders check in at GPS checkpoints to collect playing cards.
@Model
final class PokerRun {
    @Attribute(.unique) var id: UUID
    var title: String
    var organizerID: UUID
    var startDate: Date
    var state: PokerRunState
    var participantIDs: [UUID]

    @Relationship(deleteRule: .cascade, inverse: \PokerRunCheckpoint.pokerRun)
    var checkpoints: [PokerRunCheckpoint]

    init(title: String, organizerID: UUID, startDate: Date = .now) {
        self.id = UUID()
        self.title = title
        self.organizerID = organizerID
        self.startDate = startDate
        self.state = .upcoming
        self.participantIDs = []
        self.checkpoints = []
    }
}

enum PokerRunState: String, Codable {
    case upcoming, active, completed
}

/// A single checkpoint in a poker run — riders check in via GPS proximity.
@Model
final class PokerRunCheckpoint {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    /// GPS radius (meters) within which check-in triggers.
    var proximityRadius: Double
    var sortOrder: Int

    /// Rider IDs who have checked in at this checkpoint.
    var checkedInRiderIDs: [UUID]

    /// Cards assigned per rider — encoded as "riderID:suit-rank" entries.
    var assignedCards: [String]

    var pokerRun: PokerRun?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(name: String, latitude: Double, longitude: Double,
         sortOrder: Int, proximityRadius: Double = 100) {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.sortOrder = sortOrder
        self.proximityRadius = proximityRadius
        self.checkedInRiderIDs = []
        self.assignedCards = []
    }

    func isCheckedIn(_ riderID: UUID) -> Bool {
        checkedInRiderIDs.contains(riderID)
    }
}

// MARK: - Playing Cards

struct PlayingCard: Identifiable, Equatable {
    let id = UUID()
    let suit: Suit
    let rank: Rank

    enum Suit: String, CaseIterable {
        case spades = "♠️", hearts = "♥️", diamonds = "♦️", clubs = "♣️"
        var color: String { (self == .hearts || self == .diamonds) ? "red" : "black" }
    }

    enum Rank: String, CaseIterable {
        case two = "2", three = "3", four = "4", five = "5", six = "6"
        case seven = "7", eight = "8", nine = "9", ten = "10"
        case jack = "J", queen = "Q", king = "K", ace = "A"

        var pokerValue: Int {
            switch self {
            case .two: return 2; case .three: return 3; case .four: return 4
            case .five: return 5; case .six: return 6; case .seven: return 7
            case .eight: return 8; case .nine: return 9; case .ten: return 10
            case .jack: return 11; case .queen: return 12; case .king: return 13
            case .ace: return 14
            }
        }
    }

    var display: String { "\(rank.rawValue)\(suit.rawValue)" }

    static func random() -> PlayingCard {
        PlayingCard(suit: Suit.allCases.randomElement()!,
                    rank: Rank.allCases.randomElement()!)
    }

    /// Encodes to "suit-rank" string for storage.
    var encoded: String { "\(suit.rawValue)-\(rank.rawValue)" }

    static func decode(_ string: String) -> PlayingCard? {
        let parts = string.split(separator: "-", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let suit = Suit(rawValue: parts[0]),
              let rank = Rank(rawValue: parts[1]) else { return nil }
        return PlayingCard(suit: suit, rank: rank)
    }
}

/// Evaluates a 5-card poker hand label.
struct PokerHandEvaluator {
    static func handName(for cards: [PlayingCard]) -> String {
        guard cards.count == 5 else { return "Incomplete Hand" }
        let values = cards.map(\.rank.pokerValue).sorted(by: >)
        let suits = Set(cards.map(\.suit))
        let isFlush = suits.count == 1
        let isStraight = zip(values, values.dropFirst()).allSatisfy { $0 - $1 == 1 }
        let grouped = Dictionary(grouping: values, by: { $0 }).mapValues(\.count)
        let counts = grouped.values.sorted(by: >)

        if isFlush && isStraight && values.first == 14 { return "Royal Flush" }
        if isFlush && isStraight { return "Straight Flush" }
        if counts == [4, 1] { return "Four of a Kind" }
        if counts == [3, 2] { return "Full House" }
        if isFlush { return "Flush" }
        if isStraight { return "Straight" }
        if counts == [3, 1, 1] { return "Three of a Kind" }
        if counts == [2, 2, 1] { return "Two Pair" }
        if counts == [2, 1, 1, 1] { return "One Pair" }
        return "High Card"
    }
}
