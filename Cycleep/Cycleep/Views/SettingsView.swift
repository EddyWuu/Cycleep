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
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Fires a one-off AlarmKit alarm 10 seconds from now to verify permissions and the alarm pipeline. Best tested on a physical device.")
                }
            }
            .navigationTitle("Settings")
            .cycleepListBackground()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AlarmsViewModel())
}
