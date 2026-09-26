"""
Spell and ability icons, painted in code (art/paint.py): each one a small, lit, layered painting.
    python3 art/spell_icons.py              # all
    python3 art/spell_icons.py fireball     # one
Writes godot/assets/icons/<ability id>.png (256 px).
"""
import sys, os, math
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paint import *

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'godot', 'assets', 'icons'); os.makedirs(OUT, exist_ok=True)
N = 512

def comet(c, head, tail, r_head, r_tail, palette, seed, heat=1.0, lick=0.09, streak=(1.0, 0.3)):
    """a burning body flying from tail to head: tapering, licked by flame, hottest at the head"""
    d, t = seg_dist(c, tail, head)          # t: 0 at the tail, 1 at the head
    r = r_tail + (r_head - r_tail) * t ** 0.7
    # flame licks: noise stretched along the direction of travel, and warped
    ang = math.atan2(head[1] - tail[1], head[0] - tail[0])
    n1 = streaks(c.n, 11, seed, ang, 3.0, 6) * 0.65 + noise(c.n, 14, seed + 7, 5) * 0.35
    n2 = noise(c.n, 3, seed + 1, 4)
    wx = (noise(c.n, 4, seed + 2, 3) - 0.5); wy = (noise(c.n, 4, seed + 3, 3) - 0.5)
    n1 = warp(n1, wx * math.cos(ang) + wy * 0.3, wx * math.sin(ang) + wy * 0.3, 0.06)
    edge = d - r - (n1 - 0.5) * lick * (0.6 + (1 - t) * 1.6) - (n2 - 0.5) * 0.03
    body = smooth(0.012, -0.03, edge)
    core = smooth(r * 0.9, 0.0, d) * t ** 1.5
    inner = smooth(0.0, -0.09, edge)                      # deeper inside the flame is hotter
    temp = body * (0.25 + 0.35 * t + 0.3 * inner) * (0.35 + 1.1 * n1 ** 1.3) + core * 0.25
    c.glow_add(ramp(temp * heat, palette) * body[..., None] * 0.5)
    return body

def icon_fireball():
    c = Canvas(N)
    background(c, '#5a2410', '#0e0506', seed=2, center=(0.58, 0.4))
    head = (0.64, 0.36); tail = (0.1, 0.9)
    comet(c, head, tail, 0.19, 0.02, FIRE, 11, heat=0.85, lick=0.13)
    comet(c, head, (0.26, 0.8), 0.13, 0.015, FIRE, 12, heat=0.9, lick=0.06)
    # the head: a boiling ball of fire, white-hot in the middle
    d = np.sqrt((c.x - head[0]) ** 2 + (c.y - head[1]) ** 2)
    boil = noise(c.n, 22, 21, 5, persistence=0.6)
    ballm = smooth(0.2, 0.12, d + (boil - 0.5) * 0.06)
    c.glow_add(ramp(ballm * (0.4 + 0.6 * smooth(0.18, 0.0, d)) * (0.35 + 1.0 * boil ** 1.5), FIRE) * ballm[..., None] * 0.6)
    c.glow_add(np.exp(-(d / 0.06) ** 2)[..., None] * np.array(hexc('#fff4d0', 0.9)))
    # embers peeling off the tail
    rng = np.random.default_rng(5)
    pts = []
    for k in range(16):
        t = rng.uniform(0.1, 0.85)
        x = tail[0] + (head[0] - tail[0]) * t + rng.normal(0, 0.06); y = tail[1] + (head[1] - tail[1]) * t + rng.normal(0, 0.06)
        pts.append((x, y, rng.uniform(0.004, 0.009)))
    dots(c, pts, hexc('#ffb040', 3.0))
    c.finish(os.path.join(OUT, 'fireball.png'), bloom=(0.3, 0.2, 0.12), exposure=0.9)


# ================================================================== warrior

GOLD = [(0.0, (0, 0, 0)), (0.3, hexc('#5a3a08')), (0.6, hexc('#f0a830', 1.5)), (0.85, hexc('#fff0a0', 2.6)), (1.0, hexc('#ffffff', 4.0))]
BLOOD = [(0.0, (0, 0, 0)), (0.3, hexc('#3a0404')), (0.6, hexc('#c01010', 1.3)), (0.85, hexc('#ff6040', 2.0)), (1.0, hexc('#ffe0d0', 3.0))]
STEEL = [(0.0, (0, 0, 0)), (0.3, hexc('#1a2a3a')), (0.6, hexc('#80a8d0', 1.3)), (0.85, hexc('#d8ecff', 2.2)), (1.0, hexc('#ffffff', 3.5))]
STORM = [(0.0, (0, 0, 0)), (0.3, hexc('#0a1a3a')), (0.6, hexc('#4a90ff', 1.4)), (0.85, hexc('#c8e4ff', 2.6)), (1.0, hexc('#ffffff', 4.5))]

def sparks(c, center, n, spread, col, seed=0, size=(0.004, 0.009), k=3.0):
    rng = np.random.default_rng(seed)
    dots(c, [(center[0] + rng.normal(0, spread), center[1] + rng.normal(0, spread), rng.uniform(*size)) for _ in range(n)], col, k)

def save(c, name, **kw): c.finish(os.path.join(OUT, name + '.png'), **kw)

def icon_heroic_strike():
    c = Canvas(N); background(c, '#4a3a20', '#0c0a08', seed=3)
    arc(c, (0.5, 0.52), 0.34, 200, 330, 0.035, GOLD, seed=4, heat=0.9)
    sprite(c, 'sword', (0.54, 0.46), 0.86, angle=-15, rim=hexc('#ffd070'), rim_k=0.6)
    glow_ball(c, (0.72, 0.28), 0.05, hexc('#fff0b0'), 1.2)
    sparks(c, (0.72, 0.3), 14, 0.05, hexc('#ffc050'), seed=5)
    save(c, 'heroic_strike')

def icon_charge():
    c = Canvas(N); background(c, '#4a2818', '#0c0806', seed=6, center=(0.6, 0.5))
    # speed: streaks rushing in from the left, and dust kicked up
    st = streaks(c.n, 8, 7, 0.0, 9.0, 4)
    lane = smooth(0.35, 0.0, np.abs(c.y - 0.52)) * smooth(0.95, 0.2, c.x)
    c.glow_add(ramp(lane * st ** 2 * 1.1, GOLD) * lane[..., None] * 0.5)
    smoke(c, (0.3, 0.72), 0.22, hexc('#7a5a3a', 0.8), seed=8, k=0.7, stretch=(1.8, 0.7))
    sprite(c, 'sword', (0.6, 0.5), 0.9, angle=-40, rim=hexc('#ffb060'), rim_k=0.7)
    glow_ball(c, (0.88, 0.5), 0.06, hexc('#fff0c0'), 1.0)
    save(c, 'charge')

