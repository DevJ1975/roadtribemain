//
//  QuickJournalCaptureView.swift
//  Road Tribe
//
//  Sheet content launched from the ride banner. Wraps CreateJournalEntryView
//  with the active trip, current GPS coordinate, reverse-geocoded location,
//  and current weather already filled in so the rider only writes the body.
//

import SwiftUI

struct QuickJournalCaptureView: View {
    @Environment(RideTrackingService.self) private var rideTracking
    @Environment(LocationService.self) private var locationService

    /// Optional weather service — passed in so previews and tests can stub it.
    /// The environment lookup is conditional because weather is owned by the
    /// view that hosts the sheet (Rides hub).
    let weatherService: RoadWeatherService?

    @State private var prefill: JournalEntryPrefill?

    init(weatherService: RoadWeatherService? = nil) {
        self.weatherService = weatherService
    }

    var body: some View {
        Group {
            if let prefill {
                CreateJournalEntryView(prefill: prefill)
            } else {
                ProgressView("Capturing your ride context…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            prefill = await buildPrefill()
        }
    }

    // MARK: - Prefill builder

    private func buildPrefill() async -> JournalEntryPrefill {
        var prefill = JournalEntryPrefill()
        prefill.trip = rideTracking.activeTrip
        prefill.title = QuickJournalCaptureView.suggestedTitle(
            tripTitle: rideTracking.activeTrip?.title,
            elapsedSeconds: rideTracking.elapsedSeconds
        )

        if let coord = locationService.currentLocation {
            prefill.latitude = coord.latitude
            prefill.longitude = coord.longitude
            prefill.locationName = try? await locationService.reverseGeocode(coordinate: coord)
        }

        if let condition = weatherService?.currentCondition {
            prefill.weatherDescription = "\(condition.conditionDescription), \(condition.temperatureFormatted)"
        }

        return prefill
    }

    /// Pure helper extracted for tests.
    static func suggestedTitle(tripTitle: String?, elapsedSeconds: Int) -> String {
        let stamp = formattedClock(elapsedSeconds)
        if let trip = tripTitle, !trip.isEmpty {
            return "\(trip) — \(stamp)"
        }
        return "Quick note at \(stamp)"
    }

    private static func formattedClock(_ seconds: Int) -> String {
        let total = max(0, seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        return h > 0 ? String(format: "%d:%02d", h, m) : String(format: "%dm", m)
    }
}
