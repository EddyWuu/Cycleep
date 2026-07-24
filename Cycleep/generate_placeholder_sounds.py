#!/usr/bin/env python3
"""Generate simple placeholder alarm sounds (mono 16-bit WAV) for Cycleep.

These are royalty-free synthesized tones meant only as stand-ins until real
audio assets are added. Each file is a few seconds long and loops cleanly.
"""

import math
import os
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "Cycleep", "Resources", "Sounds")


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


def envelope(i, total, attack=0.01, release=0.05):
    a = int(total * attack)
    r = int(total * release)
    if i < a:
        return i / a
    if i > total - r:
        return (total - i) / r
    return 1.0


def build(duration, fn):
    total = int(SAMPLE_RATE * duration)
    return [fn(i, total, i / SAMPLE_RATE) for i in range(total)]


# Radar: steady on/off beep at 1000 Hz
def radar(i, total, t):
    beat = int(t * 2) % 2  # 0.5s on, 0.5s off
    env = envelope(i, total)
    return 0.6 * tone(1000, t) * env if beat == 0 else 0.0


# Chimes: three descending bell notes that repeat
def chimes(i, total, t):
    notes = [880, 659, 523]  # A5, E5, C5
    step = t % 1.5
    idx = min(int(step / 0.5), 2)
    local = step - idx * 0.5
    decay = math.exp(-local * 4)
    env = envelope(i, total)
    return 0.5 * tone(notes[idx], t) * decay * env


# Waves: slow low rumble with amplitude swell
def waves(i, total, t):
    swell = 0.5 * (1 + math.sin(2 * math.pi * 0.25 * t))
    base = 0.6 * tone(120, t) + 0.2 * tone(180, t)
    return base * swell * envelope(i, total)


# Birds: quick high chirps
def birds(i, total, t):
    period = 0.4
    local = t % period
    if local < 0.12:
        f = 2200 + 1500 * (local / 0.12)
        return 0.4 * tone(f, t) * envelope(i, total)
    return 0.0


# Beacon: pulsing two-tone alert
def beacon(i, total, t):
    pulse = int(t * 2) % 2
    freq = 780 if pulse == 0 else 620
    gate = 1.0 if (t % 0.5) < 0.35 else 0.0
    return 0.55 * tone(freq, t) * gate * envelope(i, total)


if __name__ == "__main__":
    write_wav("radar.wav", build(4.0, radar))
    write_wav("chimes.wav", build(4.5, chimes))
    write_wav("waves.wav", build(6.0, waves))
    write_wav("birds.wav", build(4.0, birds))
    write_wav("beacon.wav", build(4.0, beacon))
    print("done")
