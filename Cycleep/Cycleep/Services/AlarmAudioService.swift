//
//  AlarmAudioService.swift
//  Cycleep
//
//  Created by Edmond Wu on 2026-07-23.
//

import AVFoundation
import Combine

/// Plays alarm sounds using AVAudioPlayer for the in-app experience and the
/// sound preview in the configuration sheet.
///
/// The gradual volume ramp is **baked into the sound files themselves** (they
/// start quiet and rise over ~20s). This is what lets the ramp also work on the
/// real, locked-screen alarm, which AlarmKit plays at a fixed system volume and
/// can't fade programmatically (see `AlarmKitService`).
final class AlarmAudioService: NSObject, ObservableObject {
    /// Sound currently being previewed, if any (used to toggle play/stop in UI).
    @Published private(set) var previewingSound: AlarmSound?

    private var player: AVAudioPlayer?

    /// How long the baked-in volume ramp lasts in each sound file, in seconds.
    /// Playback started past this point begins at full volume.
    static let bakedRampDuration: TimeInterval = 20

    // MARK: - Preview

    /// Plays a short, full-volume sample so the user can identify the sound
    /// quickly (skips the long baked ramp).
    func preview(_ sound: AlarmSound) {
        if previewingSound == sound {
            stop()
            return
        }
        play(sound, rampUp: false, loops: 0)
        previewingSound = sound
    }

    // MARK: - Playback

    /// Starts playing `sound`.
    /// - Parameters:
    ///   - rampUp: when `true`, playback starts at the beginning so the baked
    ///     volume ramp is heard; when `false`, it starts in the loud sustain region.
    ///   - loops: additional repeats; use a negative value to loop forever.
    func play(_ sound: AlarmSound, rampUp: Bool, loops: Int = -1) {
        stop()

        guard let url = url(for: sound) else {
            print("AlarmAudioService: missing audio file \"\(sound.fileName)\" in bundle.")
            return
        }

        do {
            try configureSession()
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.numberOfLoops = loops
            player.volume = 1
            player.prepareToPlay()

            if !rampUp {
                // Skip the baked ramp: jump into the full-volume sustain region.
                let start = min(Self.bakedRampDuration + 1, max(0, player.duration - 0.5))
                player.currentTime = start
            }

            player.play()
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

extension AlarmAudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Reset preview state so the UI stops showing a sound as "playing".
        previewingSound = nil
    }
}
