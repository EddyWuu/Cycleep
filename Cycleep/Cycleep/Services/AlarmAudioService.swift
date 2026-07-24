//
//  AlarmAudioService.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import AVFoundation
import Combine

/// Plays alarm sounds with a gradual ramp-up in volume using AVAudioPlayer.
/// This drives the in-app alarm experience and the sound preview in the
/// configuration sheet. AlarmKit acts as the system-level backup when the app
/// process isn't running (see `AlarmKitService`).
final class AlarmAudioService: ObservableObject {
    /// Sound currently being previewed, if any (used to toggle play/stop in UI).
    @Published private(set) var previewingSound: AlarmSound?

    private var player: AVAudioPlayer?

    /// Default time it takes to fade from silent to full volume.
    static let defaultRampDuration: TimeInterval = 20

    // MARK: - Preview

    /// Plays a short preview of a sound. Loops enough times to let the slower
    /// ramp-up reach full volume so the fade is actually audible.
    func preview(_ sound: AlarmSound, rampUp: Bool) {
        if previewingSound == sound {
            stop()
            return
        }
        play(sound, rampUp: rampUp, loops: 5)
        previewingSound = sound
    }

    // MARK: - Playback

    /// Starts playing `sound`, optionally fading the volume in.
    /// - Parameter loops: number of additional repeats; use a negative value to loop forever.
    func play(_ sound: AlarmSound, rampUp: Bool, rampDuration: TimeInterval = defaultRampDuration, loops: Int = -1) {
        stop()

        guard let url = url(for: sound) else {
            print("AlarmAudioService: missing audio file \"\(sound.fileName)\" in bundle. Add it to enable ramp-up playback.")
            return
        }

        do {
            try configureSession()
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loops
            player.prepareToPlay()

            if rampUp {
                player.volume = 0
                player.play()
                player.setVolume(1, fadeDuration: rampDuration)
            } else {
                player.volume = 1
                player.play()
            }

            self.player = player
        } catch {
            print("AlarmAudioService: failed to play \(sound.displayName): \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        previewingSound = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Helpers

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        // `.playback` keeps sound audible even with the ring/silent switch set to silent.
        try session.setCategory(.playback, options: [.duckOthers])
        try session.setActive(true)
    }

    private func url(for sound: AlarmSound) -> URL? {
        let name = (sound.fileName as NSString).deletingPathExtension
        let ext = (sound.fileName as NSString).pathExtension
        return Bundle.main.url(forResource: name, withExtension: ext)
    }
}
