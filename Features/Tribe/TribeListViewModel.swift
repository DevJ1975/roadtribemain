//
//  TribeListViewModel.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import SwiftData

/// ViewModel for the tribe list screen.
@Observable
final class TribeListViewModel {

    var showingCreateGroup = false
    var newGroupName = ""
    var newGroupDescription = ""

    var isValidGroup: Bool {
        !newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func createGroup(context: ModelContext) {
        let group = TribeGroup(
            name: newGroupName.trimmingCharacters(in: .whitespacesAndNewlines),
            groupDescription: newGroupDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(group)
        resetForm()
    }

    func deleteGroup(_ group: TribeGroup, context: ModelContext) {
        context.delete(group)
    }

    func resetForm() {
        newGroupName = ""
        newGroupDescription = ""
    }
}
