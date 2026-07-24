//
//  SettingsViewModel.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool = true

    let cycleLengthMinutes: Int = SleepCycleModel.cycleMinutes
}
