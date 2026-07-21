//
//  SleepNowViewModel.swift
//  Cycleep
//
//  Drives the "Sleep Now" sub-tab: wake-up options if you fall asleep now.
//

import Foundation
import Combine

@MainActor
final class SleepNowViewModel: ObservableObject {
    @Published private(set) var referenceDate: Date = Date()
    @Published private(set) var options: [SleepCycleOption] = []

    /// Recompute options based on the current time.
    func refresh() {
        referenceDate = Date()
        options = SleepCycleModel.wakeOptions(sleepTime: referenceDate)
    }
}
