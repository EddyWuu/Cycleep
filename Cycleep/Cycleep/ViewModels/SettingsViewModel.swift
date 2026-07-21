//
//  SettingsViewModel.swift
//  Cycleep
//
//  Backing state for the Settings tab.
//

import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool = true

    let cycleLengthMinutes: Int = SleepCycleModel.cycleMinutes
}
