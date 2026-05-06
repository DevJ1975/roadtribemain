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
        guard estimatedRange > 0 else { return }   // can't reason about range with no MPG/capacity

        // We don't track actual fuel level yet, so we use the bike's estimated
        // full-tank range as a proxy for "how far you can go before refilling".
        // Trigger an alert when the nearest gas station is >= 15% of that range
        // away — i.e. you'd burn a meaningful chunk of a tank just reaching gas.
        let warningDistanceMiles = estimatedRange * 0.15

        let region = location.region(span: 0.3)
        guard let stations = try? await mapService.searchByCategory(.gasStation, region: region),
              let nearest = stations.first,
              let nearestLocation = nearest.placemark.location else { return }

        let userCL = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let distanceMiles = nearestLocation.distance(from: userCL).metersToMiles
        nearestStation = nearest
        nearestStationDistanceMiles = distanceMiles

        if distanceMiles > warningDistanceMiles {
            alert = FuelAlert(
                bikeName: bike.name,
                estimatedRangeMiles: estimatedRange,
                nearestStationName: nearest.name ?? "Gas Station",
                nearestStationDistanceMiles: distanceMiles
            )
        } else if alert != nil {
            alert = nil
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
