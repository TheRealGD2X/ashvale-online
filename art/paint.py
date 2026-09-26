"""
A small painter for spell icons and effect textures: layered noise, domain warping, soft shapes,
light and glow, done in numpy at twice the final size and brought down for clean edges. Every icon
is its own little painting (see art/spell_icons.py); effect flipbooks use the same tools.
"""
import numpy as np
import math
from scipy import ndimage
from PIL import Image

class Canvas:
    def __init__(self, size=512):
        self.n = size
        y, x = np.mgrid[0:size, 0:size].astype(np.float32) / size
        self.x, self.y = x, y
        self.rgb = np.zeros((size, size, 3), np.float32)      # linear light
        self.emit = np.zeros((size, size, 3), np.float32)     # what glows (gets bloom)

    # ---------------------------------------------------------------- layers
    def paint(self, col, alpha):
        """lay colour over what's there (alpha 0..1 per pixel); it covers the glow beneath it too"""
        a = np.clip(alpha, 0, 1)[..., None]
        self.rgb = self.rgb * (1 - a) + np.asarray(col, np.float32) * a
        self.emit = self.emit * (1 - a)

    def paint_img(self, img, alpha):
        a = np.clip(alpha, 0, 1)[..., None]
        self.rgb = self.rgb * (1 - a) + img * a
        self.emit = self.emit * (1 - a)

    def add(self, img):
        self.rgb += img

    def glow_add(self, img):
        """emissive light: added now, and bloomed at the end"""
        self.rgb += img; self.emit += img

    def finish(self, path, bloom=(0.9, 0.5, 0.25), exposure=1.0, size=256, vignette=0.35, sat=1.1):
        img = self.rgb.copy()
        for i, (s, k) in enumerate(zip([self.n * 0.012, self.n * 0.035, self.n * 0.09], bloom)):
            img += blur(self.emit, s) * k
        # vignette
        d = np.sqrt((self.x - 0.5) ** 2 + (self.y - 0.5) ** 2)
        img *= (1.0 - vignette * smooth(0.3, 0.75, d))[..., None]
        img *= exposure
        # gentle filmic curve: highlights roll off to white without clipping hue harshly
        lum = img.max(axis=2, keepdims=True)
        mapped = 1.0 - np.exp(-lum * 1.6)
        img = img / np.maximum(lum, 1e-5) * mapped
        img = np.clip(img + np.clip(lum - 1.2, 0, None) * 0.12, 0, 1)     # very hot goes towards white
        g = img.mean(axis=2, keepdims=True); img = np.clip(g + (img - g) * sat, 0, 1)
        out = (np.power(img, 1 / 2.2) * 255).astype(np.uint8)
        Image.fromarray(out, 'RGB').resize((size, size), Image.LANCZOS).save(path)

# -------------------------------------------------------------------- helpers

def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)

def blur(img, s):
    if s <= 0: return img
    if img.ndim == 3: return np.stack([ndimage.gaussian_filter(img[..., c], s) for c in range(img.shape[2])], axis=2)
    return ndimage.gaussian_filter(img, s)

_rng_cache = {}
def noise(n, scale, seed=0, octaves=5, persistence=0.5, aniso=(1.0, 1.0)):
    """fractal value noise in 0..1 (smooth, tileless): octaves of random lattices, cubic-upsampled"""
    rng = np.random.default_rng(seed)
    out = np.zeros((n, n), np.float32); amp = 1.0; tot = 0.0; f = scale
    for o in range(octaves):
        gy = max(2, int(f * aniso[1]) + 2); gx = max(2, int(f * aniso[0]) + 2)
        grid = rng.random((gy, gx)).astype(np.float32)
        z = ndimage.zoom(grid, (n / (gy - 1.5), n / (gx - 1.5)), order=3, mode='reflect')[:n, :n]
        if z.shape != (n, n): z = np.pad(z, ((0, n - z.shape[0]), (0, n - z.shape[1])), mode='edge')
        out += z * amp; tot += amp; amp *= persistence; f *= 2.0
    out /= tot
    return (out - out.min()) / max(1e-6, out.max() - out.min())

def streaks(n, scale, seed, angle, stretch=3.0, octaves=5):
    """noise stretched along a direction (angle in radians, image space): flame licks, motion, wind"""
    m = int(n * 1.5)
    f = noise(m, scale, seed, octaves, aniso=(1.0 / stretch, 1.0))
    r = ndimage.rotate(f, -math.degrees(angle), reshape=False, order=1, mode='reflect')
    o = (m - n) // 2
    return r[o:o + n, o:o + n]

def warp(field, dx, dy, strength):
    n = field.shape[0]
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    return ndimage.map_coordinates(field, [y + dy * strength * n, x + dx * strength * n], order=1, mode='reflect')

