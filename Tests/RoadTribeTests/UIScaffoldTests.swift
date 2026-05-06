//
//  UIScaffoldTests.swift
//  Road Tribe
//
//  Sanity tests for the small amount of pure logic inside the new tab
//  scaffolding (mostly Hashable conformance for navigation destinations).
//

import XCTest
import SwiftData
@testable import RoadTribe

@MainActor
final class CommunityDestinationTests: XCTestCase {

    func test_publicProfile_equalityUsesProfileID() {
        let a = UserProfile(displayName: "A")
        let b = UserProfile(displayName: "B")
        XCTAssertEqual(CommunityDestination.publicProfile(a),
                       CommunityDestination.publicProfile(a))
        XCTAssertNotEqual(CommunityDestination.publicProfile(a),
                          CommunityDestination.publicProfile(b))
    }

    func test_publicProfile_hashesByID() {
        let a = UserProfile(displayName: "A")
        var hasher1 = Hasher()
        var hasher2 = Hasher()
        CommunityDestination.publicProfile(a).hash(into: &hasher1)
        CommunityDestination.publicProfile(a).hash(into: &hasher2)
        XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
    }
}

@MainActor
final class MaintenanceDestinationTests: XCTestCase {

    func test_due_equalityUsesBikeID() {
        let a = Motorcycle(name: "A")
        let b = Motorcycle(name: "B")
        XCTAssertEqual(MaintenanceDestination.due(a), MaintenanceDestination.due(a))
        XCTAssertNotEqual(MaintenanceDestination.due(a), MaintenanceDestination.due(b))
    }
}
