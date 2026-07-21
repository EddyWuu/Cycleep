//
//  SleepTimeView.swift
//  Cycleep
//
//  Sub-tab: pick a bedtime, choose a wake-up time, and set an alarm.
//

import SwiftUI

struct SleepTimeView: View {
    @EnvironmentObject private var alarmsViewModel: AlarmsViewModel
    @StateObject private var viewModel = SleepTimeViewModel()

    var body: some View {
        List {
            Section {
                DatePicker("Go to sleep at",
                           selection: $viewModel.sleepTime,
                           displayedComponents: .hourAndMinute)
            } footer: {
                Text("Pick when you plan to fall asleep, then choose a wake-up time below.")
            }

            Section("Wake up at") {
                ForEach(viewModel.wakeOptions) { option in
                    CycleOptionRowView(option: option) {
                        alarmsViewModel.addWakeAlarm(at: option.time, cycles: option.cycles)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    SleepTimeView()
        .environmentObject(AlarmsViewModel())
}
