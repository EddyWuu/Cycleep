//
//  AlarmConfigViewModel.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation
import Combine

/// Whether the config sheet is creating new alarm(s) or editing an existing one.
enum AlarmConfigMode {
    case create(AlarmDraft)
    case edit(AlarmModel)
}

/// Quick repeat presets offered in the config sheet.
enum RepeatPreset: String, CaseIterable, Identifiable {
    case never = "Never"
    case everyday = "Every Day"
    case weekdays = "Weekdays"
    case weekends = "Weekends"

    var id: String { rawValue }
}

@MainActor
final class AlarmConfigViewModel: ObservableObject {
    let mode: AlarmConfigMode

    @Published var selectedSound: AlarmSound
    @Published var snoozeMinutes: Int
    @Published var repeatDays: Set<Weekday>
    @Published var name: String

    /// Selectable snooze durations in minutes (0 = off).
    let snoozeOptions = [0, 5, 9, 10, 15, 20]

    init(mode: AlarmConfigMode) {
        self.mode = mode
        switch mode {
        case let .create(draft):
            self.selectedSound = .default
            self.snoozeMinutes = 9
            self.repeatDays = []
            // Pre-fill the name from a manual draft's label, if any.
            if case let .manual(_, label) = draft {
                self.name = label
            } else {
                self.name = ""
            }
        case let .edit(alarm):
            self.selectedSound = alarm.sound
            self.snoozeMinutes = alarm.snoozeMinutes
            self.repeatDays = alarm.repeatDays
            self.name = alarm.label
        }
    }

    var navigationTitle: String {
        switch mode {
        case .create: return "Set Alarm"
        case .edit: return "Edit Alarm"
        }
    }

    /// Whether the name field names a folder (pair) rather than a single alarm.
    var isNamingFolder: Bool {
        if case let .create(draft) = mode, case .sleepWakePair = draft { return true }
        return false
    }

    /// Section title for the name field.
    var nameSectionTitle: String { isNamingFolder ? "Folder Name" : "Name" }

    /// Placeholder text for the name field.
    var namePlaceholder: String { isNamingFolder ? "Sleep Schedule" : "Alarm name" }

    /// Applies the chosen settings by creating or updating alarm(s).
    func apply(using alarmsViewModel: AlarmsViewModel) {
        switch mode {
        case let .create(draft):
            alarmsViewModel.create(from: draft,
                                   name: name,
                                   sound: selectedSound,
                                   snoozeMinutes: snoozeMinutes,
                                   repeatDays: repeatDays)
        case let .edit(alarm):
            var updated = alarm
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { updated.label = trimmed }
            updated.soundName = selectedSound.rawValue
            updated.snoozeMinutes = snoozeMinutes
            updated.repeatDays = repeatDays
            alarmsViewModel.update(updated)
        }
    }

    /// Toggles a single day in the repeat selection.
    func toggleDay(_ day: Weekday) {
        if repeatDays.contains(day) {
            repeatDays.remove(day)
        } else {
            repeatDays.insert(day)
        }
    }

    /// Applies a preset repeat selection.
    func setRepeatPreset(_ preset: RepeatPreset) {
        switch preset {
        case .never: repeatDays = []
        case .everyday: repeatDays = Weekday.everyday
        case .weekdays: repeatDays = Weekday.weekdays
        case .weekends: repeatDays = Weekday.weekends
        }
    }

    /// Currently matching preset, if the selection equals one.
    var activePreset: RepeatPreset? {
        if repeatDays.isEmpty { return .never }
        if repeatDays == Weekday.everyday { return .everyday }
        if repeatDays == Weekday.weekdays { return .weekdays }
        if repeatDays == Weekday.weekends { return .weekends }
        return nil
    }

    /// Human-readable repeat summary, e.g. "Weekdays".
    var repeatSummary: String {
        if repeatDays.isEmpty { return "Never" }
        if repeatDays == Weekday.everyday { return "Every day" }
        if repeatDays == Weekday.weekdays { return "Weekdays" }
        if repeatDays == Weekday.weekends { return "Weekends" }
        return repeatDays.sorted().map(\.shortName).joined(separator: ", ")
    }

    /// Human-readable description of which alarm(s) this affects.
    var summary: String {
        switch mode {
        case let .create(draft):
            switch draft {
            case let .wake(time, cycles):
                return "Sets a wake-up alarm for \(Self.timeText(time)) (\(Self.cycleText(cycles)))."
            case let .sleepWakePair(sleepTime, wakeTime, cycles):
                return "Sets a bedtime alarm for \(Self.timeText(sleepTime)) and a wake-up alarm for \(Self.timeText(wakeTime)) (\(Self.cycleText(cycles)))."
            case let .manual(time, label):
                let name = label.isEmpty ? "an alarm" : "\"\(label)\""
                return "Sets \(name) for \(Self.timeText(time))."
            }
        case let .edit(alarm):
            let kind = alarm.kind == .sleep ? "bedtime" : "wake-up"
            return "Editing the \(kind) alarm for \(Self.timeText(alarm.time))."
        }
    }

    func snoozeLabel(_ minutes: Int) -> String {
        minutes == 0 ? "Off" : "\(minutes) min"
    }

    // MARK: - Helpers

    private static func cycleText(_ cycles: Int) -> String {
        "\(cycles) cycle\(cycles > 1 ? "s" : "")"
    }

    private static func timeText(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
