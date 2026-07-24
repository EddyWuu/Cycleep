//
//  ContentView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-05-22.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var alarmsViewModel = AlarmsViewModel()
    @StateObject private var audioService = AlarmAudioService()
    @StateObject private var rampScheduler = ForegroundAlarmSchedulerService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            SleepView()
                .tabItem {
                    Image(systemName: "bed.double.fill")
                    Text("Sleep")
                }

            AlarmsView()
                .tabItem {
                    Image(systemName: "alarm")
                    Text("Alarms")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .environmentObject(alarmsViewModel)
        .environmentObject(audioService)
        .onAppear { rescheduleRampUp() }
        .onChange(of: scenePhase) { _, _ in rescheduleRampUp() }
        .onChange(of: alarmsViewModel.alarms) { _, _ in rescheduleRampUp() }
    }

    /// Refreshes the in-app ramp-up timers. AlarmKit remains the authoritative
    /// alarm; this only adds the gentle fade while the app is in the foreground.
    private func rescheduleRampUp() {
        rampScheduler.reschedule(alarms: alarmsViewModel.alarms,
                                 isActive: scenePhase == .active,
                                 audioService: audioService)
    }
}

#Preview {
    ContentView()
}
