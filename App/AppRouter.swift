//
//  AppRouter.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import SwiftUI

/// Centralized navigation state for the app using NavigationPath.
@Observable
final class AppRouter {

    /// The main tab selection.
    var selectedTab: AppTab = .feed

    /// Navigation paths for each tab (enables deep linking per tab).
    var feedPath = NavigationPath()
    var ridesPath = NavigationPath()
    var mapPath = NavigationPath()
    var communityPath = NavigationPath()
    var profilePath = NavigationPath()

    // MARK: - Navigation Actions

    func navigateToTrip(_ trip: Trip) {
        selectedTab = .rides
        ridesPath.append(trip)
    }

    func navigateToProfile(_ profile: UserProfile) {
        selectedTab = .community
        communityPath.append(CommunityDestination.publicProfile(profile))
    }

    func popToRoot(tab: AppTab) {
        switch tab {
        case .feed: feedPath = NavigationPath()
        case .rides: ridesPath = NavigationPath()
        case .map: mapPath = NavigationPath()
        case .community: communityPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        }
    }
}

// MARK: - Tab Definition

/// The main tabs of the app.
enum AppTab: String, CaseIterable, Identifiable {
    case feed
    case rides
    case map
    case community
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feed: return "Feed"
        case .rides: return "Rides"
        case .map: return "Map"
        case .community: return "Community"
        case .profile: return "Profile"
        }
    }

    var iconName: String {
        switch self {
        case .feed: return "text.bubble.fill"
        case .rides: return "motorcycle.fill"
        case .map: return "map.fill"
        case .community: return "person.3.fill"
        case .profile: return "person.crop.circle"
        }
    }
}

// MARK: - Navigation Destinations

/// Destinations within the Trips tab.
enum TripDestination: Hashable {
    case detail(Trip)
    case createTrip

    func hash(into hasher: inout Hasher) {
        switch self {
        case .detail(let trip): hasher.combine("detail"); hasher.combine(trip.id)
        case .createTrip: hasher.combine("create")
        }
    }

    static func == (lhs: TripDestination, rhs: TripDestination) -> Bool {
        switch (lhs, rhs) {
        case (.detail(let a), .detail(let b)): return a.id == b.id
        case (.createTrip, .createTrip): return true
        default: return false
        }
    }
}

/// Destinations within the Journal tab.
enum JournalDestination: Hashable {
    case list(Trip)
    case entryDetail(JournalEntry)
    case createEntry(Trip)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .list(let trip): hasher.combine("list"); hasher.combine(trip.id)
        case .entryDetail(let entry): hasher.combine("detail"); hasher.combine(entry.id)
        case .createEntry(let trip): hasher.combine("create"); hasher.combine(trip.id)
        }
    }

    static func == (lhs: JournalDestination, rhs: JournalDestination) -> Bool {
        switch (lhs, rhs) {
        case (.list(let a), .list(let b)): return a.id == b.id
        case (.entryDetail(let a), .entryDetail(let b)): return a.id == b.id
        case (.createEntry(let a), .createEntry(let b)): return a.id == b.id
        default: return false
        }
    }
}
