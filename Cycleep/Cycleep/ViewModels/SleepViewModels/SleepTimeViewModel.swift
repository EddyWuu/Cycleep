//
//  SleepTimeViewModel.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation
import Combine

@MainActor
final class SleepTimeViewModel: ObservableObject {
    @Published var sleepTime: Date = SleepTimeViewModel.defaultSleepTime()

    /// Wake-up times for full cycles after the chosen bedtime.
    var wakeOptions: [SleepCycleOption] {
        SleepCycleModel.wakeOptions(sleepTime: sleepTime)
    }

    private static func defaultSleepTime() -> Date {
        var components = DateComponents()
        components.hour = 23
        components.minute = 0
        return Calendar.current.nextDate(after: Date(),
                                         matching: components,
                                         matchingPolicy: .nextTime) ?? Date()
    }
}
