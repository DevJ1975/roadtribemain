//
//  JournalEntryDetailView.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import SwiftUI
import MapKit

/// Detail view for a single journal entry.
struct JournalEntryDetailView: View {
    @Bindable var entry: JournalEntry
    @State private var selectedPhotoIndex: PhotoIndex?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    if let mood = entry.mood {
                        Text(mood.emoji + " " + mood.displayName)
                            .font(.rtCaptionBold)
                            .foregroundStyle(.secondary)
                    }

                    Text(entry.title)
                        .font(.rtDisplay)

                    HStack(spacing: Spacing.xs) {
                        Label(
                            Formatters.journalDate.string(from: entry.timestamp),
                            systemImage: "calendar"
                        )
                        if let locationName = entry.locationName {
                            Label(locationName, systemImage: "mappin")
                        }
                    }
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
                }

                // Photos
                if !entry.photoDataItems.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(entry.photoDataItems.indices, id: \.self) { index in
                                if let uiImage = ImageCache.shared.image(from: entry.photoDataItems[index]) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                                        .onTapGesture {
                                            selectedPhotoIndex = PhotoIndex(value: index)
                                        }
                                }
                            }
                        }
                    }
                }

                // Location map
                if let lat = entry.latitude, let lon = entry.longitude {
                    Map {
                        Marker(entry.locationName ?? "Location", coordinate:
                            CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        )
                    }
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    .allowsHitTesting(false)
                }

                // Content
                Text(entry.content)
                    .font(.rtBody)
                    .lineSpacing(4)

                // Weather
                if let weather = entry.weatherDescription {
                    Label(weather, systemImage: "cloud.sun")
                        .font(.rtCallout)
                        .foregroundStyle(.secondary)
                        .padding(Spacing.xs)
                        .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: CornerRadius.small))
                }
            }
            .padding(Spacing.sm)
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedPhotoIndex) { photoIndex in
            PhotoFullScreenView(
                photos: entry.photoDataItems,
                initialIndex: photoIndex.value
            )
        }
    }
}

// MARK: - Photo Index Wrapper

/// Wrapper to avoid retroactive Identifiable conformance on Int.
struct PhotoIndex: Identifiable {
    let value: Int
    var id: Int { value }
}

// MARK: - Full-Screen Photo Viewer

struct PhotoFullScreenView: View {
    let photos: [Data]
    let initialIndex: Int
    @State private var currentIndex: Int = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    if let uiImage = ImageCache.shared.image(from: photos[index]) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .always : .never))

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white, .white.opacity(0.3))
            }
            .padding()
        }
        .onAppear {
            currentIndex = initialIndex
        }
    }
}
