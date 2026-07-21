//
//  AlarmsViewModel.swift
//  Cycleep
//
//  Shared store for all alarms. Injected via the environment so the Sleep
//  sub-tabs can create alarms and the Alarms tab can display them.
//

import Foundation
import Combine

@MainActor
final class AlarmsViewModel: ObservableObject {
    @Published private(set) var alarms: [AlarmModel] = []

    /// Alarms ordered by time of day.
    var sortedAlarms: [AlarmModel] {
        alarms.sorted { $0.time < $1.time }
    }

    /// Create a single wake-up alarm (Sleep Now / Sleep Time tabs).
    func addWakeAlarm(at time: Date, cycles: Int) {
        alarms.append(AlarmModel(time: time, label: "Wake up", kind: .wake, cycles: cycles))
    }

    /// Create a paired bedtime + wake-up alarm (Wake Up Time tab).
    func addSleepWakePair(sleepTime: Date, wakeTime: Date, cycles: Int) {
        let bedtime = AlarmModel(time: sleepTime, label: "Bedtime", kind: .sleep, cycles: cycles)
        let wake = AlarmModel(time: wakeTime, label: "Wake up", kind: .wake, cycles: cycles)
        alarms.append(contentsOf: [bedtime, wake])
    }

    func toggle(_ alarm: AlarmModel) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
    }

    func delete(_ alarm: AlarmModel) {
        alarms.removeAll { $0.id == alarm.id }
    }

    /// Delete using offsets from a (possibly sorted) list shown in the UI.
    func delete(at offsets: IndexSet, in displayed: [AlarmModel]) {
        let ids = offsets.map { displayed[$0].id }
        alarms.removeAll { ids.contains($0.id) }
    }
}
