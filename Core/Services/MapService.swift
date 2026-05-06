//
//  MapService.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import MapKit

/// Provides map-related functionality: route calculation, POI search, and directions.
@Observable
final class MapService {

    // MARK: - Route Calculation

    /// Calculate a driving route between two coordinates.
    func calculateRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()

        guard let route = response.routes.first else {
            throw MapError.noRouteFound
        }
        return route
    }

    /// Calculate a multi-stop route through an ordered list of waypoints.
    func calculateMultiStopRoute(
        through waypoints: [CLLocationCoordinate2D]
    ) async throws -> [MKRoute] {
        guard waypoints.count >= 2 else {
            throw MapError.insufficientWaypoints
        }

        var routes: [MKRoute] = []
        for i in 0..<(waypoints.count - 1) {
            let route = try await calculateRoute(from: waypoints[i], to: waypoints[i + 1])
            routes.append(route)
        }
        return routes
    }

    // MARK: - Points of Interest Search

    /// Search for nearby points of interest.
    func searchNearby(
        query: String,
        region: MKCoordinateRegion,
        maxResults: Int = 20
    ) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return Array(response.mapItems.prefix(maxResults))
    }

    /// Search for POIs by category within a region.
    func searchByCategory(
        _ category: MKPointOfInterestCategory,
        region: MKCoordinateRegion
    ) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.region = region
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [category])

        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems
    }

    // MARK: - Utility

    /// Estimate driving time and distance between two coordinates.
    func estimateTravelInfo(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> TravelEstimate {
        let route = try await calculateRoute(from: source, to: destination)
        return TravelEstimate(
            distance: route.distance,
            expectedTravelTime: route.expectedTravelTime
        )
    }
}

/// Summary of travel between two points.
struct TravelEstimate {
    let distance: CLLocationDistance // meters
    let expectedTravelTime: TimeInterval // seconds

    var formattedDistance: String {
        let formatter = MKDistanceFormatter()
        return formatter.string(fromDistance: distance)
    }

    var formattedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: expectedTravelTime) ?? ""
    }
}

// MARK: - Errors

enum MapError: LocalizedError {
    case noRouteFound
    case insufficientWaypoints

    var errorDescription: String? {
        switch self {
        case .noRouteFound: return "No driving route could be found."
        case .insufficientWaypoints: return "At least two waypoints are needed for a route."
        }
    }
}
