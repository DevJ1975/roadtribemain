// RTBeaconService.swift
// Road Tribe
//
// Manages the distress beacon lifecycle: activate → broadcast → resolve/cancel.
// In this build, presence is local-only (no backend). Phase 3 will sync via NetworkService.

import Foundation
import SwiftData

@Observable
@MainActor
final class RTBeaconService {

    // MARK: - State

    private(set) var activeBeacon: DistressBeacon? = nil
    private(set) var beaconElapsedSeconds: Int = 0

    var isBeaconActive: Bool { activeBeacon != nil }

    private var timerTask: Task<Void, Never>? = nil

    // MARK: - Activation

    func activateBeacon(
        riderID: UUID,
        bikeType: BikeType,
        message: String,
        latitude: Double,
        longitude: Double,
        in context: ModelContext
    ) {
        let beacon = DistressBeacon(
            riderID: riderID,
            latitude: latitude,
            longitude: longitude,
            message: message,
            bikeType: bikeType
        )
        context.insert(beacon)
        try? context.save()
        activeBeacon = beacon
        beaconElapsedSeconds = 0
        startElapsedTimer()
    }

    // MARK: - Resolution

    func cancelBeacon(in context: ModelContext) {
        guard let beacon = activeBeacon else { return }
        beacon.status = .cancelled
        beacon.resolvedAt = .now
        try? context.save()
        clearActive()
    }

    func resolveBeacon(in context: ModelContext) {
        guard let beacon = activeBeacon else { return }
        beacon.status = .resolved
        beacon.resolvedAt = .now
        try? context.save()
        clearActive()
    }

    // MARK: - Private

    private func clearActive() {
        activeBeacon = nil
        stopElapsedTimer()
    }

    private func startElapsedTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                beaconElapsedSeconds += 1
            }
        }
    }

    private func stopElapsedTimer() {
        timerTask?.cancel()
        timerTask = nil
        beaconElapsedSeconds = 0
    }
}
