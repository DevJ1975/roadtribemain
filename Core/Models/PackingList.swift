//
//  PackingList.swift
//  Road Tribe
//

import Foundation
import SwiftData

/// A gear packing checklist scoped to a trip or saved as a reusable template.
@Model
final class PackingList {
    @Attribute(.unique) var id: UUID
    /// Nil when this is a standalone template (not attached to a trip).
    var tripID: UUID?
    var title: String
    var isTemplate: Bool
    /// JSON-encoded [PackingItem]
    var itemsData: Data
    var createdAt: Date

    var items: [PackingItem] {
        get { (try? JSONDecoder().decode([PackingItem].self, from: itemsData)) ?? [] }
        set { itemsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var checkedCount: Int { items.filter(\.isChecked).count }
    var totalCount: Int { items.count }
    var isComplete: Bool { totalCount > 0 && checkedCount == totalCount }

    init(
        id: UUID = UUID(),
        tripID: UUID? = nil,
        title: String,
        isTemplate: Bool = false,
        items: [PackingItem] = PackingList.defaultItems
    ) {
        self.id = id
        self.tripID = tripID
        self.title = title
        self.isTemplate = isTemplate
        self.itemsData = (try? JSONEncoder().encode(items)) ?? Data()
        self.createdAt = .now
    }

    // MARK: - Default Template

    static let defaultItems: [PackingItem] = [
        // Safety
        PackingItem(name: "Helmet", category: .safety),
        PackingItem(name: "Riding jacket", category: .safety),
        PackingItem(name: "Gloves", category: .safety),
        PackingItem(name: "Riding boots", category: .safety),
        PackingItem(name: "Riding pants / armor", category: .safety),
        PackingItem(name: "High-vis vest", category: .safety),
        PackingItem(name: "First aid kit", category: .safety),
        // Tools & Repair
        PackingItem(name: "Tire plug kit + CO2", category: .tools),
        PackingItem(name: "Multi-tool / hex keys", category: .tools),
        PackingItem(name: "Zip ties & duct tape", category: .tools),
        PackingItem(name: "Tow strap", category: .tools),
        PackingItem(name: "Spare fuses", category: .tools),
        // Navigation
        PackingItem(name: "Phone mount + cable", category: .navigation),
        PackingItem(name: "Power bank", category: .navigation),
        PackingItem(name: "Ear plugs (for comms)", category: .navigation),
        // Clothing
        PackingItem(name: "Rain suit", category: .clothing),
        PackingItem(name: "Base layers (cold)", category: .clothing),
        PackingItem(name: "Change of clothes", category: .clothing),
        // Documents
        PackingItem(name: "License & registration", category: .documents),
        PackingItem(name: "Insurance card", category: .documents),
        PackingItem(name: "Emergency contact info", category: .documents),
        PackingItem(name: "Cash", category: .documents),
        // Comfort
        PackingItem(name: "Water & snacks", category: .comfort),
        PackingItem(name: "Sunscreen", category: .comfort),
        PackingItem(name: "Anti-fog spray", category: .comfort),
    ]
}

// MARK: - PackingItem

struct PackingItem: Codable, Identifiable {
    var id: UUID
    var name: String
    var category: PackingCategory
    var isChecked: Bool

    init(id: UUID = UUID(), name: String, category: PackingCategory, isChecked: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.isChecked = isChecked
    }
}

// MARK: - PackingCategory

enum PackingCategory: String, Codable, CaseIterable, Identifiable {
    case safety
    case tools
    case navigation
    case clothing
    case documents
    case comfort

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .safety: return "Safety Gear"
        case .tools: return "Tools & Repair"
        case .navigation: return "Navigation & Power"
        case .clothing: return "Clothing"
        case .documents: return "Documents & Money"
        case .comfort: return "Comfort & Misc"
        }
    }

    var iconName: String {
        switch self {
        case .safety: return "shield.lefthalf.filled"
        case .tools: return "wrench.and.screwdriver"
        case .navigation: return "location.fill"
        case .clothing: return "tshirt"
        case .documents: return "doc.text"
        case .comfort: return "sun.max"
        }
    }
}
