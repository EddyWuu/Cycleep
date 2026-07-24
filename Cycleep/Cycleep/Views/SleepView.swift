//
//  SleepView.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import SwiftUI

struct SleepView: View {
    enum SleepTab: String, CaseIterable, Identifiable {
        case sleepNow = "Sleep Now"
        case wakeUp = "Wake Up Time"
        case sleepTime = "Sleep Time"
        case manual = "Manual"

        var id: String { rawValue }
    }

    @State private var selectedTab: SleepTab = .sleepNow

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $selectedTab) {
                    ForEach(SleepTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .sleepNow:
                    SleepNowView()
                case .wakeUp:
                    WakeUpTimeView()
                case .sleepTime:
                    SleepTimeView()
                case .manual:
                    ManualAlarmView()
                }
            }
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SleepView()
        .environmentObject(AlarmsViewModel())
}
