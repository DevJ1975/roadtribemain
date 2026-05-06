//
//  Formatters.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation

/// Centralized date and number formatters for consistent display across the app.
enum Formatters {

    // MARK: - Date Formatters

    /// "Apr 6, 2026"
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// "Apr 6 – Apr 12, 2026" style range
    static func dateRange(from start: Date, to end: Date?) -> String {
        guard let end else {
            return mediumDate.string(from: start) + " – ..."
        }
        return mediumDate.string(from: start) + " – " + mediumDate.string(from: end)
    }

    /// "2:30 PM"
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// "Sunday, April 6"
    static let journalDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    /// Relative format: "2 hours ago", "Yesterday"
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    // MARK: - Distance

    /// Formats meters into a human-readable distance string.
    static func distance(meters: Double, unit: DistanceUnit = .miles) -> String {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let target: UnitLength = unit == .miles ? .miles : .kilometers
        let converted = measurement.converted(to: target)
        return String(format: "%.1f %@", converted.value, unit.abbreviation)
    }

    /// "3 PM" — cached formatter for hourly forecast display.
    static let hourlyTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()

    // MARK: - Duration

    /// Cached components formatter for "Xh Ym" style durations.
    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    /// Formats seconds into "Xh Ym" style.
    static func duration(seconds: TimeInterval) -> String {
        durationFormatter.string(from: seconds) ?? ""
    }
}
