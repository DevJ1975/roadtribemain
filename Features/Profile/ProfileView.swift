//
//  ProfileView.swift
//  Road Tribe
//
//  Profile tab — shows the current user's rank, XP, garage, and a settings list.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AuthService.self) private var auth
    @Environment(RTXPService.self) private var xp

    @Query private var profiles: [UserProfile]
    @Query private var motorcycles: [Motorcycle]

    private var currentProfile: UserProfile? {
        if let id = auth.currentProfileID {
            return profiles.first(where: { $0.id == id })
        }
        return profiles.first(where: { $0.id == MockDataSeeder.kevinID }) ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            List {
                if let profile = currentProfile {
                    Section { header(profile: profile) }
                        .listRowBackground(Color.clear)
                    Section("Rank") { rankProgress(profile: profile) }
                }

                Section("Garage") {
                    if motorcycles.isEmpty {
                        Text("No motorcycles yet").foregroundStyle(.secondary)
                    } else {
                        ForEach(motorcycles) { bike in
                            HStack {
                                Image(systemName: "motorcycle.fill")
                                VStack(alignment: .leading) {
                                    Text(bike.name).font(.rtCaptionBold)
                                    Text("\(bike.year) \(bike.make) \(bike.model)")
                                        .font(.rtCaption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(bike.currentMileage.formatted()) mi")
                                    .font(.rtCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Account") {
                    if let email = auth.storedEmail {
                        LabeledContent("Email", value: email)
                    }
                    Button("Sign Out", role: .destructive) {
                        auth.signOut()
                    }
                }

                Section {
                    Text("Road Tribe v1.0")
                        .frame(maxWidth: .infinity)
                        .font(.rtCaption)
                        .foregroundStyle(.tertiary)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
        }
    }

    private func header(profile: UserProfile) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            Text(profile.displayName).font(.rtTitle)
            if !profile.bio.isEmpty {
                Text(profile.bio)
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    private func rankProgress(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: profile.currentRank.iconName)
                    .foregroundStyle(profile.currentRank.color)
                Text(profile.currentRank.displayName).font(.rtHeadline)
                Spacer()
                Text("\(profile.totalXP.formatted()) XP")
                    .font(.rtCaptionBold)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: xp.progressToNextRank)
                .tint(profile.currentRank.color)
            if let next = profile.currentRank.next {
                Text("\(xp.xpToNextRank) XP to \(next.displayName)")
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Max rank reached")
                    .font(.rtCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            xp.sync(with: profile)
        }
    }
}
