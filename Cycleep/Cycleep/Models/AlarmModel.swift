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

/// A day of the week. Raw values match `Calendar`'s weekday numbering
/// (1 = Sunday … 7 = Saturday).
enum Weekday: Int, Codable, CaseIterable, Identifiable, Comparable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Monday–Friday.
    static let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    /// Saturday & Sunday.
    static let weekends: Set<Weekday> = [.saturday, .sunday]
    /// All seven days.
    static let everyday: Set<Weekday> = Set(allCases)

    /// Abbreviated name, e.g. "Mon".
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    /// Single-letter name for compact day pickers, e.g. "M".
    var narrowName: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
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
    /// Number of sleep cycles this alarm is based on, if any.
    var cycles: Int?
    /// Days the alarm repeats on. Empty means it fires once (next occurrence).
    var repeatDays: Set<Weekday>
    /// Identifier shared by alarms created together (e.g. a bedtime + wake-up
    /// pair). `nil` for standalone alarms. Used to group them in a folder.
    var groupID: UUID?
    /// Display name of the group/folder this alarm belongs to, if grouped.
    var groupName: String

    init(id: UUID = UUID(),
         time: Date,
         isEnabled: Bool = true,
         label: String = "",
         kind: AlarmKind = .wake,
         soundName: String = AlarmSound.default.rawValue,
         snoozeMinutes: Int = 9,
         cycles: Int? = nil,
         repeatDays: Set<Weekday> = [],
         groupID: UUID? = nil,
         groupName: String = "") {
        self.id = id
        self.time = time
        self.isEnabled = isEnabled
        self.label = label
        self.kind = kind
        self.soundName = soundName
        self.snoozeMinutes = snoozeMinutes
        self.cycles = cycles
        self.repeatDays = repeatDays
        self.groupID = groupID
        self.groupName = groupName
    }

    // Custom decoding so alarms persisted before newer fields existed still load.
    private enum CodingKeys: String, CodingKey {
        case id, time, isEnabled, label, kind, soundName, snoozeMinutes, cycles, repeatDays, groupID, groupName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        time = try c.decode(Date.self, forKey: .time)
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        label = try c.decodeIfPresent(String.self, forKey: .label) ?? ""
        kind = try c.decodeIfPresent(AlarmKind.self, forKey: .kind) ?? .wake
        soundName = try c.decodeIfPresent(String.self, forKey: .soundName) ?? AlarmSound.default.rawValue
        snoozeMinutes = try c.decodeIfPresent(Int.self, forKey: .snoozeMinutes) ?? 9
        cycles = try c.decodeIfPresent(Int.self, forKey: .cycles)
        repeatDays = try c.decodeIfPresent(Set<Weekday>.self, forKey: .repeatDays) ?? []
        groupID = try c.decodeIfPresent(UUID.self, forKey: .groupID)
        groupName = try c.decodeIfPresent(String.self, forKey: .groupName) ?? ""
    }

    /// Whether this alarm belongs to a folder/group.
    var isGrouped: Bool { groupID != nil }

    /// The selected sound, falling back to the default if unknown.
    var sound: AlarmSound {
        AlarmSound(rawValue: soundName) ?? .default
    }

    /// Whether this alarm repeats on a schedule.
    var isRepeating: Bool { !repeatDays.isEmpty }

    /// Human-readable repeat description, e.g. "Weekdays" or "Mon, Wed, Fri".
    var repeatSummary: String {
        if repeatDays.isEmpty { return "Never" }
        if repeatDays == Weekday.everyday { return "Every day" }
        if repeatDays == Weekday.weekdays { return "Weekdays" }
        if repeatDays == Weekday.weekends { return "Weekends" }
        return repeatDays.sorted().map(\.shortName).joined(separator: ", ")
    }

    /// The next future date this alarm will fire, resolved from its hour/minute
    /// and (for repeating alarms) its chosen weekdays.
    var nextFireDate: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: time)

        if repeatDays.isEmpty {
            return calendar.nextDate(after: Date(),
                                     matching: components,
                                     matchingPolicy: .nextTime) ?? time
        }

        let candidates = repeatDays.compactMap { day -> Date? in
            components.weekday = day.rawValue
            return calendar.nextDate(after: Date(),
                                     matching: components,
                                     matchingPolicy: .nextTime)
        }
        return candidates.min() ?? time
    }
}
