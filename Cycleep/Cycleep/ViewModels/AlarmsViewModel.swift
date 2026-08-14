//
//  AlarmsViewModel.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation
import Combine

@MainActor
final class AlarmsViewModel: ObservableObject {
    @Published private(set) var alarms: [AlarmModel] = []
    /// A user-facing message when an alarm can't be scheduled (e.g. permission denied).
    @Published var errorMessage: String?
    /// A transient confirmation message (e.g. a test alarm was scheduled).
    @Published var infoMessage: String?

    private let alarmKit = AlarmKitService()
    private let store = AlarmStoreService()

    /// AlarmKit ids seen active on the previous update, used to detect when a
    /// one-time alarm has fired and been dismissed (so we can switch it off).
    private var previouslyActiveIDs: Set<UUID> = []

    init() {
        alarms = store.load()
        // Ask for permission up front so the very first alarm can be scheduled,
        // then re-arm AlarmKit for every enabled alarm.
        Task {
            await alarmKit.requestAuthorization()
            reconcileWithAlarmKit()
        }
        // Watch AlarmKit so one-time alarms turn themselves off after firing.
        Task { [weak self] in
            for await activeIDs in AlarmKitService.alarmIDUpdates() {
                self?.handleActiveAlarms(activeIDs)
            }
        }
    }

    /// Alarms ordered by time of day.
    var sortedAlarms: [AlarmModel] {
        alarms.sorted { $0.time < $1.time }
    }

    // MARK: - Creation

    /// Creates the alarm(s) described by a draft, applying the chosen sound/snooze.
    func create(from draft: AlarmDraft, sound: AlarmSound, snoozeMinutes: Int, repeatDays: Set<Weekday>) {
        switch draft {
        case let .wake(time, cycles):
            let alarm = AlarmModel(time: time,
                                   label: "Wake up",
                                   kind: .wake,
                                   soundName: sound.rawValue,
                                   snoozeMinutes: snoozeMinutes,
                                   cycles: cycles,
                                   repeatDays: repeatDays)
            add(alarm)

        case let .sleepWakePair(sleepTime, wakeTime, cycles):
            let bedtime = AlarmModel(time: sleepTime,
                                     label: "Bedtime",
                                     kind: .sleep,
                                     soundName: sound.rawValue,
                                     snoozeMinutes: snoozeMinutes,
                                     cycles: cycles,
                                     repeatDays: repeatDays)
            let wake = AlarmModel(time: wakeTime,
                                  label: "Wake up",
                                  kind: .wake,
                                  soundName: sound.rawValue,
                                  snoozeMinutes: snoozeMinutes,
                                  cycles: cycles,
                                  repeatDays: repeatDays)
            add(bedtime)
            add(wake)

        case let .manual(time, label):
            let alarm = AlarmModel(time: time,
                                   label: label.isEmpty ? "Alarm" : label,
                                   kind: .wake,
                                   soundName: sound.rawValue,
                                   snoozeMinutes: snoozeMinutes,
                                   cycles: nil,
                                   repeatDays: repeatDays)
            add(alarm)
        }
    }

    // MARK: - Mutations

    /// Replaces an existing alarm and reschedules its backup.
    func update(_ alarm: AlarmModel) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index] = alarm
        alarmKit.cancel(id: alarm.id)
        scheduleBackup(alarm)
        persist()
    }

    func toggle(_ alarm: AlarmModel) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
        if alarms[index].isEnabled {
            scheduleBackup(alarms[index])
        } else {
            alarmKit.cancel(id: alarm.id)
        }
        persist()
    }

    func delete(_ alarm: AlarmModel) {
        alarmKit.cancel(id: alarm.id)
        alarms.removeAll { $0.id == alarm.id }
        persist()
    }

    /// Delete using offsets from a (possibly sorted) list shown in the UI.
    func delete(at offsets: IndexSet, in displayed: [AlarmModel]) {
        let ids = offsets.map { displayed[$0].id }
        ids.forEach { alarmKit.cancel(id: $0) }
        alarms.removeAll { ids.contains($0.id) }
        persist()
    }

    /// Fires a countdown alarm after `seconds` to verify the alarm pipeline.
    func scheduleTestAlarm(after seconds: TimeInterval = 10) {
        Task {
            do {
                try await alarmKit.scheduleTest(after: seconds)
                infoMessage = "An alarm will fire in about \(Int(seconds)) seconds. Lock the device or leave the app to confirm it works in the background."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Private

    private func add(_ alarm: AlarmModel) {
        alarms.append(alarm)
        scheduleBackup(alarm)
        persist()
    }

    /// Reacts to AlarmKit's active-alarm list. When a one-time alarm disappears
    /// (it fired and was dismissed), switch it off in our list. Repeating alarms
    /// stay scheduled in AlarmKit, so they remain on.
    private func handleActiveAlarms(_ activeIDs: Set<UUID>) {
        let disappeared = previouslyActiveIDs.subtracting(activeIDs)
        previouslyActiveIDs = activeIDs
        guard !disappeared.isEmpty else { return }

        var changed = false
        for id in disappeared {
            guard let index = alarms.firstIndex(where: { $0.id == id }) else { continue }
            // Only auto-disable non-repeating alarms that are still marked on.
            if !alarms[index].isRepeating && alarms[index].isEnabled {
                alarms[index].isEnabled = false
                changed = true
            }
        }
        if changed { persist() }
    }

    private func scheduleBackup(_ alarm: AlarmModel) {
        guard alarm.isEnabled else { return }
        Task {
            do {
                try await alarmKit.schedule(alarm)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Re-schedules AlarmKit for all enabled alarms. Scheduling by the existing
    /// id is idempotent, so this safely keeps the fallback in sync on launch.
    private func reconcileWithAlarmKit() {
        for alarm in alarms where alarm.isEnabled {
            scheduleBackup(alarm)
        }
    }

    private func persist() {
        store.save(alarms)
    }
}
