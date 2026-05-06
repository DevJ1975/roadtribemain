//
//  FallenRiderMemorial.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// Community-placed memorial pin marking where a rider was lost.
@Model
final class FallenRiderMemorial {
    @Attribute(.unique) var id: UUID
    var latitude: Double
    var longitude: Double
    var riderName: String
    var dateOfPassing: Date
    var tribute: String
    var authorID: UUID
    var photoData: Data?
    var tributeCount: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        riderName: String,
        dateOfPassing: Date,
        tribute: String = "",
        authorID: UUID,
        photoData: Data? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.riderName = riderName
        self.dateOfPassing = dateOfPassing
        self.tribute = tribute
        self.authorID = authorID
        self.photoData = photoData
        self.tributeCount = 0
        self.createdAt = .now
    }
}
