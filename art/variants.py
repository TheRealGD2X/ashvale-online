"""
Makes recoloured copies of KayKit's palette textures — that's how armour sets get their colours.

A KayKit texture is a grid of 8 × 3 gradient swatches (128 × 256 px each) plus a bottom band; every
material on a character points at one swatch. Recolouring a swatch keeps its light-to-dark ramp and
changes the hue/saturation, so shading survives. The cell map (which swatch a body part uses) comes
from the UV probe; see CELLS below.

    python3 art/variants.py            # writes art/models/variants/*.png and variants.json

Usage from make_jobs.py: body("plate_gold", ..., texture="art/models/variants/knight__plate_gold.png")
"""
import os, json, colorsys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'models', 'kaykit'); OUT = os.path.join(HERE, 'models', 'variants'); os.makedirs(OUT, exist_ok=True)
CW, CH = 128, 256

def hex2rgb(h): h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))

def recolour(im, cells, target, keep_l=1.0, gain=1.0):
    """Recolour the given (col,row) cells toward `target` (hex). keep_l scales lightness; gain pushes contrast."""
    px = im.load(); th, tl, ts = colorsys.rgb_to_hls(*hex2rgb(target))
    for (c, r) in cells:
        x0, y0 = c * CW, r * CH
        for y in range(y0, min(y0 + CH, im.height)):
            for x in range(x0, x0 + CW):
                R, G, B, A = px[x, y]
                h, l, s = colorsys.rgb_to_hls(R / 255, G / 255, B / 255)
                # keep the ramp: map the pixel's lightness through the target's lightness
                nl = min(1, max(0, (0.5 + (l - 0.5) * gain) * keep_l * (tl / 0.5)))
                r2, g2, b2 = colorsys.hls_to_rgb(th, nl, ts)
                px[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255), A)

def neutral(im, cells, light=0.72):
    """Turn cells into a light neutral grey ramp so the game can tint them to any colour."""
    px = im.load()
    for (c, r) in cells:
        x0, y0 = c * CW, r * CH
        for y in range(y0, min(y0 + CH, im.height)):
            for x in range(x0, x0 + CW):
                R, G, B, A = px[x, y]
                h, l, s = colorsys.rgb_to_hls(R / 255, G / 255, B / 255)
                v = int(min(1, max(0, 0.35 + l * 0.65) * light * 1.35) * 255)
                px[x, y] = (v, v, v, A)

# which cells each part uses (from the UV probe). 'armour' = body+arms+legs minus skin cells.
CELLS = {
    'knight':    {'armour': [(3, 0), (4, 0), (6, 0), (7, 0), (7, 1), (2, 1), (1, 1)], 'cloth': [(0, 1)], 'helm': [(3, 0), (7, 0)], 'cape': [(0, 1)], 'trim': [(1, 1)]},
    'barbarian': {'armour': [(1, 1), (2, 1), (3, 0), (6, 0), (7, 0), (7, 1), (7, 2), (3, 2)], 'cloth': [(0, 1)], 'helm': [(2, 0), (2, 1), (7, 0)], 'cape': [(7, 0)], 'trim': [(7, 2)]},
    'mage':      {'armour': [(0, 1), (0, 2), (2, 2), (3, 0), (4, 0), (5, 0), (7, 1), (7, 2), (3, 2)], 'cloth': [(0, 1), (0, 2)], 'helm': [(1, 1), (3, 0), (5, 0)], 'cape': [(2, 1)], 'trim': [(5, 0), (4, 0)]},
    'rogue':     {'armour': [(0, 1), (1, 1), (3, 0), (5, 0), (6, 0), (7, 1), (5, 2), (3, 2)], 'cloth': [(0, 1), (1, 1)], 'helm': [(1, 1)], 'cape': [(1, 1)], 'trim': [(5, 0)]},
}

# variant name → (base, recolours). Each recolour: (cell group, colour, keep_l, gain)
VARIANTS = {
    # Warrior plate (Knight)
    'plate_iron':   ('knight', []),
    'plate_dark':   ('knight', [('armour', '#4a4e58', .85, 1.1), ('cloth', '#6a1414', 1, 1)]),
    'plate_bronze': ('knight', [('armour', '#b07a3a', 1, 1.05), ('cloth', '#3a2a22', 1, 1)]),
    'plate_gold':   ('knight', [('armour', '#e0b23a', 1.05, 1.1), ('cloth', '#8a1e1e', 1, 1), ('trim', '#fff0b0', 1, 1)]),
    'plate_abyss':  ('knight', [('armour', '#3a2a5a', .8, 1.15), ('cloth', '#8a40e0', 1, 1), ('trim', '#c090ff', 1, 1)]),
    # Warrior leather (Barbarian)
    'leather_hide': ('barbarian', []),
    'leather_dark': ('barbarian', [('armour', '#4a3628', .8, 1.05), ('cloth', '#2a2a30', 1, 1)]),
    'leather_green':('barbarian', [('armour', '#5a6a3a', .9, 1), ('cloth', '#3a4a2a', 1, 1)]),
    # Wizard robes (Mage)
    'robe_purple':  ('mage', []),
    'robe_blue':    ('mage', [('cloth', '#3b3f8a', 1, 1), ('trim', '#c9a6ff', 1, 1)]),
    'robe_arcane':  ('mage', [('cloth', '#1d1b52', .9, 1.1), ('trim', '#ffcc55', 1, 1)]),
    'robe_abyss':   ('mage', [('cloth', '#140a24', .8, 1.2), ('trim', '#b070ff', 1, 1)]),
    'robe_red':     ('mage', [('cloth', '#8a2020', 1, 1), ('trim', '#ffd080', 1, 1)]),
    # Taoist robes (Rogue hooded)
    'tao_green':    ('rogue', []),
    'tao_spirit':   ('rogue', [('cloth', '#ece6d4', 1.05, .9), ('trim', '#3fae6a', 1, 1)]),
    'tao_abyss':    ('rogue', [('cloth', '#2a2238', .85, 1.15), ('trim', '#9aff9a', 1, 1)]),
    'tao_blue':     ('rogue', [('cloth', '#2f4a8a', 1, 1), ('trim', '#e4d7a0', 1, 1)]),
    # neutral (tintable) helmets and capes
    'helm_neutral_knight':    ('knight',    [('helm', None, 0, 0)]),
    'cape_neutral_knight':    ('knight',    [('cape', None, 0, 0)]),
    'cape_neutral_mage':      ('mage',      [('cape', None, 0, 0)]),
    'cape_neutral_rogue':     ('rogue',     [('cape', None, 0, 0)]),
    'cape_neutral_barbarian': ('barbarian', [('cape', None, 0, 0)]),
    'hat_neutral_mage':       ('mage',      [('helm', None, 0, 0)]),
    'hat_neutral_barbarian':  ('barbarian', [('helm', None, 0, 0)]),
}

def build():
    index = {}
    for name, (base, recs) in VARIANTS.items():
        im = Image.open(os.path.join(SRC, base + '_texture.png')).convert('RGBA')
        for group, col, keep_l, gain in recs:
            cells = CELLS[base][group]
            if col is None: neutral(im, cells)
            else: recolour(im, cells, col, keep_l, gain)
        fn = f'{base}__{name}.png'; im.save(os.path.join(OUT, fn)); index[name] = {'base': base, 'texture': 'art/models/variants/' + fn}
    json.dump(index, open(os.path.join(OUT, 'variants.json'), 'w'), indent=1)
    print('wrote', len(index), 'variant textures')

if __name__ == '__main__': build()
