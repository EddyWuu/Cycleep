//
//  SleepNowView.swift
//  Cycleep
//
//  Sub-tab: wake-up options if you fall asleep right now.
//

import SwiftUI

struct SleepNowView: View {
    @EnvironmentObject private var alarmsViewModel: AlarmsViewModel
    @StateObject private var viewModel = SleepNowViewModel()

    var body: some View {
        List {
            Section {
                ForEach(viewModel.options) { option in
                    CycleOptionRowView(option: option) {
                        alarmsViewModel.addWakeAlarm(at: option.time, cycles: option.cycles)
                    }
                }
            } header: {
                Text("If you fall asleep now")
            } footer: {
                Text("Each option wakes you at the end of a full \(SleepCycleModel.cycleMinutes)-minute sleep cycle.")
            }
        }
        .listStyle(.insetGrouped)
        .onAppear { viewModel.refresh() }
    }
}

#Preview {
    SleepNowView()
        .environmentObject(AlarmsViewModel())
}
