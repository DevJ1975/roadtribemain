//
//  CommunityHubView.swift
//  Road Tribe
//
//  Community tab — segmented switch between Tribes, Events, and the People
//  directory. Wraps the existing `TribeListView` for the tribes segment.
//

import SwiftUI
import SwiftData

/// Destinations within the Community tab.
enum CommunityDestination: Hashable {
    case publicProfile(UserProfile)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .publicProfile(let profile):
            hasher.combine("profile")
            hasher.combine(profile.id)
        }
    }

    static func == (lhs: CommunityDestination, rhs: CommunityDestination) -> Bool {
        switch (lhs, rhs) {
        case (.publicProfile(let a), .publicProfile(let b)): return a.id == b.id
        }
    }
}

struct CommunityHubView: View {
    enum Segment: String, CaseIterable, Identifiable {
        case tribes = "Tribes"
        case events = "Events"
        case people = "People"
        var id: String { rawValue }
    }

    @Environment(SocialService.self) private var social
    @Query(sort: \UserProfile.displayName) private var profiles: [UserProfile]
    @Query(sort: \RideEvent.startDate) private var events: [RideEvent]
    @Query private var follows: [Follow]

    @State private var segment: Segment = .tribes

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $segment) {
                    ForEach(Segment.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)

                switch segment {
                case .tribes: TribeListView()
                case .events: eventsList
                case .people: peopleList
                }
            }
            .navigationTitle("Community")
            .navigationDestination(for: CommunityDestination.self) { dest in
                switch dest {
                case .publicProfile(let profile):
                    PublicProfileView(profile: profile)
                }
            }
        }
    }

    // MARK: - Events

    private var eventsList: some View {
        Group {
            if events.isEmpty {
                ContentUnavailableView(
                    "No Events",
                    systemImage: "calendar",
                    description: Text("Upcoming community rides will show up here.")
                )
            } else {
                List(events) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title).font(.rtHeadline)
                        Text(Formatters.mediumDate.string(from: event.startDate))
                            .font(.rtCaption)
                            .foregroundStyle(.secondary)
                        Label(event.difficulty.displayName, systemImage: event.difficulty.iconName)
                            .font(.rtCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - People

    private var peopleList: some View {
        Group {
            if profiles.isEmpty {
                ContentUnavailableView(
                    "No Riders",
                    systemImage: "person.3",
                    description: Text("People you can follow will appear here.")
                )
            } else {
                List(profiles) { profile in
                    NavigationLink(value: CommunityDestination.publicProfile(profile)) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName).font(.rtCaptionBold)
                                Text("\(social.followerCount(for: profile.id, follows: follows)) followers")
                                    .font(.rtCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - PublicProfileView

struct PublicProfileView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(SocialService.self) private var social
    @Query private var follows: [Follow]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                Text(profile.displayName).font(.rtTitle)
                if !profile.bio.isEmpty {
                    Text(profile.bio)
                        .font(.rtBody)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                }

                HStack(spacing: DesignSystem.Spacing.lg) {
                    stat("Followers", "\(social.followerCount(for: profile.id, follows: follows))")
                    stat("Following", "\(social.followingCount(for: profile.id, follows: follows))")
                    stat("Rank", profile.currentRank.displayName)
                }

                Button {
                    social.toggleFollow(targetID: profile.id, follows: follows, context: modelContext)
                } label: {
                    let following = social.isFollowing(targetID: profile.id, follows: follows)
                    Label(following ? "Following" : "Follow",
                          systemImage: following ? "checkmark" : "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            .padding(.vertical, DesignSystem.Spacing.lg)
        }
        .navigationTitle(profile.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.rtHeadline)
            Text(label).font(.rtCaption).foregroundStyle(.secondary)
        }
    }
}
