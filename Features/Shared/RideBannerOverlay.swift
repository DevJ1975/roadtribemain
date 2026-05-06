//
//  RideBannerOverlay.swift
//  Road Tribe
//
//  Top-floating "ride in progress" banner with elapsed time, distance,
//  and quick actions. Appears whenever `RideTrackingService.isRiding`.
//

import SwiftUI

struct RideBannerOverlay: View {
    @Environment(RideTrackingService.self) private var rideTracking
    @Environment(VoiceChannelService.self) private var voice

    @State private var showQuickJournal = false
    @State private var showEndConfirm = false

    var body: some View {
        if rideTracking.isRiding {
            content
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: rideTracking.isRiding)
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            // Push the banner below the voice overlay if both are visible
            Spacer().frame(height: voice.isInChannel ? 56 : 0)

            HStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.brand.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: "motorcycle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.brand)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(rideTracking.activeTrip?.title ?? "Ride in progress")
                        .font(.rtCaptionBold)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(rideTracking.formattedElapsedTime)
                            .monospacedDigit()
                        Text("·")
                        Text(String(format: "%.1f mi", rideTracking.distanceMiles))
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showQuickJournal = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.thinMaterial))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quick journal note")

                Button {
                    showEndConfirm = true
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(DesignSystem.Colors.danger))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("End ride")
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .sheet(isPresented: $showQuickJournal) {
            QuickJournalCaptureView()
        }
        .confirmationDialog(
            "End this ride?", isPresented: $showEndConfirm, titleVisibility: .visible
        ) {
            Button("End Ride", role: .destructive) {
                _ = rideTracking.endRide()
            }
            Button("Keep Riding", role: .cancel) {}
        }
    }
}
