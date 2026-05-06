//
//  RTCallForHelpView.swift
//  Road Tribe
//
//  Full-screen distress beacon view. Activates a `DistressBeacon` via
//  `RTBeaconService` and shows status (active / acknowledged / resolved)
//  with cancel + resolve actions.
//

import SwiftUI
import SwiftData
import CoreLocation

struct RTCallForHelpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(RTBeaconService.self) private var beaconService
    @Environment(LocationService.self) private var locationService
    @Environment(AuthService.self) private var authService

    @State private var bikeType: BikeType = .other
    @State private var message: String = ""
    @State private var showCancelConfirm = false
    @State private var showResolveConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if let beacon = beaconService.activeBeacon {
                    activeStateView(beacon: beacon)
                } else {
                    activationForm
                }
            }
            .navigationTitle(beaconService.isBeaconActive ? "Help is Coming" : "Send Distress Beacon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(beaconService.isBeaconActive ? "Hide" : "Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Activation form

    private var activationForm: some View {
        Form {
            Section {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignSystem.Colors.danger)
                    Text("Broadcast Your Location")
                        .font(.rtHeadline)
                    Text("Nearby riders on the radar will see your beacon and can come help.")
                        .font(.rtCaption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.sm)
            }
            .listRowBackground(Color.clear)

            Section("What kind of bike?") {
                Picker("Bike", selection: $bikeType) {
                    ForEach(BikeType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.iconName)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Message (optional)") {
                TextField("e.g. Flat tire — need a plug kit", text: $message, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                Button {
                    activate()
                } label: {
                    Label("Send Beacon", systemImage: "wave.3.right")
                        .frame(maxWidth: .infinity)
                        .font(.rtHeadline)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.danger)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }

    // MARK: - Active state

    private func activeStateView(beacon: DistressBeacon) -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.danger.opacity(0.15))
                        .frame(width: 140, height: 140)
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 64))
                        .foregroundStyle(DesignSystem.Colors.danger)
                        .symbolEffect(.pulse)
                }

                Text(beacon.status.label)
                    .font(.rtTitle)
                Text(formattedElapsed)
                    .font(.rtBody)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.top, DesignSystem.Spacing.lg)

            if !beacon.message.isEmpty {
                Text("\u{201C}\(beacon.message)\u{201D}")
                    .font(.rtBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Label(
                    String(format: "%.4f, %.4f", beacon.latitude, beacon.longitude),
                    systemImage: "mappin.and.ellipse"
                )
                .font(.rtCaption)
                Label("\(beacon.acknowledgedByIDs.count) rider\(beacon.acknowledgedByIDs.count == 1 ? "" : "s") notified",
                      systemImage: "person.2.fill")
                    .font(.rtCaption)
            }
            .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: DesignSystem.Spacing.sm) {
                Button {
                    showResolveConfirm = true
                } label: {
                    Label("I'm OK Now", systemImage: "checkmark.seal.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.success)

                Button(role: .destructive) {
                    showCancelConfirm = true
                } label: {
                    Label("Cancel Beacon", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .confirmationDialog("Cancel beacon?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("Cancel Beacon", role: .destructive) {
                beaconService.cancelBeacon(in: modelContext)
                dismiss()
            }
            Button("Keep Active", role: .cancel) {}
        } message: {
            Text("Other riders will be notified that you cancelled.")
        }
        .confirmationDialog("Mark as resolved?", isPresented: $showResolveConfirm, titleVisibility: .visible) {
            Button("Yes, I'm OK") {
                beaconService.resolveBeacon(in: modelContext)
                dismiss()
            }
            Button("Not Yet", role: .cancel) {}
        } message: {
            Text("This will close the beacon and thank anyone who responded.")
        }
    }

    private var formattedElapsed: String {
        let total = max(0, beaconService.beaconElapsedSeconds)
        let m = total / 60
        let s = total % 60
        return String(format: "Active for %d:%02d", m, s)
    }

    // MARK: - Actions

    private func activate() {
        let coord = locationService.currentLocation ?? .sanFrancisco
        let riderID = authService.currentProfileID ?? MockDataSeeder.kevinID
        beaconService.activateBeacon(
            riderID: riderID,
            bikeType: bikeType,
            message: message.trimmingCharacters(in: .whitespaces),
            latitude: coord.latitude,
            longitude: coord.longitude,
            in: modelContext
        )
        DesignSystem.Haptics.warning()
    }
}
