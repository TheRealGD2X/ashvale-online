"""
Icons for monster spells and for the buffs and debuffs that aren't player abilities (silenced, entangled,
enraged, eating...), painted like the spell icons (art/spell_icons.py).
    python3 art/buff_icons.py [names...]
Writes godot/assets/icons/<id>.png.
"""
import sys, os, math
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import paint as P
from paint import *
from spell_icons import comet, burst, shard, sparks, rune_circle, save, N, GOLD, BLOOD, OUT

SEA = [(0.0, (0, 0, 0)), (0.25, hexc('#032a30')), (0.5, hexc('#108a90')), (0.75, hexc('#60e0d0', 1.6)), (1.0, hexc('#f0fffc', 3.5))]
BOG = [(0.0, (0, 0, 0)), (0.3, hexc('#0a2006')), (0.6, hexc('#5aa020', 1.3)), (0.85, hexc('#d0ff60', 2.2)), (1.0, hexc('#ffffe0', 3.5))]
EARTH = [(0.0, (0, 0, 0)), (0.3, hexc('#2a1a0a')), (0.6, hexc('#a06a30', 1.2)), (0.85, hexc('#ffc080', 2.0)), (1.0, hexc('#fff0d8', 3.0))]
ITEMS = os.path.join(os.path.dirname(os.path.abspath(__file__)), '_items')

def bolt(name, bg, palette, seed, heat=0.8, head=(0.64, 0.36), r=0.15, core='#fff4d0', extra=None):
    c = Canvas(N); background(c, bg[0], bg[1], seed=seed, center=(0.58, 0.42))
    comet(c, head, (0.1, 0.9), r, 0.02, palette, seed + 1, heat=heat, lick=0.12)
    comet(c, head, (0.28, 0.82), r * 0.7, 0.015, palette, seed + 2, heat=heat * 1.05, lick=0.06)
    glow_ball(c, head, r * 0.4, hexc(core), 1.1)
    if extra: extra(c)
    save(c, name)

def nova(name, bg, palette, seed, shards_col=None, heat=0.85):
    c = Canvas(N); background(c, bg[0], bg[1], seed=seed, center=(0.5, 0.55))
    ring(c, (0.5, 0.55), 0.32, 0.035, palette, seed=seed + 1, heat=heat, wobble=0.05)
    ring(c, (0.5, 0.55), 0.2, 0.02, palette, seed=seed + 2, heat=heat * 0.8, wobble=0.04)
    burst(c, (0.5, 0.55), 0.1, palette, seed + 3, heat=heat, spikes=16, spike_len=0.22)
    if shards_col:
        rng = np.random.default_rng(seed)
        for k in range(9):
            a = k * 2 * math.pi / 9 + rng.normal(0, 0.1)
            L = rng.uniform(0.26, 0.38)
            shard(c, (0.5 + math.cos(a) * L, 0.55 + math.sin(a) * L * 0.8), (0.5 + math.cos(a) * 0.1, 0.55 + math.sin(a) * 0.08), rng.uniform(0.016, 0.026),
                col=hexc(shards_col[0]), emit=hexc(shards_col[1]), emit_k=0.6)
    glow_ball(c, (0.5, 0.55), 0.06, hexc('#ffffff'), 0.8)
    save(c, name)

def claws(c, col, n=3, x0=0.3, y0=0.18, dx=0.14, length=0.62, palette=BLOOD, seed=0):
    for i in range(n):
        a = (x0 + i * dx, y0); b = (x0 + i * dx - 0.12, y0 + length)
        d, t = seg_dist(c, a, b)
        w = 0.028 * np.clip(np.sin(np.clip(t, 0, 1) * math.pi), 0, 1) ** 0.7 + 0.002
        m = smooth(w, w * 0.4, d)
        nz = noise(c.n, 20, seed + i, 4)
        c.glow_add(ramp(m * (0.6 + 0.6 * nz), palette) * m[..., None] * 0.9)
        c.glow_add((np.exp(-(d / (w * 0.4 + 1e-4)) ** 2) * m)[..., None] * np.array(hexc('#fff0e0', 1.2)) * 0.5)

def icon_ember_bolt(): bolt('ember_bolt', ('#4a1c0c', '#0c0403'), FIRE, 300, 0.75, r=0.12)
def icon_bog_bolt(): bolt('bog_bolt', ('#1a3008', '#040801'), BOG, 310, 0.75, core='#f0ffc0')
def icon_brine_bolt(): bolt('brine_bolt', ('#08323a', '#01080a'), SEA, 320, 0.75, core='#e0fffa')
def icon_void_bolt(): bolt('void_bolt', ('#240a34', '#040108'), SHADOW, 330, 0.8, core='#f4e8ff')

