"""
Textures for spell and ability effects, painted in code: animated flipbooks (fire, smoke, explosion,
frost mist, shadow wisps) and sprites (flares, spark streaks, embers, ice shards, light rays, shock
rings, weapon-slash bands) and ground decals (scorch, frost, holy glyph, rune circle, cracks).

    python3 art/vfx_textures.py [names...]
Writes godot/assets/fx/<name>.png. Flipbooks are 4 x 4 frames, read left to right, top to bottom.
"""
import os, sys, math
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paint import noise, blur, smooth, ramp, hexc, streaks, warp, FIRE, FROST, HOLY, SHADOW

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'godot', 'assets', 'fx'); os.makedirs(OUT, exist_ok=True)

def grid(n):
    y, x = np.mgrid[0:n, 0:n].astype(np.float32) / n
    return x, y

def to8(a): return (np.clip(a, 0, 1) * 255).astype(np.uint8)
def srgb(a): a = np.clip(a, 0, 1); return np.where(a <= 0.0031308, a * 12.92, 1.055 * a ** (1 / 2.4) - 0.055)

def save_rgba(path, rgb, a, size=None):
    im = Image.fromarray(np.dstack([to8(srgb(rgb)), to8(a)]), 'RGBA')
    if size: im = im.resize(size, Image.LANCZOS)
    im.save(path, optimize=True)
    print('fx', os.path.basename(path))

def sheet(frames, fsize):
    """pack 16 (rgb, alpha) frames into a 4 x 4 sheet"""
    n = frames[0][0].shape[0]
    rgb = np.zeros((n * 4, n * 4, 3), np.float32); a = np.zeros((n * 4, n * 4), np.float32)
    for i, (fr, fa) in enumerate(frames):
        r, c = divmod(i, 4)
        rgb[r * n:(r + 1) * n, c * n:(c + 1) * n] = fr; a[r * n:(r + 1) * n, c * n:(c + 1) * n] = fa
    return rgb, a

def tonemap(c):
    """keep hue while squeezing hot values under 1 (the engine adds its own glow)"""
    lum = c.max(axis=2, keepdims=True)
    m = 1.0 - np.exp(-lum * 1.4)
    return c / np.maximum(lum, 1e-5) * m

# ------------------------------------------------------------------ flipbooks
N = 192     # working size of one frame (saved at 128)

def _scroll_noise(big, x, y, ox, oy, scale):
    """sample a big noise field at scrolled coordinates (for continuous motion between frames)"""
    n = big.shape[0]
    xi = ((x * scale + ox) % 1.0) * (n - 1); yi = ((y * scale + oy) % 1.0) * (n - 1)
    from scipy import ndimage
    return ndimage.map_coordinates(big, [yi, xi], order=1, mode='wrap')

def fire_flip():
    """a licking flame puff: born hot and round, rising, fraying, cooling to red wisps"""
    x, y = grid(N)
    big = noise(512, 8, 11, 6, persistence=0.55); big2 = noise(512, 20, 12, 5, persistence=0.6)
    frames = []
    for i in range(16):
        t = i / 15.0
        cx, cy = 0.5, 0.62 - t * 0.18
        dx, dy = (x - cx), (y - cy) * (1.0 + 0.4 * (y < cy))
        d = np.sqrt(dx * dx + dy * dy)
        n1 = _scroll_noise(big, x, y, 0.1, t * 0.5, 0.9); n2 = _scroll_noise(big2, x, y, 0.3, t * 0.9, 1.0)
        nz = n1 * 0.6 + n2 * 0.4
        r = 0.18 + 0.16 * t
        body = smooth(0.03, -0.06, d - r - (nz - 0.5) * (0.18 + 0.25 * t) + (y - cy) * 0.25)
        heat = body * (1.0 - t) ** 1.3 * (0.35 + 1.1 * nz ** 1.4) * (0.6 + 0.6 * smooth(r, 0.0, d))
        col = tonemap(ramp(heat * 1.25, FIRE))
        a = np.clip(heat * 2.2, 0, 1) * body
        frames.append((col, a))
    rgb, a = sheet(frames, N)
    save_rgba(os.path.join(OUT, 'fire_flip.png'), rgb, a, (512, 512))

