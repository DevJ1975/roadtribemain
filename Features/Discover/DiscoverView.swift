//
//  DiscoverView.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import SwiftUI
import MapKit

/// Discover screen for finding nearby points of interest.
struct DiscoverView: View {
    @Environment(LocationService.self) private var locationService
    @State private var viewModel: DiscoverViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filters
                categoryPills

                // Results
                if let viewModel {
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Searching...")
                        Spacer()
                    } else if viewModel.searchResults.isEmpty {
                        Spacer()
                        EmptyStateView(
                            iconName: "magnifyingglass",
                            title: "Discover Places",
                            message: "Search for nearby restaurants, gas stations, hotels, and more."
                        )
                        Spacer()
                    } else {
                        resultsList(viewModel.searchResults)
                    }
                } else {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        DiscoverRoadsView()
                    } label: {
                        Label("Best Roads", systemImage: "road.lanes")
                    }
                }
            }
            .searchable(text: searchTextBinding, prompt: "Search places nearby")
            .onSubmit(of: .search) {
                Task { await viewModel?.search() }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = DiscoverViewModel(locationService: locationService)
                }
            }
        }
    }

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel?.searchText ?? "" },
            set: { viewModel?.searchText = $0 }
        )
    }

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xxs) {
                ForEach(DiscoverCategory.allCases) { category in
                    Button {
                        viewModel?.selectedCategory = category
                        Task { await viewModel?.search() }
                    } label: {
                        Label(category.displayName, systemImage: category.iconName)
                            .font(.rtCaptionBold)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, Spacing.xxs)
                            .background(
                                viewModel?.selectedCategory == category
                                    ? Color.rtDiscoverColor
                                    : Color.rtSurfaceFallback,
                                in: Capsule()
                            )
                            .foregroundStyle(
                                viewModel?.selectedCategory == category ? .white : .primary
                            )
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
        }
    }

    private func resultsList(_ items: [MKMapItem]) -> some View {
        List(items, id: \.self) { item in
            HStack(spacing: Spacing.xs) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.rtDiscoverColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name ?? "Unknown")
                        .font(.rtBody)
                    if let address = item.placemark.title {
                        Text(address)
                            .font(.rtCaption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button {
                    item.openInMaps()
                } label: {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.rtAccentFallback)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, Spacing.xxxs)
        }
        .listStyle(.plain)
    }
}

#Preview {
    DiscoverView()
        .environment(LocationService())
}
