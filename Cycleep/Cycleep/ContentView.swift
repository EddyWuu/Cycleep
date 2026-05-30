//
//  ContentView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-05-22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SleepNowView()
                .tabItem {
                    Image(systemName: "bed.double.fill")
                    Text("Sleep Now")
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
    }
}

#Preview {
    ContentView()
}
