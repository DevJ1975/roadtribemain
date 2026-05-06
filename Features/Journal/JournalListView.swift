//
//  JournalListView.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import SwiftUI
import SwiftData

/// Main journal list showing entries grouped by day.
struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.timestamp, order: .reverse) private var allEntries: [JournalEntry]
    @State private var viewModel = JournalListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if allEntries.isEmpty {
                    EmptyStateView(
                        iconName: "book.fill",
                        title: "No Journal Entries",
                        message: "Capture moments from your trips — photos, thoughts, and memories.",
                        actionTitle: "New Entry"
                    ) {
                        viewModel.showingCreateEntry = true
                    }
                } else {
                    journalList
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        MemoryMapView()
                    } label: {
                        Image(systemName: "map.fill")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingCreateEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateEntry) {
                CreateJournalEntryView()
            }
            .navigationDestination(for: JournalDestination.self) { destination in
                switch destination {
                case .entryDetail(let entry):
                    JournalEntryDetailView(entry: entry)
                case .list, .createEntry:
                    EmptyView()
                }
            }
        }
    }

    private var journalList: some View {
        List {
            let grouped = viewModel.groupedEntries(allEntries)
            ForEach(grouped, id: \.date) { group in
                Section {
                    ForEach(group.entries) { entry in
                        NavigationLink(value: JournalDestination.entryDetail(entry)) {
                            journalRow(entry)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            viewModel.deleteEntry(group.entries[index], context: modelContext)
                        }
                    }
                } header: {
                    Text(Formatters.journalDate.string(from: group.date))
                        .font(.rtCaptionBold)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func journalRow(_ entry: JournalEntry) -> some View {
        HStack(spacing: Spacing.xs) {
            if let mood = entry.mood {
                Text(mood.emoji)
                    .font(.title2)
            } else {
                Image(systemName: "text.alignleft")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.rtBody)
                    .lineLimit(1)
                Text(entry.content)
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Photo thumbnail
            if let firstPhoto = entry.photoDataItems.first,
               let uiImage = ImageCache.shared.image(from: firstPhoto) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))

                if entry.photoDataItems.count > 1 {
                    Text("+\(entry.photoDataItems.count - 1)")
                        .font(.rtCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.xxxs)
    }
}

#Preview {
    let container = try! PersistenceService.previewContainer()
    MockDataSeeder.seed(context: container.mainContext)
    return JournalListView()
        .modelContainer(container)
}
