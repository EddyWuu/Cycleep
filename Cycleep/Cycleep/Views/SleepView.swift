//
//  SleepView.swift
//  Cycleep
//
//  Tab 1. Hosts three sub-tabs: Sleep Now, Wake Up Time, and Sleep Time.
//

import SwiftUI

struct SleepView: View {
    enum SleepTab: String, CaseIterable, Identifiable {
        case sleepNow = "Sleep Now"
        case wakeUp = "Wake Up Time"
        case sleepTime = "Sleep Time"

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
