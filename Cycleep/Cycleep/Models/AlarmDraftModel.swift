//
//  AlarmDraftModel.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation

/// Describes the alarm(s) a "Set" button will create, before the user confirms
/// sound/snooze in the configuration sheet.
///
/// A pending request produced by tapping "Set" on a cycle option. Conforms to
/// `Identifiable` so it can drive a `.sheet(item:)` presentation.
enum AlarmDraft: Identifiable {
    /// A single wake-up alarm (Sleep Now tab).
    case wake(time: Date, cycles: Int)
    /// A paired bedtime + wake-up alarm (Wake Up Time / Sleep Time tabs).
    case sleepWakePair(sleepTime: Date, wakeTime: Date, cycles: Int)
    /// A plain alarm at a user-chosen time (Manual tab), with no cycle math.
    case manual(time: Date, label: String)

    var id: String {
        switch self {
        case let .wake(time, cycles):
            return "wake-\(time.timeIntervalSince1970)-\(cycles)"
        case let .sleepWakePair(sleepTime, wakeTime, cycles):
            return "pair-\(sleepTime.timeIntervalSince1970)-\(wakeTime.timeIntervalSince1970)-\(cycles)"
        case let .manual(time, label):
            return "manual-\(time.timeIntervalSince1970)-\(label)"
        }
    }

    /// Number of sleep cycles this draft is based on, if any.
    var cycles: Int? {
        switch self {
        case let .wake(_, cycles): return cycles
        case let .sleepWakePair(_, _, cycles): return cycles
        case .manual: return nil
        }
    }
}
