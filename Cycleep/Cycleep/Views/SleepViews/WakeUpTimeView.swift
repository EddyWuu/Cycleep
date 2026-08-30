//
//  WakeUpTimeView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct WakeUpTimeView: View {
    @StateObject private var viewModel = WakeUpTimeViewModel()
    @State private var draft: AlarmDraft?

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
                        draft = .sleepWakePair(sleepTime: option.time,
                                               wakeTime: viewModel.wakeTime,
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
    WakeUpTimeView()
        .environmentObject(AlarmsViewModel())
}
