// RiderRadarService.swift
// Road Tribe
//
// Manages the Rider Radar layer: nearby rider presence, distress beacons,
// and per-user visibility settings. In this build, data is seeded locally.
// Phase 3 sync will push/pull presence records via NetworkService.

import Foundation
import CoreLocation
import SwiftData

@Observable
@MainActor
final class RiderRadarService {

    // MARK: - Settings (persisted in-memory; survives the session)

    var isEnabled: Bool = true
    var visibilityRadiusMiles: Double = 25
    var shareHeading: Bool = true
    var shareSpeed: Bool = false
    var highlightVeterans: Bool = true
    var showDistressBeacons: Bool = true

    // MARK: - Live Data

    private(set) var nearbyPresences: [RiderPresence] = []
    private(set) var nearbyBeacons: [DistressBeacon] = []

    /// Mock veteran IDs — Big Mike and Patches ride under the flag.
    let veteranRiderIDs: Set<UUID> = [MockDataSeeder.bigMikeID, MockDataSeeder.patchesID]

    // MARK: - Computed

    var visiblePresences: [RiderPresence] {
        guard isEnabled else { return [] }
        return nearbyPresences.filter { !$0.isStale }
    }

    // MARK: - Load

    func loadNearbyPresences(from coordinate: CLLocationCoordinate2D, in context: ModelContext) {
        let descriptor = FetchDescriptor<RiderPresence>()
        let existing = (try? context.fetch(descriptor)) ?? []

        if existing.isEmpty {
            seedMockPresences(near: coordinate, in: context)
            seedMockBeacon(near: coordinate, in: context)
        }

        let all = (try? context.fetch(FetchDescriptor<RiderPresence>())) ?? []
        nearbyPresences = all.filter { !$0.isStale }

        let beaconDesc = FetchDescriptor<DistressBeacon>()
        let allBeacons = (try? context.fetch(beaconDesc)) ?? []
        if showDistressBeacons {
            nearbyBeacons = allBeacons.filter { $0.status == .active }
        } else {
            nearbyBeacons = []
        }
    }

    // MARK: - Map Conversion

    func asLiveRiderInfos() -> [LiveRiderInfo] {
        visiblePresences.map { presence in
            LiveRiderInfo(
                id: presence.riderID,
                name: presence.displayName,
                coordinate: CLLocationCoordinate2D(latitude: presence.latitude, longitude: presence.longitude),
                speedMPH: Int(presence.speedMPH),
                heading: presence.heading
            )
        }
    }

    func isVeteran(_ riderID: UUID) -> Bool {
        highlightVeterans && veteranRiderIDs.contains(riderID)
    }

    // MARK: - Mock Seeding

    private func seedMockPresences(near center: CLLocationCoordinate2D, in context: ModelContext) {
        let mockRiders: [(UUID, String)] = [
            (MockDataSeeder.bigMikeID,  "Big Mike"),
            (MockDataSeeder.whiskeyID,  "Whiskey"),
            (MockDataSeeder.turboID,    "Turbo"),
            (MockDataSeeder.redID,      "Red"),
            (MockDataSeeder.patchesID,  "Patches"),
            (MockDataSeeder.smokeyID,   "Smokey"),
        ]
        for (id, name) in mockRiders {
            let p = RiderPresence(
                riderID: id,
                displayName: name,
                latitude: center.latitude + Double.random(in: -0.04...0.04),
                longitude: center.longitude + Double.random(in: -0.04...0.04),
                heading: Double.random(in: 0...360),
                speedMPH: Double(Int.random(in: 0...70))
            )
            context.insert(p)
        }
        try? context.save()
    }

    private func seedMockBeacon(near center: CLLocationCoordinate2D, in context: ModelContext) {
        let beacon = DistressBeacon(
            riderID: MockDataSeeder.smokeyID,
            latitude: center.latitude + 0.022,
            longitude: center.longitude - 0.018,
            message: "Flat tire — need tire plug kit",
            bikeType: .cruiser
        )
        context.insert(beacon)
        try? context.save()
    }
}
