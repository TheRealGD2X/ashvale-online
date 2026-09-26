"""Synthesised sound effects for Ashvale (our own, no licences needed).
Writes 44.1 kHz 16-bit mono WAVs to godot/assets/sfx/.   python3 art/sfx.py

The palette is 'cozy fantasy': soft transients, warm low end, bell-like chimes for magic,
wooden and leathery thuds for weapons, nothing harsh or metallic-shrill.
"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "godot", "assets", "sfx")
rng = np.random.default_rng(7)


def t(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.005, d=0.2, shape=4.0):
    """attack then exponential decay over n samples"""
    x = np.arange(n) / SR
    e = np.minimum(x / max(a, 1e-4), 1.0) * np.exp(-np.maximum(x - a, 0) * shape / max(d, 1e-3))
    return e


def adsr(n, a, peak_at, release):
    x = np.linspace(0, 1, n)
    e = np.where(x < peak_at, x / peak_at, 1.0)
    e *= np.clip((1 - x) / release, 0, 1)
    return e


def noise(n):
    return rng.standard_normal(n)


def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), hi / (SR / 2)], "band")
    return signal.lfilter(b, a, x)


def lp(x, f, order=2):
    b, a = signal.butter(order, f / (SR / 2), "low")
    return signal.lfilter(b, a, x)


def hp(x, f, order=2):
    b, a = signal.butter(order, f / (SR / 2), "high")
    return signal.lfilter(b, a, x)


def sweep_filter(x, f0, f1, q=2.0):
    """band-pass whose centre glides from f0 to f1 (processed in blocks)"""
    out = np.zeros_like(x)
    blk = 256
    n = len(x)
    zi = None
    for i in range(0, n, blk):
        k = i / max(n - 1, 1)
        fc = f0 * (f1 / f0) ** k
        bw = fc / q
        lo, hi = max(40, fc - bw / 2), min(SR / 2 - 100, fc + bw / 2)
        b, a = signal.butter(2, [lo / (SR / 2), hi / (SR / 2)], "band")
        if zi is None or len(zi) != max(len(a), len(b)) - 1:
            zi = np.zeros(max(len(a), len(b)) - 1)
        out[i:i + blk], zi = signal.lfilter(b, a, x[i:i + blk], zi=zi)
    return out


def bell(f, d, decay=1.6, partials=((1, 1.0), (2.76, 0.4), (5.4, 0.2), (8.9, 0.08))):
    x = t(d)
    s = np.zeros_like(x)
    for m, g in partials:
        s += g * np.sin(2 * np.pi * f * m * x) * np.exp(-x * decay * (1 + m * 0.35))
    return s * np.minimum(x / 0.002, 1)


def pluck(f, d, bright=0.5):
    """Karplus-Strong-ish harp pluck"""
    n = int(SR * d)
    p = int(SR / f)
    buf = rng.uniform(-1, 1, p) * bright + np.sin(np.linspace(0, 2 * np.pi, p)) * (1 - bright)
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % p]
        buf[i % p] = 0.5 * (buf[i % p] + buf[(i + 1) % p]) * 0.996
    return out


def mix(*parts, length=None):
    L = length or max(len(p) for p, _ in parts)
    out = np.zeros(L)
    for p, off in parts:
        o = int(off * SR)
        if o >= L:
            continue
        seg = p[: L - o]
        out[o:o + len(seg)] += seg
    return out


def reverb(x, amount=0.25, room=0.6):
    """cheap feedback-delay reverb for a cozy room tail"""
    tail = np.zeros(len(x) + int(SR * room * 1.5))
    tail[: len(x)] = x
    out = tail.copy()
    for dl, g in ((0.0297, 0.75), (0.0371, 0.7), (0.0411, 0.66), (0.0437, 0.62)):
        d = int(dl * SR * (0.6 + room))
        y = np.zeros_like(tail)
        for i in range(0, len(tail), d):
            seg = tail[i:i + d]
            y[i:i + len(seg)] += seg
            if i + d < len(tail):
                tail_part = y[i:i + len(seg)] * g
                end = min(len(tail), i + d + len(tail_part))
                y[i + d:end] += tail_part[: end - i - d]
        out += lp(y, 5000) * amount * 0.25
    return out


def save(name, x, gain=0.85):
    x = np.asarray(x, dtype=np.float64)
    x = x - np.mean(x[: min(len(x), 2000)]) * 0  # keep DC out of the way
    x = hp(x, 30, 1)
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * gain
    # fade the last 20 ms
    f = min(len(x), int(0.02 * SR))
    x[-f:] *= np.linspace(1, 0, f)
    os.makedirs(OUT, exist_ok=True)
    wavfile.write(os.path.join(OUT, name + ".wav"), SR, (x * 32767).astype(np.int16))
    print(name, f"{len(x) / SR:.2f}s")


# ----------------------------------------------------------------- weapons

def swing(i):
    d = 0.32 + 0.04 * i
    n = int(SR * d)
    x = sweep_filter(noise(n), 500 + 150 * i, 2600 + 300 * i, q=1.6)
    return x * adsr(n, 0.001, 0.45, 0.55) ** 1.5


def hit(i, heavy=False):
    d = 0.4
    x = t(d)
    f0 = (130 if heavy else 170) - 12 * i
    body = np.sin(2 * np.pi * f0 * x * np.exp(-x * 9)) * np.exp(-x * (10 if heavy else 16))
    thud = lp(noise(len(x)), 900) * np.exp(-x * 28) * 1.2
    slap = bp(noise(len(x)), 1500, 4500) * np.exp(-x * 60) * 0.6
    return body + thud + slap


def crit():
    return mix((hit(0, True) * 1.3, 0), (swing(2) * 0.5, 0), (bell(620, 0.6, 5) * 0.25, 0.01))


def thunder_clap():
    x = t(1.6)
    boom = lp(noise(len(x)), 180, 4) * np.exp(-x * 3.2) * 3
    sub = np.sin(2 * np.pi * 55 * x * np.exp(-x * 2)) * np.exp(-x * 4) * 1.5
    crack = bp(noise(len(x)), 1200, 6000) * np.exp(-x * 25) * 0.8
    rumble = lp(noise(len(x)), 90) * np.exp(-x * 1.8) * 2
    return reverb(boom + sub + crack + rumble, 0.35, 0.8)


def charge():
    d = 0.7
    n = int(SR * d)
    rush = sweep_filter(noise(n), 300, 1800, 1.3) * adsr(n, 0.001, 0.7, 0.3)
    steps = np.zeros(n)
    for k in range(4):
        o = int(SR * (0.05 + k * 0.12))
        seg = hit(2, True)[: 4000] * 0.4
        steps[o:o + len(seg)] += seg[: n - o]
    return rush + steps


def shout():
    x = t(1.0)
    horn = sum(np.sin(2 * np.pi * f * x) * g for f, g in ((196, 1), (294, 0.6), (392, 0.4), (588, 0.15)))
    horn = lp(np.tanh(horn * 1.5), 2200) * adsr(len(x), 0.08, 0.2, 0.5)
    return reverb(horn, 0.4, 1.0)


# ----------------------------------------------------------------- magic

def fire_launch():
    d = 0.9
    n = int(SR * d)
    whoosh = sweep_filter(noise(n), 250, 900, 1.2) * adsr(n, 0.02, 0.25, 0.8) * 1.4
    roar = lp(noise(n), 400) * adsr(n, 0.01, 0.2, 0.9) * 0.9
    crackle = np.zeros(n)
    for k in range(40):
        o = rng.integers(0, n - 800)
        crackle[o:o + 800] += bp(noise(800), 2000, 7000) * np.exp(-np.arange(800) / 90) * rng.uniform(0.2, 0.6)
    return whoosh + roar + crackle * adsr(n, 0.01, 0.2, 0.8)


def fire_impact():
    x = t(1.4)
    boom = lp(noise(len(x)), 350, 3) * np.exp(-x * 4.5) * 2.5
    sub = np.sin(2 * np.pi * 70 * x * np.exp(-x * 3)) * np.exp(-x * 6) * 1.2
    crackle = np.zeros(len(x))
    for k in range(70):
        o = rng.integers(0, int(len(x) * 0.8))
        crackle[o:o + 900] += bp(noise(900), 1800, 8000) * np.exp(-np.arange(900) / 80) * rng.uniform(0.1, 0.5) * np.exp(-o / SR * 2)
    return reverb(boom + sub + crackle, 0.3, 0.7)


def frost_launch():
    d = 0.8
    x = t(d)
    air = sweep_filter(noise(len(x)), 2500, 7000, 2.0) * adsr(len(x), 0.02, 0.3, 0.7)
    shimmer = sum(np.sin(2 * np.pi * f * x + rng.uniform(0, 6)) for f in (1760, 2217, 2637, 3520)) * 0.15 * adsr(len(x), 0.02, 0.2, 0.8)
    return air + shimmer


def ice_shatter():
    x = t(1.2)
    s = np.zeros(len(x))
    for k in range(45):
        f = rng.uniform(2200, 7000)
        o = rng.uniform(0, 0.25)
        s += np.roll(np.sin(2 * np.pi * f * x) * np.exp(-x * rng.uniform(25, 60)), int(o * SR)) * rng.uniform(0.2, 0.6)
    crack = hp(noise(len(x)), 2500) * np.exp(-x * 30) * 0.8
    thump = lp(noise(len(x)), 300) * np.exp(-x * 14)
    return reverb(s + crack + thump, 0.35, 0.6)


def frost_nova():
    return mix((ice_shatter() * 0.9, 0.05), (sweep_filter(noise(int(SR * 0.9)), 4000, 900, 1.5) * adsr(int(SR * 0.9), 0.01, 0.2, 0.8), 0))


def arcane():
    x = t(0.6)
    s = sum(np.sin(2 * np.pi * f * x * (1 + 0.02 * np.sin(2 * np.pi * 7 * x))) for f in (880, 1320, 1760)) * 0.3
    return s * adsr(len(x), 0.01, 0.1, 0.9) + sweep_filter(noise(len(x)), 1500, 4000, 2) * adsr(len(x), 0.01, 0.2, 0.8) * 0.5


def holy_smite():
    notes = [523.25, 659.25, 783.99, 1046.5]
    s = mix(*[(bell(f, 2.2, 1.4) * (1 - i * 0.12), i * 0.035) for i, f in enumerate(notes)])
    whoosh = sweep_filter(noise(int(SR * 0.5)), 3000, 600, 1.5) * adsr(int(SR * 0.5), 0.002, 0.1, 0.9) * 0.6
    return reverb(mix((s, 0), (whoosh, 0)), 0.5, 1.2)


def heal():
    notes = [392.0, 493.88, 587.33, 783.99, 987.77]
    s = mix(*[(pluck(f, 1.8, 0.35) * 0.9, i * 0.07) for i, f in enumerate(notes)])
    pad = sum(np.sin(2 * np.pi * f * t(2.0)) for f in (392.0, 587.33)) * adsr(int(SR * 2.0), 0.3, 0.4, 0.6) * 0.15
    return reverb(mix((s, 0), (pad, 0)), 0.55, 1.3)


def shield():
    x = t(1.4)
    hum = sum(np.sin(2 * np.pi * f * x * (1 + 0.15 * x)) * g for f, g in ((330, 1.0), (495, 0.5), (660, 0.3)))
    return reverb(hum * adsr(len(x), 0.15, 0.3, 0.7) + bell(1318.5, 1.4, 2.2) * 0.3, 0.5, 1.0)


def shadow():
    x = t(1.3)
    low = lp(noise(len(x)), 250) * adsr(len(x), 0.1, 0.35, 0.6) * 1.5
    moan = np.sin(2 * np.pi * 110 * x * (1 - 0.2 * x)) * adsr(len(x), 0.2, 0.4, 0.6) * 0.5
    whisper = sweep_filter(noise(len(x)), 800, 2500, 3) * adsr(len(x), 0.2, 0.5, 0.5) * 0.5
    return reverb(low + moan + whisper, 0.5, 1.0)


def flamestrike():
    return mix((fire_launch() * 0.7, 0), (fire_impact() * 1.2, 0.15), (thunder_clap() * 0.4, 0.15))


def holy_nova():
    return mix((holy_smite() * 0.8, 0), (sweep_filter(noise(int(SR * 0.8)), 600, 5000, 1.5) * adsr(int(SR * 0.8), 0.01, 0.15, 0.8) * 0.8, 0))


def blink():
    x = t(0.5)
    return sweep_filter(noise(len(x)), 5000, 400, 2) * adsr(len(x), 0.001, 0.1, 0.9) + np.sin(2 * np.pi * 1200 * x * np.exp(-x * 4)) * np.exp(-x * 8) * 0.4


def cast_loop():
    """a soft magical hum that loops while casting"""
    d = 2.0
    x = t(d)
    s = sum(np.sin(2 * np.pi * f * x) * g for f, g in ((220, 0.5), (330, 0.4), (440, 0.25), (660, 0.12)))
    s *= 1 + 0.15 * np.sin(2 * np.pi * 3 * x)
    s += bp(noise(len(x)), 2000, 6000) * 0.08
    return s


def level_up():
    notes = [523.25, 659.25, 783.99, 1046.5, 1318.5, 1567.98]
    s = mix(*[(bell(f, 2.6, 1.0) * 0.8, i * 0.09) for i, f in enumerate(notes)])
    chord = mix(*[(pluck(f, 2.5, 0.3) * 0.5, 0.55) for f in (523.25, 659.25, 783.99)])
    return reverb(mix((s, 0), (chord, 0)), 0.6, 1.4)


def ui_click():
    x = t(0.08)
    return np.sin(2 * np.pi * 1400 * x) * np.exp(-x * 90) + lp(noise(len(x)), 3000) * np.exp(-x * 150) * 0.3


def ui_open():
    x = t(0.35)
    return sweep_filter(noise(len(x)), 400, 2500, 2) * adsr(len(x), 0.005, 0.2, 0.8) * 0.8 + pluck(880, 0.35, 0.2) * 0.3


def step(i):
    x = t(0.18)
    return lp(noise(len(x)), 700 + 150 * i) * np.exp(-x * 40) + bp(noise(len(x)), 2000, 5000) * np.exp(-x * 70) * 0.25


def death():
    x = t(1.2)
    thud = lp(noise(len(x)), 200) * np.exp(-x * 6) * 1.5
    return reverb(thud + np.sin(2 * np.pi * 90 * x * np.exp(-x)) * np.exp(-x * 5), 0.3, 0.7)


# ----------------------------------------------------------------- interface and world

def quest_accept():
    # a warm two-note horn-ish chime
    return reverb(mix((bell(392.0, 1.2, 2.2) * 0.7, 0), (bell(587.33, 1.4, 2.0) * 0.8, 0.12)), 0.4, 0.9)


def quest_done():
    notes = [392.0, 493.88, 587.33, 783.99]
    s = mix(*[(bell(f, 1.8, 1.4) * 0.7, i * 0.11) for i, f in enumerate(notes)])
    return reverb(mix((s, 0), (pluck(196.0, 1.6, 0.3) * 0.5, 0.33)), 0.5, 1.1)


def coins():
    parts = []
    for i in range(7):
        f = rng.uniform(2800, 5200)
        parts.append((bell(f, 0.25, 18, ((1, 1.0), (2.4, 0.5), (3.9, 0.3))) * rng.uniform(0.4, 1.0), i * rng.uniform(0.025, 0.05)))
    return mix(*parts)


def anvil():
    x = t(1.2)
    ring = bell(880, 1.2, 3.0, ((1, 1.0), (2.1, 0.6), (3.3, 0.4), (4.7, 0.2)))
    return mix((ring * 0.6 + lp(noise(len(x)), 1500) * np.exp(-x * 40) * 0.8, 0), (ring * 0.35, 0.35))


def learn():
    notes = [659.25, 783.99, 987.77, 1318.5]
    return reverb(mix(*[(bell(f, 1.5, 1.8) * 0.6, i * 0.07) for i, f in enumerate(notes)]), 0.5, 1.0)


def pickup():
    x = t(0.25)
    return lp(noise(len(x)), 1800) * np.exp(-x * 30) * 0.6 + bell(1200, 0.25, 12) * 0.3


def loot_open():
    x = t(0.4)
    return lp(noise(len(x)), 900) * adsr(len(x), 0.01, 0.15, 0.7) * 0.8 + bp(noise(len(x)), 2000, 4000) * np.exp(-x * 25) * 0.15


def whisper():
    return reverb(mix((bell(1046.5, 0.8, 3.0) * 0.5, 0), (bell(1318.5, 0.8, 3.0) * 0.4, 0.08)), 0.3, 0.6)


def bag():
    x = t(0.3)
    return lp(noise(len(x)), 1200) * adsr(len(x), 0.02, 0.1, 0.8) * 0.7


def page():
    x = t(0.45)
    return sweep_filter(noise(len(x)), 3000, 1200, 1.5) * adsr(len(x), 0.02, 0.3, 0.7) * 0.5


if __name__ == "__main__":
    for i in range(3):
        save(f"swing_{i}", swing(i), 0.55)
        save(f"hit_{i}", hit(i), 0.8)
        save(f"step_{i}", step(i), 0.35)
    save("crit", crit())
    save("thunder_clap", thunder_clap())
    save("charge", charge())
    save("shout", shout(), 0.7)
    save("fire_launch", fire_launch(), 0.75)
    save("fire_impact", fire_impact())
    save("frost_launch", frost_launch(), 0.6)
    save("ice_shatter", ice_shatter(), 0.75)
    save("frost_nova", frost_nova())
    save("arcane", arcane(), 0.6)
    save("holy_smite", holy_smite(), 0.75)
    save("heal", heal(), 0.7)
    save("shield", shield(), 0.6)
    save("shadow", shadow(), 0.7)
    save("flamestrike", flamestrike())
    save("holy_nova", holy_nova(), 0.8)
    save("blink", blink(), 0.6)
    save("cast_loop", cast_loop(), 0.35)
    save("level_up", level_up(), 0.8)
    save("ui_click", ui_click(), 0.4)
    save("ui_open", ui_open(), 0.5)
    save("death", death(), 0.7)
    for n, g in (("quest_accept", 0.6), ("quest_done", 0.7), ("coins", 0.5), ("anvil", 0.55), ("learn", 0.6), ("pickup", 0.5),
                 ("loot_open", 0.45), ("whisper", 0.5), ("bag", 0.4), ("page", 0.4)):
        save(n, globals()[n](), g)
