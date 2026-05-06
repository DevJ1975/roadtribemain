// ContentView.swift
// Road Tribe
//
// Root layout: all tab views kept alive in a ZStack (preserves per-tab
// NavigationStack state). RTTabBar replaces the system tab chrome.
// SOS pill floats above the bar; if beacon is active it's always visible.

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var router = AppRouter()
    @Environment(RideTrackingService.self) private var rideTracking
    @Environment(RTBeaconService.self) private var beaconService
    @Environment(RTXPService.self) private var xpService
    @State private var showSOSConfirm = false
    @State private var showBeaconView = false

    /// Estimated bottom region height: tab bar + safe area inset buffer
    private static let tabRegionHeight: CGFloat = DesignSystem.Spacing.tabBarHeight + 34

    var body: some View {
        ZStack(alignment: .bottom) {
            // All tabs stay in the hierarchy — opacity + hitTesting drives visibility.
            // This preserves each tab's NavigationStack state across switches.
            tabStack

            // Non-tab overlays (voice, ride banner)
            VoiceChannelOverlay()
            RideBannerOverlay()

            // Bottom chrome: SOS pill (conditional) + custom tab bar
            VStack(spacing: 0) {
                if showSOS {
                    RTSOSPill {
                        if beaconService.isBeaconActive {
                            showBeaconView = true
                        } else {
                            showSOSConfirm = true
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.sm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                RTTabBar(selectedTab: $router.selectedTab)
            }
            .animation(.easeInOut(duration: 0.2), value: showSOS)
        }
        .ignoresSafeArea(edges: .bottom)
        .environment(router)
        .tint(DesignSystem.Colors.brand)
        .confirmationDialog(
            "Emergency SOS",
            isPresented: $showSOSConfirm,
            titleVisibility: .visible
        ) {
            Button("Call 911", role: .destructive) {
                guard let url = URL(string: "tel://911") else { return }
                UIApplication.shared.open(url)
            }
            Button("Send Distress Beacon") {
                showBeaconView = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Do you need emergency assistance?")
        }
        .fullScreenCover(isPresented: $showBeaconView) {
            RTCallForHelpView()
        }
        .fullScreenCover(isPresented: Bindable(xpService).showRankUp) {
            RTRankUpCelebrationView(
                fromRank: xpService.rankUpFromTier,
                toRank: xpService.rankUpToTier,
                totalXP: xpService.currentXP
            )
            .environment(xpService)
        }
    }

    // MARK: - Tab Stack

    @ViewBuilder
    private var tabStack: some View {
        let bottomInset = ContentView.tabRegionHeight

        SocialFeedView()
            .tabVisible(router.selectedTab == .feed, bottomInset: bottomInset)

        RidesHubView()
            .tabVisible(router.selectedTab == .rides, bottomInset: bottomInset)

        TripMapView()
            .tabVisible(router.selectedTab == .map, bottomInset: bottomInset)

        CommunityHubView()
            .tabVisible(router.selectedTab == .community, bottomInset: bottomInset)

        ProfileView()
            .tabVisible(router.selectedTab == .profile, bottomInset: bottomInset)
    }

    /// SOS pill is visible on Rides/Map tabs, and always when a beacon is active.
    private var showSOS: Bool {
        beaconService.isBeaconActive
            || router.selectedTab == .rides
            || router.selectedTab == .map
    }
}

// MARK: - tabVisible Modifier

private extension View {
    /// Shows/hides a tab while keeping it in the view hierarchy for state preservation.
    func tabVisible(_ visible: Bool, bottomInset: CGFloat) -> some View {
        self
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: bottomInset)
            }
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(visible)
    }
}

// MARK: - Preview

#Preview {
    let container = try! PersistenceService.previewContainer()
    MockDataSeeder.seed(context: container.mainContext)
    return ContentView()
        .environment(LocationService())
        .environment(AuthService())
        .environment(SocialService())
        .environment(VoiceChannelService())
        .environment(RideTrackingService())
        .environment(RTBeaconService())
        .environment(RiderRadarService())
        .modelContainer(container)
        .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    let container = try! PersistenceService.previewContainer()
    MockDataSeeder.seed(context: container.mainContext)
    return ContentView()
        .environment(LocationService())
        .environment(AuthService())
        .environment(SocialService())
        .environment(VoiceChannelService())
        .environment(RideTrackingService())
        .environment(RTBeaconService())
        .environment(RiderRadarService())
        .modelContainer(container)
        .preferredColorScheme(.light)
}
