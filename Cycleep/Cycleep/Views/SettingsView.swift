//
//  SettingsView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

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
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
