//
//  ManualAlarmViewModel.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation
import Combine

@MainActor
final class ManualAlarmViewModel: ObservableObject {
    @Published var time: Date = ManualAlarmViewModel.defaultTime()
    @Published var label: String = ""

    /// The draft to configure and create from the current selection.
    var draft: AlarmDraft {
        .manual(time: time, label: label.trimmingCharacters(in: .whitespaces))
    }

    private static func defaultTime() -> Date {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.nextDate(after: Date(),
                                         matching: components,
                                         matchingPolicy: .nextTime) ?? Date()
    }
}