def icon_rend():
    c = Canvas(N); background(c, '#3a1414', '#0a0404', seed=9)
    for i in range(3):
        off = (i - 1) * 0.12
        a = arc(c, (0.2 + off, 0.95 + off * 0.2), 0.62, -75, -35, 0.012, BLOOD, seed=10 + i, heat=1.0)
    sprite(c, 'dagger', (0.66, 0.36), 0.55, angle=-10, rim=hexc('#ff4030'), rim_k=0.4)
    rng = np.random.default_rng(12)
    for k in range(10):
        x, y = 0.3 + rng.uniform(0, 0.35), 0.45 + rng.uniform(0, 0.4)
        d = np.sqrt((c.x - x) ** 2 + ((c.y - y) * 0.7) ** 2)
        c.paint(hexc('#8a0606', 1.2), smooth(0.012, 0.004, d))
    save(c, 'rend')

def icon_thunder_clap():
    c = Canvas(N); background(c, '#1a2440', '#05070c', seed=13, center=(0.5, 0.62))
    # a cracked ground plate seen from the side, and the shockwave rolling out
    gy = 0.66
    ground = smooth(gy - 0.01, gy + 0.02, c.y)
    c.paint(hexc('#2a2420'), ground)
    cracks = streaks(c.n, 10, 14, math.pi / 2, 5.0, 5)
    crackm = ground * smooth(0.72, 0.8, cracks) * smooth(0.5, 0.0, np.abs(c.x - 0.5))
    c.glow_add(crackm[..., None] * np.array(hexc('#9ad0ff', 2.0)))
    for i, (r, w) in enumerate([(0.18, 0.02), (0.3, 0.016), (0.42, 0.012)]):
        dx, dy = (c.x - 0.5), (c.y - gy) * 2.8
        rr = np.sqrt(dx * dx + dy * dy)
        band = np.exp(-((rr - r) / w) ** 2) * smooth(gy + 0.1, gy - 0.12, c.y)
        c.glow_add(ramp(band * (1.0 - i * 0.2), STORM) * band[..., None] * 0.7)
    # lightning forks up from the impact
    rng = np.random.default_rng(15)
    for b in range(5):
        x, y = 0.5, gy
        a = -math.pi / 2 + rng.uniform(-0.9, 0.9)
        pts = []
        for s in range(9):
            a += rng.normal(0, 0.45); x += math.cos(a) * 0.045; y += math.sin(a) * 0.045; pts.append((x, y, 0.006))
        dots(c, pts, hexc('#d8ecff', 2.0), 1.0)
    glow_ball(c, (0.5, gy), 0.08, hexc('#c8e4ff'), 1.4)
    save(c, 'thunder_clap')

def icon_execute():
    c = Canvas(N); background(c, '#4a0e0a', '#080202', seed=16, center=(0.5, 0.35))
    arc(c, (0.3, 0.85), 0.62, -95, -20, 0.03, BLOOD, seed=17, heat=1.1)
    sprite(c, 'axe', (0.52, 0.44), 0.95, angle=-20, rim=hexc('#ff3020'), rim_k=0.9, light=0.9)
    smoke(c, (0.5, 0.95), 0.4, hexc('#200202'), seed=18, k=0.8, stretch=(1.5, 0.6))
    sparks(c, (0.8, 0.5), 10, 0.06, hexc('#ff5030'), seed=19)
    save(c, 'execute')

def icon_battle_shout():
    c = Canvas(N); background(c, '#4a3a18', '#0c0906', seed=20, center=(0.35, 0.5))
    for i, r in enumerate([0.16, 0.26, 0.36, 0.46]):
        arc(c, (0.22, 0.52), r, -45, 45, 0.018 - i * 0.002, GOLD, seed=21 + i, heat=1.0 - i * 0.15, taper=False)
    sprite(c, 'sword_up', (0.24, 0.52), 0.8, angle=-8, rim=hexc('#ffc050'), rim_k=0.5)
    sparks(c, (0.62, 0.52), 12, 0.12, hexc('#ffd060'), seed=22, k=2.0)
    save(c, 'battle_shout')

def icon_hamstring():
    c = Canvas(N); background(c, '#30283a', '#07060a', seed=23)
    arc(c, (0.5, 0.1), 0.62, 60, 120, 0.02, BLOOD, seed=24, heat=1.0)
    # the slowing: cold coils wound round where the blow landed
    for i in range(3):
        ring(c, (0.5, 0.74 - i * 0.05), 0.16 - i * 0.02, 0.008, STORM, seed=25 + i, heat=0.7, wobble=0.01)
    sprite(c, 'dagger', (0.5, 0.42), 0.6, angle=-50, rim=hexc('#9fc0ff'), rim_k=0.5)
    save(c, 'hamstring')

def shield_shape(cx, cy, w, h):
    pts = []
    for k in range(21):
        t = k / 20.0; x = cx - w / 2 + w * t
        pts.append((x, cy - h * 0.5 + h * 0.05 * math.sin(t * math.pi)))
    for k in range(21):
        t = k / 20.0; a = t * math.pi
        pts.append((cx + math.cos(a) * w / 2, cy - h * 0.1 + math.sin(a) ** 1.4 * h * 0.62))
    return pts

def painted_shield(c, cx=0.5, cy=0.5, w=0.56, h=0.66, face='#6a1a14', trim='#c8a050', emblem=None):
    shade_poly(c, shield_shape(cx, cy, w, h), hexc(trim, 1.1), spec=0.8)
    shade_poly(c, shield_shape(cx, cy + 0.01, w * 0.86, h * 0.86), hexc(face, 1.0), spec=0.4)
    if emblem:
        emblem(c, cx, cy)

def icon_taunt():
    c = Canvas(N); background(c, '#4a1410', '#0a0303', seed=26)
    ring(c, (0.5, 0.5), 0.36, 0.014, BLOOD, seed=27, heat=1.0)
    ring(c, (0.5, 0.5), 0.26, 0.01, BLOOD, seed=28, heat=0.8)
    def em(c, cx, cy):
        rays(c, (cx, cy + 0.02), 8, 0.2, 0.02, hexc('#ff5030', 1.5), seed=29)
        glow_ball(c, (cx, cy + 0.02), 0.05, hexc('#ffb080'), 1.2)
    painted_shield(c, 0.5, 0.5, 0.46, 0.56, face='#3a1410', trim='#9a8a70', emblem=em)
    save(c, 'taunt')

