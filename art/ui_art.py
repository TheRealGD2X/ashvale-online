"""
UI art painted in code: icon frames (per quality), and later the HUD orbs, hotbar and panels.
    python3 art/ui_art.py
Writes godot/assets/ui/*.png (with alpha).
"""
import sys, os, math
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paint import *
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(ROOT, 'godot', 'assets', 'ui'); os.makedirs(UI, exist_ok=True)

def rounded_sq(c, inset, radius):
    """signed-ish distance field for a rounded square (0..1 coords), negative inside"""
    qx = np.abs(c.x - 0.5) - (0.5 - inset - radius); qy = np.abs(c.y - 0.5) - (0.5 - inset - radius)
    out = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2) + np.minimum(np.maximum(qx, qy), 0) - radius
    return out

def save_rgba(c, alpha, path, size):
    img = c.rgb.copy()
    img = np.clip(img, 0, None); lum = img.max(axis=2, keepdims=True)
    mapped = 1.0 - np.exp(-lum * 1.6); img = img / np.maximum(lum, 1e-5) * mapped
    img = np.clip(img, 0, 1)
    rgb = (np.power(img, 1 / 2.2) * 255).astype(np.uint8)
    a = (np.clip(alpha, 0, 1) * 255).astype(np.uint8)
    Image.fromarray(np.dstack([rgb, a]), 'RGBA').resize((size, size), Image.LANCZOS).save(path)

def icon_frame(name, metal='#7a5a34', glow=None, glow_k=0.0, size=128):
    """an ornate square frame: a bevelled metal band with an inner shadow and small corner studs"""
    c = Canvas(512)
    d = rounded_sq(c, 0.01, 0.06)
    band = smooth(0.004, -0.004, d) * smooth(-0.07, -0.062, d)            # the metal ring
    # bevel: light from top-left across the ring's cross-section
    t = np.clip((-d) / 0.066, 0, 1)                                       # 0 outer edge .. 1 inner edge
    ridge = np.sin(t * math.pi)
    lightdir = (0.5 - c.x) * 0.7 + (0.5 - c.y) * 1.0
    shade = 0.45 + 0.8 * ridge * (0.6 + 0.6 * np.sign(lightdir) * np.clip(np.abs(lightdir) * 3, 0, 1) * (1 - 2 * (t > 0.5)))
    grain = 0.85 + 0.3 * noise(c.n, 40, 3, 4, aniso=(1.0, 0.2))
    col = np.asarray(hexc(metal), np.float32) * (shade * grain)[..., None]
    c.rgb = col * band[..., None]
    # specular glint along the upper-left edges
    spec = band * np.clip(ridge * np.clip(lightdir * 2, 0, 1), 0, 1) ** 3
    c.rgb += spec[..., None] * np.array(hexc('#fff0d0', 1.2))
    # dark inner lip (the recess the picture sits in)
    lip = smooth(-0.062, -0.07, d) * smooth(-0.1, -0.07, d)
    alpha = np.maximum(band, lip * 0.75)
    c.rgb = c.rgb * (1 - lip[..., None] * 0.9)
    # studs in the corners
    for (x, y) in [(0.07, 0.07), (0.93, 0.07), (0.07, 0.93), (0.93, 0.93)]:
        r = np.sqrt((c.x - x) ** 2 + (c.y - y) ** 2)
        stud = smooth(0.026, 0.018, r)
        hl = np.clip(1 - np.sqrt((c.x - x + 0.008) ** 2 + (c.y - y + 0.008) ** 2) / 0.02, 0, 1)
        c.rgb = c.rgb * (1 - stud[..., None]) + (np.asarray(hexc(metal, 1.3)) * (0.6 + hl[..., None] * 1.2)) * stud[..., None]
        alpha = np.maximum(alpha, stud)
    if glow is not None:
        g = smooth(-0.04, -0.075, d) * smooth(-0.16, -0.075, d)
        c.rgb += g[..., None] * np.asarray(hexc(glow), np.float32) * glow_k
        alpha = np.maximum(alpha, g * glow_k * 0.9)
    save_rgba(c, alpha, os.path.join(UI, name + '.png'), size)
    print('ui', name)

def frames():
    icon_frame('frame_ability', '#8a6a3a')
    for q, col in [(0, '#6a6a6a'), (1, '#b0b0b0'), (2, '#30d018'), (3, '#1a78e0'), (4, '#a838f0'), (5, '#ff8a10')]:
        icon_frame('frame_q%d' % q, '#7a6448', glow=col, glow_k=0.0 if q <= 1 else 0.9)


