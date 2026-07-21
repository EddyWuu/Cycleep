//
//  WakeUpTimeView.swift
//  Cycleep
//
//  Sub-tab: pick a wake-up time, choose a bedtime, and set both alarms.
//

import SwiftUI

struct WakeUpTimeView: View {
    @EnvironmentObject private var alarmsViewModel: AlarmsViewModel
    @StateObject private var viewModel = WakeUpTimeViewModel()

    var body: some View {
        List {
            Section {
                DatePicker("Wake up at",
                           selection: $viewModel.wakeTime,
                           displayedComponents: .hourAndMinute)
            } footer: {
                Text("Choose a bedtime below to set both a bedtime alarm and a wake-up alarm.")
            }

            Section("Go to sleep at") {
                ForEach(viewModel.sleepOptions) { option in
                    CycleOptionRowView(option: option) {
                        alarmsViewModel.addSleepWakePair(sleepTime: option.time,
                                                         wakeTime: viewModel.wakeTime,
                                                         cycles: option.cycles)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    WakeUpTimeView()
        .environmentObject(AlarmsViewModel())
}