def icon_defensive_stance():
    c = Canvas(N); background(c, '#1a2a44', '#05080e', seed=30)
    ring(c, (0.5, 0.5), 0.42, 0.02, STEEL, seed=31, heat=0.8)
    def em(c, cx, cy):
        pts = [(cx, cy - 0.12), (cx + 0.1, cy - 0.02), (cx, cy + 0.14), (cx - 0.1, cy - 0.02)]
        shade_poly(c, pts, hexc('#c8d8f0', 1.2), spec=1.0)
    painted_shield(c, 0.5, 0.5, 0.56, 0.66, face='#1a3a6a', trim='#b8c0d0', emblem=em)
    save(c, 'defensive_stance')

def icon_shield_block():
    c = Canvas(N); background(c, '#2a2a34', '#060608', seed=32, center=(0.62, 0.5))
    painted_shield(c, 0.42, 0.52, 0.56, 0.66, face='#5a3a1a', trim='#a8a8b0')
    glow_ball(c, (0.72, 0.4), 0.07, hexc('#fff0c0'), 1.6)
    rays(c, (0.72, 0.4), 12, 0.22, 0.012, hexc('#ffd080', 1.8), seed=33)
    sparks(c, (0.78, 0.42), 18, 0.06, hexc('#ffc060'), seed=34)
    save(c, 'shield_block')

def icon_mortal_strike():
    c = Canvas(N); background(c, '#3a0a14', '#060104', seed=35)
    smoke(c, (0.5, 0.6), 0.45, hexc('#140408'), seed=36, k=0.9)
    arc(c, (0.8, 0.9), 0.62, 180, 255, 0.04, BLOOD, seed=37, heat=1.2)
    sprite(c, 'sword', (0.46, 0.46), 0.9, angle=30, rim=hexc('#ff2030'), rim_k=0.9, light=0.85, flip=True)
    sparks(c, (0.3, 0.6), 10, 0.05, hexc('#ff4040'), seed=38)
    save(c, 'mortal_strike')

def icon_whirlwind():
    c = Canvas(N); background(c, '#2a3040', '#06070a', seed=39)
    for i in range(3):
        arc(c, (0.5, 0.52), 0.18 + i * 0.1, i * 120.0, i * 120.0 + 230, 0.022 - i * 0.004, STEEL, seed=40 + i, heat=0.9)
    sprite(c, 'sword', (0.5, 0.5), 0.8, angle=-60, rim=hexc('#c8e0ff'), rim_k=0.6)
    save(c, 'whirlwind')

def icon_recklessness():
    c = Canvas(N); background(c, '#501008', '#0a0202', seed=42, center=(0.5, 0.6))
    comet(c, (0.5, 0.35), (0.5, 1.05), 0.3, 0.22, FIRE, 43, heat=0.55, lick=0.16)
    sprite(c, 'axe', (0.5, 0.48), 0.84, angle=0, rim=hexc('#ff5020'), rim_k=1.0, light=0.8)
    save(c, 'recklessness')

def icon_shield_wall():
    c = Canvas(N); background(c, '#3a3218', '#080704', seed=44)
    rays(c, (0.5, 0.5), 16, 0.5, 0.02, hexc('#ffd070', 1.2), seed=45)
    for dx in (-0.2, 0.2):
        painted_shield(c, 0.5 + dx, 0.54, 0.34, 0.46, face='#6a4a14', trim='#c8b070')
    def em(c, cx, cy): glow_ball(c, (cx, cy), 0.05, hexc('#fff0b0'), 1.0)
    painted_shield(c, 0.5, 0.5, 0.42, 0.56, face='#8a6a1a', trim='#e8d090', emblem=em)
    save(c, 'shield_wall')

def icon_rallying_cry():
    c = Canvas(N); background(c, '#4a3818', '#0a0805', seed=46, center=(0.55, 0.35))
    rays(c, (0.6, 0.3), 14, 0.55, 0.018, hexc('#ffd878', 1.1), seed=47)
    # the banner: a pole and a cloth that ripples
    pole = smooth(0.012, 0.004, np.abs(c.x - 0.3)) * smooth(0.08, 0.12, c.y) * smooth(0.96, 0.9, c.y)
    c.paint(hexc('#5a3a20'), pole)
    wave = 0.02 * np.sin(c.x * 22.0) * (c.x - 0.3) * 3.0
    cloth = smooth(0.29, 0.31, c.x) * smooth(0.78, 0.74, c.x) * smooth(0.13, 0.15, c.y - wave) * smooth(0.55, 0.52, c.y - wave + (c.x - 0.3) * 0.25 * ((c.x * 30) % 1 > 0.5))
    fold = 0.75 + 0.25 * np.sin(c.x * 22.0 + 1.2)
    c.paint(np.asarray(hexc('#a01818')) * fold[..., None], cloth)
    glow_ball(c, (0.52, 0.32), 0.06, hexc('#ffd060'), 0.6)
    glow_ball(c, (0.3, 0.1), 0.02, hexc('#ffe0a0'), 1.5)
    save(c, 'rallying_cry')

def icon_cleaving_slam():
    c = Canvas(N); background(c, '#4a2a14', '#0a0604', seed=48, center=(0.5, 0.7))
    gy = 0.72
    c.paint(hexc('#2a2018'), smooth(gy - 0.01, gy + 0.02, c.y))
    cracks = streaks(c.n, 10, 49, math.pi / 2, 5.0, 5)
    crackm = smooth(gy - 0.01, gy + 0.02, c.y) * smooth(0.74, 0.8, cracks) * smooth(0.45, 0.0, np.abs(c.x - 0.5))
    c.glow_add(ramp(crackm, FIRE)[..., :] * crackm[..., None] * 1.0)
    glow_ball(c, (0.5, gy), 0.12, hexc('#ff9a30'), 1.3)
    rng = np.random.default_rng(50)
    for k in range(14):
        x = 0.5 + rng.normal(0, 0.18); y = gy - rng.uniform(0.02, 0.3)
        pts = [(x - 0.02, y), (x, y - 0.025), (x + 0.02, y - 0.005), (x + 0.01, y + 0.02)]
        shade_poly(c, pts, hexc('#4a3a2a'), spec=0.3, soft=0.5)
    sprite(c, 'worldbreaker', (0.5, 0.38), 0.8, angle=0, rim=hexc('#ff9030'), rim_k=0.8)
    save(c, 'cleaving_slam')


