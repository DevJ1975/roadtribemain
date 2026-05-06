//
//  RTSOSPill.swift
//  Road Tribe
//
//  Floating capsule shown above the tab bar on Rides/Map tabs (and any time
//  a distress beacon is active). Tap → host view either confirms 911 / beacon
//  or opens RTCallForHelpView when a beacon is already running.
//

import SwiftUI

struct RTSOSPill: View {
    /// Whether the pill should display its "active beacon" state.
    var isBeaconActive: Bool = false
    /// Optional elapsed-time string from `RTBeaconService` to display when the beacon is live.
    var elapsedText: String?

    let action: () -> Void

    var body: some View {
        Button(action: tap) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 28, height: 28)
                    Image(systemName: isBeaconActive ? "wave.3.right" : "sos")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, isActive: isBeaconActive)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(isBeaconActive ? "Beacon Active" : "SOS")
                        .font(.rtCaptionBold)
                        .foregroundStyle(.white)
                    if let elapsedText, isBeaconActive {
                        Text(elapsedText)
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.85))
                            .monospacedDigit()
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                Capsule()
                    .fill(DesignSystem.Colors.danger)
            )
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: DesignSystem.Colors.danger.opacity(0.4), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .accessibilityLabel(isBeaconActive ? "Distress beacon active" : "Emergency SOS")
        .accessibilityHint("Opens emergency assistance options")
    }

    private func tap() {
        DesignSystem.Haptics.heavy()
        action()
    }
}
