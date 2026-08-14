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
/// The gradual volume ramp is applied **programmatically here** by fading the
/// player's volume from barely audible up to full over `rampDuration`. This
/// only runs while the app is alive. When the app is closed, AlarmKit plays the
/// same (constant-volume) file at the fixed system volume with no ramp — that's
/// the intended backup behaviour (see `AlarmKitService`).
final class AlarmAudioService: NSObject, ObservableObject {
    /// Sound currently being previewed, if any (used to toggle play/stop in UI).
    @Published private(set) var previewingSound: AlarmSound?

    private var player: AVAudioPlayer?
    private var previewStopTimer: Timer?
    private var rampTimer: Timer?

    /// How long the programmatic volume ramp takes to go from quiet to full.
    static let rampDuration: TimeInterval = 60

    /// Starting volume for the ramp (~ -44 dB): barely audible.
    private static let rampMinVolume: Float = 0.006

    /// How long a tap-to-hear preview plays before auto-stopping.
    private static let previewDuration: TimeInterval = 6

    // MARK: - Preview

    /// Plays a short, full-volume sample so the user can identify the sound
    /// quickly. Previews never ramp.
    func preview(_ sound: AlarmSound) {
        if previewingSound == sound {
            stop()
            return
        }
        play(sound, rampUp: false, loops: -1)
        previewingSound = sound

        // Auto-stop so the preview stays a brief sample.
        previewStopTimer?.invalidate()
        previewStopTimer = Timer.scheduledTimer(withTimeInterval: Self.previewDuration,
                                                repeats: false) { [weak self] _ in
            self?.stop()
        }
    }

    /// Plays the full ramp-up fade (barely audible → max over `rampDuration`) so
    /// the gradual wake experience can be heard on demand, then auto-stops.
    func previewRamp(_ sound: AlarmSound) {
        play(sound, rampUp: true, loops: -1)
        previewingSound = sound
        previewStopTimer?.invalidate()
        previewStopTimer = Timer.scheduledTimer(withTimeInterval: Self.rampDuration + 3,
                                                repeats: false) { [weak self] _ in
            self?.stop()
        }
    }

    // MARK: - Playback

    /// Starts playing `sound`.
    /// - Parameters:
    ///   - rampUp: when `true`, the volume fades in from barely audible to full
    ///     over `rampDuration`; when `false`, it plays at full volume immediately.
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
            player.volume = rampUp ? Self.rampMinVolume : 1
            player.prepareToPlay()
            player.play()
            self.player = player

            if rampUp {
                startVolumeRamp()
            }
        } catch {
            print("AlarmAudioService: failed to play \(sound.displayName): \(error)")
        }
    }

    func stop() {
        rampTimer?.invalidate()
        rampTimer = nil
        previewStopTimer?.invalidate()
        previewStopTimer = nil
        player?.stop()
        player = nil
        previewingSound = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Helpers

    /// Fades the player volume exponentially from `rampMinVolume` to full over
    /// `rampDuration` using a repeating timer (barely audible → max).
    private func startVolumeRamp() {
        let start = Date()
        let minVol = Self.rampMinVolume
        let duration = Self.rampDuration
        rampTimer?.invalidate()
        rampTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self, let player = self.player else {
                timer.invalidate()
                return
            }
            let elapsed = Date().timeIntervalSince(start)
            if elapsed >= duration {
                player.volume = 1
                timer.invalidate()
                return
            }
            // Exponential curve for a natural "barely audible → loud" swell.
            let fraction = Float(elapsed / duration)
            player.volume = minVol * pow(1 / minVol, fraction)
        }
    }

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