# ================================================================== wizard

def shard(c, tip, base, width, col=hexc('#9fd8ff'), emit=hexc('#60b8ff'), emit_k=0.6, spec=1.2):
    """an ice crystal: a long faceted spike from base to tip"""
    ax, ay = base; bx, by = tip
    vx, vy = bx - ax, by - ay; L = math.hypot(vx, vy); nx, ny = -vy / L, vx / L
    pts = [(ax + nx * width, ay + ny * width), (ax + vx * 0.75 + nx * width * 0.8, ay + vy * 0.75 + ny * width * 0.8), (bx, by),
           (ax + vx * 0.75 - nx * width * 0.8, ay + vy * 0.75 - ny * width * 0.8), (ax - nx * width, ay - ny * width)]
    m = shade_poly(c, pts, col, spec=spec, soft=0.6, emit=emit, emit_k=emit_k)
    # the bright facet edge down the middle
    d, t = seg_dist(c, base, tip)
    c.glow_add((np.exp(-(d / (width * 0.18)) ** 2) * m * 0.8)[..., None] * np.array(hexc('#e8f8ff', 1.5)))
    return m

def icon_frostbolt():
    c = Canvas(N); background(c, '#123050', '#03060c', seed=60, center=(0.6, 0.4))
    comet(c, (0.62, 0.38), (0.08, 0.92), 0.13, 0.02, FROST, 61, heat=0.7, lick=0.08)
    shard(c, (0.8, 0.2), (0.45, 0.55), 0.06)
    shard(c, (0.74, 0.18), (0.5, 0.42), 0.03, emit_k=0.9)
    shard(c, (0.84, 0.3), (0.56, 0.44), 0.028, emit_k=0.9)
    rng = np.random.default_rng(62)
    dots(c, [(0.1 + rng.uniform(0, 0.5), 0.5 + rng.uniform(0, 0.45), rng.uniform(0.003, 0.007)) for _ in range(24)], hexc('#d8f0ff', 2.0))
    save(c, 'frostbolt')

def burst(c, center, radius, palette, seed, heat=1.0, spikes=14, spike_len=0.35):
    """an explosion: a boiling ball with jets of flame thrown out"""
    dx, dy = c.x - center[0], c.y - center[1]
    r = np.sqrt(dx * dx + dy * dy); ang = np.arctan2(dy, dx)
    rng = np.random.default_rng(seed)
    spike = np.zeros_like(r)
    for i in range(spikes):
        a = rng.uniform(-math.pi, math.pi); w = rng.uniform(0.08, 0.2); L = radius * (1 + rng.uniform(0.3, 1.0) * spike_len / radius * 0.8)
        da = np.abs((ang - a + math.pi) % (2 * math.pi) - math.pi)
        spike = np.maximum(spike, np.exp(-(da / w) ** 2) * (L - radius))
    nz = noise(c.n, 14, seed, 6, persistence=0.6)
    edge = r - radius - spike * (0.6 + 0.8 * nz) - (nz - 0.5) * radius * 0.4
    body = smooth(0.015, -0.03, edge)
    temp = body * (0.35 + 0.65 * smooth(radius * 1.4, 0.0, r)) * (0.5 + 0.9 * nz)
    c.glow_add(ramp(temp * heat, palette) * body[..., None] * 0.55)
    return body

def icon_fire_blast():
    c = Canvas(N); background(c, '#5a1a08', '#0c0302', seed=63)
    burst(c, (0.5, 0.52), 0.16, FIRE, 64, heat=1.0, spikes=16, spike_len=0.3)
    glow_ball(c, (0.5, 0.52), 0.07, hexc('#fff4d0'), 1.2)
    sparks(c, (0.5, 0.52), 30, 0.2, hexc('#ffb040'), seed=65, k=2.5)
    save(c, 'fire_blast')

def icon_pyroblast():
    c = Canvas(N); background(c, '#6a1404', '#0a0201', seed=66, center=(0.5, 0.45))
    comet(c, (0.56, 0.44), (0.2, 0.95), 0.28, 0.05, FIRE, 67, heat=0.65, lick=0.2)
    burst(c, (0.56, 0.44), 0.18, FIRE, 68, heat=0.75, spikes=12, spike_len=0.24)
    d = np.sqrt((c.x - 0.56) ** 2 + (c.y - 0.44) ** 2)
    c.glow_add(np.exp(-(d / 0.06) ** 2)[..., None] * np.array(hexc('#fff8e0', 1.1)))
    save(c, 'pyroblast')

def icon_frost_nova():
    c = Canvas(N); background(c, '#10304a', '#02060a', seed=69, center=(0.5, 0.55))
    ring(c, (0.5, 0.55), 0.3, 0.03, FROST, seed=70, heat=0.8, wobble=0.04)
    rng = np.random.default_rng(71)
    for k in range(11):
        a = k * 2 * math.pi / 11 + rng.normal(0, 0.1)
        L = rng.uniform(0.22, 0.34)
        base = (0.5 + math.cos(a) * 0.08, 0.55 + math.sin(a) * 0.08 * 0.6)
        tip = (0.5 + math.cos(a) * L, 0.55 + math.sin(a) * L * 0.75 - 0.08)
        shard(c, tip, base, rng.uniform(0.018, 0.03), emit_k=0.5)
    glow_ball(c, (0.5, 0.55), 0.08, hexc('#c8f0ff'), 1.2)
    save(c, 'frost_nova')

def icon_cone_of_cold():
    c = Canvas(N); background(c, '#0e2a44', '#02050a', seed=72, center=(0.6, 0.45))
    ang = math.radians(-35)
    dx, dy = c.x - 0.15, c.y - 0.85
    along = dx * math.cos(ang) + dy * math.sin(ang); across = -dx * math.sin(ang) + dy * math.cos(ang)
    cone = smooth(0.0, 0.1, along) * smooth(along * 0.45 + 0.02, along * 0.3, np.abs(across)) * smooth(0.95, 0.6, along)
    st = streaks(c.n, 9, 73, ang, 5.0, 5)
    c.glow_add(ramp(cone * (0.4 + 0.8 * st), FROST) * cone[..., None] * 0.55)
    rng = np.random.default_rng(74)
    for k in range(9):
        t = rng.uniform(0.35, 0.8); o = rng.uniform(-0.2, 0.2) * t
        bx = 0.15 + math.cos(ang) * t - math.sin(ang) * o; by = 0.85 + math.sin(ang) * t + math.cos(ang) * o
        shard(c, (bx + math.cos(ang) * 0.09, by + math.sin(ang) * 0.09), (bx, by), 0.014, emit_k=0.7)
    save(c, 'cone_of_cold')

