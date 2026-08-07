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
        .alert("Alarm Problem",
               isPresented: Binding(get: { alarmsViewModel.errorMessage != nil },
                                    set: { if !$0 { alarmsViewModel.errorMessage = nil } })) {
            Button("OK", role: .cancel) { alarmsViewModel.errorMessage = nil }
        } message: {
            Text(alarmsViewModel.errorMessage ?? "")
        }
        .alert("Test Alarm Set",
               isPresented: Binding(get: { alarmsViewModel.infoMessage != nil },
                                    set: { if !$0 { alarmsViewModel.infoMessage = nil } })) {
            Button("OK", role: .cancel) { alarmsViewModel.infoMessage = nil }
        } message: {
            Text(alarmsViewModel.infoMessage ?? "")
        }
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
