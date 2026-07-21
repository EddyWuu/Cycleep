//
//  SleepCycle.swift
//  Cycleep
//
//  Sleep-cycle math and the option model used by the Sleep sub-tabs.
//

import Foundation

/// A single selectable option in a Sleep list (one row).
struct SleepCycleOption: Identifiable {
    let id = UUID()
    /// Number of full sleep cycles this option represents.
    let cycles: Int
    /// The resulting time (a wake-up time or a bedtime depending on context).
    let time: Date

    var durationMinutes: Int { cycles * SleepCycle.cycleMinutes }

    var durationText: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        return minutes == 0 ? "\(hours) hr" : "\(hours) hr \(minutes) min"
    }
}

/// Central sleep-cycle constants and calculations.
enum SleepCycle {
    /// Length of one sleep cycle in minutes (1.5 hours).
    static let cycleMinutes = 90
    /// How many options to show in the lists.
    static let maxCycles = 15

    /// Wake-up times if you fall asleep at `sleepTime`.
    static func wakeOptions(sleepTime: Date, count: Int = maxCycles) -> [SleepCycleOption] {
        (1...count).compactMap { cycle in
            guard let time = Calendar.current.date(byAdding: .minute,
                                                   value: cycle * cycleMinutes,
                                                   to: sleepTime) else { return nil }
            return SleepCycleOption(cycles: cycle, time: time)
        }
    }

    /// Bedtimes required to wake up at `wakeTime`.
    static func sleepOptions(wakeTime: Date, count: Int = maxCycles) -> [SleepCycleOption] {
        (1...count).compactMap { cycle in
            guard let time = Calendar.current.date(byAdding: .minute,
                                                   value: -cycle * cycleMinutes,
                                                   to: wakeTime) else { return nil }
            return SleepCycleOption(cycles: cycle, time: time)
        }
    }
}
