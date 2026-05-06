//
//  Motorcycle.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import SwiftData

/// A motorcycle that the user tracks maintenance for.
@Model
final class Motorcycle {
    @Attribute(.unique) var id: UUID
    var name: String
    var make: String
    var model: String
    var year: Int
    var currentMileage: Int
    var vin: String
    var photoData: Data?
    var createdAt: Date

    /// Fuel tank capacity in gallons.
    var fuelCapacityGallons: Double
    /// Average miles per gallon for fuel range estimation.
    var averageMPG: Double
    /// Whether maintenance reminders are enabled.
    var remindersEnabled: Bool

    /// Odometer reading at the most recent fill-up. `nil` if no fill-up has been recorded.
    var lastFillUpMileage: Int?
    /// Wall-clock time of the most recent fill-up.
    var lastFillUpDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceRecord.motorcycle)
    var maintenanceRecords: [MaintenanceRecord]

    init(
        id: UUID = UUID(),
        name: String,
        make: String = "",
        model: String = "",
        year: Int = Calendar.current.component(.year, from: .now),
        currentMileage: Int = 0,
        vin: String = "",
        photoData: Data? = nil,
        fuelCapacityGallons: Double = 5.5,
        averageMPG: Double = 45.0,
        remindersEnabled: Bool = false,
        lastFillUpMileage: Int? = nil,
        lastFillUpDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.currentMileage = currentMileage
        self.vin = vin
        self.photoData = photoData
        self.fuelCapacityGallons = fuelCapacityGallons
        self.averageMPG = averageMPG
        self.remindersEnabled = remindersEnabled
        self.lastFillUpMileage = lastFillUpMileage
        self.lastFillUpDate = lastFillUpDate
        self.createdAt = .now
        self.maintenanceRecords = []
    }

    /// Estimated full-tank range in miles. Returns 0 when capacity or MPG is non-positive.
    var estimatedRange: Double {
        guard fuelCapacityGallons > 0, averageMPG > 0 else { return 0 }
        return fuelCapacityGallons * averageMPG
    }

    /// Miles ridden since the last fill-up. Returns 0 if no fill-up has been
    /// recorded or the odometer has somehow gone backwards.
    func milesSinceFillUp(currentMileage: Int) -> Int {
        guard let last = lastFillUpMileage else { return 0 }
        return max(0, currentMileage - last)
    }

    /// Estimated remaining fuel range in miles based on the odometer delta
    /// since the last recorded fill-up. Falls back to `estimatedRange` when
    /// no fill-up has been recorded yet.
    func remainingRangeMiles(currentMileage: Int) -> Double {
        guard estimatedRange > 0 else { return 0 }
        guard lastFillUpMileage != nil else { return estimatedRange }
        let consumed = Double(milesSinceFillUp(currentMileage: currentMileage))
        return max(0, estimatedRange - consumed)
    }

    /// Fraction of the tank remaining (0...1) since the last fill-up.
    /// Returns `nil` if estimated range is unknown or no fill-up recorded.
    func remainingFuelFraction(currentMileage: Int) -> Double? {
        guard estimatedRange > 0, lastFillUpMileage != nil else { return nil }
        return min(1, max(0, remainingRangeMiles(currentMileage: currentMileage) / estimatedRange))
    }

    /// Record a fill-up at the given odometer reading. Defaults to `currentMileage`.
    func recordFillUp(at mileage: Int? = nil, on date: Date = .now) {
        lastFillUpMileage = mileage ?? currentMileage
        lastFillUpDate = date
    }
}