def icon_flamestrike():
    c = Canvas(N); background(c, '#4a1406', '#0a0302', seed=75, center=(0.5, 0.55))
    # the column of fire falling from above onto a burning circle
    gy = 0.8
    dx, dy = (c.x - 0.5), (c.y - gy) * 3.2
    rr = np.sqrt(dx * dx + dy * dy)
    band = np.exp(-((rr - 0.28) / 0.02) ** 2)
    c.glow_add(ramp(band, FIRE) * band[..., None] * 0.6)
    col = smooth(0.18, 0.08, np.abs(c.x - 0.5) + (c.y) * 0.08) * smooth(0.0, 0.1, c.y) * smooth(gy + 0.05, gy - 0.02, c.y)
    st = streaks(c.n, 9, 76, math.pi / 2, 5.0, 6)
    c.glow_add(ramp(col * (0.35 + 0.9 * st), FIRE) * col[..., None] * 0.55)
    burst(c, (0.5, gy), 0.1, FIRE, 77, heat=0.9, spikes=12, spike_len=0.12)
    save(c, 'flamestrike')

def icon_meteor():
    c = Canvas(N); background(c, '#3a1a28', '#060308', seed=78, center=(0.4, 0.6))
    comet(c, (0.62, 0.58), (0.05, 0.02), 0.17, 0.04, FIRE, 79, heat=0.85, lick=0.14)
    rock = [(0.55, 0.5), (0.63, 0.47), (0.72, 0.52), (0.74, 0.62), (0.68, 0.7), (0.58, 0.69), (0.52, 0.61)]
    shade_poly(c, rock, hexc('#3a2a24'), spec=0.4, emit=hexc('#ff5010'), emit_k=0.15)
    cr = streaks(c.n, 16, 80, 0.4, 2.0, 4)
    rm = poly_mask(c, rock, 0) * smooth(0.72, 0.8, cr)
    c.glow_add(rm[..., None] * np.array(hexc('#ff8020', 2.0)))
    save(c, 'meteor')

def icon_arcane_missiles():
    c = Canvas(N); background(c, '#2a1040', '#05020a', seed=81, center=(0.6, 0.4))
    for i, (h, t) in enumerate([((0.78, 0.22), (0.1, 0.8)), ((0.66, 0.44), (0.05, 0.95)), ((0.84, 0.46), (0.25, 0.98))]):
        comet(c, h, t, 0.06, 0.008, ARCANE, 82 + i, heat=0.85, lick=0.04)
        glow_ball(c, h, 0.03, hexc('#ffe0ff'), 1.4)
    save(c, 'arcane_missiles')

def rune_circle(c, center, radius, palette, seed, heat=1.0, ticks=24):
    ring(c, center, radius, 0.008, palette, seed, heat, wobble=0.0)
    ring(c, center, radius * 0.82, 0.005, palette, seed + 1, heat * 0.8, wobble=0.0)
    dx, dy = c.x - center[0], c.y - center[1]
    r = np.sqrt(dx * dx + dy * dy); ang = np.arctan2(dy, dx)
    band = smooth(radius * 0.84, radius * 0.86, r) * smooth(radius * 0.98, radius * 0.96, r)
    rng = np.random.default_rng(seed)
    marks = np.zeros_like(r)
    for i in range(ticks):
        a = -math.pi + i * 2 * math.pi / ticks
        da = np.abs((ang - a + math.pi) % (2 * math.pi) - math.pi) * r
        marks += np.exp(-(da / 0.004) ** 2) * (rng.random() > 0.3)
    m = band * np.clip(marks, 0, 1)
    c.glow_add(ramp(m * heat, palette) * m[..., None])

def icon_arcane_power():
    c = Canvas(N); background(c, '#2a0c3a', '#050108', seed=84)
    rune_circle(c, (0.5, 0.5), 0.4, ARCANE, 85)
    rune_circle(c, (0.5, 0.5), 0.24, ARCANE, 86, heat=0.9, ticks=12)
    burst(c, (0.5, 0.5), 0.08, ARCANE, 87, heat=0.9, spikes=8, spike_len=0.1)
    glow_ball(c, (0.5, 0.5), 0.05, hexc('#ffffff'), 1.4)
    save(c, 'arcane_power')

def icon_blink():
    c = Canvas(N); background(c, '#1a1040', '#030208', seed=88, center=(0.7, 0.4))
    st = streaks(c.n, 6, 89, math.radians(-30), 8.0, 4)
    d, t = seg_dist(c, (0.12, 0.82), (0.74, 0.34))
    band = np.exp(-(d / (0.02 + 0.08 * t)) ** 2)
    c.glow_add(ramp(band * t * (0.5 + 0.7 * st), ARCANE) * band[..., None] * 0.6)
    ring(c, (0.74, 0.34), 0.12, 0.012, ARCANE, seed=90, heat=0.9)
    glow_ball(c, (0.74, 0.34), 0.05, hexc('#f0d8ff'), 1.3)
    rng = np.random.default_rng(91)
    dots(c, [(0.74 + rng.normal(0, 0.1), 0.34 + rng.normal(0, 0.1), rng.uniform(0.003, 0.007)) for _ in range(24)], hexc('#e0c0ff', 2.0))
    save(c, 'blink')

def icon_frost_armor():
    c = Canvas(N); background(c, '#10283e', '#02050a', seed=92)
    # a breastplate of ice
    plate = [(0.3, 0.26), (0.42, 0.22), (0.5, 0.28), (0.58, 0.22), (0.7, 0.26), (0.72, 0.5), (0.64, 0.74), (0.5, 0.82), (0.36, 0.74), (0.28, 0.5)]
    shade_poly(c, plate, hexc('#6aa8d8', 1.1), spec=1.4, emit=hexc('#4090d0'), emit_k=0.25)
    for tip, base, w in [((0.5, 0.36), (0.5, 0.74), 0.03), ((0.38, 0.32), (0.4, 0.6), 0.02), ((0.62, 0.32), (0.6, 0.6), 0.02)]:
        shard(c, tip, base, w, emit_k=0.3)
    ring(c, (0.5, 0.52), 0.4, 0.01, FROST, seed=93, heat=0.6)
    save(c, 'frost_armor')