def icon_magma_spit():
    def drops(c):
        rng = np.random.default_rng(341)
        for k in range(7):
            x, y = rng.uniform(0.2, 0.8), rng.uniform(0.4, 0.9); r = rng.uniform(0.018, 0.035)
            glow_ball(c, (x, y), r, hexc('#ff8020'), 1.1)
    bolt('magma_spit', ('#3a1406', '#0a0302'), FIRE, 340, 0.6, r=0.17, core='#ffe0a0', extra=drops)

def icon_frost_lance():
    c = Canvas(N); background(c, '#10304a', '#02060a', seed=350, center=(0.6, 0.4))
    comet(c, (0.7, 0.3), (0.08, 0.92), 0.06, 0.01, FROST, 351, heat=0.6, lick=0.05)
    shard(c, (0.86, 0.14), (0.24, 0.76), 0.07, emit_k=0.5)
    shard(c, (0.8, 0.16), (0.52, 0.44), 0.03, emit_k=0.9)
    rng = np.random.default_rng(352)
    dots(c, [(0.1 + rng.uniform(0, 0.5), 0.5 + rng.uniform(0, 0.45), rng.uniform(0.003, 0.007)) for _ in range(24)], hexc('#d8f0ff', 2.0))
    save(c, 'frost_lance')

def icon_glacial_nova(): nova('glacial_nova', ('#10304a', '#02060a'), FROST, 360, ('#9fd8ff', '#60b8ff'))
def icon_void_nova(): nova('void_nova', ('#240a34', '#040108'), SHADOW, 370, ('#6a3aa0', '#a040ff'))
def icon_pyre_nova(): nova('pyre_nova', ('#5a1a08', '#0c0302'), FIRE, 380, None, heat=0.8)
def icon_vaal_nova(): nova('vaal_nova', ('#2a0620', '#060106'), [(0.0, (0, 0, 0)), (0.3, hexc('#2a0420')), (0.6, hexc('#c01860', 1.4)), (0.85, hexc('#ff90e0', 2.4)), (1.0, hexc('#ffffff', 4.0))], 390, ('#4a1a4a', '#ff3090'))
def icon_grub_eruption(): nova('grub_eruption', ('#1a3008', '#040801'), BOG, 400, None, heat=0.8)

def icon_hellfire_ring():
    c = Canvas(N); background(c, '#4a1406', '#0a0201', seed=410, center=(0.5, 0.6))
    for i, (r, w) in enumerate([(0.34, 0.05), (0.3, 0.03)]):
        ring(c, (0.5, 0.58), r, w, FIRE, seed=411 + i, heat=0.9, wobble=0.06)
    for k in range(14):
        a = 2 * math.pi * k / 14
        x, y = 0.5 + math.cos(a) * 0.34, 0.58 + math.sin(a) * 0.34 * 0.55
        comet(c, (x, y - 0.14), (x, y + 0.02), 0.012, 0.035, FIRE, 420 + k, heat=0.8, lick=0.05)
    save(c, 'hellfire_ring')

def icon_colossus_stomp():
    c = Canvas(N); background(c, '#3a2a18', '#080503', seed=430, center=(0.5, 0.65))
    ring(c, (0.5, 0.66), 0.34, 0.03, EARTH, seed=431, heat=0.8, wobble=0.05)
    rng = np.random.default_rng(432)
    for k in range(12):
        a = rng.uniform(0, 2 * math.pi); L = rng.uniform(0.18, 0.36)
        d, t = seg_dist(c, (0.5, 0.66), (0.5 + math.cos(a) * L, 0.66 + math.sin(a) * L * 0.5))
        m = smooth(0.012, 0.0, d + t * 0.006)
        c.glow_add(ramp(m * 0.9, FIRE) * m[..., None] * 0.7)
    for k in range(10):
        x = 0.5 + rng.normal(0, 0.2); y = 0.5 + rng.normal(0, 0.12)
        pts = [(x + math.cos(a) * 0.03, y + math.sin(a) * 0.025) for a in np.linspace(0, 2 * math.pi, 6)[:-1] + rng.uniform(0, 1)]
        shade_poly(c, pts, hexc('#6a5a48'), spec=0.4)
    burst(c, (0.5, 0.66), 0.08, EARTH, 433, heat=0.8, spikes=10, spike_len=0.2)
    save(c, 'colossus_stomp')

def icon_ravage():
    c = Canvas(N); background(c, '#3a0a0a', '#070101', seed=440)
    claws(c, BLOOD, 3, 0.36, 0.14, 0.15, 0.7, BLOOD, 441)
    sparks(c, (0.5, 0.5), 24, 0.3, hexc('#ff6040'), seed=442, k=2.0)
    save(c, 'ravage')

