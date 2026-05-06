//
//  MaintenanceDueView.swift
//  Road Tribe
//

import SwiftUI
import SwiftData

/// "What's due" dashboard for a motorcycle's upcoming services.
struct MaintenanceDueView: View {
    let motorcycle: Motorcycle

    @Environment(\.modelContext) private var modelContext

    private var items: [MaintenanceDueItem] {
        MaintenanceDueService.upcomingServices(for: motorcycle)
    }

    private var overdue: [MaintenanceDueItem] { items.filter(\.isOverdue) }
    private var upcoming: [MaintenanceDueItem] { items.filter(\.isUpcoming) }
    private var later: [MaintenanceDueItem] {
        items.filter { !$0.isOverdue && !$0.isUpcoming }
    }

    var body: some View {
        List {
            Section {
                summaryHeader
            }
            .listRowBackground(Color.clear)

            if !overdue.isEmpty {
                Section("Overdue") {
                    ForEach(overdue) { row($0) }
                }
            }
            if !upcoming.isEmpty {
                Section("Coming Up") {
                    ForEach(upcoming) { row($0) }
                }
            }
            if !later.isEmpty {
                Section("On the Horizon") {
                    ForEach(later) { row($0) }
                }
            }
        }
        .navigationTitle("Maintenance Due")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    scheduleAllReminders()
                } label: {
                    Label("Remind Me", systemImage: "bell.badge")
                }
                .disabled(items.allSatisfy { $0.milesUntilDue <= 0 })
            }
        }
    }

    // MARK: - Subviews

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(motorcycle.name)
                .font(.rtHeadline)
            Text("\(motorcycle.currentMileage.formatted()) mi")
                .font(.rtCaption)
                .foregroundStyle(.secondary)

            if !overdue.isEmpty {
                Label(
                    "\(overdue.count) service\(overdue.count == 1 ? "" : "s") overdue",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.rtCaption)
                .foregroundStyle(DesignSystem.Colors.danger)
            } else if !upcoming.isEmpty {
                Label(
                    "\(upcoming.count) service\(upcoming.count == 1 ? "" : "s") coming up",
                    systemImage: "clock.fill"
                )
                .font(.rtCaption)
                .foregroundStyle(DesignSystem.Colors.warning)
            } else {
                Label("All caught up", systemImage: "checkmark.seal.fill")
                    .font(.rtCaption)
                    .foregroundStyle(DesignSystem.Colors.success)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ item: MaintenanceDueItem) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: item.serviceType.iconName)
                .frame(width: 28)
                .foregroundStyle(item.isOverdue
                                 ? DesignSystem.Colors.danger
                                 : (item.isUpcoming ? DesignSystem.Colors.warning : .secondary))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.serviceType.displayName)
                    .font(.rtBody)
                Text(secondaryLine(for: item))
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(milesLine(for: item))
                .font(.rtCaptionBold)
                .foregroundStyle(item.isOverdue
                                 ? DesignSystem.Colors.danger
                                 : .primary)
                .monospacedDigit()
        }
    }

    private func secondaryLine(for item: MaintenanceDueItem) -> String {
        if let last = item.lastDoneAtMileage {
            return "Last done at \(last.formatted()) mi"
        }
        return "Never recorded"
    }

    private func milesLine(for item: MaintenanceDueItem) -> String {
        if item.isOverdue {
            return "\((-item.milesUntilDue).formatted()) mi over"
        }
        return "in \(item.milesUntilDue.formatted()) mi"
    }

    // MARK: - Actions

    private func scheduleAllReminders() {
        let upcomingItems = items.filter { $0.milesUntilDue > 0 }
        NotificationService.shared.scheduleReminders(
            for: motorcycle,
            upcomingServices: MaintenanceDueService.reminderTriples(from: upcomingItems)
        )
        DesignSystem.Haptics.success()
    }
}
