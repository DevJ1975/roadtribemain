//
//  RideChallenge.swift
//  Road Tribe
//

import Foundation
import SwiftData
import SwiftUI

/// A time-boxed community challenge that riders compete on together.
@Model
final class RideChallenge {
    @Attribute(.unique) var id: UUID
    var title: String
    var challengeDescription: String
    var goalType: ChallengeGoalType
    /// The target number (miles, states, rides, etc.)
    var targetValue: Double
    var startDate: Date
    var endDate: Date
    var participantIDs: [UUID]
    /// IDs of riders who have achieved the goal.
    var completedIDs: [UUID]
    var createdAt: Date

    var isActive: Bool {
        let now = Date.now
        return now >= startDate && now <= endDate
    }

    var isUpcoming: Bool { Date.now < startDate }
    var isFinished: Bool { Date.now > endDate }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: .now, to: endDate).day ?? 0)
    }

    init(
        id: UUID = UUID(),
        title: String,
        challengeDescription: String = "",
        goalType: ChallengeGoalType,
        targetValue: Double,
        startDate: Date,
        endDate: Date,
        participantIDs: [UUID] = [],
        completedIDs: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.challengeDescription = challengeDescription
        self.goalType = goalType
        self.targetValue = targetValue
        self.startDate = startDate
        self.endDate = endDate
        self.participantIDs = participantIDs
        self.completedIDs = completedIDs
        self.createdAt = .now
    }
}

// MARK: - ChallengeGoalType

enum ChallengeGoalType: String, Codable, CaseIterable, Identifiable {
    case totalMiles
    case singleRideMiles
    case numberOfRides
    case statesVisited
    case roadRatings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .totalMiles: return "Total Miles"
        case .singleRideMiles: return "Single Ride Distance"
        case .numberOfRides: return "Number of Rides"
        case .statesVisited: return "States Visited"
        case .roadRatings: return "Roads Rated"
        }
    }

    var unit: String {
        switch self {
        case .totalMiles: return "mi"
        case .singleRideMiles: return "mi"
        case .numberOfRides: return "rides"
        case .statesVisited: return "states"
        case .roadRatings: return "roads"
        }
    }

    var iconName: String {
        switch self {
        case .totalMiles: return "gauge.with.dots.needle.67percent"
        case .singleRideMiles: return "road.lanes"
        case .numberOfRides: return "motorcycle"
        case .statesVisited: return "map"
        case .roadRatings: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .totalMiles: return .orange
        case .singleRideMiles: return .blue
        case .numberOfRides: return .green
        case .statesVisited: return .purple
        case .roadRatings: return .yellow
        }
    }
}
