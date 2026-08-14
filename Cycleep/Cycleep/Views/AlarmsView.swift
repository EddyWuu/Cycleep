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
                        ForEach(alarmsViewModel.sortedAlarms) { alarm in
                            AlarmRowView(alarm: alarm) {
                                alarmsViewModel.toggle(alarm)
                            } onSelect: {
                                editingAlarm = alarm
                            }
                        }
                        .onDelete { offsets in
                            alarmsViewModel.delete(at: offsets, in: alarmsViewModel.sortedAlarms)
                        }
                    }
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                if !alarmsViewModel.alarms.isEmpty {
                    EditButton()
                }
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmConfigView(mode: .edit(alarm))
            }
        }
    }
}

#Preview {
    AlarmsView()
        .environmentObject(AlarmsViewModel())
}
