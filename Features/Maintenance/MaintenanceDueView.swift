//
//  MaintenanceDueView.swift
//  Road Tribe
//

import SwiftUI
import SwiftData

/// Navigation destinations for the Maintenance feature. Used as
/// `NavigationLink` values from the Rides hub toolbar.
enum MaintenanceDestination: Hashable {
    case due(Motorcycle)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .due(let bike):
            hasher.combine("due")
            hasher.combine(bike.id)
        }
    }

    static func == (lhs: MaintenanceDestination, rhs: MaintenanceDestination) -> Bool {
        switch (lhs, rhs) {
        case (.due(let a), .due(let b)): return a.id == b.id
        }
    }
}

/// "What's due" dashboard for a motorcycle's upcoming services.
struct MaintenanceDueView: View {
    let motorcycle: Motorcycle

    @Environment(\.modelContext) private var modelContext
    @State private var showingFillUpSheet = false

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

            fuelStatusRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var fuelStatusRow: some View {
        HStack(spacing: Spacing.sm) {
            if let fraction = motorcycle.remainingFuelFraction(currentMileage: motorcycle.currentMileage) {
                let pct = Int(fraction * 100)
                Label("\(pct)% tank · \(Int(motorcycle.remainingRangeMiles(currentMileage: motorcycle.currentMileage))) mi left",
                      systemImage: "fuelpump.fill")
                    .font(.rtCaption)
                    .foregroundStyle(fraction < 0.2
                                     ? DesignSystem.Colors.danger
                                     : .secondary)
            } else {
                Label("No fill-up recorded", systemImage: "fuelpump")
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Record Fill-up") {
                showingFillUpSheet = true
            }
            .font(.rtCaptionBold)
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.top, Spacing.xs)
        .sheet(isPresented: $showingFillUpSheet) {
            RecordFillUpSheet(motorcycle: motorcycle)
                .presentationDetents([.fraction(0.35), .medium])
        }
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

// MARK: - Record fill-up sheet

/// Compact sheet that records a fill-up at the given odometer reading.
/// Defaults to the motorcycle's current mileage.
struct RecordFillUpSheet: View {
    let motorcycle: Motorcycle

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var mileageString: String
    @State private var date: Date = .now

    init(motorcycle: Motorcycle) {
        self.motorcycle = motorcycle
        _mileageString = State(initialValue: "\(motorcycle.currentMileage)")
    }

    private var parsedMileage: Int? {
        Int(mileageString.trimmingCharacters(in: .whitespaces))
    }

    private var canSave: Bool {
        guard let m = parsedMileage else { return false }
        return m >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Odometer") {
                    TextField("Mileage", text: $mileageString)
                        .keyboardType(.numberPad)
                }
                Section("When") {
                    DatePicker("Date", selection: $date, in: ...Date.now)
                }
            }
            .navigationTitle("Record Fill-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let mileage = parsedMileage else { return }
                        motorcycle.recordFillUp(at: mileage, on: date)
                        // Keep currentMileage in sync if fill-up reading is higher.
                        if mileage > motorcycle.currentMileage {
                            motorcycle.currentMileage = mileage
                        }
                        try? modelContext.save()
                        DesignSystem.Haptics.success()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
