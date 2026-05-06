//
//  TripCardView.swift
//  Road Tribe
//
//  Card row used by the Trips list inside RidesHubView.
//

import SwiftUI

struct TripCardView: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(trip.status == .active
                          ? DesignSystem.Colors.brand.opacity(0.2)
                          : Color.rtSurfaceFallback)
                    .frame(width: 56, height: 56)
                Image(systemName: trip.status.iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(trip.status == .active
                                     ? DesignSystem.Colors.brand
                                     : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(trip.title)
                    .font(.rtHeadline)
                    .lineLimit(1)
                Text(Formatters.dateRange(from: trip.startDate, to: trip.endDate))
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Label("\(trip.waypoints.count)", systemImage: "mappin")
                    Text("·")
                    Label(trip.formattedDistance, systemImage: "road.lanes")
                    Text("·")
                    Text(trip.status.displayName)
                }
                .font(.rtCaption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(Color.rtSurfaceFallback, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}
