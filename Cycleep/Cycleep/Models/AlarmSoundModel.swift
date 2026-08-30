//
//  AlarmSoundModel.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import Foundation

/// A built-in alarm sound. The raw value doubles as the stored identifier.
///
/// Each sound ships as two bundled files:
/// * `<name>.caf` — the alarm file (IMA4 CAF). Opens with a short silent intro,
///   then a 60s ramp to full, then a long full-volume sustain. AlarmKit loops it,
///   so the sleeper hears the gentle ramp once and then it stays loud.
/// * `<name>_preview.wav` — a short, constant-volume clip used only for the
///   in-app "tap to audition" preview (no ramp — a preview is a quick showcase).
enum AlarmSound: String, CaseIterable, Identifiable, Codable {
    case radar = "Radar"
    case beacon = "Beacon"
    case signal = "Signal"
    case circuit = "Circuit"
    case digital = "Digital"
    case presto = "Presto"
    case bulletin = "Bulletin"
    case chimes = "Chimes"
    case crystals = "Crystals"
    case twinkle = "Twinkle"
    case xylophone = "Xylophone"
    case uplift = "Uplift"
    case waves = "Waves"
    case birds = "Birds"
    case cosmic = "Cosmic"
    case pulse = "Pulse"

    var id: String { rawValue }

    var displayName: String { rawValue }

    /// Base file name (no extension), e.g. "radar".
    private var baseName: String { rawValue.lowercased() }

    /// Ramped alarm file AlarmKit plays via `AlertSound.named(...)`.
    var fileName: String { baseName + ".caf" }

    /// Constant-volume preview clip resource name (no extension) for AVAudioPlayer.
    var previewResourceName: String { baseName + "_preview" }

    /// SF Symbol shown next to the sound in the picker.
    var systemImage: String {
        switch self {
        case .radar: return "dot.radiowaves.left.and.right"
        case .beacon: return "wave.3.right"
        case .signal: return "antenna.radiowaves.left.and.right"
        case .circuit: return "cpu"
        case .digital: return "waveform.path"
        case .presto: return "hare"
        case .bulletin: return "megaphone"
        case .chimes: return "bell"
        case .crystals: return "sparkles"
        case .twinkle: return "star"
        case .xylophone: return "pianokeys"
        case .uplift: return "arrow.up.circle"
        case .waves: return "water.waves"
        case .birds: return "bird"
        case .cosmic: return "moon.stars"
        case .pulse: return "heart"
        }
    }

    nonisolated static var `default`: AlarmSound { .radar }
}