def explosion_flip():
    """a fireball going off: a white flash, a boiling shell of flame racing out, embers, then gone"""
    x, y = grid(N)
    big = noise(512, 10, 21, 6, persistence=0.6)
    frames = []
    for i in range(16):
        t = i / 15.0
        d = np.sqrt((x - 0.5) ** 2 + (y - 0.5) ** 2)
        nz = _scroll_noise(big, x, y, t * 0.2, t * 0.3, 1.0)
        R = 0.08 + 0.36 * (1 - (1 - t) ** 2.5)
        shell = smooth(0.05, -0.05, d - R - (nz - 0.5) * 0.14) * smooth(-0.22 - 0.1 * t, -0.02, d - R + (nz - 0.5) * 0.2 * t)
        core = smooth(R * 0.9, 0.0, d) * (1 - t) ** 3
        heat = (shell * (0.4 + 0.9 * nz) + core * 1.5) * (1 - t) ** 1.1
        col = tonemap(ramp(np.clip(heat * 1.3, 0, 1.2), FIRE))
        a = np.clip(heat * 2.0, 0, 1)
        frames.append((col, a))
    rgb, a = sheet(frames, N)
    save_rgba(os.path.join(OUT, 'explosion_flip.png'), rgb, a, (512, 512))

def smoke_flip():
    """a smoke puff that swells and thins: grey-white, lit from above (tinted in the game)"""
    x, y = grid(N)
    big = noise(512, 7, 31, 6, persistence=0.55)
    frames = []
    for i in range(16):
        t = i / 15.0
        d = np.sqrt((x - 0.5) ** 2 + (y - 0.52) ** 2)
        nz = _scroll_noise(big, x, y, t * 0.12, t * 0.25, 0.8)
        R = 0.16 + 0.2 * t
        dens = smooth(0.06, -0.12, d - R - (nz - 0.5) * 0.22)
        dens *= (0.5 + 0.7 * nz) * (1 - t) ** 0.9
        gy = np.gradient(blur(dens, 4), axis=0)
        shade = np.clip(0.75 - gy * 18.0, 0.35, 1.1)
        col = np.dstack([shade] * 3) * np.array([1.0, 0.98, 0.95])
        frames.append((col, np.clip(dens * 1.4, 0, 1)))
    rgb, a = sheet(frames, N)
    save_rgba(os.path.join(OUT, 'smoke_flip.png'), rgb, a, (512, 512))

def wisp_flip():
    """shadowy tendrils curling out of a dark heart (white; tinted violet in the game)"""
    x, y = grid(N)
    big = noise(512, 6, 41, 5); sw = noise(512, 3, 42, 3); sw2 = noise(512, 3, 43, 3)
    frames = []
    for i in range(16):
        t = i / 15.0
        dx, dy = x - 0.5, y - 0.5
        d = np.sqrt(dx * dx + dy * dy); ang = np.arctan2(dy, dx)
        # swirl: rotate by an amount that grows outward and with time
        rot = (1.2 + 2.0 * t) * d
        u = 0.5 + d * np.cos(ang + rot); v = 0.5 + d * np.sin(ang + rot)
        st = _scroll_noise(big, u, v, t * 0.3, t * 0.1, 1.4)
        tendr = np.clip((st - 0.45) * 4.0, 0, 1) ** 1.5
        R = 0.2 + 0.2 * t
        mask = smooth(R + 0.1, R - 0.15, d)
        a = tendr * mask * (1 - t) ** 0.8 + smooth(0.12, 0.0, d) * (1 - t) * 0.5
        frames.append((np.ones((N, N, 3), np.float32) * (0.8 + 0.2 * tendr[..., None]), np.clip(a, 0, 1)))
    rgb, a = sheet(frames, N)
    save_rgba(os.path.join(OUT, 'wisp_flip.png'), rgb, a, (512, 512))

