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
        remindersEnabled: Bool = false
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
        self.createdAt = .now
        self.maintenanceRecords = []
    }

    /// Estimated full-tank range in miles. Returns 0 when capacity or MPG is non-positive.
    var estimatedRange: Double {
        guard fuelCapacityGallons > 0, averageMPG > 0 else { return 0 }
        return fuelCapacityGallons * averageMPG
    }
}
