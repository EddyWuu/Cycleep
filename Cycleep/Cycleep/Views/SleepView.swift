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
    @Namespace private var pillNamespace

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    tabSelector
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

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
            }
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SleepTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? Theme.background : Theme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(Theme.textPrimary)
                                        .matchedGeometryEffect(id: "pill", in: pillNamespace)
                                } else {
                                    Capsule().fill(Theme.surface)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    SleepView()
        .environmentObject(AlarmsViewModel())
}
