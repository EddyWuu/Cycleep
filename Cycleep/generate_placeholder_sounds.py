#!/usr/bin/env python3
"""Generate placeholder alarm sounds for Cycleep.

Two variants are written per sound:

  * ``<name>.caf`` — the ALARM file (IMA4-compressed CAF). It opens with a short
    stretch of true silence, then a 60s exponential ramp from ~silent to full,
    then a LONG full-volume sustain. AlarmKit loops this whole file while
    ringing, so the long loud tail means the sleeper hears the quiet ramp only
    once at the very start — after that it stays loud (the loop back to the ramp
    is minutes away). Baking the ramp in is the only way to get a gradual
    wake-up, because Cycleep plays alarms with AlarmKit (fixed system volume,
    can't fade programmatically). The file is compressed to IMA4 CAF (~4:1) so
    the long duration stays small; iOS alarm sounds support IMA4 CAF.

  * ``<name>_preview.wav`` — the PREVIEW file. A short, CONSTANT full-volume clip
    used only for the in-app "tap to audition" preview in the config sheet. No
    ramp: a preview is a quick showcase, not a wake-up.

These are synthesized placeholders — Apple's own ringtones are copyrighted and
can't be bundled. Drop real assets in (same names, ramp baked into the alarm
variant) to replace them.
"""

import array
import math
import os
import struct
import subprocess
import wave

SAMPLE_RATE = 22050          # plenty for alarm tones; keeps ramp files small
OUT_DIR = os.path.join(os.path.dirname(__file__), "Cycleep", "Resources", "Sounds")

# Alarm file layout (AlarmKit loops this while ringing):
#   [SILENCE_INTRO] true digital silence, so any buffer priming / volume
#                   normalization iOS applies to the FIRST alert lands on
#                   silence instead of making the fade-in start loud.
#   [RAMP_TIME]     exponential rise from ~silent to full — the ONE gentle
#                   wake-up ramp the sleeper hears.
#   [SUSTAIN]       a long stretch held at full volume. Because AlarmKit loops
#                   the whole file, a long loud tail means the quiet ramp is
#                   only ever hit once at the very start; after that it just
#                   stays loud (the loop back to the ramp is minutes away).
# The finished WAV is converted to IMA4-compressed CAF so the long file stays
# small (~4:1). iOS alarm sounds support IMA4 CAF.
SILENCE_INTRO = 2.0          # seconds of true silence at the very start
RAMP_TIME = 60.0             # seconds spent rising from silent to full
SUSTAIN = 180.0              # seconds held at full volume before it could loop
ALARM_DURATION = SILENCE_INTRO + RAMP_TIME + SUSTAIN
PREVIEW_DURATION = 4.0       # short showcase clip
MIN_AMP = 0.002              # starting amplitude (~ -54 dB): effectively silent
MAX_AMP = 1.0                # full amplitude at the end of the ramp


def ramp_gain(t):
    # True silence during the intro.
    if t < SILENCE_INTRO:
        return 0.0
    r = t - SILENCE_INTRO
    if r >= RAMP_TIME:
        return MAX_AMP
    return MIN_AMP * (MAX_AMP / MIN_AMP) ** (r / RAMP_TIME)


def edge(i, total):
    # Short attack, longer release to avoid clicks at file/loop boundaries.
    a = int(SAMPLE_RATE * 0.005)
    r = int(SAMPLE_RATE * 0.15)
    if i < a:
        return i / a
    if i > total - r:
        return (total - i) / r
    return 1.0


def write_wav(path, samples):
    """Write 16-bit mono PCM WAV. `samples` is an array('h') of int16."""
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(samples.tobytes())


def tone(freq, t):
    return math.sin(2 * math.pi * freq * t)


def build(fn, duration, ramped):
    """Render the sound to an array('h') of clamped int16 samples."""
    total = int(SAMPLE_RATE * duration)
    out = array.array("h", bytes(2 * total))  # preallocate
    for i in range(total):
        t = i / SAMPLE_RATE
        gain = ramp_gain(t) if ramped else MAX_AMP
        v = fn(t) * gain * edge(i, total)
        if v > 1.0:
            v = 1.0
        elif v < -1.0:
            v = -1.0
        out[i] = int(v * 32767)
    return out


# --- Sound definitions (t in seconds -> amplitude roughly in [-1, 1]) ---------

def radar(t):
    return 0.9 * tone(1000, t) if int(t * 2) % 2 == 0 else 0.0


def beacon(t):
    freq = 780 if int(t * 2) % 2 == 0 else 620
    gate = 1.0 if (t % 0.5) < 0.35 else 0.0
    return 0.9 * tone(freq, t) * gate


def signal(t):
    segs = [(0.12, True), (0.1, False), (0.12, True), (0.1, False),
            (0.32, True), (0.5, False)]
    period = sum(d for d, _ in segs)
    x = t % period
    acc = 0.0
    for d, on in segs:
        if x < acc + d:
            return 0.85 * tone(760, t) if on else 0.0
        acc += d
    return 0.0


