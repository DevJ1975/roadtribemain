//
//  NotificationService.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import UserNotifications

/// Manages local push notifications for maintenance reminders.
@Observable
final class NotificationService {
    static let shared = NotificationService()

    private(set) var isAuthorized = false

    // MARK: - Authorization

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            isAuthorized = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            isAuthorized = false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Maintenance Reminders

    /// Schedule a local notification for an upcoming maintenance service.
    func scheduleMaintenanceReminder(
        bikeName: String,
        serviceType: String,
        milesUntilDue: Int,
        averageDailyMiles: Double = 30
    ) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Service Due Soon"
        content.body = "\(bikeName) needs \(serviceType) in ~\(milesUntilDue) miles. Time to schedule a visit!"
        content.sound = .default
        content.categoryIdentifier = "MAINTENANCE_REMINDER"

        // Estimate days until due based on average daily riding.
        // Guard against zero/negative miles-per-day so we don't divide by zero or by a negative.
        let dailyMiles = max(1, averageDailyMiles)
        let estimatedDays = max(1, Int(Double(milesUntilDue) / dailyMiles))
        // Notify 2 days before estimated due date, minimum 1 hour from now
        let notifyInSeconds = max(3600, TimeInterval((estimatedDays - 2)) * MeasurementConstants.secondsPerDay)

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: notifyInSeconds,
            repeats: false
        )

        let identifier = "maint-\(bikeName)-\(serviceType)".replacingOccurrences(of: " ", with: "-").lowercased()
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    /// Schedule reminders for all upcoming services on a bike.
    func scheduleReminders(for bike: Motorcycle, upcomingServices: [(serviceType: ServiceType, dueMileage: Int, milesUntilDue: Int)]) {
        // Clear existing reminders for this bike first
        cancelReminders(for: bike.name)

        for service in upcomingServices where service.milesUntilDue > 0 {
            scheduleMaintenanceReminder(
                bikeName: bike.name,
                serviceType: service.serviceType.displayName,
                milesUntilDue: service.milesUntilDue
            )
        }
    }

    /// Cancel all maintenance reminders for a specific bike.
    func cancelReminders(for bikeName: String) {
        let center = UNUserNotificationCenter.current()
        let prefix = "maint-\(bikeName)".replacingOccurrences(of: " ", with: "-").lowercased()
        center.getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// Cancel all maintenance reminders.
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
