//
//  AlarmAudioService.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-08-29.
//

import Foundation
import Foundation
import AVFoundation
import Combine

/// Plays short, constant-volume sound previews in the foreground so users can
/// audition alarm tones from the config sheet.
///
/// This is PREVIEW-ONLY on purpose: it plays the `_preview.wav` clip (no ramp),
/// only while the app is active, and is user-initiated. It never runs in the
/// background and never keeps the app alive — the real alarm, including its
/// baked-in volume ramp, is played entirely by AlarmKit. Keeping playback to a
/// foreground, user-triggered preview keeps it App Review-safe.
@MainActor
final class AlarmAudioService: NSObject, ObservableObject {
    /// The sound currently previewing, if any (drives the picker's play indicator).
    @Published private(set) var playingSound: AlarmSound?

    private var player: AVAudioPlayer?

    /// Toggles preview for a sound: plays it, or stops if it's already playing.
    func togglePreview(_ sound: AlarmSound) {
        if playingSound == sound {
            stop()
        } else {
            play(sound)
        }
    }

    /// Plays a sound's preview clip once at full volume (no ramp).
    func play(_ sound: AlarmSound) {
        stop()
        guard let url = Bundle.main.url(forResource: sound.previewResourceName,
                                        withExtension: "wav") else {
            print("AlarmAudioService: preview file missing for \(sound.rawValue)")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.volume = 1.0
            newPlayer.prepareToPlay()
            newPlayer.play()

            player = newPlayer
            playingSound = sound
        } catch {
            print("AlarmAudioService: preview failed for \(sound.rawValue): \(error)")
            playingSound = nil
        }
    }

    /// Stops any preview and releases the audio session.
    func stop() {
        player?.stop()
        player = nil
        playingSound = nil
        try? AVAudioSession.sharedInstance()
            .setActive(false, options: .notifyOthersOnDeactivation)
    }
}

extension AlarmAudioService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.stop() }
    }
}
