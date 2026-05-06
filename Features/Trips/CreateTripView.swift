//
//  CreateTripView.swift
//  Road Tribe
//
//  Compact form to plan a new trip — title, dates, optional description.
//  Waypoints are added later from the trip detail screen.
//

import SwiftUI
import SwiftData

struct CreateTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date.now
    @State private var hasEndDate = true
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    Toggle("Has end date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func create() {
        let trip = Trip(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            tripDescription: description.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            status: .planning
        )
        modelContext.insert(trip)
        DesignSystem.Haptics.success()
        dismiss()
    }
}
