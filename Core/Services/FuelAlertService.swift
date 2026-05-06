//
//  FuelAlertService.swift
//  Road Tribe
//

import Foundation
import MapKit
import CoreLocation

/// Monitors fuel range and surfaces an alert when the nearest gas station
/// is within 20% of the bike's remaining estimated range.
@MainActor @Observable
final class FuelAlertService {

    /// Alert state published to UI.
    private(set) var alert: FuelAlert?

    /// Nearest gas station found.
    private(set) var nearestStation: MKMapItem?
    private(set) var nearestStationDistanceMiles: Double = 0

    private let mapService = MapService()
    private var monitorTask: Task<Void, Never>?

    // MARK: - Start / Stop

    func startMonitoring(bike: Motorcycle, locationService: LocationService) {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            // Check every 30 seconds while riding
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled,
                      let self,
                      let location = locationService.currentLocation else { continue }
                await self.evaluate(bike: bike, location: location)
            }
        }
    }

    func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
        alert = nil
        nearestStation = nil
    }

    func dismissAlert() {
        alert = nil
    }

    // MARK: - Evaluation

    private func evaluate(bike: Motorcycle, location: CLLocationCoordinate2D) async {
        let estimatedRange = bike.estimatedRange   // miles (full tank estimate)
        // Use 80% of range as the "remaining" assumption (we don't track actual fuel level)
        // A more advanced version would track mileage since last fill-up
        let warningThresholdMiles = estimatedRange * 0.20   // warn when < 20% range left

        let region = location.region(span: 0.3)
        guard let stations = try? await mapService.searchByCategory(.gasStation, region: region),
              let nearest = stations.first,
              let nearestLocation = nearest.placemark.location else { return }

        let userCL = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let distanceMeters = nearestLocation.distance(from: userCL)
        let distanceMiles = distanceMeters / 1609.344
        nearestStation = nearest
        nearestStationDistanceMiles = distanceMiles

        if distanceMiles > warningThresholdMiles * 0.75 {
            // Far from any gas station relative to remaining range — alert
            alert = FuelAlert(
                bikeName: bike.name,
                estimatedRangeMiles: estimatedRange,
                nearestStationName: nearest.name ?? "Gas Station",
                nearestStationDistanceMiles: distanceMiles
            )
        } else {
            // Plenty of range — clear any existing alert
            if alert != nil { alert = nil }
        }
    }
}

// MARK: - Alert Model

struct FuelAlert {
    let bikeName: String
    let estimatedRangeMiles: Double
    let nearestStationName: String
    let nearestStationDistanceMiles: Double

    var formattedDistance: String {
        String(format: "%.1f mi", nearestStationDistanceMiles)
    }
}
