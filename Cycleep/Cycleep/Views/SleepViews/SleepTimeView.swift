//
//  SleepTimeView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct SleepTimeView: View {
    @StateObject private var viewModel = SleepTimeViewModel()
    @State private var draft: AlarmDraft?

    var body: some View {
        List {
            Section {
                DatePicker("Go to sleep at",
                           selection: $viewModel.sleepTime,
                           displayedComponents: .hourAndMinute)
            } footer: {
                Text("Pick when you plan to fall asleep, then choose a wake-up time below. Both a bedtime and a wake-up alarm are set.")
            }

            Section("Wake up at") {
                ForEach(viewModel.wakeOptions) { option in
                    CycleOptionRowView(option: option) {
                        draft = .sleepWakePair(sleepTime: viewModel.sleepTime,
                                               wakeTime: option.time,
                                               cycles: option.cycles)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .cycleepListBackground()
        .sheet(item: $draft) { draft in
            AlarmConfigView(mode: .create(draft))
        }
    }
}

#Preview {
    SleepTimeView()
        .environmentObject(AlarmsViewModel())
}
