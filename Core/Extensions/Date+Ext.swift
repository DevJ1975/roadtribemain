//
//  Date+Ext.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation

extension Date {

    /// Number of days between this date and another.
    func days(until other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: self, to: other).day ?? 0
    }

    /// Whether this date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Whether this date is in the past.
    var isPast: Bool {
        self < .now
    }

    /// Whether this date is in the future.
    var isFuture: Bool {
        self > .now
    }

    /// Start of the day for this date.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// The date one week from now.
    static var oneWeekFromNow: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: 1, to: .now) ?? .now
    }
}
