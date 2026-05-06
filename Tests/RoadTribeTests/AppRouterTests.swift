//
//  AppRouterTests.swift
//  Road Tribe
//

import XCTest
import SwiftUI
@testable import RoadTribe

@MainActor
final class AppRouterTests: XCTestCase {

    func test_initialState_selectsFeedTab() {
        let router = AppRouter()
        XCTAssertEqual(router.selectedTab, .feed)
        XCTAssertEqual(router.feedPath.count, 0)
    }

    func test_navigateToTrip_selectsRidesTabAndPushes() {
        let router = AppRouter()
        router.navigateToTrip(Trip(title: "X"))
        XCTAssertEqual(router.selectedTab, .rides)
        XCTAssertEqual(router.ridesPath.count, 1)
    }

    func test_popToRoot_clearsThePath() {
        let router = AppRouter()
        router.navigateToTrip(Trip(title: "X"))
        router.popToRoot(tab: .rides)
        XCTAssertEqual(router.ridesPath.count, 0)
    }

    func test_popToRoot_doesNotAffectOtherTabs() {
        let router = AppRouter()
        router.navigateToTrip(Trip(title: "A"))
        router.feedPath.append("a-detail-id")
        router.popToRoot(tab: .feed)
        XCTAssertEqual(router.feedPath.count, 0)
        XCTAssertEqual(router.ridesPath.count, 1)
    }

    func test_appTab_idMatchesRawValue() {
        for tab in AppTab.allCases {
            XCTAssertEqual(tab.id, tab.rawValue)
            XCTAssertFalse(tab.title.isEmpty)
            XCTAssertFalse(tab.iconName.isEmpty)
        }
    }

    func test_tripDestination_equalityUsesTripID() {
        let trip = Trip(title: "X")
        XCTAssertEqual(TripDestination.detail(trip), TripDestination.detail(trip))
        XCTAssertEqual(TripDestination.createTrip, TripDestination.createTrip)
        XCTAssertNotEqual(TripDestination.detail(trip), TripDestination.createTrip)
    }
}
