#!/usr/bin/env python3
"""Generate placeholder alarm sounds (mono 16-bit WAV) for Cycleep.

These are short, constant-volume loops. The volume ramp is NOT baked in — it
is applied at playback time by AVAudioPlayer while the app is running. When the
app is closed, AlarmKit plays these at the fixed system volume (no ramp), which
is the intended backup behaviour.
"""

import math
import os
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "Cycleep", "Resources", "Sounds")

DURATION = 6.0       # short loop; AlarmKit and AVAudioPlayer repeat it while ringing


def edge(i, total):
    # Tiny 5ms attack/release only, to avoid clicks. No long fades — volume is
    # constant so AVAudioPlayer can ramp it programmatically.
    a = int(SAMPLE_RATE * 0.005)
    if i < a:
        return i / a
    if i > total - a:
        return (total - i) / a
    return 1.0


def write_wav(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(v * 32767))
        w.writeframes(bytes(frames))
    print("wrote", path, f"({len(samples)/SAMPLE_RATE:.1f}s)")


def tone(freq, t):
    return math.sin(2 * math.pi * freq * t)


def build(fn):
    total = int(SAMPLE_RATE * DURATION)
    out = []
    for i in range(total):
        t = i / SAMPLE_RATE
        out.append(fn(t) * edge(i, total))
    return out


def radar(t):
    beat = int(t * 2) % 2
    return 0.9 * tone(1000, t) if beat == 0 else 0.0


def chimes(t):
    notes = [880, 659, 523]
    step = t % 1.5
    idx = min(int(step / 0.5), 2)
    local = step - idx * 0.5
    decay = math.exp(-local * 4)
    return 0.85 * tone(notes[idx], t) * decay


def waves(t):
    swell = 0.5 * (1 + math.sin(2 * math.pi * 0.25 * t))
    base = 0.6 * tone(120, t) + 0.3 * tone(180, t)
    return base * swell


def birds(t):
    period = 0.4
    local = t % period
    if local < 0.12:
        f = 2200 + 1500 * (local / 0.12)
        return 0.8 * tone(f, t)
    return 0.0


def beacon(t):
    pulse = int(t * 2) % 2
    freq = 780 if pulse == 0 else 620
    gate = 1.0 if (t % 0.5) < 0.35 else 0.0
    return 0.9 * tone(freq, t) * gate


if __name__ == "__main__":
    write_wav("radar.wav", build(radar))
    write_wav("chimes.wav", build(chimes))
    write_wav("waves.wav", build(waves))
    write_wav("birds.wav", build(birds))
    write_wav("beacon.wav", build(beacon))
    print("done")
