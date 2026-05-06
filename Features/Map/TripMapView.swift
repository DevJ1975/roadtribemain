//
//  TripMapView.swift
//  Road Tribe
//
//  Map tab — live rider radar plus reported road hazards. Long-press to drop
//  a hazard, tap a beacon to see details.
//

import SwiftUI
import MapKit
import SwiftData

struct TripMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    @Environment(RiderRadarService.self) private var radar

    @Query private var hazards: [RoadHazard]
    @Query private var memorials: [FallenRiderMemorial]

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var followsUser = true
    @State private var showingMemorialPicker = false
    @State private var pendingMemorialCoord: CLLocationCoordinate2D?

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, interactionModes: .all) {
                // User location
                UserAnnotation()

                // Rider radar — nearby live riders
                ForEach(radar.visiblePresences) { presence in
                    Annotation(presence.displayName, coordinate: presence.coordinate) {
                        riderPin(for: presence)
                    }
                }

                // Distress beacons
                ForEach(radar.nearbyBeacons) { beacon in
                    Annotation("Help", coordinate: beacon.coordinate) {
                        Image(systemName: "wave.3.right")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Circle().fill(DesignSystem.Colors.danger))
                    }
                }

                // Road hazards
                ForEach(hazards.filter { !$0.isExpired }) { hazard in
                    Annotation(hazard.hazardType.displayName, coordinate: hazard.coordinate) {
                        Image(systemName: hazard.hazardType.iconName)
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Circle().fill(hazard.hazardType.markerColor))
                    }
                }

                // Memorials
                ForEach(memorials) { memorial in
                    Annotation(memorial.riderName, coordinate: CLLocationCoordinate2D(
                        latitude: memorial.latitude, longitude: memorial.longitude
                    )) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .including([.gasStation])))
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            recenter()
                        } label: {
                            Label("Recenter", systemImage: "location.fill")
                        }
                        Button {
                            radar.isEnabled.toggle()
                        } label: {
                            Label(radar.isEnabled ? "Hide Riders" : "Show Riders",
                                  systemImage: radar.isEnabled ? "eye.slash" : "eye")
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .task {
                locationService.startTracking()
                if let coord = locationService.currentLocation {
                    radar.loadNearbyPresences(from: coord, in: modelContext)
                    cameraPosition = .region(coord.region(span: 0.15))
                } else {
                    radar.loadNearbyPresences(from: .sanFrancisco, in: modelContext)
                }
            }
            .sheet(isPresented: $showingMemorialPicker) {
                if let coord = pendingMemorialCoord {
                    AddMemorialView(coordinate: coord, authorID: MockDataSeeder.kevinID)
                }
            }
        }
    }

    private func riderPin(for presence: RiderPresence) -> some View {
        VStack(spacing: 1) {
            ZStack {
                Circle()
                    .fill(radar.isVeteran(presence.riderID)
                          ? DesignSystem.Colors.brand
                          : DesignSystem.Colors.accent)
                    .frame(width: 26, height: 26)
                Image(systemName: "motorcycle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(presence.heading))
            }
            Text(presence.displayName)
                .font(.system(size: 9, weight: .semibold))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.thinMaterial, in: Capsule())
        }
    }

    private func recenter() {
        if let coord = locationService.currentLocation {
            withAnimation { cameraPosition = .region(coord.region(span: 0.15)) }
        }
    }
}
