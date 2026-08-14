//
//  ManualAlarmView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct ManualAlarmView: View {
    @StateObject private var viewModel = ManualAlarmViewModel()
    @State private var draft: AlarmDraft?

    var body: some View {
        List {
            Section {
                DatePicker("Time",
                           selection: $viewModel.time,
                           displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)

                TextField("Label (optional)", text: $viewModel.label)
            } footer: {
                Text("Set an alarm for any time you choose — no sleep-cycle math.")
            }

            Section {
                Button {
                    draft = viewModel.draft
                } label: {
                    Text("Set Alarm")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .sheet(item: $draft) { draft in
            AlarmConfigView(mode: .create(draft))
        }
    }
}

#Preview {
    ManualAlarmView()
        .environmentObject(AlarmsViewModel())
}
