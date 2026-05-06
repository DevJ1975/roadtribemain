//
//  TripDetailView.swift
//  Road Tribe
//
//  Trip detail — header, waypoint map, waypoint list, journal entries, and
//  share/start actions.
//

import SwiftUI
import SwiftData
import MapKit

struct TripDetailView: View {
    @Bindable var trip: Trip
    @Environment(\.modelContext) private var modelContext
    @Environment(RideTrackingService.self) private var rideTracking

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showStartConfirm = false

    private var sortedWaypoints: [Waypoint] {
        trip.waypoints.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                header

                if !sortedWaypoints.isEmpty {
                    waypointMap
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                }

                statsRow
                waypointsSection
                journalSection
                actionsSection
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                GPXShareLink(trip: trip)
                    .disabled(sortedWaypoints.isEmpty)
            }
        }
        .onAppear { fitCamera() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Label(trip.status.displayName, systemImage: trip.status.iconName)
                .font(.rtCaptionBold)
                .padding(.horizontal, DesignSystem.Spacing.xs)
                .padding(.vertical, 4)
                .background(Color.rtSurfaceFallback, in: Capsule())

            Text(Formatters.dateRange(from: trip.startDate, to: trip.endDate))
                .font(.rtCaption)
                .foregroundStyle(.secondary)

            if !trip.tripDescription.isEmpty {
                Text(trip.tripDescription)
                    .font(.rtBody)
            }
        }
    }

    // MARK: - Map

    private var waypointMap: some View {
        Map(position: $cameraPosition) {
            ForEach(sortedWaypoints) { wp in
                Annotation(wp.name, coordinate: wp.coordinate) {
                    Image(systemName: wp.waypointType.iconName)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(DesignSystem.Colors.brand))
                }
            }
            if sortedWaypoints.count >= 2 {
                MapPolyline(coordinates: sortedWaypoints.map(\.coordinate))
                    .stroke(DesignSystem.Colors.brand, lineWidth: 3)
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell("Distance", trip.formattedDistance, system: "road.lanes")
            Divider().frame(height: 36)
            statCell("Stops", "\(sortedWaypoints.count)", system: "mappin")
            Divider().frame(height: 36)
            statCell("Riders", "\(trip.memberIDs.count)", system: "person.2.fill")
        }
        .padding(DesignSystem.Spacing.sm)
        .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    private func statCell(_ label: String, _ value: String, system: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: system)
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.brand)
            Text(value).font(.rtCaptionBold)
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Waypoints

    private var waypointsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Waypoints").font(.rtHeadline)
            if sortedWaypoints.isEmpty {
                Text("No waypoints yet.")
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedWaypoints) { wp in
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: wp.waypointType.iconName)
                            .frame(width: 24)
                            .foregroundStyle(DesignSystem.Colors.brand)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(wp.name).font(.rtCaptionBold)
                            Text(wp.waypointType.displayName)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Journal entries

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text("Journal").font(.rtHeadline)
                Spacer()
                Text("\(trip.journalEntries.count) entries")
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
            }
            if trip.journalEntries.isEmpty {
                Text("No journal entries yet.")
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(trip.journalEntries.sorted { $0.timestamp > $1.timestamp }) { entry in
                    NavigationLink(value: entry) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title).font(.rtCaptionBold)
                            Text(Formatters.relative.localizedString(for: entry.timestamp, relativeTo: .now))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            if rideTracking.isRiding && rideTracking.activeTrip?.id == trip.id {
                Button(role: .destructive) {
                    _ = rideTracking.endRide()
                } label: {
                    Label("End Ride", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.danger)
            } else if !rideTracking.isRiding && trip.status != .completed {
                Button {
                    showStartConfirm = true
                } label: {
                    Label("Start Ride", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.brand)
            }
        }
        .confirmationDialog("Start this ride?", isPresented: $showStartConfirm, titleVisibility: .visible) {
            Button("Start") {
                trip.status = .active
                try? modelContext.save()
                rideTracking.startRide(trip: trip)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Camera

    private func fitCamera() {
        let coords = sortedWaypoints.map(\.coordinate)
        guard !coords.isEmpty else { return }
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.05, (lats.max()! - lats.min()!) * 1.4),
            longitudeDelta: max(0.05, (lons.max()! - lons.min()!) * 1.4)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}