def ramp(t, stops):
    """colour ramp: stops = [(pos, (r,g,b)), ...] in linear light"""
    t = np.clip(t, 0, 1)
    out = np.zeros(t.shape + (3,), np.float32)
    ps = [s[0] for s in stops]; cs = [np.asarray(s[1], np.float32) for s in stops]
    for i in range(len(stops) - 1):
        a, b = ps[i], ps[i + 1]
        m = (t >= a) & (t <= b)
        k = ((t - a) / max(1e-6, b - a))[..., None]
        out[m] = (cs[i] * (1 - k) + cs[i + 1] * k)[m]
    out[t < ps[0]] = cs[0]; out[t > ps[-1]] = cs[-1]
    return out

def hexc(h, k=1.0):
    h = h.lstrip('#'); c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(((v / 12.92) if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4) * k for v in c)

FIRE = [(0.0, (0, 0, 0)), (0.18, hexc('#3a0602')), (0.38, hexc('#b3200a')), (0.58, hexc('#ff6a10', 1.4)), (0.78, hexc('#ffc040', 2.5)), (1.0, hexc('#fff6d8', 5.0))]
FROST = [(0.0, (0, 0, 0)), (0.25, hexc('#062040')), (0.5, hexc('#1a70c0')), (0.75, hexc('#8fd8ff', 1.8)), (1.0, hexc('#f0fcff', 4.0))]
HOLY = [(0.0, (0, 0, 0)), (0.3, hexc('#4a3004')), (0.6, hexc('#e0a830', 1.5)), (0.85, hexc('#fff0b0', 2.8)), (1.0, hexc('#ffffff', 5.0))]
SHADOW = [(0.0, (0, 0, 0)), (0.3, hexc('#1a0630')), (0.6, hexc('#6a28b0', 1.3)), (0.85, hexc('#c890ff', 2.4)), (1.0, hexc('#f4e8ff', 4.0))]
ARCANE = [(0.0, (0, 0, 0)), (0.3, hexc('#20083a')), (0.6, hexc('#b040e0', 1.4)), (0.85, hexc('#ffa0ff', 2.6)), (1.0, hexc('#ffffff', 4.5))]
NATURE = [(0.0, (0, 0, 0)), (0.3, hexc('#0a2a08')), (0.6, hexc('#40b030', 1.3)), (0.85, hexc('#c8ff90', 2.4)), (1.0, hexc('#ffffff', 4.0))]

def seg_dist(c, a, b):
    """distance from every pixel to segment a-b, and t along it (0 at a)"""
    ax, ay = a; bx, by = b
    vx, vy = bx - ax, by - ay
    L2 = vx * vx + vy * vy
    t = np.clip(((c.x - ax) * vx + (c.y - ay) * vy) / L2, 0, 1)
    px, py = ax + vx * t, ay + vy * t
    return np.sqrt((c.x - px) ** 2 + (c.y - py) ** 2), t

def background(c, inner, outer, seed=1, center=(0.5, 0.45), texture=0.35):
    """a painted backdrop: a warm pool of light in the middle falling to a deep edge, with brushy noise"""
    d = np.sqrt((c.x - center[0]) ** 2 + (c.y - center[1]) ** 2)
    base = ramp(smooth(0.0, 0.72, d), [(0, hexc(inner)), (1, hexc(outer))])
    tex = noise(c.n, 5, seed, 6)
    tex2 = noise(c.n, 18, seed + 9, 4, aniso=(1.0, 0.35))       # brush streaks
    k = 1.0 + (tex - 0.5) * texture + (tex2 - 0.5) * texture * 0.6
    c.rgb = base * k[..., None]

def dots(c, pts, col, strength=1.0):
    """little glowing sparks: pts = [(x, y, radius), ...]"""
    img = np.zeros_like(c.rgb)
    for (x, y, r) in pts:
        d = np.sqrt((c.x - x) ** 2 + (c.y - y) ** 2)
        img += np.exp(-(d / r) ** 2)[..., None] * np.asarray(col, np.float32)
    c.glow_add(img * strength)

# -------------------------------------------------------------------- shapes and sprites

import os
from PIL import ImageDraw
SPRITES = os.path.join(os.path.dirname(os.path.abspath(__file__)), '_sprites')
_spr = {}

def _lin(a): return np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)

def sprite(c, name, center, size, angle=0.0, light=1.0, rim=None, rim_k=1.0, flip=False):
    """paste a rendered object (art/_sprites/<name>.png) — centre and size in 0..1, angle in degrees"""
    if name not in _spr: _spr[name] = Image.open(os.path.join(SPRITES, name + '.png')).convert('RGBA')
    im = _spr[name]
    if flip: im = im.transpose(Image.FLIP_LEFT_RIGHT)
    px = int(size * c.n)
    im = im.resize((px, px), Image.LANCZOS).rotate(angle, resample=Image.BICUBIC, expand=True)
    layer = Image.new('RGBA', (c.n, c.n), (0, 0, 0, 0))
    layer.paste(im, (int(center[0] * c.n - im.width / 2), int(center[1] * c.n - im.height / 2)), im)
    a = np.asarray(layer, np.float32) / 255.0
    rgb = _lin(a[..., :3]) * light; al = a[..., 3]
    c.paint_img(rgb, al)
    if rim is not None:
        edge = np.clip(blur(al, c.n * 0.01) * 1.5 - al, 0, 1)          # a halo just outside the object
        c.glow_add(edge[..., None] * np.asarray(rim, np.float32) * rim_k * 0.35)
    return al

