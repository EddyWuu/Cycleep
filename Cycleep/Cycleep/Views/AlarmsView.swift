//
//  AlarmsView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct AlarmsView: View {
    @EnvironmentObject private var alarmsViewModel: AlarmsViewModel
    @State private var editingAlarm: AlarmModel?

    var body: some View {
        NavigationStack {
            Group {
                if alarmsViewModel.alarms.isEmpty {
                    ContentUnavailableView("No Alarms",
                                           systemImage: "alarm",
                                           description: Text("Set an alarm from the Sleep tab to see it here."))
                } else {
                    List {
                        ForEach(alarmsViewModel.displayGroups) { group in
                            if let name = group.name {
                                Section {
                                    ForEach(group.alarms) { alarm in
                                        row(for: alarm)
                                    }
                                } header: {
                                    Label(name, systemImage: "moon.zzz.fill")
                                        .textCase(nil)
                                }
                            } else {
                                ForEach(group.alarms) { alarm in
                                    row(for: alarm)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Alarms")
            .sheet(item: $editingAlarm) { alarm in
                AlarmConfigView(mode: .edit(alarm))
            }
        }
    }

    private func row(for alarm: AlarmModel) -> some View {
        AlarmRowView(alarm: alarm) {
            alarmsViewModel.toggle(alarm)
        } onSelect: {
            editingAlarm = alarm
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                alarmsViewModel.delete(alarm)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    AlarmsView()
        .environmentObject(AlarmsViewModel())
}
