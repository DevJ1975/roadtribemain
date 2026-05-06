//
//  TribeDetailView.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import SwiftUI
import SwiftData
import UIKit

/// Detail view for a tribe group showing members and linked trips.
struct TribeDetailView: View {
    @Bindable var group: TribeGroup
    @Environment(SocialService.self) private var socialService
    @Environment(\.modelContext) private var modelContext
    @Query private var allProfiles: [UserProfile]
    @Query private var allTrips: [Trip]

    @State private var showingTripPicker = false
    @State private var selectedMemberForInvite: UUID?

    private var profileLookup: [UUID: UserProfile] {
        socialService.profileLookup(from: allProfiles)
    }

    /// Resolve a member UUID to a profile.
    private func memberProfile(for id: UUID) -> UserProfile? {
        profileLookup[id]
    }

    private func memberName(for id: UUID) -> String {
        profileLookup[id]?.displayName ?? "Unknown Rider"
    }

    var body: some View {
        List {
            // Group info section
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Image(systemName: group.iconName)
                            .font(.largeTitle)
                            .foregroundStyle(Color.rtPrimaryFallback)
                        VStack(alignment: .leading) {
                            Text(group.name)
                                .font(.rtHeadline)
                            Text("Est. \(Formatters.mediumDate.string(from: group.createdAt))")
                                .font(.rtCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !group.groupDescription.isEmpty {
                        Text(group.groupDescription)
                            .font(.rtBody)
                    }
                }
                .padding(.vertical, Spacing.xxs)
            }

            // Members section
            Section("Members (\(group.memberIDs.count))") {
                if group.memberIDs.isEmpty {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(.secondary)
                        Text("Invite friends to join this tribe")
                            .font(.rtCallout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(group.memberIDs, id: \.self) { memberID in
                        let profile = memberProfile(for: memberID)
                        let name = profile?.displayName ?? "Unknown Rider"
                        HStack(spacing: Spacing.xs) {
                            AvatarView(name: name, imageName: profile?.avatarImageName, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(name)
                                    .font(.rtBody)
                                if memberID == socialService.currentUserID {
                                    Text("Road Captain")
                                        .font(.rtCaption)
                                        .foregroundStyle(Color.rtPrimaryFallback)
                                }
                            }
                        }
                        .contextMenu {
                            if memberID != socialService.currentUserID {
                                Button("Invite to Ride", systemImage: "motorcycle.fill") {
                                    selectedMemberForInvite = memberID
                                    showingTripPicker = true
                                }
                            }
                        }
                    }
                }

                Button("Invite Member", systemImage: "person.badge.plus") { }
                    .disabled(true)
            }

            // Actions section
            Section {
                Button("Start a Trip Together", systemImage: "motorcycle.fill") { }
                    .disabled(true)

                Button("Share Invite Link", systemImage: "link") { }
                    .disabled(true)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingTripPicker) {
            NavigationStack {
                List {
                    let myTrips = allTrips.filter { $0.memberIDs.contains(socialService.currentUserID) && $0.status != .completed && $0.status != .cancelled }
                    if myTrips.isEmpty {
                        Text("No active trips to invite to")
                            .font(.rtCallout)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(myTrips) { trip in
                            Button {
                                if let riderID = selectedMemberForInvite {
                                    let invite = TripInvite(
                                        tripID: trip.id,
                                        senderID: socialService.currentUserID,
                                        recipientID: riderID
                                    )
                                    modelContext.insert(invite)

                                    let activity = ActivityItem(
                                        actorID: socialService.currentUserID,
                                        targetUserID: riderID,
                                        activityType: .tripInvite,
                                        referenceID: trip.id,
                                        message: "You've been invited to join \(trip.title)!"
                                    )
                                    modelContext.insert(activity)
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                }
                                showingTripPicker = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(trip.title)
                                            .font(.rtBody)
                                            .foregroundStyle(.primary)
                                        Text(trip.status.displayName)
                                            .font(.rtCaption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .navigationTitle("Select Trip")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingTripPicker = false }
                    }
                }
            }
        }
    }
}
