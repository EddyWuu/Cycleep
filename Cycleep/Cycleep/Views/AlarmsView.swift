//
//  AlarmsView.swift
//  Cycleep
//
//  Tab 2. Lists all alarms created from the Sleep tab.
//

import SwiftUI

struct AlarmsView: View {
    @EnvironmentObject private var alarmsViewModel: AlarmsViewModel

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
                            AlarmRow(alarm: alarm) {
                                alarmsViewModel.toggle(alarm)
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
        }
    }
}

#Preview {
    AlarmsView()
        .environmentObject(AlarmsViewModel())
}