class Wide:
    """a non-square canvas (w x h pixels) with the same painting tools"""
    def __init__(self, w, h):
        self.w, self.h = w, h; self.n = max(w, h)
        y, x = np.mgrid[0:h, 0:w].astype(np.float32)
        self.x, self.y = x / w, y / h          # 0..1 across each axis
        self.px, self.py = x, y                # pixels
        self.rgb = np.zeros((h, w, 3), np.float32)

def save_wide(c, alpha, path, out_w, out_h):
    img = np.clip(c.rgb, 0, None); lum = img.max(axis=2, keepdims=True)
    mapped = 1.0 - np.exp(-lum * 1.6); img = np.clip(img / np.maximum(lum, 1e-5) * mapped, 0, 1)
    rgb = (np.power(img, 1 / 2.2) * 255).astype(np.uint8); a = (np.clip(alpha, 0, 1) * 255).astype(np.uint8)
    Image.fromarray(np.dstack([rgb, a]), 'RGBA').resize((out_w, out_h), Image.LANCZOS).save(path)

def metal_shade(c, t, lightdir, metal, grain_seed=5):
    """a bevelled metal band: t = 0 at one edge of the band, 1 at the other"""
    ridge = np.sin(np.clip(t, 0, 1) * math.pi)
    shade = 0.4 + 0.9 * ridge * (0.55 + 0.45 * lightdir)
    gn = noise(max(c.w, c.h) if hasattr(c, 'w') else c.n, 60, grain_seed, 3)
    if hasattr(c, 'w'): gn = gn[:c.h, :c.w]
    return np.asarray(hexc(metal), np.float32) * (shade * (0.85 + 0.3 * gn))[..., None], ridge

def orb_frame(name='orb_frame', metal='#8a6a3a', gem='#c02020', size=256):
    """the ring round a health or mana orb: bronze, engraved, with a gem at the top and a cradle below"""
    c = Canvas(768)
    dx, dy = c.x - 0.5, c.y - 0.5
    r = np.sqrt(dx * dx + dy * dy); ang = np.arctan2(dy, dx)
    r_in, r_out = 0.385, 0.47
    band = smooth(r_out + 0.003, r_out - 0.003, r) * smooth(r_in - 0.003, r_in + 0.003, r)
    t = (r - r_in) / (r_out - r_in)
    lightdir = np.clip(-(dx * 0.6 + dy * 1.0) / np.maximum(r, 1e-3), -1, 1) * np.where(t < 0.5, -1, 1)
    col, ridge = metal_shade(c, t, lightdir, metal)
    # engraving: small ticks all round the ring
    ticks = (np.cos(ang * 48) > 0.93) * smooth(0.2, 0.3, t) * smooth(0.8, 0.7, t)
    col *= (1 - 0.5 * ticks)[..., None]
    c.rgb = col * band[..., None]
    spec = band * np.clip(ridge * np.clip(lightdir, 0, 1), 0, 1) ** 4
    c.rgb += spec[..., None] * np.array(hexc('#fff0d0', 1.1))
    alpha = band.copy()
    # inner shadow lip over the liquid
    lip = smooth(r_in + 0.004, r_in - 0.002, r) * smooth(r_in - 0.04, r_in, r)
    c.rgb = c.rgb * (1 - lip[..., None]) ; alpha = np.maximum(alpha, lip * 0.7)
    # a gem set at the top, in a little claw
    gy = 0.5 - (r_out + r_in) / 2
    for (gx, gyy, gr, gc) in [(0.5, gy, 0.045, gem)]:
        d = np.sqrt((c.x - gx) ** 2 + (c.y - gyy) ** 2)
        setting = smooth(gr + 0.018, gr + 0.012, d)
        c.rgb = c.rgb * (1 - setting[..., None]) + np.asarray(hexc(metal, 1.2)) * setting[..., None] * (0.7 + 0.5 * ((c.y - gyy) < 0))[..., None]
        stone = smooth(gr, gr - 0.004, d)
        hl = np.clip(1 - np.sqrt((c.x - gx + gr * 0.35) ** 2 + (c.y - gyy + gr * 0.35) ** 2) / (gr * 0.5), 0, 1)
        g = np.asarray(hexc(gc, 1.4)) * (0.4 + 0.8 * smooth(gr, 0, d))[..., None] + hl[..., None] ** 2 * 2.0
        c.rgb = c.rgb * (1 - stone[..., None]) + g * stone[..., None]
        alpha = np.maximum(alpha, setting)
    # the cradle: two curling arms under the orb
    for sgn in (-1, 1):
        cx = 0.5 + sgn * 0.3; cy = 0.86
        d = np.sqrt((c.x - cx) ** 2 + ((c.y - cy) * 1.4) ** 2)
        arm = smooth(0.11, 0.105, d) * smooth(0.075, 0.08, d) * (c.y > cy - 0.02)
        tt = np.clip((d - 0.075) / 0.035, 0, 1)
        acol, aridge = metal_shade(c, tt, -np.ones_like(tt) * 0.3, metal, 9)
        c.rgb = c.rgb * (1 - arm[..., None]) + acol * arm[..., None]
        alpha = np.maximum(alpha, arm)
    save_rgba(c, alpha, os.path.join(UI, name + '.png'), size)
    print('ui', name)

