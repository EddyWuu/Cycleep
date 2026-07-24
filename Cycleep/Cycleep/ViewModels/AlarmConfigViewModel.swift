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

@MainActor
final class AlarmConfigViewModel: ObservableObject {
    let mode: AlarmConfigMode

    @Published var selectedSound: AlarmSound
    @Published var snoozeMinutes: Int
    @Published var rampUpEnabled: Bool

    /// Selectable snooze durations in minutes (0 = off).
    let snoozeOptions = [0, 5, 9, 10, 15, 20]

    init(mode: AlarmConfigMode) {
        self.mode = mode
        switch mode {
        case .create:
            self.selectedSound = .default
            self.snoozeMinutes = 9
            self.rampUpEnabled = true
        case let .edit(alarm):
            self.selectedSound = alarm.sound
            self.snoozeMinutes = alarm.snoozeMinutes
            self.rampUpEnabled = alarm.rampUpVolume
        }
    }

    var navigationTitle: String {
        switch mode {
        case .create: return "Set Alarm"
        case .edit: return "Edit Alarm"
        }
    }

    /// Applies the chosen settings by creating or updating alarm(s).
    func apply(using alarmsViewModel: AlarmsViewModel) {
        switch mode {
        case let .create(draft):
            alarmsViewModel.create(from: draft,
                                   sound: selectedSound,
                                   snoozeMinutes: snoozeMinutes,
                                   rampUp: rampUpEnabled)
        case let .edit(alarm):
            var updated = alarm
            updated.soundName = selectedSound.rawValue
            updated.snoozeMinutes = snoozeMinutes
            updated.rampUpVolume = rampUpEnabled
            alarmsViewModel.update(updated)
        }
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