def icon_tidal_slam():
    c = Canvas(N); background(c, '#08323a', '#01080a', seed=450, center=(0.5, 0.6))
    # a curling wave: a thick arc of water, foam along its crest
    arc(c, (0.5, 0.7), 0.32, 160, 340, 0.09, SEA, seed=451, heat=0.8)
    arc(c, (0.58, 0.62), 0.18, 190, 400, 0.05, SEA, seed=452, heat=0.95)
    arc(c, (0.46, 0.76), 0.4, 175, 320, 0.05, SEA, seed=454, heat=0.6)
    rng = np.random.default_rng(453)
    dots(c, [(0.3 + rng.uniform(0, 0.5), 0.3 + rng.uniform(0, 0.2), rng.uniform(0.004, 0.01)) for _ in range(30)], hexc('#e8fffc', 2.0))
    save(c, 'tidal_slam')

def icon_arrow_shot():
    c = Canvas(N); background(c, '#2a2a30', '#050507', seed=460, center=(0.6, 0.4))
    comet(c, (0.66, 0.34), (0.08, 0.92), 0.02, 0.005, [(0.0, (0, 0, 0)), (0.5, hexc('#606878')), (1.0, hexc('#e0e8f0', 1.5))], 461, heat=0.7, lick=0.02)
    P.SPRITES = ITEMS
    sprite(c, 'arrow', (0.5, 0.5), 0.9, angle=0, rim=hexc('#c0d0ff'), rim_k=0.6)
    save(c, 'arrow_shot')

# ------------------------------------------------------------------ auras that aren't abilities
def icon_silenced():
    c = Canvas(N); background(c, '#1e0a2c', '#040108', seed=470)
    rune_circle(c, (0.5, 0.5), 0.36, SHADOW, 471, heat=0.85, ticks=18)
    d, t = seg_dist(c, (0.24, 0.24), (0.76, 0.76))
    m = smooth(0.035, 0.02, d)
    c.glow_add(ramp(m * 0.95, BLOOD) * m[..., None])
    smoke(c, (0.5, 0.52), 0.18, hexc('#2a0a44', 0.9), seed=472, k=0.6)
    save(c, 'silenced')

def vine(c, pts, width, col, seed=0):
    """a thick twisting stem: distance to the polyline, shaded round, with a lit edge"""
    best = np.full(c.x.shape, 9.0, np.float32); tt = np.zeros_like(best)
    for i in range(len(pts) - 1):
        d, t = seg_dist(c, pts[i], pts[i + 1])
        m = d < best; best = np.where(m, d, best); tt = np.where(m, (i + t) / (len(pts) - 1), tt)
    w = width * (1.0 - 0.7 * tt)
    body = smooth(w, w * 0.7, best)
    shade = np.clip(1.0 - best / np.maximum(w, 1e-4), 0, 1) ** 0.5
    nz = noise(c.n, 40, seed, 3, aniso=(1.0, 0.3))
    c.paint((np.asarray(col, np.float32) * (0.35 + 0.8 * shade * (0.7 + 0.5 * nz))[..., None]), body)
    return body

def icon_entangle():
    c = Canvas(N); background(c, '#16300c', '#030702', seed=480, center=(0.5, 0.6))
    rng = np.random.default_rng(481)
    for i in range(5):
        x0 = 0.15 + i * 0.17; pts = []
        for k in range(14):
            t = k / 13
            pts.append((x0 + math.sin(t * 7 + i) * 0.1 * (1 - t * 0.3) + (0.5 - x0) * t * 0.4, 1.02 - t * 0.9))
        vine(c, pts, 0.035, hexc('#3a6a1a'), seed=482 + i)
        for k in range(3):
            j = rng.integers(3, 12); x, y = pts[j]
            S.leaf(c, (x, y), (x + rng.choice([-1, 1]) * rng.uniform(0.08, 0.13), y - rng.uniform(0.02, 0.08)), 0.035, hexc('#5aa030'))
    thorns = [(0.3, 0.4, 0.004), (0.6, 0.3, 0.004), (0.7, 0.6, 0.004)]
    glow_ball(c, (0.5, 0.95), 0.2, hexc('#80ff40'), 0.25)
    save(c, 'entangle')