def mist_flip():
    """soft cold mist rolling out (white; tinted in the game)"""
    x, y = grid(N)
    big = noise(512, 5, 51, 5, persistence=0.6)
    frames = []
    for i in range(16):
        t = i / 15.0
        d = np.sqrt((x - 0.5) ** 2 + ((y - 0.5) * 1.3) ** 2)
        nz = _scroll_noise(big, x, y, t * 0.2, 0.0, 0.7)
        R = 0.2 + 0.18 * t
        a = smooth(0.08, -0.2, d - R - (nz - 0.5) * 0.2) * (0.35 + 0.8 * nz) * (1 - t) ** 1.1 * 0.8
        frames.append((np.ones((N, N, 3), np.float32), np.clip(a, 0, 1)))
    rgb, a = sheet(frames, N)
    save_rgba(os.path.join(OUT, 'mist_flip.png'), rgb, a, (512, 512))

# ------------------------------------------------------------------ sprites
def glow():
    n = 128; x, y = grid(n); d = np.sqrt((x - 0.5) ** 2 + (y - 0.5) ** 2) * 2
    a = np.exp(-(d / 0.45) ** 2) * 0.85 + np.exp(-(d / 0.12) ** 2) * 0.3
    a *= smooth(1.0, 0.85, d)
    save_rgba(os.path.join(OUT, 'glow.png'), np.ones((n, n, 3)), a)

def flare():
    """a star of light: hot core, four long rays, four short ones, a faint halo"""
    n = 256; x, y = grid(n); dx, dy = x - 0.5, y - 0.5; d = np.sqrt(dx * dx + dy * dy) * 2
    ang = np.arctan2(dy, dx)
    core = np.exp(-(d / 0.08) ** 2) + np.exp(-(d / 0.25) ** 2) * 0.35
    long_r = np.exp(-(np.abs(np.sin(ang * 2)) * d / 0.018) ** 2) * np.exp(-(d / 0.8) ** 2)
    short = np.exp(-(np.abs(np.cos(ang * 2)) * d / 0.02) ** 2) * np.exp(-(d / 0.35) ** 2) * 0.5
    halo = np.exp(-((d - 0.55) / 0.05) ** 2) * 0.12
    a = np.clip(core + long_r * 0.8 + short + halo, 0, 1) * smooth(1.0, 0.9, d)
    save_rgba(os.path.join(OUT, 'flare.png'), np.ones((n, n, 3)), a)

def spark():
    """a streak for flying sparks (long axis vertical: the game stretches it along the velocity)"""
    w, h = 32, 128
    y, x = np.mgrid[0:h, 0:w].astype(np.float32); x = (x + 0.5) / w - 0.5; y = (y + 0.5) / h - 0.5
    a = np.exp(-(x / 0.12) ** 2) * np.exp(-(y / 0.32) ** 4)
    core = np.exp(-(x / 0.05) ** 2) * np.exp(-(y / 0.2) ** 2)
    rgb = np.ones((h, w, 3)) * np.clip(0.75 + core[..., None] * 0.5, 0, 1)
    save_rgba(os.path.join(OUT, 'spark.png'), rgb, np.clip(a + core * 0.5, 0, 1))

def ember():
    n = 64; x, y = grid(n); d = np.sqrt((x - 0.5) ** 2 + (y - 0.5) ** 2) * 2
    a = np.exp(-(d / 0.18) ** 2) + np.exp(-(d / 0.5) ** 2) * 0.35
    save_rgba(os.path.join(OUT, 'ember.png'), np.ones((n, n, 3)), np.clip(a, 0, 1))

