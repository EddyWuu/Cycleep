//
//  SleepNowView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct SleepNowView: View {
    @StateObject private var viewModel = SleepNowViewModel()
    @State private var draft: AlarmDraft?

    var body: some View {
        List {
            Section {
                ForEach(viewModel.options) { option in
                    CycleOptionRowView(option: option) {
                        draft = .wake(time: option.time, cycles: option.cycles)
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
        .sheet(item: $draft) { draft in
            AlarmConfigView(mode: .create(draft))
        }
    }
}

#Preview {
    SleepNowView()
        .environmentObject(AlarmsViewModel())
        .environmentObject(AlarmAudioService())
}
