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
    /// Whether the one-time launch reconciliation has run yet.
    private var didLaunchReconcile = false

    init() {
        alarms = store.load()
        // Resolve authorization first, then use AlarmKit's first snapshot to
        // reconcile our list on launch and to react to alarms firing afterwards.
        Task { [weak self] in
            await self?.alarmKit.requestAuthorization()
            for await activeIDs in AlarmKitService.alarmIDUpdates() {
                self?.handleAlarmUpdate(activeIDs)
            }
        }
    }

    /// Alarms ordered by time of day.
    var sortedAlarms: [AlarmModel] {
        alarms.sorted { $0.time < $1.time }
    }

    /// The Alarms list organized for display: standalone alarms and grouped
    /// "folders" (e.g. a bedtime + wake-up pair), ordered by earliest time.
    var displayGroups: [AlarmDisplayGroup] {
        var byGroup: [UUID: [AlarmModel]] = [:]
        var singles: [AlarmModel] = []
        for alarm in alarms {
            if let gid = alarm.groupID {
                byGroup[gid, default: []].append(alarm)
            } else {
                singles.append(alarm)
            }
        }

        var result: [AlarmDisplayGroup] = []

        for (gid, members) in byGroup {
            let sorted = members.sorted(by: Self.bedtimeFirst)
            if sorted.count > 1 {
                let name = sorted.first(where: { !$0.groupName.isEmpty })?.groupName ?? "Sleep Schedule"
                let earliest = sorted.map(\.time).min() ?? Date()
                result.append(AlarmDisplayGroup(id: gid.uuidString,
                                                name: name,
                                                alarms: sorted,
                                                sortDate: earliest))
            } else if let only = sorted.first {
                // A pair whose partner was deleted falls back to a standalone row.
                result.append(AlarmDisplayGroup(id: only.id.uuidString,
                                                name: nil,
                                                alarms: [only],
                                                sortDate: only.time))
            }
        }

        for alarm in singles {
            result.append(AlarmDisplayGroup(id: alarm.id.uuidString,
                                            name: nil,
                                            alarms: [alarm],
                                            sortDate: alarm.time))
        }

        return result.sorted { $0.sortDate < $1.sortDate }
    }

    /// Sort order within a folder: bedtime before wake-up, then by time.
    private static func bedtimeFirst(_ a: AlarmModel, _ b: AlarmModel) -> Bool {
        if a.kind != b.kind { return a.kind == .sleep }
        return a.time < b.time
    }

    // MARK: - Creation

    /// Creates the alarm(s) described by a draft, applying the chosen name/sound/snooze.
    func create(from draft: AlarmDraft, name: String, sound: AlarmSound, snoozeMinutes: Int, repeatDays: Set<Weekday>) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        switch draft {
        case let .wake(time, cycles):
            let alarm = AlarmModel(time: time,
                                   label: trimmedName.isEmpty ? "Wake up" : trimmedName,
                                   kind: .wake,
                                   soundName: sound.rawValue,
                                   snoozeMinutes: snoozeMinutes,
                                   cycles: cycles,
                                   repeatDays: repeatDays)
            add(alarm)

        case let .sleepWakePair(sleepTime, wakeTime, cycles):
            // Both alarms share a group id so the Alarms tab shows them in one folder.
            let groupID = UUID()
            let groupName = trimmedName.isEmpty ? "Sleep Schedule" : trimmedName
            let bedtime = AlarmModel(time: sleepTime,
                                     label: "Bedtime",
                                     kind: .sleep,
                                     soundName: sound.rawValue,
                                     snoozeMinutes: snoozeMinutes,
                                     cycles: cycles,
                                     repeatDays: repeatDays,
                                     groupID: groupID,
                                     groupName: groupName)
            let wake = AlarmModel(time: wakeTime,
                                  label: "Wake up",
                                  kind: .wake,
                                  soundName: sound.rawValue,
                                  snoozeMinutes: snoozeMinutes,
                                  cycles: cycles,
                                  repeatDays: repeatDays,
                                  groupID: groupID,
                                  groupName: groupName)
            add(bedtime)
            add(wake)

        case let .manual(time, label):
            let finalName = trimmedName.isEmpty
                ? (label.isEmpty ? "Alarm" : label)
                : trimmedName
            let alarm = AlarmModel(time: time,
                                   label: finalName,
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

    /// Renames a folder by updating the `groupName` of all its member alarms.
    func renameGroup(_ group: AlarmDisplayGroup, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Sleep Schedule" : trimmed
        var changed = false
        for index in alarms.indices where alarms[index].groupID?.uuidString == group.id {
            alarms[index].groupName = name
            changed = true
        }
        if changed { persist() }
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

    /// Routes each AlarmKit snapshot: the first one reconciles our list on
    /// launch; later ones detect one-time alarms that fired and switch them off.
    private func handleAlarmUpdate(_ activeIDs: Set<UUID>) {
        if !didLaunchReconcile {
            didLaunchReconcile = true
            reconcileOnLaunch(knownIDs: activeIDs)
        } else {
            handleActiveAlarms(activeIDs)
        }
        previouslyActiveIDs = activeIDs
    }

    /// Reconciles our saved alarms against AlarmKit's known set on launch.
    /// Repeating alarms are re-armed (idempotent). A one-time alarm that AlarmKit
    /// no longer knows about has already fired (possibly while the app was closed),
    /// so it's switched off instead of being re-scheduled.
    private func reconcileOnLaunch(knownIDs: Set<UUID>) {
        let authorized = alarmKit.isAuthorized
        var changed = false
        for index in alarms.indices where alarms[index].isEnabled {
            let alarm = alarms[index]
            if alarm.isRepeating {
                scheduleBackup(alarm)
            } else if authorized && !knownIDs.contains(alarm.id) {
                // One-time alarm already fired (or was lost) → turn it off.
                alarms[index].isEnabled = false
                changed = true
            }
            // A one-time alarm still known to AlarmKit stays scheduled as-is.
        }
        if changed { persist() }
    }

    /// Reacts to AlarmKit's active-alarm list. When a one-time alarm disappears
    /// (it fired and was dismissed), switch it off in our list. Repeating alarms
    /// stay scheduled in AlarmKit, so they remain on.
    private func handleActiveAlarms(_ activeIDs: Set<UUID>) {
        let disappeared = previouslyActiveIDs.subtracting(activeIDs)
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

    private func persist() {
        store.save(alarms)
    }
}