def icon_ice_barrier():
    c = Canvas(N); background(c, '#0e2a44', '#02050a', seed=94)
    d = np.sqrt((c.x - 0.5) ** 2 + (c.y - 0.52) ** 2)
    shell = smooth(0.36, 0.34, d)
    fres = shell * smooth(0.1, 0.35, d) ** 2
    facets = streaks(c.n, 7, 95, 0.7, 1.5, 3)
    edges = np.abs(np.gradient(np.floor(facets * 7))[0]) + np.abs(np.gradient(np.floor(facets * 7))[1])
    c.paint(hexc('#3a78b0', 0.7), shell * 0.35)
    c.glow_add((fres * 0.8 + np.clip(edges, 0, 1) * shell * 0.6)[..., None] * np.array(hexc('#a8e0ff', 1.3)))
    glow_ball(c, (0.4, 0.38), 0.05, hexc('#ffffff'), 0.8)
    save(c, 'ice_barrier')

def icon_evocation():
    c = Canvas(N); background(c, '#101c4a', '#02030a', seed=96)
    dx, dy = c.x - 0.5, c.y - 0.5
    r = np.sqrt(dx * dx + dy * dy); a = np.arctan2(dy, dx)
    swirl = 0.5 + 0.5 * np.sin(a * 3 + r * 28)
    m = smooth(0.42, 0.1, r) * swirl ** 3
    c.glow_add(ramp(m * 0.9, STORM) * m[..., None] * 0.7)
    glow_ball(c, (0.5, 0.5), 0.06, hexc('#e0f0ff'), 1.5)
    save(c, 'evocation')

def icon_time_warp():
    c = Canvas(N); background(c, '#2a1c40', '#05030a', seed=97)
    rune_circle(c, (0.5, 0.5), 0.42, ARCANE, 98, heat=0.8, ticks=12)
    glass = [(0.36, 0.22), (0.64, 0.22), (0.52, 0.5), (0.64, 0.78), (0.36, 0.78), (0.48, 0.5)]
    shade_poly(c, glass, hexc('#6a5a8a', 0.6), spec=1.2)
    sand_top = poly_mask(c, [(0.41, 0.3), (0.59, 0.3), (0.51, 0.47), (0.49, 0.47)], 0.6)
    sand_bot = poly_mask(c, [(0.42, 0.74), (0.58, 0.74), (0.52, 0.64), (0.48, 0.64)], 0.6)
    c.glow_add((sand_top + sand_bot)[..., None] * np.array(hexc('#ffc060', 1.6)))
    for y in (0.21, 0.79):
        c.paint(hexc('#c8a050'), smooth(0.02, 0.012, np.abs(c.y - y)) * smooth(0.2, 0.18, np.abs(c.x - 0.5)))
    save(c, 'time_warp')

# ================================================================== cleric

def beam(c, x, width, palette, seed, heat=1.0, top=0.0, bottom=1.0):
    st = streaks(c.n, 8, seed, math.pi / 2, 6.0, 5)
    col = smooth(width, width * 0.2, np.abs(c.x - x)) * smooth(top, top + 0.1, c.y) * smooth(bottom + 0.02, bottom - 0.05, c.y)
    c.glow_add(ramp(col * (0.5 + 0.6 * st) * heat, palette) * col[..., None] * 0.6)

def light_cross(c, center, size, col, k=1.0, thick=0.05):
    x, y = center
    m = np.maximum(smooth(thick, thick * 0.5, np.abs(c.x - x)) * smooth(size, size * 0.9, np.abs(c.y - y)),
                   smooth(thick, thick * 0.5, np.abs(c.y - y + size * 0.25)) * smooth(size * 0.7, size * 0.62, np.abs(c.x - x)))
    shade = 1.0 - 0.4 * (c.y - (y - size)) / (2 * size)
    c.glow_add((m * shade)[..., None] * np.asarray(col, np.float32) * k)
    return m

def icon_smite():
    c = Canvas(N); background(c, '#4a3a18', '#0a0804', seed=100, center=(0.5, 0.7))
    beam(c, 0.5, 0.12, HOLY, 101, heat=0.75, top=0.0, bottom=0.78)
    burst(c, (0.5, 0.78), 0.1, HOLY, 102, heat=0.9, spikes=12, spike_len=0.16)
    rays(c, (0.5, 0.78), 16, 0.3, 0.012, hexc('#ffd878', 0.9), seed=103)
    save(c, 'smite')

def icon_holy_fire():
    c = Canvas(N); background(c, '#4a3410', '#0a0703', seed=104, center=(0.5, 0.6))
    comet(c, (0.5, 0.2), (0.5, 0.86), 0.06, 0.2, HOLY, 105, heat=0.7, lick=0.14)
    comet(c, (0.5, 0.36), (0.5, 0.84), 0.04, 0.11, FIRE, 106, heat=0.55, lick=0.08)
    glow_ball(c, (0.5, 0.72), 0.06, hexc('#fff8e0'), 0.9)
    save(c, 'holy_fire')

def icon_mend():
    c = Canvas(N); background(c, '#3a3014', '#080603', seed=107)
    rays(c, (0.5, 0.5), 20, 0.48, 0.012, hexc('#ffe8a0', 0.9), seed=108)
    light_cross(c, (0.5, 0.52), 0.26, hexc('#fff0c0', 1.6))
    glow_ball(c, (0.5, 0.46), 0.1, hexc('#fff8e0'), 0.8)
    save(c, 'mend')

def icon_greater_mend():
    c = Canvas(N); background(c, '#4a3a14', '#0a0803', seed=109)
    ring(c, (0.5, 0.5), 0.36, 0.012, HOLY, seed=110, heat=0.9)
    rays(c, (0.5, 0.5), 28, 0.5, 0.014, hexc('#ffe8a0', 1.1), seed=111)
    light_cross(c, (0.5, 0.52), 0.3, hexc('#fff4d0', 2.0), thick=0.06)
    save(c, 'greater_mend')

def leaf(c, base, tip, width, col):
    ax, ay = base; bx, by = tip
    vx, vy = bx - ax, by - ay; L = math.hypot(vx, vy); nx, ny = -vy / L, vx / L
    pts = []
    for k in range(13):
        t = k / 12.0; w = math.sin(t * math.pi) * width
        pts.append((ax + vx * t + nx * w, ay + vy * t + ny * w))
    for k in range(12, -1, -1):
        t = k / 12.0; w = math.sin(t * math.pi) * width
        pts.append((ax + vx * t - nx * w, ay + vy * t - ny * w))
    return shade_poly(c, pts, col, spec=0.7, soft=0.6)

