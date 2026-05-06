//
//  MemoryMapView.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import SwiftUI
import SwiftData
import MapKit

/// A map showing all journal entries with GPS coordinates as pins.
/// Tap a pin to see the journal entry with its photos and story.
struct MemoryMapView: View {
    @Query(sort: \JournalEntry.timestamp, order: .reverse) private var entries: [JournalEntry]
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedEntry: JournalEntry?

    private var mappableEntries: [JournalEntry] {
        entries.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(mappableEntries) { entry in
                    Annotation(
                        entry.title,
                        coordinate: CLLocationCoordinate2D(
                            latitude: entry.latitude!,
                            longitude: entry.longitude!
                        )
                    ) {
                        MemoryPinView(entry: entry) {
                            selectedEntry = entry
                        }
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }

            // Entry count badge
            if !mappableEntries.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("\(mappableEntries.count) memories")
                        }
                        .font(.rtCaptionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(.black.opacity(0.7), in: Capsule())
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
        .navigationTitle("Memory Map")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEntry) { entry in
            MemoryDetailSheet(entry: entry)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Memory Pin View

private struct MemoryPinView: View {
    let entry: JournalEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    // Photo thumbnail or mood emoji
                    if let firstPhoto = entry.photoDataItems.first,
                       let uiImage = UIImage(data: firstPhoto) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else if let mood = entry.mood {
                        Text(mood.emoji)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color.rtSurfaceFallback, in: Circle())
                    } else {
                        Image(systemName: "book.fill")
                            .font(.body)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.rtPrimaryFallback, in: Circle())
                    }
                }
                .overlay(Circle().strokeBorder(Color.rtPrimaryFallback, lineWidth: 2))
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)

                // Pin stem
                Image(systemName: "triangle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.rtPrimaryFallback)
                    .rotationEffect(.degrees(180))
                    .offset(y: -3)
            }
        }
    }
}

// MARK: - Memory Detail Sheet

private struct MemoryDetailSheet: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Photos
                    if !entry.photoDataItems.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(entry.photoDataItems.indices, id: \.self) { index in
                                    if let uiImage = UIImage(data: entry.photoDataItems[index]) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.sm)
                        }
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Mood + title
                        HStack(spacing: Spacing.xs) {
                            if let mood = entry.mood {
                                Text(mood.emoji)
                                    .font(.title)
                            }
                            Text(entry.title)
                                .font(.rtHeadline)
                        }

                        // Location + time
                        HStack(spacing: Spacing.xxs) {
                            if let location = entry.locationName {
                                Label(location, systemImage: "mappin")
                                    .font(.rtCaption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text(Formatters.relative.localizedString(for: entry.timestamp, relativeTo: .now))
                                .font(.rtCaption)
                                .foregroundStyle(.secondary)
                        }

                        // Content
                        if !entry.content.isEmpty {
                            Text(entry.content)
                                .font(.rtBody)
                                .padding(.top, Spacing.xxxs)
                        }

                        // Weather
                        if let weather = entry.weatherDescription {
                            Label(weather, systemImage: "cloud.sun")
                                .font(.rtCaption)
                                .foregroundStyle(.secondary)
                                .padding(.top, Spacing.xxxs)
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
                }
                .padding(.vertical, Spacing.sm)
            }
            .navigationTitle("Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let container = try! PersistenceService.previewContainer()
    MockDataSeeder.seed(context: container.mainContext)
    return NavigationStack {
        MemoryMapView()
    }
    .modelContainer(container)
}
