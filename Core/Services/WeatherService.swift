//
//  WeatherService.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import WeatherKit
import CoreLocation

/// Provides weather data and alerts using Apple WeatherKit.
@Observable
final class RoadWeatherService {

    private let service = WeatherKit.WeatherService.shared

    private(set) var currentCondition: CurrentConditionInfo?
    private(set) var weatherAlerts: [WeatherAlertInfo] = []
    private(set) var hourlyForecast: [HourForecastInfo] = []
    private(set) var isLoading = false
    private(set) var lastError: String?

    // MARK: - Fetch Weather at Location

    /// Fetch current conditions, alerts, hourly and daily forecast for a location.
    func fetchWeather(at coordinate: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let (current, hourly, daily, alerts) = try await service.weather(
                for: location,
                including: .current, .hourly, .daily, .alerts
            )

            let today = daily.first
            currentCondition = CurrentConditionInfo(
                temperature: current.temperature.converted(to: .fahrenheit).value,
                feelsLike: current.apparentTemperature.converted(to: .fahrenheit).value,
                conditionDescription: current.condition.description,
                symbolName: current.symbolName,
                windSpeedMPH: current.wind.speed.converted(to: .milesPerHour).value,
                windGustMPH: current.wind.gust?.converted(to: .milesPerHour).value,
                windDirection: current.wind.compassDirection.abbreviation,
                humidity: current.humidity,
                uvIndexValue: current.uvIndex.value,
                dewPointF: current.dewPoint.converted(to: .fahrenheit).value,
                pressureInHg: current.pressure.converted(to: .inchesOfMercury).value,
                pressureTrend: current.pressureTrend,
                visibilityMiles: current.visibility.converted(to: .miles).value,
                isDaylight: current.isDaylight,
                sunrise: today?.sun.sunrise,
                sunset: today?.sun.sunset
            )

            hourlyForecast = Array(hourly.prefix(12)).map { hour in
                HourForecastInfo(
                    date: hour.date,
                    temperature: hour.temperature.converted(to: .fahrenheit).value,
                    symbolName: hour.symbolName,
                    precipitationChance: hour.precipitationChance,
                    conditionDescription: hour.condition.description
                )
            }

            if let alerts {
                weatherAlerts = alerts.map { alert in
                    WeatherAlertInfo(
                        summary: alert.summary,
                        severity: mapSeverity(alert.severity),
                        source: alert.source,
                        detailsURL: alert.detailsURL
                    )
                }
            } else {
                weatherAlerts = []
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Fetch weather at multiple points along a route — runs all requests concurrently.
    func fetchRouteWeather(coordinates: [CLLocationCoordinate2D]) async -> [RouteWeatherPoint] {
        // Sample every ~50 miles along the route (take up to 5 points)
        let stride = max(1, coordinates.count / 5)
        let samplePoints = Swift.stride(from: 0, to: coordinates.count, by: stride).map { coordinates[$0] }

        return await withTaskGroup(of: RouteWeatherPoint?.self) { group in
            for coord in samplePoints {
                group.addTask { [service] in
                    let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                    guard let current = try? await service.weather(for: location, including: .current) else { return nil }
                    return RouteWeatherPoint(
                        coordinate: coord,
                        temperature: current.temperature.converted(to: .fahrenheit).value,
                        symbolName: current.symbolName,
                        conditionDescription: current.condition.description,
                        windSpeedMPH: current.wind.speed.converted(to: .milesPerHour).value
                    )
                }
            }
            var results: [RouteWeatherPoint] = []
            for await point in group {
                if let point { results.append(point) }
            }
            return results.sorted { $0.coordinate.latitude < $1.coordinate.latitude }
        }
    }

    private func mapSeverity(_ severity: WeatherSeverity) -> AlertSeverity {
        switch severity {
        case .minor: return .minor
        case .moderate: return .moderate
        case .severe: return .severe
        case .extreme: return .extreme
        default: return .minor
        }
    }
}

// MARK: - Data Models

struct CurrentConditionInfo {
    let temperature: Double          // Fahrenheit
    let feelsLike: Double            // Fahrenheit
    let conditionDescription: String
    let symbolName: String           // SF Symbol name
    let windSpeedMPH: Double
    let windGustMPH: Double?
    let windDirection: String
    let humidity: Double             // 0.0–1.0
    let uvIndexValue: Int
    let dewPointF: Double            // Fahrenheit
    let pressureInHg: Double         // inches of mercury
    let pressureTrend: PressureTrend
    let visibilityMiles: Double
    let isDaylight: Bool
    let sunrise: Date?
    let sunset: Date?

    var temperatureFormatted: String { "\(Int(temperature))°F" }
    var feelsLikeFormatted: String { "\(Int(feelsLike))°F" }
    var windFormatted: String { "\(Int(windSpeedMPH)) mph \(windDirection)" }
    var humidityFormatted: String { "\(Int(humidity * 100))%" }
    var dewPointFormatted: String { "\(Int(dewPointF))°F" }
    var pressureFormatted: String { String(format: "%.2f inHg", pressureInHg) }

    var pressureTrendSymbol: String {
        switch pressureTrend {
        case .rising: return "arrow.up.right"
        case .falling: return "arrow.down.right"
        case .steady: return "arrow.right"
        @unknown default: return "arrow.right"
        }
    }
}

struct HourForecastInfo: Identifiable {
    var id: Date { date }
    let date: Date
    let temperature: Double
    let symbolName: String
    let precipitationChance: Double
    let conditionDescription: String

    var timeFormatted: String { Formatters.hourlyTime.string(from: date) }
    var tempFormatted: String { "\(Int(temperature))°" }
    var precipFormatted: String { "\(Int(precipitationChance * 100))%" }
}

struct WeatherAlertInfo: Identifiable {
    var id: String { summary + severity.rawValue }
    let summary: String
    let severity: AlertSeverity
    let source: String
    let detailsURL: URL?
}

enum AlertSeverity: String {
    case minor, moderate, severe, extreme

    var color: String {
        switch self {
        case .minor: return "yellow"
        case .moderate: return "orange"
        case .severe: return "red"
        case .extreme: return "purple"
        }
    }

    var iconName: String {
        switch self {
        case .minor: return "exclamationmark.triangle"
        case .moderate: return "exclamationmark.triangle.fill"
        case .severe: return "bolt.trianglebadge.exclamationmark.fill"
        case .extreme: return "exclamationmark.octagon.fill"
        }
    }
}

struct RouteWeatherPoint: Identifiable {
    var id: String { "\(coordinate.latitude),\(coordinate.longitude)" }
    let coordinate: CLLocationCoordinate2D
    let temperature: Double
    let symbolName: String
    let conditionDescription: String
    let windSpeedMPH: Double
}