def poly_mask(c, pts, soft=1.0):
    """a filled polygon (points in 0..1) as a soft mask"""
    im = Image.new('L', (c.n, c.n), 0); ImageDraw.Draw(im).polygon([(x * c.n, y * c.n) for x, y in pts], fill=255)
    m = np.asarray(im, np.float32) / 255.0
    return blur(m, soft) if soft > 0 else m

def arc(c, center, radius, a0, a1, width, palette, seed=0, heat=1.0, taper=True):
    """a slash or swipe: a crescent sweeping from angle a0 to a1 (degrees), thin at the tail, bright at the lead"""
    dx, dy = c.x - center[0], c.y - center[1]
    r = np.sqrt(dx * dx + dy * dy)
    ang = np.degrees(np.arctan2(dy, dx))
    span = a1 - a0
    rel = np.mod((ang - a0) * np.sign(span), 360.0)                  # degrees travelled from the tail
    t = np.clip(rel / abs(span), 0, 1)                               # 0 at the tail, 1 at the lead
    inside = (rel <= abs(span)).astype(np.float32) * smooth(abs(span) + 1e-3, abs(span) * 0.9, rel)
    w = width * (t ** 0.8 if taper else 1.0)
    band = np.exp(-((r - radius) / np.maximum(w, 1e-4)) ** 2) * inside
    st = noise(c.n, 30, seed, 3, aniso=(0.25, 1.0))
    temp = band * (0.3 + 0.7 * t) * (0.7 + 0.5 * st)
    c.glow_add(ramp(temp * heat, palette) * band[..., None] * 0.6)
    return band

def ring(c, center, radius, width, palette, seed=0, heat=1.0, wobble=0.02):
    dx, dy = c.x - center[0], c.y - center[1]
    r = np.sqrt(dx * dx + dy * dy)
    nz = noise(c.n, 12, seed, 5)
    band = np.exp(-((r - radius - (nz - 0.5) * wobble) / width) ** 2)
    c.glow_add(ramp(band * heat * (0.6 + 0.6 * nz), palette) * band[..., None] * 0.6)
    return band

def rays(c, center, n, length, width, col, seed=0, k=1.0, start=0.0):
    rng = np.random.default_rng(seed)
    dx, dy = c.x - center[0], c.y - center[1]
    r = np.sqrt(dx * dx + dy * dy); ang = np.arctan2(dy, dx)
    img = np.zeros(r.shape, np.float32)
    for i in range(n):
        a = start + i * 2 * math.pi / n + rng.normal(0, 0.08)
        L = length * rng.uniform(0.7, 1.1)
        da = np.abs((ang - a + math.pi) % (2 * math.pi) - math.pi)
        img += np.exp(-(da * r / (width * (1 - np.clip(r / L, 0, 1)) + 1e-4)) ** 2) * np.clip(1 - r / L, 0, 1)
    c.glow_add(img[..., None] * np.asarray(col, np.float32) * k)
    return img

def glow_ball(c, center, radius, col, k=1.0):
    d = np.sqrt((c.x - center[0]) ** 2 + (c.y - center[1]) ** 2)
    c.glow_add(np.exp(-(d / radius) ** 2)[..., None] * np.asarray(col, np.float32) * k)

def shade_poly(c, pts, base, light_dir=(-0.6, -0.8), spec=0.6, soft=0.8, emit=None, emit_k=0.0):
    """a solid shape shaded like a lit, bevelled surface (for shields, crystals, stones)"""
    m = poly_mask(c, pts, soft)
    inside = poly_mask(c, pts, 0)
    dist = ndimage.distance_transform_edt(inside) / c.n
    gy, gx = np.gradient(blur(np.clip(dist * 25, 0, 1), c.n * 0.004))
    nl = -(gx * light_dir[0] + gy * light_dir[1]) * 40
    shade = np.clip(0.55 + nl, 0.15, 1.6)
    grad = 1.0 - 0.45 * ((c.y - min(p[1] for p in pts)) / max(1e-3, max(p[1] for p in pts) - min(p[1] for p in pts)))
    col = np.asarray(base, np.float32) * (shade * grad)[..., None]
    c.paint_img(col, m)
    hl = np.clip(nl, 0, None) ** 2 * spec * m
    c.add(hl[..., None] * np.array([1.0, 0.95, 0.85]))
    if emit is not None: c.glow_add(m[..., None] * np.asarray(emit, np.float32) * emit_k)
    return m

def smoke(c, center, radius, col, seed=0, k=1.0, stretch=(1.0, 1.0)):
    n1 = noise(c.n, 6, seed, 6, persistence=0.55)
    dx = (c.x - center[0]) / stretch[0]; dy = (c.y - center[1]) / stretch[1]
    d = np.sqrt(dx * dx + dy * dy)
    m = smooth(radius, radius * 0.2, d + (n1 - 0.5) * radius * 0.9) * n1
    c.paint(col, m * k)
    return m
