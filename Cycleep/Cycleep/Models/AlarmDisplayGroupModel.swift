//
//  AlarmDisplayGroupModel.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-08-29.
//

import Foundation

/// A displayable entry in the Alarms tab: either a standalone alarm or a named
/// folder of alarms created together (e.g. a bedtime + wake-up pair).
struct AlarmDisplayGroup: Identifiable {
    let id: String
    /// Folder title when this represents a group; `nil` for a standalone alarm.
    let name: String?
    /// Member alarms, pre-sorted for display.
    let alarms: [AlarmModel]
    /// Earliest alarm time, used to order groups against standalone alarms.
    let sortDate: Date

    /// Whether this entry is a folder (more than one alarm under a name).
    var isFolder: Bool { name != nil }
}
