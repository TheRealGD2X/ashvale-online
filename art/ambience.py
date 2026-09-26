"""Outdoor ambience loops for Ashvale: python3 art/ambience.py -> godot/assets/music/amb_day.wav, amb_night.wav
day: soft wind in the grass and leaves, songbirds near and far.  night: crickets, a distant owl, a breeze."""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "godot", "assets", "music")
rng = np.random.default_rng(5)


def lp(x, f, o=2):
    b, a = signal.butter(o, f / (SR / 2), "low"); return signal.lfilter(b, a, x)


def bp(x, lo, hi, o=2):
    b, a = signal.butter(o, [lo / (SR / 2), hi / (SR / 2)], "band"); return signal.lfilter(b, a, x)


def wind(n, strength=1.0):
    g = np.cumsum(rng.standard_normal(n // 2000 + 2)); g = np.interp(np.arange(n), np.arange(len(g)) * 2000, g)
    g = (g - g.min()) / (np.ptp(g) + 1e-9)
    return bp(rng.standard_normal(n), 150, 900) * (0.3 + 0.7 * g) * 0.25 * strength + bp(rng.standard_normal(n), 2000, 6000) * g * 0.03 * strength


def chirp(f0, f1, d, vib=0.0):
    t = np.arange(int(SR * d)) / SR
    f = np.linspace(f0, f1, len(t)) * (1 + vib * np.sin(2 * np.pi * 30 * t))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / d) ** 2


def song(kind):
    parts = []
    if kind == 0:   # a warbler: a quick run of falling notes
        base = rng.uniform(2800, 4200)
        for i in range(rng.integers(4, 9)):
            parts.append(chirp(base * (1 - i * 0.03), base * (0.92 - i * 0.03), 0.07, 0.02)); parts.append(np.zeros(int(SR * 0.03)))
    elif kind == 1:  # a two-note call
        f = rng.uniform(2200, 3200)
        for _ in range(2):
            parts.append(chirp(f, f * 1.2, 0.18)); parts.append(np.zeros(int(SR * 0.12))); parts.append(chirp(f * 0.8, f * 0.8, 0.25)); parts.append(np.zeros(int(SR * 0.4)))
    else:            # a trill
        f = rng.uniform(3500, 5000)
        for _ in range(rng.integers(8, 16)):
            parts.append(chirp(f, f * 1.1, 0.03)); parts.append(np.zeros(int(SR * 0.02)))
    return np.concatenate(parts)


def place(buf, x, i):
    n = min(len(x), len(buf) - i)
    if n > 0: buf[i:i + n] += x[:n]


def loop_save(name, x):
    # crossfade the end into the start so it loops
    f = int(SR * 2.0)
    x[:f] = x[:f] * np.linspace(0, 1, f) + x[-f:] * np.linspace(1, 0, f)
    x = x[:-f]
    x /= np.max(np.abs(x)) + 1e-9; x *= 0.5
    os.makedirs(OUT, exist_ok=True)
    wavfile.write(os.path.join(OUT, name + ".wav"), SR, (x * 32767).astype(np.int16)); print(name, len(x) / SR)


L = 48
n = SR * L
day = wind(n, 0.8)
for _ in range(34):
    s = song(rng.integers(0, 3)) * rng.uniform(0.08, 0.3)
    place(day, lp(s, 7000), rng.integers(0, n - len(s)))
loop_save("amb_day", day)

night = wind(n, 0.5)
t = np.arange(n) / SR
for f, rate, ph, g in ((4300, 16, 0.0, 0.05), (4700, 19, 1.3, 0.035), (3900, 13, 2.1, 0.03)):
    pulse = (np.sin(2 * np.pi * rate * t + ph) > 0.2).astype(float)
    group = (np.sin(2 * np.pi * 0.45 * t + ph * 2) > -0.3).astype(float)
    night += np.sin(2 * np.pi * f * t) * lp(pulse * group, 300) * g
for k in range(3):
    i = int((6 + k * 15 + rng.uniform(0, 4)) * SR)
    tt = np.arange(int(SR * 0.9)) / SR
    hoot = np.sin(2 * np.pi * 380 * tt * (1 - 0.05 * tt)) * np.sin(np.pi * tt / 0.9) ** 3 * 0.12
    place(night, lp(hoot, 1200), i); place(night, lp(hoot, 1200) * 0.8, i + int(SR * 1.3))
loop_save("amb_night", night)