def shard():
    """an ice crystal: faceted, pale and bright along one edge (tinted slightly in the game)"""
    w, h = 64, 192
    y, x = np.mgrid[0:h, 0:w].astype(np.float32); u = (x + 0.5) / w - 0.5; v = (y + 0.5) / h
    half = 0.42 * np.clip(np.where(v < 0.3, v / 0.3, 1.0 - (v - 0.3) / 0.7 * 0.35), 0, 1)
    half = np.where(v < 0.3, 0.42 * (v / 0.3) ** 0.8, 0.42 - (v - 0.3) * 0.25)
    inside = smooth(half + 0.02, half - 0.02, np.abs(u))
    facet = np.where(u < 0, 0.55 + 0.45 * (1 + u / np.maximum(half, 1e-3)), 1.0 - 0.3 * (u / np.maximum(half, 1e-3)))
    edge = np.exp(-(u / 0.03) ** 2) * 0.6
    base = np.array(hexc('#bfe6ff')); tip = np.array(hexc('#ffffff'))
    col = base * facet[..., None] + tip * edge[..., None]
    a = inside * (0.55 + 0.45 * facet) * smooth(1.0, 0.9, v)
    save_rgba(os.path.join(OUT, 'shard.png'), np.clip(col, 0, 1), np.clip(a, 0, 1))

def rays():
    """shafts of light fanning up from a point low in the frame (holy beams, level up)"""
    n = 256; x, y = grid(n); dx, dy = x - 0.5, y - 0.95
    ang = np.arctan2(dx, -dy); d = np.sqrt(dx * dx + dy * dy)
    st = noise(n, 1, 61, 1)
    rng = np.random.default_rng(62); a = np.zeros_like(d)
    for k in range(22):
        c = rng.normal(0, 0.45); w = rng.uniform(0.01, 0.05); L = rng.uniform(0.5, 1.0)
        a += np.exp(-((ang - c) / w) ** 2) * smooth(L, L * 0.3, d) * rng.uniform(0.4, 1.0)
    a = np.clip(a, 0, 1) * smooth(0.0, 0.08, d) * smooth(1.0, 0.8, d)
    save_rgba(os.path.join(OUT, 'rays.png'), np.ones((n, n, 3)), a)

def shock_ring():
    n = 256; x, y = grid(n); d = np.sqrt((x - 0.5) ** 2 + (y - 0.5) ** 2) * 2
    nz = noise(n, 12, 71, 4)
    band = np.exp(-(np.maximum(d - 0.86, 0) / 0.03) ** 2) * smooth(0.55, 0.86, d)
    band *= (0.55 + 0.7 * nz)
    a = np.clip(band + np.exp(-((d - 0.86) / 0.012) ** 2) * 0.6, 0, 1) * smooth(1.0, 0.97, d)
    save_rgba(os.path.join(OUT, 'shock_ring.png'), np.ones((n, n, 3)), a)

def slash_band():
    """the texture along a weapon swipe: u runs tail -> lead, v runs outer edge -> inner edge"""
    w, h = 512, 64
    y, x = np.mgrid[0:h, 0:w].astype(np.float32); u = x / w; v = y / h
    st = streaks(512, 6, 81, 0.0, 6.0, 4)[:h, :]
    edge = np.exp(-(v / 0.12) ** 2)                               # the keen outer edge
    body = smooth(1.0, 0.1, v) * (0.35 + 0.8 * st)
    along = u ** 1.6 * smooth(1.0, 0.94, u)                       # grows toward the lead, clipped at the very tip
    a = np.clip((edge * 1.2 + body * 0.8) * along, 0, 1)
    rgb = np.ones((h, w, 3)) * np.clip(0.8 + edge[..., None] * 0.4, 0, 1)
    save_rgba(os.path.join(OUT, 'slash.png'), rgb, a)

def leaf():
    n = 64; x, y = grid(n); u, v = x - 0.5, y - 0.5
    w = 0.22 * np.cos(np.clip(v * 2.2, -1.5, 1.5)) ** 0.8
    inside = smooth(w + 0.02, w - 0.02, np.abs(u)) * smooth(0.48, 0.44, np.abs(v))
    vein = np.exp(-(u / 0.02) ** 2)
    col = np.array(hexc('#5ab030')) * (0.7 + 0.5 * (u < 0))[..., None] + vein[..., None] * np.array(hexc('#c8f080')) * 0.5
    save_rgba(os.path.join(OUT, 'leaf.png'), np.clip(col, 0, 1), inside)

