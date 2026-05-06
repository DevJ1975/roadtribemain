//
//  RecordedRouteView.swift
//  Road Tribe
//

import SwiftUI
import MapKit
import Charts
import SwiftData

/// Displays a recorded GPS route with map, speed heatmap, elevation profile, and stats.
struct RecordedRouteView: View {
    let route: RecordedRoute
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showingElevation = false

    private var points: [RoutePoint] { route.points }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Map with route trace
                routeMap
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                    .padding(.horizontal, Spacing.sm)

                // Stats card (distance / duration / max & avg speed / elevation gain)
                RideStatsCard(route: route)
                    .padding(.horizontal, Spacing.sm)

                // Speed chart
                if points.count >= 2 {
                    speedChart
                        .padding(.horizontal, Spacing.sm)

                    // Elevation profile
                    elevationChart
                        .padding(.horizontal, Spacing.sm)
                }
            }
            .padding(.bottom, Spacing.xl)
        }
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                GPXShareLink(route: route)
                    .disabled(points.isEmpty)
            }
        }
    }

    // MARK: - Route Map

    private var routeMap: some View {
        Map(position: $cameraPosition) {
            if points.count >= 2 {
                MapPolyline(coordinates: points.map(\.coordinate))
                    .stroke(.orange, lineWidth: 4)
            }
            if let first = points.first {
                Annotation("Start", coordinate: first.coordinate) {
                    Circle().fill(.green).frame(width: 14)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
            if let last = points.last {
                Annotation("End", coordinate: last.coordinate) {
                    Circle().fill(.red).frame(width: 14)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
        }
        .onAppear { fitCamera() }
    }

    private func fitCamera() {
        let coords = points.map(\.coordinate)
        guard !coords.isEmpty else { return }
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (lats.max()! - lats.min()!) * 1.4),
            longitudeDelta: max(0.01, (lons.max()! - lons.min()!) * 1.4)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    // MARK: - Speed Chart

    private var speedChart: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Label("Speed Over Time", systemImage: "speedometer")
                .font(.rtHeadline)
            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    AreaMark(
                        x: .value("Time", index),
                        y: .value("MPH", point.speedMPH)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.rtPrimaryFallback.opacity(0.7), Color.rtPrimaryFallback.opacity(0.1)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Time", index),
                        y: .value("MPH", point.speedMPH)
                    )
                    .foregroundStyle(Color.rtPrimaryFallback)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .frame(height: 120)
            .chartXAxis(.hidden)
            .chartYAxisLabel("mph")
        }
        .padding(Spacing.sm)
        .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

    // MARK: - Elevation Chart

    @ViewBuilder
    private var elevationChart: some View {
        let altitudesFeet = points.map { $0.altitude * 3.280_839_895 } // meters → feet
        if (altitudesFeet.max() ?? 0) > 0 {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack {
                    Label("Elevation Profile", systemImage: "mountain.2.fill")
                        .font(.rtHeadline)
                    Spacer()
                    Text("+\(Int(route.elevationGainFeet)) ft gain")
                        .font(.rtCaptionBold)
                        .foregroundStyle(Color.rtPrimaryFallback)
                }
                Chart {
                    ForEach(Array(altitudesFeet.enumerated()), id: \.offset) { index, alt in
                        AreaMark(
                            x: .value("Point", index),
                            y: .value("Feet", alt)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.1)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 100)
                .chartXAxis(.hidden)
                .chartYAxisLabel("ft")
            }
            .padding(Spacing.sm)
            .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
    }
}

// MARK: - Route History List

/// Lists all saved recorded routes for the user.
struct RecordedRouteListView: View {
    @Query(sort: \RecordedRoute.startDate, order: .reverse) private var routes: [RecordedRoute]

    init() {}

    var body: some View {
        Group {
            if routes.isEmpty {
                ContentUnavailableView(
                    "No Rides Recorded",
                    systemImage: "location.slash.fill",
                    description: Text("Start a trip to record your GPS route automatically.")
                )
            } else {
                List {
                    ForEach(routes) { route in
                        NavigationLink(value: route) {
                            routeRow(route)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Ride History")
        .navigationDestination(for: RecordedRoute.self) { route in
            RecordedRouteView(route: route)
        }
    }

    private func routeRow(_ route: RecordedRoute) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "location.fill.viewfinder")
                .font(.title2)
                .foregroundStyle(Color.rtPrimaryFallback)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(route.title)
                    .font(.rtTitle)
                    .lineLimit(1)
                HStack(spacing: Spacing.xxs) {
                    Text(route.formattedDistance)
                    Text("·")
                    Text(route.formattedDuration)
                    Text("·")
                    Text(Formatters.mediumDate.string(from: route.startDate))
                }
                .font(.rtCaption)
                .foregroundStyle(.secondary)
            }
        }
    }
}
