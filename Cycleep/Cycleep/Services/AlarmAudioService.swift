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

// Plays short, constant-volume sound previews in the foreground so users can
// audition alarm tones from the config sheet
@MainActor
final class AlarmAudioService: NSObject, ObservableObject {
    @Published private(set) var playingSound: AlarmSound?

    private var player: AVAudioPlayer?

    func togglePreview(_ sound: AlarmSound) {
        if playingSound == sound {
            stop()
        } else {
            play(sound)
        }
    }

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
