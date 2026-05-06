//
//  TribeListView.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import SwiftUI
import SwiftData

/// Main screen for managing travel groups (tribes).
struct TribeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TribeGroup.createdAt, order: .reverse) private var groups: [TribeGroup]
    @State private var viewModel = TribeListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    EmptyStateView(
                        iconName: "person.3.fill",
                        title: "No Tribes Yet",
                        message: "Create a tribe to plan and share trips with friends and family.",
                        actionTitle: "Create Tribe"
                    ) {
                        viewModel.showingCreateGroup = true
                    }
                } else {
                    tribeList
                }
            }
            .navigationTitle("Tribe")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingCreateGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateGroup) {
                createGroupSheet
            }
            .navigationDestination(for: TribeGroup.self) { group in
                TribeDetailView(group: group)
            }
        }
    }

    private var tribeList: some View {
        List {
            ForEach(groups) { group in
                NavigationLink(value: group) {
                    tribeRow(group)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    viewModel.deleteGroup(groups[index], context: modelContext)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func tribeRow(_ group: TribeGroup) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: group.iconName)
                .font(.title2)
                .foregroundStyle(Color.rtPrimaryFallback)
                .frame(width: 44, height: 44)
                .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: CornerRadius.small))

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.rtTitle)
                Text("\(group.memberIDs.count) members")
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xxxs)
    }

    private var createGroupSheet: some View {
        NavigationStack {
            Form {
                Section("Group Info") {
                    TextField("Tribe Name", text: $viewModel.newGroupName)
                    TextField("Description (optional)", text: $viewModel.newGroupDescription, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("New Tribe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showingCreateGroup = false
                        viewModel.resetForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createGroup(context: modelContext)
                        viewModel.showingCreateGroup = false
                    }
                    .disabled(!viewModel.isValidGroup)
                }
            }
        }
    }
}

#Preview {
    let container = try! PersistenceService.previewContainer()
    MockDataSeeder.seed(context: container.mainContext)
    return TribeListView()
        .modelContainer(container)
}
