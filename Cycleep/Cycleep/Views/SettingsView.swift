//
//  SettingsView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var alarmsViewModel: AlarmsViewModel
    @EnvironmentObject private var audioService: AlarmAudioService

    var body: some View {
        NavigationStack {
            Form {
                Section("Sleep Cycle") {
                    HStack {
                        Text("Cycle length")
                        Spacer()
                        Text("\(viewModel.cycleLengthMinutes) min")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notifications") {
                    Toggle("Enable notifications", isOn: $viewModel.notificationsEnabled)
                }

                Section {
                    Button {
                        alarmsViewModel.scheduleTestAlarm(after: 10)
                    } label: {
                        Label("Test alarm in 10 seconds", systemImage: "alarm.waves.left.and.right")
                    }

                    Button {
                        audioService.previewRamp(.default)
                    } label: {
                        Label("Preview ramp-up (60s)", systemImage: "speaker.wave.3")
                    }

                    Button(role: .destructive) {
                        audioService.stop()
                    } label: {
                        Label("Stop preview", systemImage: "stop.fill")
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("“Test alarm” fires a one-off AlarmKit alarm (no ramp — that’s the backup path); best on a physical device. “Preview ramp-up” plays the in-app AVAudioPlayer fade so you can hear it swell from barely audible to full over ~60s.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AlarmsViewModel())
        .environmentObject(AlarmAudioService())
}