def hotbar(name='hotbar', slots=5, metal='#8a6a3a', stone='#2a2622'):
    """the plate the action bar sits on: dark stone with a bronze rim, a recess for each slot"""
    W, H = 1160, 220
    c = Wide(W, H)
    # the plate: a long rounded shape, fuller in the middle
    cx, cy = W / 2, H / 2 + 10
    hw, hh = W / 2 - 16, 78
    qx = np.abs(c.px - cx) - (hw - 40); qy = np.abs(c.py - cy) - (hh - 40)
    d = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2) + np.minimum(np.maximum(qx, qy), 0) - 40
    plate = smooth(1.5, -1.5, d)
    n1 = noise(W, 12, 21, 6)[:H, :W]; n2 = noise(W, 40, 22, 4)[:H, :W]
    shade = 0.75 + 0.25 * (1 - (c.py - (cy - hh)) / (2 * hh)) + (n1 - 0.5) * 0.3 + (n2 - 0.5) * 0.15
    c.rgb = np.asarray(hexc(stone), np.float32) * shade[..., None] * plate[..., None]
    alpha = plate.copy()
    # bronze rim
    rim = smooth(1.5, -1.5, d) * smooth(-16, -12, d)
    t = np.clip(-d / 14.0, 0, 1)
    ld = np.clip((cy - c.py) / hh, -1, 1) * np.where(t < 0.5, 1, -1)
    mcol, ridge = metal_shade(c, t, ld, metal, 23)
    c.rgb = c.rgb * (1 - rim[..., None]) + mcol * rim[..., None]
    c.rgb += (rim * np.clip(ridge * np.clip(ld, 0, 1), 0, 1) ** 4)[..., None] * np.array(hexc('#fff0d0', 1.0))
    # slot recesses
    size = 150; gap = 22
    total = slots * size + (slots - 1) * gap
    x0 = cx - total / 2
    pos = []
    for i in range(slots):
        sx = x0 + i * (size + gap) + size / 2
        pos.append(sx)
        qx2 = np.abs(c.px - sx) - (size / 2 - 14); qy2 = np.abs(c.py - cy) - (size / 2 - 14)
        d2 = np.sqrt(np.maximum(qx2, 0) ** 2 + np.maximum(qy2, 0) ** 2) + np.minimum(np.maximum(qx2, qy2), 0) - 14
        hole = smooth(2, -2, d2)
        inner_shadow = smooth(-18, 0, d2) * hole
        c.rgb = c.rgb * (1 - hole[..., None] * 0.75) - inner_shadow[..., None] * 0.02
        ring = smooth(5, 2, d2) * smooth(-1, 2, d2)
        c.rgb += ring[..., None] * np.array(hexc('#b89060', 0.5))
    # small filigree at both ends
    for sgn in (-1, 1):
        ex = cx + sgn * (hw - 50)
        dd = np.sqrt((c.px - ex) ** 2 + (c.py - cy) ** 2)
        knob = smooth(22, 19, dd)
        hl = np.clip(1 - np.sqrt((c.px - ex + 6) ** 2 + (c.py - cy + 6) ** 2) / 12, 0, 1)
        c.rgb = c.rgb * (1 - knob[..., None]) + (np.asarray(hexc(metal, 1.2)) * (0.6 + hl[..., None] * 1.3)) * knob[..., None]
    c.rgb = np.clip(c.rgb, 0, None)
    save_wide(c, alpha, os.path.join(UI, name + '.png'), W // 2, H // 2)
    print('ui', name, 'slot centres (px at half size):', [round(p / 2, 1) for p in pos], 'y', cy / 2)

def hud():
    orb_frame('orb_frame_hp', gem='#d02818')
    orb_frame('orb_frame_mp', gem='#2050e0')
    hotbar()

# ------------------------------------------------------------------ Albion-style panels (9-slice textures)
def rrect_px(c, x0, y0, x1, y1, r):
    """signed distance in pixels to a rounded rectangle (negative inside)"""
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2; hx, hy = (x1 - x0) / 2 - r, (y1 - y0) / 2 - r
    qx = np.abs(c.px - cx) - hx; qy = np.abs(c.py - cy) - hy
    return np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2) + np.minimum(np.maximum(qx, qy), 0) - r