def icon_renewal():
    c = Canvas(N); background(c, '#1c3a18', '#030803', seed=112)
    dx, dy = c.x - 0.5, c.y - 0.5
    r = np.sqrt(dx * dx + dy * dy); a = np.arctan2(dy, dx)
    sw = (0.5 + 0.5 * np.sin(a * 2 - r * 22)) ** 4 * smooth(0.44, 0.15, r)
    c.glow_add(ramp(sw * 0.9, NATURE) * sw[..., None] * 0.6)
    for k in range(5):
        ang = k * 2 * math.pi / 5 + 0.3
        leaf(c, (0.5 + math.cos(ang) * 0.06, 0.5 + math.sin(ang) * 0.06), (0.5 + math.cos(ang) * 0.3, 0.5 + math.sin(ang) * 0.3), 0.06, hexc('#4ab040', 1.1))
    glow_ball(c, (0.5, 0.5), 0.07, hexc('#f0ffd0'), 1.4)
    save(c, 'renewal')

def icon_ward_of_light():
    c = Canvas(N); background(c, '#3a3014', '#080603', seed=113)
    d = np.sqrt((c.x - 0.5) ** 2 + (c.y - 0.52) ** 2)
    shell = smooth(0.38, 0.36, d)
    c.paint(hexc('#c89a30', 0.5), shell * 0.3)
    c.glow_add((shell * smooth(0.18, 0.37, d) ** 2.5)[..., None] * np.array(hexc('#ffe090', 1.8)))
    hexes = (np.sin(c.x * 60) * np.sin(c.y * 60 + c.x * 30)) > 0.85
    c.glow_add((hexes * shell * 0.25)[..., None] * np.array(hexc('#fff0c0', 1.0)))
    glow_ball(c, (0.42, 0.4), 0.06, hexc('#ffffff'), 0.7)
    save(c, 'ward_of_light')

def icon_shadow_rot():
    c = Canvas(N); background(c, '#1c0c28', '#030105', seed=114, center=(0.5, 0.65))
    for i in range(3):
        smoke(c, (0.5 + (i - 1) * 0.1, 0.62 - i * 0.04), 0.32 - i * 0.04, hexc('#2a0a44', 0.9), seed=115 + i, k=0.7, stretch=(0.8, 1.3))
    for i, (h, t) in enumerate([((0.36, 0.2), (0.5, 0.82)), ((0.62, 0.16), (0.46, 0.84)), ((0.5, 0.26), (0.52, 0.86)), ((0.74, 0.34), (0.5, 0.84)), ((0.24, 0.38), (0.5, 0.86))]):
        comet(c, h, t, 0.035, 0.05, SHADOW, 163 + i, heat=0.7, lick=0.05)
    rng = np.random.default_rng(170)
    dots(c, [(0.5 + rng.normal(0, 0.16), rng.uniform(0.2, 0.8), rng.uniform(0.003, 0.007)) for _ in range(20)], hexc('#b080ff', 2.0))
    glow_ball(c, (0.5, 0.8), 0.1, hexc('#8040c0'), 0.9)
    save(c, 'shadow_rot')

def icon_mind_blast():
    c = Canvas(N); background(c, '#240a34', '#040108', seed=120)
    burst(c, (0.5, 0.5), 0.12, SHADOW, 121, heat=0.9, spikes=18, spike_len=0.3)
    ring(c, (0.5, 0.5), 0.3, 0.014, SHADOW, seed=122, heat=0.9)
    ring(c, (0.5, 0.5), 0.4, 0.008, SHADOW, seed=123, heat=0.7)
    glow_ball(c, (0.5, 0.5), 0.05, hexc('#f8e8ff'), 1.4)
    save(c, 'mind_blast')

def icon_holy_nova():
    c = Canvas(N); background(c, '#4a3a14', '#0a0803', seed=124)
    rays(c, (0.5, 0.5), 24, 0.5, 0.014, hexc('#ffc850', 1.0), seed=125)
    ring(c, (0.5, 0.5), 0.3, 0.02, HOLY, seed=126, heat=0.8)
    ring(c, (0.5, 0.5), 0.2, 0.012, HOLY, seed=159, heat=0.6)
    glow_ball(c, (0.5, 0.5), 0.07, hexc('#fff8e0'), 1.0)
    save(c, 'holy_nova')

def icon_prayer_of_healing():
    c = Canvas(N); background(c, '#3a3014', '#080603', seed=127, center=(0.5, 0.3))
    beam(c, 0.5, 0.25, HOLY, 128, heat=0.7, top=0.0, bottom=1.0)
    rng = np.random.default_rng(129)
    dots(c, [(0.5 + rng.normal(0, 0.18), rng.uniform(0.15, 0.9), rng.uniform(0.005, 0.012)) for _ in range(36)], hexc('#fff0b0', 2.0))
    for x in (0.28, 0.5, 0.72):
        light_cross(c, (x, 0.62 if x != 0.5 else 0.5), 0.1, hexc('#fff4d0', 1.3), thick=0.022)
    save(c, 'prayer_of_healing')

def icon_divine_protection():
    c = Canvas(N); background(c, '#4a3a14', '#0a0803', seed=130)
    rays(c, (0.5, 0.5), 18, 0.5, 0.02, hexc('#ffd878', 1.0), seed=131)
    # wings of light either side of the shield
    for sgn in (-1, 1):
        for k in range(5):
            leaf(c, (0.5 + sgn * 0.12, 0.42 + k * 0.03), (0.5 + sgn * (0.44 - k * 0.05), 0.2 + k * 0.08), 0.035, hexc('#fff0c8', 1.2))
    def em(c, cx, cy): light_cross(c, (cx, cy), 0.11, hexc('#fff8e0', 1.4), thick=0.022)
    painted_shield(c, 0.5, 0.52, 0.34, 0.44, face='#c89a30', trim='#fff0b0', emblem=em)
    save(c, 'divine_protection')

def icon_radiance():
    c = Canvas(N); background(c, '#4a3410', '#0a0703', seed=132)
    rays(c, (0.5, 0.5), 12, 0.5, 0.04, hexc('#ffb840', 0.9), seed=133)
    rays(c, (0.5, 0.5), 24, 0.36, 0.012, hexc('#ffe090', 0.9), seed=134, start=0.13)
    d = np.sqrt((c.x - 0.5) ** 2 + (c.y - 0.5) ** 2)
    sun = smooth(0.16, 0.14, d)
    c.glow_add(ramp(sun * (0.7 + 0.3 * noise(c.n, 20, 135, 4)), HOLY) * sun[..., None] * 0.6)
    save(c, 'radiance')

