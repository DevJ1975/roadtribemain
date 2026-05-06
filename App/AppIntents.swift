//
//  AppIntents.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import AppIntents

// MARK: - Open Trip Intent

struct OpenTripsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open My Trips"
    static var description: IntentDescription = "Open the Road Tribe trips screen"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Open Map Intent

struct OpenMapIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Rider Map"
    static var description: IntentDescription = "Open the Road Tribe map with POIs and weather"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Open Journal Intent

struct OpenJournalIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Ride Journal"
    static var description: IntentDescription = "Open the Road Tribe journal"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Open Maintenance Intent

struct OpenMaintenanceIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Bike Maintenance"
    static var description: IntentDescription = "Open motorcycle maintenance tracking in Road Tribe"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Shortcuts Provider

struct RoadTribeShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTripsIntent(),
            phrases: [
                "Open my trips in \(.applicationName)",
                "Show my road trips in \(.applicationName)",
                "Open \(.applicationName) trips"
            ],
            shortTitle: "My Trips",
            systemImageName: "motorcycle.fill"
        )

        AppShortcut(
            intent: OpenMapIntent(),
            phrases: [
                "Open rider map in \(.applicationName)",
                "Show the map in \(.applicationName)",
                "Find gas stations in \(.applicationName)"
            ],
            shortTitle: "Rider Map",
            systemImageName: "map.fill"
        )

        AppShortcut(
            intent: OpenJournalIntent(),
            phrases: [
                "Open my ride journal in \(.applicationName)",
                "Show journal in \(.applicationName)"
            ],
            shortTitle: "Ride Journal",
            systemImageName: "book.fill"
        )

        AppShortcut(
            intent: OpenMaintenanceIntent(),
            phrases: [
                "Check bike maintenance in \(.applicationName)",
                "Open maintenance in \(.applicationName)",
                "Show my bike in \(.applicationName)"
            ],
            shortTitle: "Bike Maintenance",
            systemImageName: "wrench.and.screwdriver.fill"
        )
    }
}