def leather(c, dark, light, seed=1, grain=0.35):
    """dark tooled leather: soft blotches, fine grain, a little lighter in the middle"""
    n = max(c.w, c.h)
    b = noise(n, 4, seed, 5)[:c.h, :c.w]; g = noise(n, 70, seed + 3, 3)[:c.h, :c.w]; s = noise(n, 18, seed + 5, 4, aniso=(1.0, 0.3))[:c.h, :c.w]
    t = np.clip(b * 0.7 + s * 0.3, 0, 1)
    col = np.asarray(hexc(dark), np.float32) * (1 - t[..., None]) + np.asarray(hexc(light), np.float32) * t[..., None]
    return col * (1.0 + (g[..., None] - 0.5) * grain)

def panel9(name, W, H, radius, border, metal, dark, light, bg_alpha=0.96, shadow=12, hair=True, studs=True, header=0, scale=2, seed=1):
    """a window/panel skin: leather body, bevelled metal rim, gold hairline inside, corner studs,
    a soft drop shadow in the outer margin (the game draws it with expand margins)"""
    c = Wide(W * scale, H * scale)
    S = shadow * scale; R = radius * scale; B = border * scale
    d = rrect_px(c, S, S, c.w - S, c.h - S, R)
    body = smooth(0.8, -0.8, d)
    col = leather(c, dark, light, seed)
    # the header band: a darker strip under the title
    if header:
        hb = smooth(0, 3 * scale, c.py - S - B - header * scale)
        col = col * (0.62 + 0.38 * hb[..., None])
    # inner vignette: darker toward the rim
    col *= (0.7 + 0.3 * smooth(-0.0, -28.0 * scale, d))[..., None]
    rgb = col
    # the rim: a bevelled metal band, lit from the top left
    t = np.clip(-d / B, 0, 1)
    band = smooth(0.8, -0.8, d) * smooth(-B - 0.8, -B + 0.8, d)
    gy, gx = np.gradient(d)
    ln = np.sqrt(gx * gx + gy * gy) + 1e-6
    lightdir = np.clip(-(gx / ln) * 0.6 - (gy / ln) * 0.8, -1, 1) * (1 - 2 * (t > 0.5))
    mcol, ridge = metal_shade(c, t, lightdir, metal, seed + 7)
    spec = np.clip(ridge * np.clip(lightdir, 0, 1), 0, 1) ** 3 * band
    rgb = rgb * (1 - band[..., None]) + (mcol + spec[..., None] * np.array(hexc('#fff0d0', 1.0))) * band[..., None]
    # a dark lip inside the rim and a thin gold hairline a little further in
    lip = smooth(-B - 0.5, -B - 4 * scale, d) * smooth(-B - 12 * scale, -B - 4 * scale, d)
    rgb *= (1 - 0.5 * lip * (1 - band))[..., None]
    if hair:
        hl = np.exp(-((d + B + 6 * scale) / (0.8 * scale)) ** 2)
        rgb += hl[..., None] * np.array(hexc(metal, 0.7)) * 0.8
    alpha = np.maximum(body * bg_alpha, band)
    # corner studs: a small domed rivet set into each corner of the rim
    if studs:
        k = S + R - (R - B * 0.5) * 0.7071
        for (x, y) in [(k, k), (c.w - k, k), (k, c.h - k), (c.w - k, c.h - k)]:
            r = np.sqrt((c.px - x) ** 2 + (c.py - y) ** 2); rs = B * 0.9
            stud = smooth(rs, rs - 1.5 * scale, r)
            hl = np.clip(1 - np.sqrt((c.px - x + rs * 0.35) ** 2 + (c.py - y + rs * 0.35) ** 2) / (rs * 0.9), 0, 1)
            scol = np.asarray(hexc(metal, 1.1)) * (0.45 + hl[..., None] * 1.3)
            rgb = rgb * (1 - stud[..., None]) + scol * stud[..., None]
            alpha = np.maximum(alpha, stud)
    # drop shadow outside
    if S > 0:
        sh = np.exp(-np.maximum(d, 0) / (S * 0.45)) * (d > 0)
        alpha = np.maximum(alpha, sh * 0.45 * (1 - body))
    rgb = rgb * body[..., None] + 0 * (1 - body[..., None]) + rgb * band[..., None] * (1 - body[..., None])
    c.rgb = rgb
    save_wide(c, alpha, os.path.join(UI, name + '.png'), W, H)
    print('ui', name)