def icon_salvation():
    c = Canvas(N); background(c, '#4a4020', '#0a0904', seed=136)
    beam(c, 0.5, 0.2, HOLY, 137, heat=0.8, top=0.0, bottom=0.62)
    rays(c, (0.5, 0.5), 8, 0.5, 0.025, hexc('#fff0c0', 1.3), seed=138)
    rays(c, (0.5, 0.5), 32, 0.42, 0.008, hexc('#ffd080', 0.9), seed=139)
    ring(c, (0.5, 0.5), 0.22, 0.01, HOLY, seed=160, heat=0.8)
    glow_ball(c, (0.5, 0.5), 0.06, hexc('#ffffff'), 1.4)
    save(c, 'salvation')

def icon_inner_fire():
    c = Canvas(N); background(c, '#4a2410', '#0a0503', seed=140, center=(0.5, 0.6))
    rune_circle(c, (0.5, 0.52), 0.4, GOLD, 142, heat=0.8, ticks=16)
    comet(c, (0.5, 0.3), (0.5, 0.78), 0.16, 0.1, FIRE, 141, heat=0.75, lick=0.14)
    comet(c, (0.5, 0.42), (0.5, 0.76), 0.08, 0.06, HOLY, 162, heat=0.7, lick=0.06)
    save(c, 'inner_fire')

def icon_resurrection():
    c = Canvas(N); background(c, '#3a3420', '#080704', seed=143, center=(0.5, 0.35))
    beam(c, 0.5, 0.16, HOLY, 144, heat=0.85, top=0.0, bottom=0.9)
    # an ankh of light
    d = np.sqrt((c.x - 0.5) ** 2 + ((c.y - 0.3) * 0.8) ** 2)
    loop = smooth(0.1, 0.085, d) * smooth(0.045, 0.06, d)
    stem = smooth(0.025, 0.018, np.abs(c.x - 0.5)) * smooth(0.36, 0.38, c.y) * smooth(0.82, 0.8, c.y)
    bar = smooth(0.022, 0.015, np.abs(c.y - 0.44)) * smooth(0.16, 0.15, np.abs(c.x - 0.5))
    m = np.clip(loop + stem + bar, 0, 1)
    c.glow_add(m[..., None] * np.array(hexc('#fff4d0', 2.2)))
    rng = np.random.default_rng(145)
    dots(c, [(0.5 + rng.normal(0, 0.15), rng.uniform(0.2, 0.95), rng.uniform(0.004, 0.009)) for _ in range(30)], hexc('#fff0c0', 2.0))
    save(c, 'resurrection')

# ================================================================== everyone else

def icon_hearthstone():
    c = Canvas(N); background(c, '#2a3040', '#05060a', seed=150)
    stone = [(0.3, 0.42), (0.36, 0.28), (0.5, 0.22), (0.66, 0.28), (0.72, 0.44), (0.68, 0.66), (0.54, 0.76), (0.38, 0.72), (0.3, 0.58)]
    m = shade_poly(c, stone, hexc('#7a8090', 0.8), spec=0.9)
    d = np.sqrt((c.x - 0.51) ** 2 + (c.y - 0.5) ** 2)
    rune = (smooth(0.1, 0.09, d) * smooth(0.07, 0.08, d) + smooth(0.012, 0.006, np.abs(c.x - 0.51)) * smooth(0.12, 0.1, np.abs(c.y - 0.5))) * m
    c.glow_add(np.clip(rune, 0, 1)[..., None] * np.array(hexc('#60c8ff', 2.2)))
    glow_ball(c, (0.51, 0.5), 0.12, hexc('#4090ff'), 0.4)
    save(c, 'hearthstone')

def icon_summon_stag():
    c = Canvas(N); background(c, '#24344a', '#04060a', seed=151, center=(0.3, 0.3))
    glow_ball(c, (0.26, 0.24), 0.07, hexc('#e8f0ff'), 1.2)
    c.paint(hexc('#16241a'), smooth(0.8, 0.84, c.y + (noise(c.n, 6, 161, 3) - 0.5) * 0.04))
    sprite(c, 'stag', (0.58, 0.6), 1.35, rim=hexc('#c8e0ff'), rim_k=0.5)
    save(c, 'summon_stag')

def icon_myth_quake():
    c = Canvas(N); background(c, '#5a2a08', '#0c0602', seed=152, center=(0.5, 0.7))
    gy = 0.74
    c.paint(hexc('#2a1a10'), smooth(gy - 0.01, gy + 0.02, c.y))
    cr = streaks(c.n, 10, 153, math.pi / 2, 5.0, 5)
    cm = smooth(gy - 0.01, gy + 0.02, c.y) * smooth(0.72, 0.8, cr)
    c.glow_add(ramp(cm * 1.2, FIRE) * cm[..., None])
    burst(c, (0.5, gy), 0.12, FIRE, 154, heat=0.9, spikes=14, spike_len=0.2)
    sprite(c, 'worldbreaker', (0.5, 0.36), 0.85, rim=hexc('#ffa040'), rim_k=0.6)
    save(c, 'myth_quake')

def icon_myth_hours():
    c = Canvas(N); background(c, '#3a2a14', '#080503', seed=155)
    rune_circle(c, (0.5, 0.5), 0.42, GOLD, 156, heat=0.9, ticks=12)
    sprite(c, 'eternity', (0.5, 0.5), 0.9, angle=0, rim=hexc('#ffc060'), rim_k=0.9)
    save(c, 'myth_hours')

def icon_myth_dawn():
    c = Canvas(N); background(c, '#5a3a18', '#0a0703', seed=157, center=(0.5, 0.75))
    rays(c, (0.5, 0.82), 20, 0.7, 0.018, hexc('#ffc050', 0.9), seed=158)
    glow_ball(c, (0.5, 0.86), 0.12, hexc('#ffe0a0'), 1.0)
    sprite(c, 'moon', (0.5, 0.44), 0.85, rim=hexc('#fff0b0'), rim_k=0.8)
    save(c, 'myth_dawn')

ICONS = {k[5:]: v for k, v in dict(globals()).items() if k.startswith('icon_')}

if __name__ == '__main__':
    names = sys.argv[1:] or list(ICONS)
    for n in names: ICONS[n](); print('icon', n)
