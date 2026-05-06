//
//  PersistenceService.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import SwiftData

/// Configures and provides access to the SwiftData model container.
///
/// SwiftData is recommended over CoreData for this project because:
/// - Native Swift integration with @Model macro
/// - Built-in support for SwiftUI via @Query
/// - Simpler schema migrations
/// - iOS 17+ minimum aligns with our deployment target
actor PersistenceService {

    static let shared = PersistenceService()

    let modelContainer: ModelContainer

    private static let allModelTypes: [any PersistentModel.Type] = [
        Trip.self,
        Waypoint.self,
        JournalEntry.self,
        TribeGroup.self,
        UserProfile.self,
        Motorcycle.self,
        MaintenanceRecord.self,
        Post.self,
        Follow.self,
        Like.self,
        Comment.self,
        Conversation.self,
        DirectMessage.self,
        RideEvent.self,
        ActivityItem.self,
        TripInvite.self,
        VoiceChannel.self,
        RoadHazard.self,
        PreRideCheck.self,
        RecordedRoute.self,
        PokerRun.self,
        PokerRunCheckpoint.self,
        RoadRating.self,
        PackingList.self,
        RideChallenge.self,
        // Phase 2 models
        DistressBeacon.self,
        RiderPresence.self,
        VeteranProfile.self,
        RiderRadarConfig.self,
        FallenRiderMemorial.self,
        // Phase 3 models
        RTRankEvent.self,
    ]

    private init() {
        let schema = Schema(Self.allModelTypes)

        let configuration = ModelConfiguration(
            "RoadTribe",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            // Schema migration failed — delete the old store and retry.
            // This is expected during development when models change.
            Self.deleteExistingStore()
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [configuration]
                )
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
    }

    /// Creates an in-memory container for previews and testing.
    static func previewContainer() throws -> ModelContainer {
        let schema = Schema(allModelTypes)

        let configuration = ModelConfiguration(
            "RoadTribePreview",
            schema: schema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    /// Removes the existing on-disk SwiftData store so a fresh one can be created.
    private static func deleteExistingStore() {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }

        // Delete all .store files and their companions (covers named and default stores)
        if let contents = try? fileManager.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil) {
            for url in contents where url.lastPathComponent.contains(".store") {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}