def button9(name, W=160, H=48, face='#5a2a18', metal='#9a7a4a', glow=0.0, press=False, scale=2):
    c = Wide(W * scale, H * scale)
    R = 8 * scale; B = 3 * scale
    d = rrect_px(c, 1, 1, c.w - 1, c.h - 1, R)
    body = smooth(0.8, -0.8, d)
    fc = leather(c, face, _mix(face, '#000000', 0.25), 3, grain=0.12)
    # lacquer: light from above, darker at the bottom (inverted when pressed)
    v = c.py / c.h
    g = (1.0 - 0.45 * v) if not press else (0.7 + 0.25 * v)
    fc = fc * g[..., None]
    gl = np.exp(-((v - 0.16) / 0.1) ** 2) * (0 if press else 0.12)
    fc += gl[..., None] * np.array(hexc('#ffe8c0', 0.6))
    if glow: fc += (smooth(-2.0, -18.0 * scale, d) * glow)[..., None] * np.array(hexc('#ff9a40', 0.5))
    t = np.clip(-d / B, 0, 1); band = body * smooth(-B - 0.8, -B + 0.8, d)
    gy, gx = np.gradient(d); ln = np.sqrt(gx * gx + gy * gy) + 1e-6
    lightdir = np.clip(-(gx / ln) * 0.3 - (gy / ln) * 0.95, -1, 1) * (1 - 2 * (t > 0.5))
    mcol, ridge = metal_shade(c, t, lightdir, metal, 9)
    rgb = fc * (1 - band[..., None]) + mcol * band[..., None]
    c.rgb = rgb * body[..., None]
    save_wide(c, body, os.path.join(UI, name + '.png'), W, H)
    print('ui', name)

def _mix(a, b, k):
    ca = np.asarray(hexc(a)); cb = np.asarray(hexc(b)); m = ca * (1 - k) + cb * k
    s = lambda v: v * 12.92 if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055
    return '#%02x%02x%02x' % tuple(int(np.clip(s(v), 0, 1) * 255) for v in m)

def divider(name='divider', W=512, H=24, metal='#b08a50', scale=2):
    c = Wide(W * scale, H * scale)
    cy = c.h / 2; cx = c.w / 2
    dx = np.abs(c.px - cx) / cx
    line = np.exp(-((c.py - cy) / (1.2 * scale)) ** 2) * smooth(1.0, 0.7, dx)
    dia = smooth(1.0, 0.0, (np.abs(c.px - cx) + np.abs(c.py - cy)) - 9 * scale)
    ring = np.exp(-(((np.abs(c.px - cx) + np.abs(c.py - cy)) - 14 * scale) / (1.0 * scale)) ** 2)
    hl = np.clip(1 - ((c.px - cx + 3 * scale) ** 2 + (c.py - cy + 3 * scale) ** 2) ** 0.5 / (8 * scale), 0, 1)
    rgb = np.asarray(hexc(metal), np.float32) * (line + ring * 0.9)[..., None]
    rgb = rgb * (1 - dia[..., None]) + np.asarray(hexc('#c02020'), np.float32) * (0.5 + hl[..., None] * 1.4) * dia[..., None]
    c.rgb = rgb
    save_wide(c, np.clip(line + ring + dia, 0, 1), os.path.join(UI, name + '.png'), W, H)
    print('ui', name)

def panels():
    panel9('panel_window', 256, 256, 12, 5, '#9a7a4a', '#16120e', '#2c241c', 0.97, shadow=14, header=0)
    panel9('panel_hud', 128, 128, 10, 3, '#8a6a3a', '#141210', '#221c16', 0.8, shadow=8, hair=False, studs=False, seed=4)
    panel9('panel_tooltip', 128, 128, 6, 2, '#b8a070', '#0c0c12', '#16161e', 0.95, shadow=8, hair=False, studs=False, seed=6)
    panel9('panel_inset', 128, 128, 6, 2, '#5a4a34', '#0e0c0a', '#18140f', 0.85, shadow=0, hair=False, studs=False, seed=8)
    button9('btn_normal', face='#6a1c10'); button9('btn_hover', face='#7e2614', glow=0.12); button9('btn_pressed', face='#4a140c', press=True)
    button9('btn_disabled', face='#2a2622', metal='#5a5448')
    divider()

if __name__ == '__main__':
    what = sys.argv[1:] or ['frames', 'hud', 'panels']
    if 'panels' in what: panels()
    if 'frames' in what: frames()
    if 'hud' in what: hud()
