//
//  LocationService.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import CoreLocation

/// Manages device location tracking and geocoding.
@Observable
final class LocationService: NSObject {

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private(set) var currentLocation: CLLocationCoordinate2D?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var isTracking = false

    /// Current speed in meters per second (negative means invalid).
    private(set) var currentSpeedMPS: Double = -1

    /// Current speed in MPH, nil if not available.
    var currentSpeedMPH: Int? {
        guard currentSpeedMPS >= 0 else { return nil }
        return Int(currentSpeedMPS * 2.23694)
    }

    /// Current heading in degrees (0–360), nil if unavailable.
    private(set) var currentHeading: CLLocationDirection?

    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    // MARK: - Recording

    /// Whether GPS breadcrumb recording is active.
    private(set) var isRecording = false
    /// Accumulated route points for the current recording session.
    private(set) var recordedPoints: [RoutePoint] = []
    private var lastRecordedDate: Date = .distantPast
    /// Minimum seconds between recorded points (reduces storage while keeping accuracy).
    private let recordingInterval: TimeInterval = 3

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // meters — more frequent for speed updates
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Authorization

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Location Tracking

    func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            requestAuthorization()
            return
        }
        isTracking = true
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        currentSpeedMPS = -1
    }

    func startRecording() {
        recordedPoints = []
        lastRecordedDate = .distantPast
        isRecording = true
        startTracking()
    }

    func stopRecording() -> [RoutePoint] {
        isRecording = false
        let captured = recordedPoints
        recordedPoints = []
        return captured
    }

    /// Request a single location update.
    func requestCurrentLocation() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    // MARK: - Geocoding

    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else {
            throw LocationError.geocodingFailed
        }
        return [placemark.locality, placemark.administrativeArea]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    func geocode(address: String) async throws -> CLLocationCoordinate2D {
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let location = placemarks.first?.location else {
            throw LocationError.geocodingFailed
        }
        return location.coordinate
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
        currentSpeedMPS = location.speed
        currentHeading = location.course >= 0 ? location.course : nil

        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(returning: location.coordinate)
        }

        // Breadcrumb recording — sample at most once every `recordingInterval` seconds
        if isRecording {
            let now = Date()
            if now.timeIntervalSince(lastRecordedDate) >= recordingInterval {
                recordedPoints.append(RoutePoint(from: location))
                lastRecordedDate = now
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(throwing: error)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

// MARK: - Errors

enum LocationError: LocalizedError {
    case geocodingFailed
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .geocodingFailed: return "Unable to find that location."
        case .unauthorized: return "Location access is required for this feature."
        }
    }
}
