//
//  MaintenanceRecord.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import SwiftData

/// A single maintenance event for a motorcycle.
@Model
final class MaintenanceRecord {
    @Attribute(.unique) var id: UUID
    var serviceType: ServiceType
    var date: Date
    var mileage: Int
    var cost: Double?
    var shop: String
    var notes: String
    var isCompleted: Bool

    var motorcycle: Motorcycle?

    init(
        id: UUID = UUID(),
        serviceType: ServiceType,
        date: Date = .now,
        mileage: Int = 0,
        cost: Double? = nil,
        shop: String = "",
        notes: String = "",
        isCompleted: Bool = true
    ) {
        self.id = id
        self.serviceType = serviceType
        self.date = date
        self.mileage = mileage
        self.cost = cost
        self.shop = shop
        self.notes = notes
        self.isCompleted = isCompleted
    }
}

/// Types of motorcycle maintenance services.
enum ServiceType: String, Codable, CaseIterable, Identifiable {
    // Routine
    case oilChange
    case tireRotation
    case tireReplacement
    case brakeInspection
    case brakePadReplacement
    case chainCleanLube
    case chainReplacement
    case airFilter
    case sparkPlugs
    case coolantFlush
    case brakeFluidFlush

    // Mileage-based intervals
    case service5k
    case service10k
    case service15k
    case service20k
    case service25k
    case service30k

    // Major
    case valveAdjustment
    case forkSeal
    case batteryReplacement
    case statorAlternator
    case clutchReplacement
    case finalDrive

    // Other
    case inspection
    case recall
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oilChange: return "Oil Change"
        case .tireRotation: return "Tire Rotation"
        case .tireReplacement: return "Tire Replacement"
        case .brakeInspection: return "Brake Inspection"
        case .brakePadReplacement: return "Brake Pad Replacement"
        case .chainCleanLube: return "Chain Clean & Lube"
        case .chainReplacement: return "Chain & Sprocket Replacement"
        case .airFilter: return "Air Filter"
        case .sparkPlugs: return "Spark Plugs"
        case .coolantFlush: return "Coolant Flush"
        case .brakeFluidFlush: return "Brake Fluid Flush"
        case .service5k: return "5,000 Mile Service"
        case .service10k: return "10,000 Mile Service"
        case .service15k: return "15,000 Mile Service"
        case .service20k: return "20,000 Mile Service"
        case .service25k: return "25,000 Mile Service"
        case .service30k: return "30,000 Mile Service"
        case .valveAdjustment: return "Valve Adjustment"
        case .forkSeal: return "Fork Seal Replacement"
        case .batteryReplacement: return "Battery Replacement"
        case .statorAlternator: return "Stator / Alternator"
        case .clutchReplacement: return "Clutch Replacement"
        case .finalDrive: return "Final Drive Service"
        case .inspection: return "General Inspection"
        case .recall: return "Recall Service"
        case .custom: return "Custom Service"
        }
    }

    var iconName: String {
        switch self {
        case .oilChange: return "drop.fill"
        case .tireRotation, .tireReplacement: return "circle.circle"
        case .brakeInspection, .brakePadReplacement: return "exclamationmark.octagon.fill"
        case .chainCleanLube, .chainReplacement: return "link"
        case .airFilter: return "wind"
        case .sparkPlugs: return "bolt.fill"
        case .coolantFlush: return "thermometer.medium"
        case .brakeFluidFlush: return "drop.triangle.fill"
        case .service5k, .service10k, .service15k,
             .service20k, .service25k, .service30k: return "gauge.with.dots.needle.67percent"
        case .valveAdjustment: return "wrench.adjustable.fill"
        case .forkSeal: return "arrow.up.and.down"
        case .batteryReplacement: return "battery.100percent"
        case .statorAlternator: return "bolt.circle.fill"
        case .clutchReplacement: return "gearshape.fill"
        case .finalDrive: return "gear"
        case .inspection: return "checklist"
        case .recall: return "exclamationmark.triangle.fill"
        case .custom: return "wrench.and.screwdriver.fill"
        }
    }

    var category: ServiceCategory {
        switch self {
        case .oilChange, .tireRotation, .tireReplacement, .brakeInspection,
             .brakePadReplacement, .chainCleanLube, .chainReplacement,
             .airFilter, .sparkPlugs, .coolantFlush, .brakeFluidFlush:
            return .routine
        case .service5k, .service10k, .service15k,
             .service20k, .service25k, .service30k:
            return .mileageInterval
        case .valveAdjustment, .forkSeal, .batteryReplacement,
             .statorAlternator, .clutchReplacement, .finalDrive:
            return .major
        case .inspection, .recall, .custom:
            return .other
        }
    }

    /// Suggested mileage interval for this service type (nil = no fixed interval).
    var suggestedIntervalMiles: Int? {
        switch self {
        case .oilChange: return 3_000
        case .chainCleanLube: return 500
        case .airFilter: return 12_000
        case .sparkPlugs: return 12_000
        case .coolantFlush: return 24_000
        case .brakeFluidFlush: return 24_000
        case .service5k: return 5_000
        case .service10k: return 10_000
        case .service15k: return 15_000
        case .service20k: return 20_000
        case .service25k: return 25_000
        case .service30k: return 30_000
        case .tireReplacement: return 10_000
        case .chainReplacement: return 20_000
        case .valveAdjustment: return 15_000
        default: return nil
        }
    }
}

/// Groupings for the service type picker.
enum ServiceCategory: String, CaseIterable, Identifiable {
    case routine = "Routine"
    case mileageInterval = "Mileage Intervals"
    case major = "Major"
    case other = "Other"

    var id: String { rawValue }
}
