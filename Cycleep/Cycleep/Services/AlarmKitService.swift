//
//  AlarmKitService.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import AlarmKit
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
        let schedule: Alarm.Schedule = .relative(.init(time: time, repeats: .never))

        let title = LocalizedStringResource(stringLiteral: alarm.label.isEmpty ? "Cycleep" : alarm.label)
        // The system provides the stop button automatically.
        let alert = AlarmPresentation.Alert(title: title,
                                            secondaryButton: nil,
                                            secondaryButtonBehavior: nil)
        let presentation = AlarmPresentation(alert: alert)
        let attributes = AlarmAttributes(presentation: presentation,
                                         metadata: AlarmKitMetadataModel(),
                                         tintColor: .indigo)

        let configuration = AlarmManager.AlarmConfiguration(schedule: schedule, attributes: attributes)

        do {
            _ = try await manager.schedule(id: alarm.id, configuration: configuration)
        } catch {
            print("AlarmKitService: failed to schedule \(alarm.id): \(error)")
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
