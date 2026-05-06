//
//  DiscoverViewModel.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import MapKit

/// ViewModel for the Discover screen — finding POIs and curated suggestions.
@Observable
final class DiscoverViewModel {

    var searchText = ""
    var selectedCategory: DiscoverCategory = .all
    var searchResults: [MKMapItem] = []
    var isLoading = false

    private let mapService = MapService()
    private let locationService: LocationService

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    func search() async {
        let query = selectedCategory == .all ? searchText : selectedCategory.searchQuery
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        let center = locationService.currentLocation ?? .sanFrancisco
        let region = center.region(span: 0.3)

        do {
            searchResults = try await mapService.searchNearby(
                query: query,
                region: region,
                maxResults: 30
            )
        } catch {
            searchResults = []
        }
    }
}

/// Categories for discovering points of interest.
enum DiscoverCategory: String, CaseIterable, Identifiable {
    case all
    case food
    case gas
    case lodging
    case scenic
    case attractions

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .food: return "Food"
        case .gas: return "Gas"
        case .lodging: return "Lodging"
        case .scenic: return "Scenic"
        case .attractions: return "Attractions"
        }
    }

    var iconName: String {
        switch self {
        case .all: return "magnifyingglass"
        case .food: return "fork.knife"
        case .gas: return "fuelpump.fill"
        case .lodging: return "bed.double.fill"
        case .scenic: return "binoculars.fill"
        case .attractions: return "star.fill"
        }
    }

    var searchQuery: String {
        switch self {
        case .all: return ""
        case .food: return "restaurant"
        case .gas: return "gas station"
        case .lodging: return "hotel"
        case .scenic: return "scenic viewpoint"
        case .attractions: return "tourist attraction"
        }
    }
}
