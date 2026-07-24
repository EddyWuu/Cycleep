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

    private let alarmKit = AlarmKitService()
    private let store = AlarmStoreService()

    init() {
        alarms = store.load()
        // Re-arm AlarmKit for every enabled alarm so the fallback stays reliable
        // even if the system dropped a fired one-time alarm while we were closed.
        reconcileWithAlarmKit()
    }

    /// Alarms ordered by time of day.
    var sortedAlarms: [AlarmModel] {
        alarms.sorted { $0.time < $1.time }
    }

    // MARK: - Creation

    /// Creates the alarm(s) described by a draft, applying the chosen sound/snooze.
    func create(from draft: AlarmDraft, sound: AlarmSound, snoozeMinutes: Int, rampUp: Bool) {
        switch draft {
        case let .wake(time, cycles):
            let alarm = AlarmModel(time: time,
                                   label: "Wake up",
                                   kind: .wake,
                                   soundName: sound.rawValue,
                                   snoozeMinutes: snoozeMinutes,
                                   rampUpVolume: rampUp,
                                   cycles: cycles)
            add(alarm)

        case let .sleepWakePair(sleepTime, wakeTime, cycles):
            let bedtime = AlarmModel(time: sleepTime,
                                     label: "Bedtime",
                                     kind: .sleep,
                                     soundName: sound.rawValue,
                                     snoozeMinutes: snoozeMinutes,
                                     rampUpVolume: rampUp,
                                     cycles: cycles)
            let wake = AlarmModel(time: wakeTime,
                                  label: "Wake up",
                                  kind: .wake,
                                  soundName: sound.rawValue,
                                  snoozeMinutes: snoozeMinutes,
                                  rampUpVolume: rampUp,
                                  cycles: cycles)
            add(bedtime)
            add(wake)

        case let .manual(time, label):
            let alarm = AlarmModel(time: time,
                                   label: label.isEmpty ? "Alarm" : label,
                                   kind: .wake,
                                   soundName: sound.rawValue,
                                   snoozeMinutes: snoozeMinutes,
                                   rampUpVolume: rampUp,
                                   cycles: nil)
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

    // MARK: - Private

    private func add(_ alarm: AlarmModel) {
        alarms.append(alarm)
        scheduleBackup(alarm)
        persist()
    }

    private func scheduleBackup(_ alarm: AlarmModel) {
        guard alarm.isEnabled else { return }
        Task { await alarmKit.schedule(alarm) }
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
