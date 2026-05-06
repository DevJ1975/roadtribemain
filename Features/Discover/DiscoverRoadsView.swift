//
//  DiscoverRoadsView.swift
//  Road Tribe
//

import SwiftUI
import SwiftData
import MapKit

/// Map-based view showing community road ratings. Riders can browse top-rated roads
/// near them and submit their own ratings.
struct DiscoverRoadsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RoadRating.timestamp, order: .reverse) private var allRatings: [RoadRating]

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showingAddRating = false
    @State private var selectedRating: RoadRating?
    @State private var minRatingFilter: Double = 1.0
    @State private var showFilterSheet = false

    private var filteredRatings: [RoadRating] {
        allRatings.filter { $0.averageRating >= minRatingFilter }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-screen map
            Map(position: $cameraPosition, selection: $selectedRating) {
                ForEach(filteredRatings) { rating in
                    Annotation(rating.routeName, coordinate: rating.coordinate, anchor: .bottom) {
                        RoadRatingPin(rating: rating)
                            .onTapGesture { selectedRating = rating }
                    }
                    .tag(rating)
                }
                UserAnnotation()
            }
            .ignoresSafeArea(edges: .top)

            // Bottom panel — selected road or summary
            VStack(spacing: 0) {
                if let rating = selectedRating {
                    RoadRatingDetailCard(rating: rating) {
                        selectedRating = nil
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    summaryBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: selectedRating?.id)
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, Spacing.sm)
        }
        .navigationTitle("Best Roads")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: minRatingFilter > 1.0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }

                Button {
                    showingAddRating = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddRating) {
            AddRoadRatingView()
        }
        .sheet(isPresented: $showFilterSheet) {
            filterSheet
                .presentationDetents([.height(220)])
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(filteredRatings.count) Rated Roads")
                    .font(.rtCaptionBold)
                Text(minRatingFilter > 1 ? "Filter: \(String(format: "%.0f", minRatingFilter))★+" : "All ratings shown")
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Rate a Road") {
                showingAddRating = true
            }
            .font(.rtCaptionBold)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxxs)
            .background(Color.rtDiscoverColor, in: Capsule())
        }
        .padding(Spacing.xs)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section("Minimum Average Rating") {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        HStack {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(minRatingFilter) ? "star.fill" : "star")
                                    .foregroundStyle(.yellow)
                                    .font(.title2)
                                    .onTapGesture { minRatingFilter = Double(star) }
                            }
                            Spacer()
                            Text(String(format: "%.0f★ and above", minRatingFilter))
                                .font(.rtCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button("Show All Roads") {
                        minRatingFilter = 1.0
                        showFilterSheet = false
                    }
                    .foregroundStyle(Color.rtDiscoverColor)
                }
            }
            .navigationTitle("Filter Roads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showFilterSheet = false }
                }
            }
        }
    }
}

// MARK: - Map Pin

private struct RoadRatingPin: View {
    let rating: RoadRating

    private var pinColor: Color {
        switch rating.averageRating {
        case 4...: return .green
        case 3..<4: return .yellow
        default: return .orange
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: 32, height: 32)
                Text(String(format: "%.1f", rating.averageRating))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            Image(systemName: "triangle.fill")
                .font(.system(size: 6))
                .foregroundStyle(pinColor)
                .rotationEffect(.degrees(180))
                .offset(y: -4)
        }
    }
}

// MARK: - Detail Card

private struct RoadRatingDetailCard: View {
    let rating: RoadRating
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rating.routeName)
                        .font(.rtTitle)
                        .lineLimit(1)
                    Text(Formatters.relative.localizedString(for: rating.timestamp, relativeTo: .now))
                        .font(.rtCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            // Rating breakdown
            HStack(spacing: Spacing.sm) {
                RatingChip(label: "Twists", value: rating.twistRating, icon: "road.lanes.curved.right")
                RatingChip(label: "Scenery", value: rating.sceneryRating, icon: "mountain.2")
                RatingChip(label: "Surface", value: rating.qualityRating, icon: "checkmark.seal")
            }

            if !rating.notes.isEmpty {
                Text(rating.notes)
                    .font(.rtCallout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(Spacing.sm)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

private struct RatingChip: View {
    let label: String
    let value: Int
    let icon: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.rtDiscoverColor)
            HStack(spacing: 1) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= value ? "star.fill" : "star")
                        .font(.system(size: 8))
                        .foregroundStyle(star <= value ? Color.yellow : Color.secondary)
                }
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxs)
        .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

// MARK: - Add Rating Sheet

struct AddRoadRatingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var routeName = ""
    @State private var twistRating = 3
    @State private var sceneryRating = 3
    @State private var qualityRating = 3
    @State private var notes = ""

    // Use current location as placement (fallback to SF HQ for demo)
    private let placeholderLat = 37.7749
    private let placeholderLon = -122.4194

    var body: some View {
        NavigationStack {
            Form {
                Section("Road Name") {
                    TextField("e.g. Highway 1 Coastal Run", text: $routeName)
                }

                Section("Ratings") {
                    StarRatingRow(label: "Twists & Curves", icon: "road.lanes.curved.right", rating: $twistRating)
                    StarRatingRow(label: "Scenery", icon: "mountain.2", rating: $sceneryRating)
                    StarRatingRow(label: "Surface Quality", icon: "checkmark.seal", rating: $qualityRating)
                }

                Section("Notes (optional)") {
                    TextField("What made it special?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Rate a Road")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(routeName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let rating = RoadRating(
            latitude: placeholderLat,
            longitude: placeholderLon,
            routeName: routeName.trimmingCharacters(in: .whitespaces),
            twistRating: twistRating,
            sceneryRating: sceneryRating,
            qualityRating: qualityRating,
            notes: notes.trimmingCharacters(in: .whitespaces),
            authorID: authService.currentProfileID ?? MockDataSeeder.kevinID
        )
        modelContext.insert(rating)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - Star Rating Row

private struct StarRatingRow: View {
    let label: String
    let icon: String
    @Binding var rating: Int

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.rtBody)
            Spacer()
            HStack(spacing: Spacing.xxxs) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(star <= rating ? Color.yellow : Color.secondary)
                        .onTapGesture { rating = star }
                }
            }
        }
    }
}
