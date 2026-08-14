//
//  ContentView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-05-22.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var alarmsViewModel = AlarmsViewModel()

    var body: some View {
        TabView {
            SleepView()
                .tabItem {
                    Image(systemName: "bed.double.fill")
                    Text("Sleep")
                }

            AlarmsView()
                .tabItem {
                    Image(systemName: "alarm")
                    Text("Alarms")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .environmentObject(alarmsViewModel)
        .alert("Alarm Problem",
               isPresented: Binding(get: { alarmsViewModel.errorMessage != nil },
                                    set: { if !$0 { alarmsViewModel.errorMessage = nil } })) {
            Button("OK", role: .cancel) { alarmsViewModel.errorMessage = nil }
        } message: {
            Text(alarmsViewModel.errorMessage ?? "")
        }
        .alert("Test Alarm Set",
               isPresented: Binding(get: { alarmsViewModel.infoMessage != nil },
                                    set: { if !$0 { alarmsViewModel.infoMessage = nil } })) {
            Button("OK", role: .cancel) { alarmsViewModel.infoMessage = nil }
        } message: {
            Text(alarmsViewModel.infoMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
}
