//
//  RideStatsCard.swift
//  Road Tribe
//

import SwiftUI

/// Post-ride summary card: distance, duration, max & avg speed, elevation gain.
struct RideStatsCard: View {
    let route: RecordedRoute

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "motorcycle.fill")
                    .foregroundStyle(DesignSystem.Colors.brand)
                Text(route.title.isEmpty ? "Ride Summary" : route.title)
                    .font(.rtHeadline)
                Spacer()
            }

            statGrid
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Grid

    private var statGrid: some View {
        let columns = [
            GridItem(.flexible(), alignment: .leading),
            GridItem(.flexible(), alignment: .leading),
        ]
        return LazyVGrid(columns: columns, spacing: Spacing.sm) {
            stat("Distance", value: distanceText, system: "ruler")
            stat("Duration", value: durationText, system: "clock")
            stat("Max Speed", value: speedText(route.maxSpeedMPH), system: "speedometer")
            stat("Avg Speed", value: speedText(route.avgSpeedMPH), system: "gauge.with.needle")
            stat("Elevation Gain", value: elevationText, system: "arrow.up.right")
            stat("Points", value: "\(route.points.count)", system: "point.bottomleft.forward.to.point.topright.scurvepath")
        }
    }

    private func stat(_ label: String, value: String, system: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: system)
                .frame(width: 18)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.rtBody)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Formatters

    private var distanceText: String {
        String(format: "%.1f mi", route.distanceMiles)
    }

    private var durationText: String {
        route.formattedDuration
    }

    private func speedText(_ mph: Double) -> String {
        mph > 0 ? String(format: "%.0f mph", mph) : "—"
    }

    private var elevationText: String {
        let feet = route.elevationGainFeet
        guard feet > 0 else { return "—" }
        return "\(Int(feet).formatted()) ft"
    }
}
