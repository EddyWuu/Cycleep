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
    }
}

#Preview {
    ContentView()
}
