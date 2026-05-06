//
//  MaintenanceDueService.swift
//  Road Tribe
//
//  Pure-logic service that computes upcoming maintenance for a motorcycle
//  by combining `ServiceType.suggestedIntervalMiles` with the bike's history
//  of `MaintenanceRecord`s.
//

import Foundation

/// One row in the "what's due" dashboard.
struct MaintenanceDueItem: Identifiable, Equatable {
    /// `ServiceType.rawValue` — stable identity across reloads.
    var id: String { serviceType.rawValue }

    let serviceType: ServiceType
    /// Mileage at which this service was last performed, or `nil` if never.
    let lastDoneAtMileage: Int?
    /// Mileage when this service is next due.
    let dueAtMileage: Int
    /// Miles between the bike's current mileage and the due mileage.
    /// Negative when the service is overdue.
    let milesUntilDue: Int

    var isOverdue: Bool { milesUntilDue < 0 }
    /// "Coming up soon" window — within 500 miles of due.
    var isUpcoming: Bool { !isOverdue && milesUntilDue <= 500 }
}

/// Computes upcoming services for a motorcycle.
struct MaintenanceDueService {

    /// Service types that have a recommended mileage interval, ordered by
    /// nearest-due first. Service types without an interval (custom, recall)
    /// are excluded — they're event-driven, not interval-driven.
    static func upcomingServices(for bike: Motorcycle) -> [MaintenanceDueItem] {
        let trackedTypes = ServiceType.allCases.filter { $0.suggestedIntervalMiles != nil }
        let items = trackedTypes.compactMap { type -> MaintenanceDueItem? in
            dueItem(for: type, bike: bike)
        }
        return items.sorted { $0.milesUntilDue < $1.milesUntilDue }
    }

    /// Compute the due item for a single service type. Returns `nil` only if
    /// the service type has no recommended interval.
    static func dueItem(for serviceType: ServiceType, bike: Motorcycle) -> MaintenanceDueItem? {
        guard let interval = serviceType.suggestedIntervalMiles else { return nil }

        let lastDone = bike.maintenanceRecords
            .filter { $0.serviceType == serviceType && $0.isCompleted }
            .map(\.mileage)
            .max()

        // If the rider has never done this service we treat the interval as
        // due from mileage 0, so (e.g.) a 12k-mile bike that's never had an
        // air filter change shows up as overdue.
        let baseMileage = lastDone ?? 0
        let dueAt = baseMileage + interval

        return MaintenanceDueItem(
            serviceType: serviceType,
            lastDoneAtMileage: lastDone,
            dueAtMileage: dueAt,
            milesUntilDue: dueAt - bike.currentMileage
        )
    }

    /// Convert the dashboard items into the tuple shape expected by
    /// `NotificationService.scheduleReminders`.
    static func reminderTriples(
        from items: [MaintenanceDueItem]
    ) -> [(serviceType: ServiceType, dueMileage: Int, milesUntilDue: Int)] {
        items.map { ($0.serviceType, $0.dueAtMileage, $0.milesUntilDue) }
    }
}
