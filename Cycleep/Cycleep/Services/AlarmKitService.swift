//
//  AlarmKitService.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import AlarmKit
import ActivityKit
import SwiftUI

/// Errors surfaced to the UI when an alarm can't be scheduled.
enum AlarmKitError: LocalizedError {
    case notAuthorized
    case scheduleFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Cycleep isn't allowed to set alarms. Enable it in Settings > Cycleep."
        case let .scheduleFailed(message):
            return "Couldn't schedule the alarm: \(message)"
        }
    }
}

final class AlarmKitService {
    private var manager: AlarmManager { AlarmManager.shared }

    /// The current authorization state without prompting.
    var authorizationState: AlarmManager.AuthorizationState {
        manager.authorizationState
    }

    /// Whether alarms are currently authorized (without prompting).
    var isAuthorized: Bool {
        manager.authorizationState == .authorized
    }

    /// Requests permission to schedule alarms if not already granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        // Already decided? Don't prompt again.
        switch manager.authorizationState {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            break
        @unknown default:
            break
        }

        do {
            let state = try await manager.requestAuthorization()
            return state == .authorized
        } catch {
            print("AlarmKitService: authorization error \(error)")
            return false
        }
    }

    /// Schedules an alarm mirroring the given app alarm.
    /// Throws `AlarmKitError` so callers can surface failures to the user.
    func schedule(_ alarm: AlarmModel) async throws {
        guard await requestAuthorization() else {
            print("AlarmKitService: not authorized; skipping schedule for \(alarm.id)")
            throw AlarmKitError.notAuthorized
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
        let hasSnooze = alarm.snoozeMinutes > 0
        let snoozeSeconds = hasSnooze ? TimeInterval(alarm.snoozeMinutes * 60) : nil

        let configuration = Self.makeConfiguration(title: title,
                                                   schedule: schedule,
                                                   snoozeSeconds: snoozeSeconds,
                                                   countdownSeconds: nil,
                                                   soundName: alarm.sound.fileName)

        do {
            _ = try await manager.schedule(id: alarm.id, configuration: configuration)
            print("AlarmKitService: scheduled \(alarm.id) for \(alarm.nextFireDate)")
        } catch {
            print("AlarmKitService: failed to schedule \(alarm.id): \(error)")
            throw AlarmKitError.scheduleFailed(error.localizedDescription)
        }
    }

    /// Schedules a one-off countdown alarm that fires after `seconds`.
    /// Used to verify the end-to-end alarm pipeline quickly.
    func scheduleTest(after seconds: TimeInterval) async throws {
        guard await requestAuthorization() else {
            throw AlarmKitError.notAuthorized
        }

        let title = LocalizedStringResource(stringLiteral: "Cycleep Test Alarm")
        let configuration = Self.makeConfiguration(title: title,
                                                   schedule: nil,
                                                   snoozeSeconds: nil,
                                                   countdownSeconds: seconds,
                                                   soundName: AlarmSound.default.fileName)

        let id = UUID()
        do {
            _ = try await manager.schedule(id: id, configuration: configuration)
            print("AlarmKitService: scheduled test alarm \(id) in \(seconds)s")
        } catch {
            print("AlarmKitService: failed to schedule test alarm: \(error)")
            throw AlarmKitError.scheduleFailed(error.localizedDescription)
        }
    }

    /// Builds an alarm configuration with a stop button and optional snooze/countdown.
    private static func makeConfiguration(title: LocalizedStringResource,
                                          schedule: Alarm.Schedule?,
                                          snoozeSeconds: TimeInterval?,
                                          countdownSeconds: TimeInterval?,
                                          soundName: String?) -> AlarmManager.AlarmConfiguration<AlarmKitMetadataModel> {
        // AlarmKit requires an explicit stop button; the system draws it in the alert.
        let stopButton = AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.circle")

        let alert: AlarmPresentation.Alert
        if let snoozeSeconds, snoozeSeconds > 0 {
            let snoozeButton = AlarmButton(text: "Snooze", textColor: .white, systemImageName: "zzz")
            alert = AlarmPresentation.Alert(title: title,
                                            stopButton: stopButton,
                                            secondaryButton: snoozeButton,
                                            secondaryButtonBehavior: .countdown)
        } else {
            alert = AlarmPresentation.Alert(title: title, stopButton: stopButton)
        }

        let presentation = AlarmPresentation(alert: alert)
        let attributes = AlarmAttributes(presentation: presentation,
                                         metadata: AlarmKitMetadataModel(),
                                         tintColor: .indigo)

        // preAlert drives a countdown-to-fire; postAlert is the snooze length.
        let countdown: Alarm.CountdownDuration?
        if countdownSeconds != nil || snoozeSeconds != nil {
            countdown = Alarm.CountdownDuration(preAlert: countdownSeconds, postAlert: snoozeSeconds)
        } else {
            countdown = nil
        }

        // Use the chosen bundled sound (its volume ramp is baked into the file);
        // fall back to the system sound if none is supplied.
        let alertSound: AlertConfiguration.AlertSound
        if let soundName {
            alertSound = .named(soundName)
        } else {
            alertSound = .default
        }

        return AlarmManager.AlarmConfiguration(
            countdownDuration: countdown,
            schedule: schedule,
            attributes: attributes,
            stopIntent: nil,
            secondaryIntent: nil,
            sound: alertSound)
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

    /// Emits the set of currently active AlarmKit alarm ids whenever they change.
    /// Used to detect when a one-time alarm has fired and been dismissed.
    static func alarmIDUpdates() -> AsyncStream<Set<UUID>> {
        AsyncStream { continuation in
            let task = Task {
                do {
                    for try await alarms in AlarmManager.shared.alarmUpdates {
                        continuation.yield(Set(alarms.map(\.id)))
                    }
                } catch {
                    print("AlarmKitService: alarm updates ended: \(error)")
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
