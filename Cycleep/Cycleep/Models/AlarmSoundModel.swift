//
//  AlarmSoundModel.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation

/// A built-in alarm sound. The raw value doubles as the stored identifier.
///
/// Each sound has a 60-second volume ramp baked into its bundled `.wav` file,
/// so AlarmKit plays a gentle fade-in even though it can't fade volume itself.
enum AlarmSound: String, CaseIterable, Identifiable, Codable {
    case radar = "Radar"
    case chimes = "Chimes"
    case waves = "Waves"
    case birds = "Birds"
    case beacon = "Beacon"

    var id: String { rawValue }

    var displayName: String { rawValue }

    /// Bundled audio file name AlarmKit plays via `AlertSound.named(...)`.
    var fileName: String { rawValue.lowercased() + ".wav" }

    /// SF Symbol shown next to the sound in the picker.
    var systemImage: String {
        switch self {
        case .radar: return "dot.radiowaves.left.and.right"
        case .chimes: return "bell"
        case .waves: return "water.waves"
        case .birds: return "bird"
        case .beacon: return "wave.3.right"
        }
    }

    nonisolated static var `default`: AlarmSound { .radar }
}
