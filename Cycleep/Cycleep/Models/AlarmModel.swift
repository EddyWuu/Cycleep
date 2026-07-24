//
//  AlarmModel.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation

/// Whether an alarm marks a bedtime or a wake-up time.
enum AlarmKind: String, Codable {
    case wake
    case sleep
}

/// A single scheduled alarm.
struct AlarmModel: Identifiable, Codable, Equatable {
    let id: UUID
    var time: Date
    var isEnabled: Bool
    var label: String
    var kind: AlarmKind
    /// Stored raw value of the selected `AlarmSound`.
    var soundName: String
    /// Snooze length in minutes. `0` disables snooze.
    var snoozeMinutes: Int
    /// Whether playback should fade the volume in gradually.
    var rampUpVolume: Bool
    /// Number of sleep cycles this alarm is based on, if any.
    var cycles: Int?

    init(id: UUID = UUID(),
         time: Date,
         isEnabled: Bool = true,
         label: String = "",
         kind: AlarmKind = .wake,
         soundName: String = AlarmSound.default.rawValue,
         snoozeMinutes: Int = 9,
         rampUpVolume: Bool = true,
         cycles: Int? = nil) {
        self.id = id
        self.time = time
        self.isEnabled = isEnabled
        self.label = label
        self.kind = kind
        self.soundName = soundName
        self.snoozeMinutes = snoozeMinutes
        self.rampUpVolume = rampUpVolume
        self.cycles = cycles
    }

    /// The selected sound, falling back to the default if unknown.
    var sound: AlarmSound {
        AlarmSound(rawValue: soundName) ?? .default
    }

    /// The next future date this alarm will fire, resolved from its hour/minute.
    /// Mirrors how AlarmKit schedules a non-repeating relative alarm.
    var nextFireDate: Date {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        return Calendar.current.nextDate(after: Date(),
                                         matching: components,
                                         matchingPolicy: .nextTime) ?? time
    }
}