# ------------------------------------------------------------------ ground decals
def scorch():
    """burnt ground: charred black centre fraying to brown, with embers still glowing (albedo + emission)"""
    n = 256; x, y = grid(n); d = np.sqrt((x - 0.5) ** 2 + (y - 0.5) ** 2) * 2
    nz = noise(n, 6, 91, 6); nz2 = noise(n, 30, 92, 4)
    body = smooth(0.95, 0.55, d + (nz - 0.5) * 0.5)
    dark = np.array(hexc('#0a0806')) * (1 - body[..., None] * 0) + 0
    col = np.array(hexc('#1a120c')) * (1 - body[..., None]) + np.array(hexc('#060504')) * body[..., None]
    a = np.clip(body * (0.75 + 0.3 * nz2), 0, 1) * 0.92
    save_rgba(os.path.join(OUT, 'scorch.png'), col, a)
    em = np.clip((nz2 - 0.62) * 5.0, 0, 1) * body * smooth(0.95, 0.3, d)
    ecol = tonemap(ramp(em * 0.9, FIRE) * 2.0)
    save_rgba(os.path.join(OUT, 'scorch_emit.png'), ecol, np.ones_like(em))

def frost_decal():
    """rime spreading out in feathery crystals"""
    n = 256; x, y = grid(n); dx, dy = x - 0.5, y - 0.5; d = np.sqrt(dx * dx + dy * dy) * 2; ang = np.arctan2(dy, dx)
    nz = noise(n, 8, 101, 5)
    arms = np.zeros_like(d)
    rng = np.random.default_rng(102)
    for k in range(14):
        c = rng.uniform(-math.pi, math.pi); L = rng.uniform(0.6, 1.0)
        da = np.abs((ang - c + math.pi) % (2 * math.pi) - math.pi)
        arms = np.maximum(arms, np.exp(-(da * d / 0.03) ** 2) * smooth(L, L * 0.5, d))
        for j in range(5):   # little side feathers
            p = rng.uniform(0.2, L * 0.9); side = rng.choice([-1, 1])
            bx, by = math.cos(c) * p / 2 + 0.5, math.sin(c) * p / 2 + 0.5
            ca = c + side * 0.7
            ex, ey = bx + math.cos(ca) * 0.08, by + math.sin(ca) * 0.08
            vx, vy = ex - bx, ey - by; L2 = vx * vx + vy * vy
            t = np.clip(((x - bx) * vx + (y - by) * vy) / L2, 0, 1)
            dd = np.sqrt((x - bx - vx * t) ** 2 + (y - by - vy * t) ** 2)
            arms = np.maximum(arms, np.exp(-(dd / 0.005) ** 2) * (1 - t))
    base = smooth(0.9, 0.2, d + (nz - 0.5) * 0.4) * 0.45
    a = np.clip(base + arms, 0, 1)
    col = np.array(hexc('#d8f0ff')) * (0.8 + 0.2 * arms[..., None])
    save_rgba(os.path.join(OUT, 'frost_decal.png'), col, a)

