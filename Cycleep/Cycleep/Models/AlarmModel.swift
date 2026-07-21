//
//  AlarmModel.swift
//  Cycleep
//
//  Model representing a single scheduled alarm.
//

import Foundation

/// Whether an alarm marks a bedtime or a wake-up time.
enum AlarmKind: String, Codable {
    case wake
    case sleep
}

/// A single alarm. Sound/snooze customization will be added later.
struct AlarmModel: Identifiable, Codable, Equatable {
    let id: UUID
    var time: Date
    var isEnabled: Bool
    var label: String
    var kind: AlarmKind
    var soundName: String
    /// Number of sleep cycles this alarm is based on, if any.
    var cycles: Int?

    init(id: UUID = UUID(),
         time: Date,
         isEnabled: Bool = true,
         label: String = "",
         kind: AlarmKind = .wake,
         soundName: String = "Radar",
         cycles: Int? = nil) {
        self.id = id
        self.time = time
        self.isEnabled = isEnabled
        self.label = label
        self.kind = kind
        self.soundName = soundName
        self.cycles = cycles
    }
}
