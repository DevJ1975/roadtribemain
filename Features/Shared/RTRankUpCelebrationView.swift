//
//  RTRankUpCelebrationView.swift
//  Road Tribe
//
//  Full-screen rank-up moment. `ContentView` presents this when
//  `RTXPService.showRankUp` flips to true.
//

import SwiftUI

struct RTRankUpCelebrationView: View {
    let fromRank: RankTier
    let toRank: RankTier
    let totalXP: Int

    @Environment(RTXPService.self) private var xpService
    @Environment(\.dismiss) private var dismiss

    @State private var badgeScale: CGFloat = 0.4
    @State private var badgeOpacity: Double = 0
    @State private var labelOpacity: Double = 0

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.lg) {
                Spacer()

                Text("RANK UP")
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.7))
                    .opacity(labelOpacity)

                badge
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)

                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(toRank.displayName)
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("Promoted from \(fromRank.displayName)")
                        .font(.rtBody)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("\(totalXP.formatted()) XP")
                        .font(.rtCaptionBold)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, DesignSystem.Spacing.xs)
                }
                .opacity(labelOpacity)

                Spacer()

                Button {
                    close()
                } label: {
                    Text("Keep Riding")
                        .font(.rtHeadline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(.white, in: Capsule())
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.lg)
                .opacity(labelOpacity)
            }
        }
        .task {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) {
                badgeScale = 1
                badgeOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.2)) {
                labelOpacity = 1
            }
            DesignSystem.Haptics.success()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [toRank.color, toRank.color.opacity(0.4), .black],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.18))
                .frame(width: 220, height: 220)
            Circle()
                .stroke(.white.opacity(0.4), lineWidth: 2)
                .frame(width: 220, height: 220)
            Image(systemName: toRank.iconName)
                .font(.system(size: 96, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
        }
    }

    private func close() {
        xpService.showRankUp = false
        dismiss()
    }
}
