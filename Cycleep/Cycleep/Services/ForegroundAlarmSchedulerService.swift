//
//  ForegroundAlarmSchedulerService.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation
import Combine

/// Runs the AVAudioPlayer ramp-up while the app is active, then hands off to
/// AlarmKit at the exact alarm time.
///
/// Why it works this way:
/// - iOS suspends backgrounded apps, so we can't reliably start audio at a
///   future time once the app is no longer running. AlarmKit is therefore the
///   authoritative alarm and always fires (foreground, background, or closed).
/// - When the app *is* active as an alarm approaches, this scheduler plays a
///   gentle volume ramp that reaches full volume right at the alarm time, then
///   stops so AlarmKit's alert takes over. This avoids two sounds overlapping.
/// - When the app leaves the foreground, in-app playback stops and AlarmKit is
///   left to deliver the alarm on its own.
@MainActor
final class ForegroundAlarmSchedulerService: ObservableObject {
    /// How long before the alarm the ramp-up begins (and how long the fade lasts).
    private let leadTime: TimeInterval = 90

    private var tasks: [Task<Void, Never>] = []

    /// Rebuilds the in-app ramp-up schedule. Call whenever the alarms change or
    /// the app's active state changes.
    func reschedule(alarms: [AlarmModel], isActive: Bool, audioService: AlarmAudioService) {
        cancelAll()

        guard isActive else {
            // Backgrounded/closed: let AlarmKit own the alarm.
            audioService.stop()
            return
        }

        let now = Date()
        for alarm in alarms where alarm.isEnabled {
            let fireInterval = alarm.nextFireDate.timeIntervalSince(now)
            guard fireInterval > 0 else { continue }

            let leadInterval = max(0, fireInterval - leadTime)
            let rampDuration = min(leadTime, fireInterval)
            let sound = alarm.sound
            let rampUp = alarm.rampUpVolume

            let task = Task {
                // Wait until it's time to begin the ramp.
                if leadInterval > 0 {
                    try? await Task.sleep(for: .seconds(leadInterval))
                    if Task.isCancelled { return }
                }

                audioService.play(sound, rampUp: rampUp, rampDuration: rampDuration, loops: -1)

                // Play through the fade, then hand off to AlarmKit at the alarm time.
                try? await Task.sleep(for: .seconds(rampDuration))
                audioService.stop()
            }
            tasks.append(task)
        }
    }

    func cancelAll() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
}
