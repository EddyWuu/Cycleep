//
//  WakeUpTimeViewModel.swift
//  Cycleep
//
//  Drives the "Wake Up Time" sub-tab: pick a wake time, get bedtime options.
//

import Foundation
import Combine

@MainActor
final class WakeUpTimeViewModel: ObservableObject {
    @Published var wakeTime: Date = WakeUpTimeViewModel.defaultWakeTime()

    /// Bedtimes that land the wake-up on a full cycle boundary.
    var sleepOptions: [SleepCycleOption] {
        SleepCycleModel.sleepOptions(wakeTime: wakeTime)
    }

    private static func defaultWakeTime() -> Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.nextDate(after: Date(),
                                         matching: components,
                                         matchingPolicy: .nextTime) ?? Date()
    }
}
