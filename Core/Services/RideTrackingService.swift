//
//  RideTrackingService.swift
//  Road Tribe
//

import Foundation
import SwiftUI
import SwiftData

/// Tracks the currently active ride across the app for the persistent ride banner.
@MainActor @Observable
final class RideTrackingService {
    var activeTrip: Trip?
    var rideStartTime: Date?
    var elapsedSeconds: Int = 0
    var distanceMiles: Double = 0

    private var timerTask: Task<Void, Never>?
    private var locationService: LocationService?

    var isRiding: Bool { activeTrip != nil }

    var formattedElapsedTime: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s)
                      : String(format: "%d:%02d", m, s)
    }

    func startRide(trip: Trip, locationService: LocationService? = nil) {
        activeTrip = trip
        rideStartTime = Date()
        elapsedSeconds = 0
        distanceMiles = trip.totalDistanceMiles
        self.locationService = locationService

        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self, let start = self.rideStartTime else { break }
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }

        locationService?.startRecording()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func pauseRide() {
        timerTask?.cancel()
        timerTask = nil
        activeTrip?.status = .paused
    }

    /// Ends the ride and returns the recorded GPS points (caller should persist them).
    @discardableResult
    func endRide() -> [RoutePoint] {
        timerTask?.cancel()
        timerTask = nil
        let points = locationService?.stopRecording() ?? []
        locationService = nil
        activeTrip?.status = .completed
        activeTrip?.endDate = Date()
        activeTrip = nil
        rideStartTime = nil
        elapsedSeconds = 0

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        return points
    }
}
