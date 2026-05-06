//
//  JournalEntry.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import SwiftData

/// A journal entry capturing a moment during a trip.
@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var title: String
    var content: String
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var photoDataItems: [Data]
    var mood: JournalMood?
    var weatherDescription: String?

    var trip: Trip?

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        title: String,
        content: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil,
        photoDataItems: [Data] = [],
        mood: JournalMood? = nil,
        weatherDescription: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.content = content
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.photoDataItems = photoDataItems
        self.mood = mood
        self.weatherDescription = weatherDescription
    }
}

/// Mood tags for journal entries.
enum JournalMood: String, Codable, CaseIterable {
    case excited
    case happy
    case relaxed
    case adventurous
    case tired
    case frustrated

    var emoji: String {
        switch self {
        case .excited: return "🤩"
        case .happy: return "😊"
        case .relaxed: return "😌"
        case .adventurous: return "🧗"
        case .tired: return "😴"
        case .frustrated: return "😤"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}
