//
//  TribeGroup.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import SwiftData

/// A group of travelers who share trips together.
@Model
final class TribeGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var groupDescription: String
    var iconName: String
    var createdAt: Date
    var memberIDs: [UUID]
    var activeTripID: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        groupDescription: String = "",
        iconName: String = "person.3.fill",
        memberIDs: [UUID] = [],
        activeTripID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.groupDescription = groupDescription
        self.iconName = iconName
        self.createdAt = .now
        self.memberIDs = memberIDs
        self.activeTripID = activeTripID
    }
}