def glyph(name, kind):
    """a magic circle for the ground: rings, runes and a star (holy) or triangles (arcane); white"""
    n = 512; x, y = grid(n); dx, dy = x - 0.5, y - 0.5; d = np.sqrt(dx * dx + dy * dy) * 2; ang = np.arctan2(dy, dx)
    def line(r, w): return np.exp(-((d - r) / w) ** 2)
    a = line(0.95, 0.008) + line(0.9, 0.004) * 0.8 + line(0.62, 0.005) * 0.9 + line(0.58, 0.003) * 0.6
    # runes between the rings: little strokes of varied shape
    rng = np.random.default_rng(111 if kind == 'holy' else 112)
    band = (d > 0.66) & (d < 0.86)
    for k in range(36):
        c = -math.pi + 2 * math.pi * (k + 0.5) / 36
        da = (ang - c + math.pi) % (2 * math.pi) - math.pi
        s = da * d * 0.5                                             # arc distance
        rr = d - 0.76
        for j in range(rng.integers(2, 4)):
            p0 = (rng.uniform(-0.012, 0.012), rng.uniform(-0.06, 0.06)); p1 = (rng.uniform(-0.012, 0.012), rng.uniform(-0.06, 0.06))
            vx, vy = p1[0] - p0[0], p1[1] - p0[1]; L2 = vx * vx + vy * vy + 1e-9
            t = np.clip(((s - p0[0]) * vx + (rr - p0[1]) * vy) / L2, 0, 1)
            dd = np.sqrt((s - p0[0] - vx * t) ** 2 + (rr - p0[1] - vy * t) ** 2)
            a += np.exp(-(dd / 0.0035) ** 2) * band * 0.9
    if kind == 'holy':
        for k in range(8):   # an eight-pointed star of thin lines
            th = k * math.pi / 4
            nx, ny = math.cos(th), math.sin(th)
            a += np.exp(-((dx * nx + dy * ny) * 2 - 0.25) ** 2 / 0.00002) * (d < 0.6) * 0.8
        a += line(0.25, 0.006) * 0.8
        a += np.exp(-(d / 0.1) ** 2) * 0.4
    else:
        for k in range(6):
            th = k * math.pi / 3 + math.pi / 6
            nx, ny = math.cos(th), math.sin(th)
            a += np.exp(-((dx * nx + dy * ny) * 2 - 0.29) ** 2 / 0.00002) * (d < 0.58) * 0.8
        a += line(0.3, 0.004) * 0.7
    a = np.clip(a, 0, 1)
    save_rgba(os.path.join(OUT, name + '.png'), np.ones((n, n, 3)), a, (384, 384))

def cracks():
    """cracked ground radiating from a blow (albedo dark; emission for glowing variants)"""
    n = 256; x, y = grid(n); dx, dy = x - 0.5, y - 0.5; d = np.sqrt(dx * dx + dy * dy) * 2
    a = np.zeros_like(d)
    rng = np.random.default_rng(121)
    for k in range(9):
        th = rng.uniform(0, 2 * math.pi); px, py = 0.5, 0.5; w = 0.012
        for s in range(7):
            th += rng.normal(0, 0.35); L = rng.uniform(0.04, 0.08)
            qx, qy = px + math.cos(th) * L, py + math.sin(th) * L
            vx, vy = qx - px, qy - py; L2 = vx * vx + vy * vy
            t = np.clip(((x - px) * vx + (y - py) * vy) / L2, 0, 1)
            dd = np.sqrt((x - px - vx * t) ** 2 + (y - py - vy * t) ** 2)
            a = np.maximum(a, np.exp(-(dd / w) ** 2)); px, py = qx, qy; w *= 0.8
    a = np.clip(a * 1.2 + np.exp(-(d / 0.12) ** 2) * 0.6, 0, 1)
    save_rgba(os.path.join(OUT, 'cracks.png'), np.ones((n, n, 3)) * 0.05, a)
    save_rgba(os.path.join(OUT, 'cracks_emit.png'), np.ones((n, n, 3)) * a[..., None], np.ones_like(a))

ALL = {'fire_flip': fire_flip, 'explosion_flip': explosion_flip, 'smoke_flip': smoke_flip, 'wisp_flip': wisp_flip, 'mist_flip': mist_flip,
    'glow': glow, 'flare': flare, 'spark': spark, 'ember': ember, 'shard': shard, 'rays': rays, 'shock_ring': shock_ring, 'slash': slash_band,
    'leaf': leaf, 'scorch': scorch, 'frost_decal': frost_decal, 'glyph_holy': lambda: glyph('glyph_holy', 'holy'),
    'glyph_arcane': lambda: glyph('glyph_arcane', 'arcane'), 'cracks': cracks}

if __name__ == '__main__':
    for k in (sys.argv[1:] or list(ALL)): ALL[k]()
