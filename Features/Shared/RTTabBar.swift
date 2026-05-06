//
//  RTTabBar.swift
//  Road Tribe
//
//  Custom bottom tab bar — replaces the system TabView so we can layer the
//  SOS pill above it without UIKit chrome wrestling.
//

import SwiftUI

struct RTTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .frame(height: DesignSystem.Spacing.tabBarHeight)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 0.5),
            alignment: .top
        )
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = tab == selectedTab
        return Button {
            if isSelected {
                // Tap-the-tab-twice gesture is reserved for popping to root —
                // host view watches `selectedTab` for that. Re-tap is a no-op here.
            } else {
                DesignSystem.Haptics.light()
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected
                             ? DesignSystem.Colors.brand
                             : Color.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
