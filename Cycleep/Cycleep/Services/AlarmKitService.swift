//
//  AlarmKitService.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import AlarmKit
import ActivityKit
import SwiftUI

final class AlarmKitService {
    private var manager: AlarmManager { AlarmManager.shared }

    /// Requests permission to schedule alarms if not already granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let state = try await manager.requestAuthorization()
            return state == .authorized
        } catch {
            print("AlarmKitService: authorization error \(error)")
            return false
        }
    }

    /// Schedules a one-time alarm mirroring the given app alarm.
    func schedule(_ alarm: AlarmModel) async {
        guard await requestAuthorization() else {
            print("AlarmKitService: not authorized; skipping schedule for \(alarm.id)")
            return
        }

        let components = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
        let time = Alarm.Schedule.Relative.Time(hour: components.hour ?? 0,
                                                minute: components.minute ?? 0)

        // Repeating alarms use a weekly recurrence; otherwise fire once.
        let schedule: Alarm.Schedule
        if alarm.repeatDays.isEmpty {
            schedule = .relative(.init(time: time, repeats: .never))
        } else {
            let days = alarm.repeatDays.sorted().map(Self.localeWeekday)
            schedule = .relative(.init(time: time, repeats: .weekly(days)))
        }

        let title = LocalizedStringResource(stringLiteral: alarm.label.isEmpty ? "Cycleep" : alarm.label)

        // A snooze button drives AlarmKit's post-alert countdown.
        let hasSnooze = alarm.snoozeMinutes > 0
        let snoozeButton = hasSnooze
            ? AlarmButton(text: "Snooze", textColor: .white, systemImageName: "zzz")
            : nil
        // The system provides the stop button automatically.
        let alert = AlarmPresentation.Alert(title: title,
                                            secondaryButton: snoozeButton,
                                            secondaryButtonBehavior: hasSnooze ? .countdown : nil)
        let presentation = AlarmPresentation(alert: alert)
        let attributes = AlarmAttributes(presentation: presentation,
                                         metadata: AlarmKitMetadataModel(),
                                         tintColor: .indigo)

        // postAlert is the snooze length; preAlert stays nil for a scheduled alarm.
        let countdown = hasSnooze
            ? Alarm.CountdownDuration(preAlert: nil, postAlert: TimeInterval(alarm.snoozeMinutes * 60))
            : nil

        let configuration = AlarmManager.AlarmConfiguration(
            countdownDuration: countdown,
            schedule: schedule,
            attributes: attributes,
            stopIntent: nil,
            secondaryIntent: nil,
            sound: .default)

        do {
            _ = try await manager.schedule(id: alarm.id, configuration: configuration)
        } catch {
            print("AlarmKitService: failed to schedule \(alarm.id): \(error)")
        }
    }

    /// Maps our `Weekday` to AlarmKit's `Locale.Weekday`.
    private static func localeWeekday(_ day: Weekday) -> Locale.Weekday {
        switch day {
        case .sunday: return .sunday
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .saturday: return .saturday
        }
    }

    /// Cancels the backup alarm for the given id.
    func cancel(id: UUID) {
        do {
            try manager.cancel(id: id)
        } catch {
            print("AlarmKitService: failed to cancel \(id): \(error)")
        }
    }
}
