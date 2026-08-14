//
//  ManualAlarmViewModel.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation
import Combine

@MainActor
final class ManualAlarmViewModel: ObservableObject {
    @Published var time: Date = Date()
    @Published var label: String = ""

    /// The draft to configure and create from the current selection.
    var draft: AlarmDraft {
        .manual(time: time, label: label.trimmingCharacters(in: .whitespaces))
    }
}
