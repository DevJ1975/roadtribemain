//
//  PreRideCheck.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// A recorded pre-ride T-CLOCS inspection for a motorcycle.
@Model
final class PreRideCheck {
    @Attribute(.unique) var id: UUID
    var motorcycleID: UUID
    var timestamp: Date

    /// Results keyed by TclocsCategory rawValue — true = passed, false = flagged.
    var results: [String: Bool]

    /// Overall pass/flag/skip outcome.
    var outcome: CheckOutcome

    init(motorcycleID: UUID, results: [String: Bool] = [:], outcome: CheckOutcome = .passed) {
        self.id = UUID()
        self.motorcycleID = motorcycleID
        self.timestamp = .now
        self.results = results
        self.outcome = outcome
    }

    /// Number of items flagged during this check.
    var flaggedCount: Int {
        results.values.filter { !$0 }.count
    }
}

enum CheckOutcome: String, Codable {
    case passed   // all items checked green
    case flagged  // one or more items flagged
    case skipped  // rider acknowledged but did not complete
}

// MARK: - T-CLOCS Categories & Items

enum TclocsCategory: String, CaseIterable, Identifiable {
    case tires      = "T"
    case controls   = "C1"
    case lights     = "L"
    case oil        = "O"
    case chassis    = "C2"
    case stands     = "S"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tires:    return "Tires & Wheels"
        case .controls: return "Controls"
        case .lights:   return "Lights & Electrics"
        case .oil:      return "Oil & Fluids"
        case .chassis:  return "Chassis & Chain"
        case .stands:   return "Stands"
        }
    }

    var letter: String {
        switch self {
        case .tires:    return "T"
        case .controls: return "C"
        case .lights:   return "L"
        case .oil:      return "O"
        case .chassis:  return "C"
        case .stands:   return "S"
        }
    }

    var iconName: String {
        switch self {
        case .tires:    return "circle.circle.fill"
        case .controls: return "hand.raised.fill"
        case .lights:   return "lightbulb.fill"
        case .oil:      return "drop.fill"
        case .chassis:  return "gearshape.2.fill"
        case .stands:   return "rectangle.portrait.bottomhalf.inset.filled"
        }
    }

    /// Individual checklist items for this category.
    var items: [TclocsItem] {
        switch self {
        case .tires:
            return [
                TclocsItem(id: "t_pressure", category: .tires, label: "Tire pressure correct"),
                TclocsItem(id: "t_tread", category: .tires, label: "Tread depth adequate"),
                TclocsItem(id: "t_cracks", category: .tires, label: "No cracks or bulges"),
                TclocsItem(id: "t_spokes", category: .tires, label: "Spokes/wheels undamaged"),
            ]
        case .controls:
            return [
                TclocsItem(id: "c_levers", category: .controls, label: "Levers adjust freely"),
                TclocsItem(id: "c_cables", category: .controls, label: "Cables undamaged & lubed"),
                TclocsItem(id: "c_throttle", category: .controls, label: "Throttle opens & snaps back"),
                TclocsItem(id: "c_foot", category: .controls, label: "Foot controls operate smoothly"),
            ]
        case .lights:
            return [
                TclocsItem(id: "l_head", category: .lights, label: "Headlight working (hi & lo)"),
                TclocsItem(id: "l_signals", category: .lights, label: "Turn signals working"),
                TclocsItem(id: "l_brake", category: .lights, label: "Brake light triggers on both levers"),
                TclocsItem(id: "l_battery", category: .lights, label: "Battery secure & connections clean"),
            ]
        case .oil:
            return [
                TclocsItem(id: "o_engine", category: .oil, label: "Engine oil level good"),
                TclocsItem(id: "o_brake", category: .oil, label: "Brake fluid at MIN line"),
                TclocsItem(id: "o_coolant", category: .oil, label: "Coolant level OK (if liquid-cooled)"),
                TclocsItem(id: "o_fuel", category: .oil, label: "Fuel level sufficient"),
            ]
        case .chassis:
            return [
                TclocsItem(id: "ch_frame", category: .chassis, label: "Frame/subframe no visible cracks"),
                TclocsItem(id: "ch_susp", category: .chassis, label: "Suspension smooth, no leaks"),
                TclocsItem(id: "ch_chain", category: .chassis, label: "Chain tension correct & lubed"),
                TclocsItem(id: "ch_bolts", category: .chassis, label: "No loose fasteners"),
            ]
        case .stands:
            return [
                TclocsItem(id: "s_side", category: .stands, label: "Side stand spring intact"),
                TclocsItem(id: "s_center", category: .stands, label: "Center stand pivot (if equipped)"),
                TclocsItem(id: "s_mount", category: .stands, label: "Stand mounting bolts tight"),
            ]
        }
    }
}

struct TclocsItem: Identifiable {
    let id: String
    let category: TclocsCategory
    let label: String
}