def rage(name, seed):
    c = Canvas(N); background(c, '#4a0a06', '#080101', seed=seed, center=(0.5, 0.55))
    burst(c, (0.5, 0.55), 0.14, BLOOD, seed + 1, heat=0.9, spikes=18, spike_len=0.3)
    claws(c, BLOOD, 3, 0.4, 0.2, 0.12, 0.56, FIRE, seed + 2)
    glow_ball(c, (0.5, 0.55), 0.05, hexc('#ffe0c0'), 0.9)
    save(c, name)
def icon_enrage(): rage('enrage', 500)
def icon_rootmaw_rage(): rage('rootmaw_rage', 510)
def icon_foremans_fury(): rage('foremans_fury', 520)

def icon_bone_prison():
    c = Canvas(N); background(c, '#1e1a24', '#040306', seed=530)
    smoke(c, (0.5, 0.55), 0.3, hexc('#301a40', 0.8), seed=531, k=0.6)
    for i in range(5):
        x = 0.22 + i * 0.14
        pts = [(x - 0.03, 0.14), (x + 0.03, 0.14), (x + 0.025, 0.88), (x - 0.025, 0.88)]
        shade_poly(c, pts, hexc('#e0d6c0'), spec=0.5)
        for y in (0.14, 0.88):
            shade_poly(c, [(x + math.cos(a) * 0.045, y + math.sin(a) * 0.03) for a in np.linspace(0, 2 * math.pi, 12)[:-1]], hexc('#ece2cc'), spec=0.5)
    shade_poly(c, [(0.14, 0.12), (0.86, 0.12), (0.86, 0.18), (0.14, 0.18)], hexc('#c8bca4'), spec=0.4)
    shade_poly(c, [(0.14, 0.84), (0.86, 0.84), (0.86, 0.9), (0.14, 0.9)], hexc('#c8bca4'), spec=0.4)
    glow_ball(c, (0.5, 0.5), 0.08, hexc('#a060ff'), 0.6)
    save(c, 'bone_prison')

def icon_weakened_soul():
    c = Canvas(N); background(c, '#2a2010', '#060402', seed=540)
    ring(c, (0.5, 0.5), 0.28, 0.03, HOLY, seed=541, heat=0.5, wobble=0.03)
    for (a, b) in [((0.5, 0.2), (0.44, 0.45)), ((0.44, 0.45), (0.56, 0.6)), ((0.56, 0.6), (0.48, 0.82))]:
        d, t = seg_dist(c, a, b)
        m = smooth(0.012, 0.004, d)
        c.paint(hexc('#100404'), m)
        c.glow_add((np.exp(-(d / 0.02) ** 2))[..., None] * np.array(hexc('#c01010', 0.6)))
    save(c, 'weakened_soul')

def icon_crush():
    c = Canvas(N); background(c, '#2a1a10', '#060302', seed=550, center=(0.5, 0.7))
    comet(c, (0.5, 0.62), (0.5, 0.0), 0.1, 0.03, EARTH, 551, heat=0.6, lick=0.08)
    ring(c, (0.5, 0.72), 0.3, 0.025, BLOOD, seed=552, heat=0.8, wobble=0.05)
    burst(c, (0.5, 0.7), 0.09, BLOOD, 553, heat=0.9, spikes=12, spike_len=0.2)
    save(c, 'crush')

def icon_lore():
    c = Canvas(N); background(c, '#2a2414', '#060503', seed=560)
    rune_circle(c, (0.5, 0.5), 0.4, GOLD, 561, heat=0.8, ticks=16)
    P.SPRITES = ITEMS
    sprite(c, 't_tome', (0.5, 0.52), 0.7, rim=hexc('#ffd080'), rim_k=0.7)
    save(c, 'lore')

def icon_eating():
    c = Canvas(N); background(c, '#3a2410', '#080503', seed=570, center=(0.5, 0.6))
    P.SPRITES = ITEMS
    sprite(c, 'stew_hearty', (0.5, 0.56), 0.86, rim=hexc('#ffd090'), rim_k=0.5)
    for i in range(3):
        smoke(c, (0.4 + i * 0.1, 0.2), 0.08, hexc('#c8c0b8', 0.35), seed=571 + i, k=0.5, stretch=(0.5, 1.6))
    save(c, 'eating')

def icon_drinking():
    c = Canvas(N); background(c, '#10283a', '#020508', seed=580, center=(0.5, 0.6))
    P.SPRITES = ITEMS
    sprite(c, 'water', (0.5, 0.54), 0.86, rim=hexc('#a0d8ff'), rim_k=0.6)
    save(c, 'drinking')

import spell_icons as S
ICONS = {k[5:]: v for k, v in dict(globals()).items() if k.startswith('icon_')}

if __name__ == '__main__':
    names = sys.argv[1:] or list(ICONS)
    for n in names: ICONS[n](); print('icon', n, flush=True)
