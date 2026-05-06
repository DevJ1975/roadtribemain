//
//  JournalListViewModel.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import SwiftData

/// ViewModel for the journal list screen.
@Observable
final class JournalListViewModel {

    var selectedTrip: Trip?
    var showingCreateEntry = false

    /// Groups journal entries by day for section display.
    func groupedEntries(_ entries: [JournalEntry]) -> [(date: Date, entries: [JournalEntry])] {
        let grouped = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }

        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }

    func deleteEntry(_ entry: JournalEntry, context: ModelContext) {
        context.delete(entry)
    }
}