def circuit(t):
    notes = [523, 659, 784, 988]
    period = 0.12
    idx = int(t / period) % len(notes)
    local = t % period
    f = notes[idx]
    return 0.55 * (tone(f, t) + 0.3 * tone(2 * f, t)) * math.exp(-local * 8)


def digital(t):
    seq = t % 1.6
    for start in (0.0, 0.2, 0.4):
        if start <= seq < start + 0.15:
            return 0.85 * tone(1200, t)
    return 0.0


def presto(t):
    local = t % 0.15
    return 0.85 * tone(988, t) if local < 0.08 else 0.0


def bulletin(t):
    notes = [523, 659, 784]
    seq = t % 1.5
    idx = min(int(seq / 0.5), 2)
    local = seq - idx * 0.5
    return 0.8 * tone(notes[idx], t) * math.exp(-local * 6)


def chimes(t):
    notes = [880, 659, 523]
    step = t % 1.5
    idx = min(int(step / 0.5), 2)
    local = step - idx * 0.5
    return 0.85 * tone(notes[idx], t) * math.exp(-local * 4)


def crystals(t):
    notes = [1568, 2093, 1760]
    period = 0.35
    idx = int(t / period) % len(notes)
    local = t % period
    f = notes[idx]
    return 0.55 * (tone(f, t) + 0.4 * tone(2 * f, t)) * math.exp(-local * 7)


def twinkle(t):
    notes = [1046, 1318, 1568, 2093, 1760, 1318]
    period = 0.3
    idx = int(t / period) % len(notes)
    local = t % period
    return 0.55 * tone(notes[idx], t) * math.exp(-local * 9)


def xylophone(t):
    notes = [784, 880, 988, 1046]
    period = 0.22
    idx = int(t / period) % len(notes)
    local = t % period
    f = notes[idx]
    return 0.5 * (tone(f, t) + 0.5 * tone(2 * f, t) + 0.25 * tone(3 * f, t)) * math.exp(-local * 12)


def uplift(t):
    notes = [392, 523, 659, 784, 988]
    period = 0.18
    idx = int(t / period) % len(notes)
    local = t % period
    return 0.7 * tone(notes[idx], t) * math.exp(-local * 5)


def waves(t):
    swell = 0.5 * (1 + math.sin(2 * math.pi * 0.25 * t))
    return (0.6 * tone(120, t) + 0.3 * tone(180, t)) * swell


def birds(t):
    local = t % 0.4
    if local < 0.12:
        return 0.8 * tone(2200 + 1500 * (local / 0.12), t)
    return 0.0


def cosmic(t):
    lfo = 0.5 * (1 + math.sin(2 * math.pi * 0.15 * t))
    base = tone(220, t) + tone(222.2, t) + 0.5 * tone(330, t)
    return 0.3 * base * (0.5 + 0.5 * lfo)


def pulse(t):
    period = 0.9
    local = t % period

    def thump(x):
        return math.exp(-x * 25) * tone(90, t) if 0 <= x < 0.12 else 0.0

    return 0.9 * (thump(local) + thump(local - 0.18))


SOUNDS = [
    ("radar", radar),
    ("beacon", beacon),
    ("signal", signal),
    ("circuit", circuit),
    ("digital", digital),
    ("presto", presto),
    ("bulletin", bulletin),
    ("chimes", chimes),
    ("crystals", crystals),
    ("twinkle", twinkle),
    ("xylophone", xylophone),
    ("uplift", uplift),
    ("waves", waves),
    ("birds", birds),
    ("cosmic", cosmic),
    ("pulse", pulse),
]


def convert_to_caf(wav_path, caf_path):
    """Compress a WAV to IMA4 CAF (supported by iOS alarm sounds, ~4:1)."""
    subprocess.run(
        ["afconvert", "-f", "caff", "-d", "ima4", wav_path, caf_path],
        check=True,
    )


if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, fn in SOUNDS:
        # Alarm file: long ramp+sustain rendered to WAV, then compressed to CAF.
        wav_tmp = os.path.join(OUT_DIR, f"{name}.wav")
        caf_out = os.path.join(OUT_DIR, f"{name}.caf")
        write_wav(wav_tmp, build(fn, ALARM_DURATION, ramped=True))
        convert_to_caf(wav_tmp, caf_out)
        os.remove(wav_tmp)  # keep only the compressed alarm file
        print(f"wrote {name}.caf ({ALARM_DURATION:.0f}s, "
              f"{os.path.getsize(caf_out) // 1024} KB)")

        # Preview file: short, constant-volume WAV played in-app by AVAudioPlayer.
        preview = os.path.join(OUT_DIR, f"{name}_preview.wav")
        write_wav(preview, build(fn, PREVIEW_DURATION, ramped=False))

    print(f"done — {len(SOUNDS)} sounds ({len(SOUNDS) * 2} files)")
