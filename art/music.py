"""Cozy background music for Ashvale, composed and synthesised here (no samples, no licences).

    python3 art/music.py            # writes godot/assets/music/<name>.wav (22 kHz mono, seamless loops)

Pieces:
  town    G major, 84 bpm: a lute picking chords, a wooden flute tune, a soft pad, a frame drum
  wilds   D dorian, 72 bpm: harp arpeggios, long pad chords, the flute now and then
  night   A minor, 60 bpm: slow harp, a warm pad, a music-box line high up
Each loops without a seam: the reverb tail of the end is folded back over the beginning.
"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "godot", "assets", "music")
NOTE = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def lp(x, f, order=2):
    b, a = signal.butter(order, f / (SR / 2), "low")
    return signal.lfilter(b, a, x)


def hp(x, f, order=1):
    b, a = signal.butter(order, f / (SR / 2), "high")
    return signal.lfilter(b, a, x)


def pluck(f, d, bright=0.6, decay=2.2):
    """a lute/harp string: decaying harmonics, the high ones fading faster"""
    t = np.arange(int(SR * d)) / SR
    s = np.zeros_like(t)
    for k in range(1, 9):
        if f * k > SR / 2.2:
            break
        s += (bright ** (k - 1)) / k * np.sin(2 * np.pi * f * k * t + k) * np.exp(-t * decay * (1 + 0.45 * k))
    return s * np.minimum(t / 0.004, 1)


def flute(f, d, vib=5.0):
    t = np.arange(int(SR * d)) / SR
    v = 1 + 0.004 * np.sin(2 * np.pi * vib * t) * np.minimum(t / 0.3, 1)
    ph = 2 * np.pi * np.cumsum(f * v) / SR
    s = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.06 * np.sin(3 * ph)
    breath = lp(np.random.default_rng(int(f)).standard_normal(len(t)), 2500) * 0.04
    env = np.minimum(t / 0.07, 1) * np.minimum((d - t) / 0.12, 1)
    return (s + breath) * np.clip(env, 0, 1)


def pad(freqs, d):
    t = np.arange(int(SR * d)) / SR
    s = np.zeros_like(t)
    for f in freqs:
        for det in (-0.12, 0.0, 0.13):
            ph = 2 * np.pi * (f * (1 + det / 100)) * t
            s += signal.sawtooth(ph) * 0.3
    s = lp(s, 900, 2)
    env = np.minimum(t / 1.2, 1) * np.minimum((d - t) / 1.2, 1)
    return s * np.clip(env, 0, 1) / max(1, len(freqs))


def box(f, d):
    t = np.arange(int(SR * d)) / SR
    return (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 4.02 * t) * np.exp(-t * 9)) * np.exp(-t * 3.2) * np.minimum(t / 0.003, 1)


def drum(d=0.5, f=95):
    t = np.arange(int(SR * d)) / SR
    body = np.sin(2 * np.pi * f * t * (1 - 0.25 * t)) * np.exp(-t * 11)
    skin = lp(np.random.default_rng(3).standard_normal(len(t)), 1800) * np.exp(-t * 35) * 0.3
    return body + skin


def place(buf, x, at):
    i = int(at * SR)
    if i >= len(buf):
        return
    n = min(len(x), len(buf) - i)
    buf[i:i + n] += x[:n]


def reverb(x, amount=0.3, size=1.0):
    ir_len = int(SR * 2.2 * size)
    t = np.arange(ir_len) / SR
    rng = np.random.default_rng(11)
    ir = rng.standard_normal(ir_len) * np.exp(-t * 3.2 / size)
    ir = lp(ir, 3500)
    ir /= np.sqrt(np.sum(ir ** 2))
    wet = signal.fftconvolve(x, ir)
    out = np.zeros(len(wet))
    out[: len(x)] += x
    out += wet * amount
    return out


def chord_notes(root, kind):
    iv = {"maj": (0, 4, 7), "min": (0, 3, 7), "sus": (0, 5, 7), "maj7": (0, 4, 7, 11), "min7": (0, 3, 7, 10), "add9": (0, 4, 7, 14)}[kind]
    return [root + i for i in iv]


def compose(name, key_root, scale, prog, bpm, bars_per_chord, seed, parts):
    rng = np.random.default_rng(seed)
    beat = 60 / bpm
    bar = beat * 4 if name != "wilds" else beat * 3
    beats_in_bar = 4 if name != "wilds" else 3
    total = bar * bars_per_chord * len(prog)
    buf = np.zeros(int(SR * (total + 0.01)))
    lute = np.zeros_like(buf); fl = np.zeros_like(buf); pd = np.zeros_like(buf); dr = np.zeros_like(buf); mb = np.zeros_like(buf)
    scale_notes = [key_root + s + o for o in (0, 12, 24) for s in scale]
    last = key_root + 12 + scale[2]
    for ci, (deg, kind) in enumerate(prog):
        root = key_root + scale[deg] - 12
        ch = chord_notes(root, kind)
        t0 = ci * bars_per_chord * bar
        if "pad" in parts:
            place(pd, pad([hz(n + 12) for n in ch[:3]], bars_per_chord * bar + 0.8), max(0, t0 - 0.2))
        for b in range(bars_per_chord):
            tb = t0 + b * bar
            # picking / arpeggio
            if "lute" in parts or "harp" in parts:
                pattern = [0, 2, 1, 2, 0, 2, 1, 3] if beats_in_bar == 4 else [0, 1, 2, 3, 2, 1]
                step = bar / len(pattern)
                for i, pi in enumerate(pattern):
                    n = (ch + [ch[0] + 12])[pi % (len(ch) + 1)] + 12
                    if i == 0:
                        n = root
                    place(lute, pluck(hz(n), 2.2 if "harp" in parts else 1.4, 0.5 if "harp" in parts else 0.7) * (0.9 if i == 0 else 0.55) * rng.uniform(0.85, 1.0),
                          tb + i * step + rng.uniform(0, 0.012))
            if "drum" in parts:
                for i in range(beats_in_bar):
                    if i == 0 or (i == 2 and rng.random() < 0.8):
                        place(dr, drum(0.6, 90 if i == 0 else 120) * (0.8 if i == 0 else 0.45), tb + i * beat)
            if "box" in parts and rng.random() < 0.6:
                n = rng.choice(ch) + 24 + 12
                place(mb, box(hz(n), 2.0) * 0.35, tb + rng.choice([0, 1, 2]) * beat)
        # a tune over the chord: stepwise, leaning on chord tones, resting sometimes
        if "flute" in parts and (ci % 2 == 0 or name == "town"):
            t = t0
            end = t0 + bars_per_chord * bar
            while t < end - beat * 0.5:
                dur = rng.choice([1, 1, 2, 0.5, 0.5, 3]) * beat
                if rng.random() < 0.18:
                    t += dur; continue
                cands = [n for n in scale_notes if abs(n - last) <= 4 and n >= key_root + 7 and n <= key_root + 28]
                tones = [n for n in cands if (n - root) % 12 in [(c - root) % 12 for c in ch]]
                n = rng.choice(tones if tones and rng.random() < 0.65 else cands) if cands else last
                place(fl, flute(hz(n), min(dur * 0.95, end - t)) * 0.33, t)
                last = n; t += dur
    mix = lute * 0.55 + fl * 0.5 + pd * 0.5 + dr * 0.35 + mb * 0.3
    mix = hp(mix, 60)
    wet = reverb(mix, 0.35, 1.2)
    # fold the tail over the start so the loop is seamless
    n = len(buf)
    out = wet[:n].copy()
    out[: len(wet) - n] += wet[n:]
    out /= np.max(np.abs(out)) + 1e-9
    out *= 0.6
    os.makedirs(OUT, exist_ok=True)
    wavfile.write(os.path.join(OUT, name + ".wav"), SR, (out * 32767).astype(np.int16))
    print(name, "%.1fs" % (n / SR))


MAJ = [0, 2, 4, 5, 7, 9, 11]
DOR = [0, 2, 3, 5, 7, 9, 10]
MIN = [0, 2, 3, 5, 7, 8, 10]

if __name__ == "__main__":
    # town: I  vi  IV  V | I  iii  IV  I ...
    compose("town", 55, MAJ, [(0, "maj"), (5, "min"), (3, "maj"), (4, "maj"), (0, "add9"), (2, "min"), (3, "maj"), (4, "sus"),
                              (5, "min"), (3, "maj"), (0, "maj"), (4, "maj"), (3, "maj7"), (4, "maj"), (0, "maj"), (0, "maj")], 84, 2, 5,
            ["lute", "flute", "pad", "drum"])
    compose("wilds", 50, DOR, [(0, "min7"), (3, "maj"), (0, "min"), (6, "maj"), (0, "min7"), (4, "min"), (3, "maj"), (0, "sus"),
                               (2, "maj"), (3, "maj"), (0, "min"), (6, "maj")], 72, 2, 9, ["harp", "flute", "pad"])
    compose("night", 57, MIN, [(0, "min"), (5, "maj"), (2, "maj"), (6, "maj"), (0, "min"), (3, "min"), (5, "maj7"), (4, "min"),
                               (0, "min"), (5, "maj"), (3, "min"), (4, "sus")], 60, 2, 13, ["harp", "pad", "box"])
