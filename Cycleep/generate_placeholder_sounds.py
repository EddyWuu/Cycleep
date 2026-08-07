#!/usr/bin/env python3
"""Generate placeholder alarm sounds (mono 16-bit WAV) for Cycleep.

Each sound has a DRAMATIC, SLOW volume ramp baked directly into the audio:
it starts near-silent and rises exponentially to full volume over ~20s, then
sustains. Baking the ramp into the file is the only way to get a gradual
volume increase on the real (locked-screen) alarm, because AlarmKit plays the
sound at a fixed system volume and can't fade it programmatically.
"""

import math
import os
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "Cycleep", "Resources", "Sounds")

DURATION = 28.0      # total length; AlarmKit loops this while ringing
RAMP_TIME = 20.0     # seconds spent rising from quiet to full
MIN_AMP = 0.03       # starting amplitude (~ -30 dB): gentle but audible
MAX_AMP = 1.0        # full amplitude at the end of the ramp


def ramp_gain(t):
    if t >= RAMP_TIME:
        return MAX_AMP
    return MIN_AMP * (MAX_AMP / MIN_AMP) ** (t / RAMP_TIME)


def edge(i, total):
    a = int(SAMPLE_RATE * 0.005)
    r = int(SAMPLE_RATE * 0.15)
    if i < a:
        return i / a
    if i > total - r:
        return (total - i) / r
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
        out.append(fn(t) * ramp_gain(t) * edge(i, total))
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
