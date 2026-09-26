"""
Finishes the item icons: takes each lit object from art/_items/<key>.png (art/item_models.py) and paints
it onto a backdrop that picks up the object's own colours, with a soft contact shadow, a back light
around the silhouette, bloom on anything that glows, and a gentle vignette. Writes
godot/assets/icons/items/<key>.png at 128 px (the game draws its quality frame over the edge).

    python3 art/item_paint.py            # all
    python3 art/item_paint.py m_ w_long   # keys starting with these
"""
import os, sys, colorsys, zlib
import numpy as np
from PIL import Image, ImageFilter
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paint import blur, noise, smooth

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, 'art', '_items')
OUT = os.path.join(ROOT, 'godot', 'assets', 'icons', 'items'); os.makedirs(OUT, exist_ok=True)
SIZE = 128

def lin(a): return np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)
def srgb(a): a = np.clip(a, 0, 1); return np.where(a <= 0.0031308, a * 12.92, 1.055 * a ** (1 / 2.4) - 0.055)

# backdrop tints for keys whose own colours would be dull or misleading
TINT = {'w_': None, 'a_': None, 'tok_': (0.62, 0.42, 0.95), 'soul_shard': (0.6, 0.3, 1.0), 'voidstone': (0.6, 0.3, 1.0), 'key_void': (0.6, 0.3, 1.0),
    'blessing': (1.0, 0.8, 0.3), 'hearth': (0.3, 0.7, 1.0), 'core': (0.3, 0.7, 1.0), 'rune_shard': (0.3, 0.7, 1.0), 't_golem': (0.3, 0.7, 1.0)}

def key_tint(key, rgb, a):
    for k, v in TINT.items():
        if key.startswith(k) and v is not None: return np.array(v, np.float32)
    # the object's own colour, weighted towards its saturated parts
    w = a * (rgb.max(axis=2) - rgb.min(axis=2) + 0.05)
    c = (rgb * w[..., None]).sum(axis=(0, 1)) / max(1e-6, w.sum())
    h, l, s = colorsys.rgb_to_hls(*[float(x) for x in srgb(c)])
    if key.startswith('w_') or key.startswith('a_'):
        s *= 0.5
    r, g, b = colorsys.hls_to_rgb(h, 0.5, min(0.55, s * 1.2 + 0.1))
    return np.array([r, g, b], np.float32)

def paint(key):
    src = os.path.join(SPR, key + '.png')
    if not os.path.exists(src): return False
    im = np.asarray(Image.open(src).convert('RGBA'), np.float32) / 255.0
    n = im.shape[0]
    rgb = lin(im[..., :3]); a = im[..., 3]
    y, x = np.mgrid[0:n, 0:n].astype(np.float32) / n
    tint = lin(key_tint(key, rgb, a))
    # backdrop: a pool of the object's colour behind it, falling to a deep edge; brushy texture
    d = np.sqrt((x - 0.5) ** 2 + (y - 0.46) ** 2)
    inner = tint * 0.16 + 0.012; outer = tint * 0.02 + 0.004
    k = smooth(0.0, 0.7, d)[..., None]
    bg = inner * (1 - k) + outer * k
    tex = noise(n, 5, zlib.crc32(key.encode()) % 1000, 6); tex2 = noise(n, 16, zlib.crc32(key.encode()) % 997 + 3, 4, aniso=(1.0, 0.35))
    bg = bg * (1.0 + (tex - 0.5)[..., None] * 0.45 + (tex2 - 0.5)[..., None] * 0.25)
    # back light: a soft glow hugging the silhouette
    halo = np.clip(blur(a, n * 0.05) * 1.3 - a * 0.3, 0, 1)
    bg += halo[..., None] * (tint * 0.35 + 0.03)
    # contact shadow, down and to the right
    sh = np.roll(np.roll(blur(a, n * 0.02), int(n * 0.025), 0), int(n * 0.015), 1)
    bg *= (1 - 0.6 * sh)[..., None]
    img = bg * (1 - a[..., None]) + rgb * a[..., None]
    # bloom from whatever glows (bright and saturated pixels)
    lum = rgb.max(axis=2)
    hot = np.clip((lum - 0.55) * 2.0, 0, 1) * a
    glow = rgb * hot[..., None]
    img += blur(glow, n * 0.012) * 0.6 + blur(glow, n * 0.04) * 0.5 + blur(glow, n * 0.1) * 0.25
    # vignette, then a soft filmic shoulder
    img *= (1.0 - 0.45 * smooth(0.25, 0.75, d))[..., None]
    img = 1.0 - np.exp(-img * 1.35)
    out = (srgb(img) * 255).astype(np.uint8)
    res = Image.fromarray(out, 'RGB').resize((SIZE, SIZE), Image.LANCZOS)
    res = res.filter(ImageFilter.UnsharpMask(radius=1.0, percent=45, threshold=1))
    res.save(os.path.join(OUT, key + '.png'), optimize=True)
    return True

EMPTY = {'head': 'a_Knight_Head_Armet_2', 'neck': 'j_pendant_gold', 'shoulders': 'a_Knight_Acc_Pauldron_Round_2', 'back': 'g_cloak_gold',
    'chest': 'a_Knight_Body_Armor_1', 'wrist': 'g_bracers', 'hands': 'a_Knight_Arms_1', 'waist': 'g_belt', 'legs': 'a_Knight_Legs_1',
    'feet': 'a_Knight_Feet_1', 'finger': 'j_band_gold', 'trinket': 't_charm', 'main_hand': 'w_long', 'off_hand': 'w_dagger'}

def paint_empty(slot):
    """an empty paper-doll slot: the silhouette of a typical piece, pressed faintly into the tile"""
    src = os.path.join(SPR, EMPTY[slot] + '.png')
    if not os.path.exists(src): return False
    im = np.asarray(Image.open(src).convert('RGBA'), np.float32) / 255.0
    a = blur(im[..., 3], 1.2)
    lum = im[..., :3].mean(axis=2)
    shade = 0.55 + 0.45 * (blur(lum, 2.0) - 0.3)
    edge = np.clip(blur(a, 3.0) - a, 0, 1) + np.clip(a - blur(a, 3.0), 0, 1)
    v = np.clip(shade * 0.5 + edge * 0.6, 0, 1)
    alpha = np.clip(a * 0.55 + edge * 0.5, 0, 1)
    out = np.dstack([v * 0.92, v * 0.86, v * 0.76, alpha])
    Image.fromarray((out * 255).astype(np.uint8), 'RGBA').resize((SIZE, SIZE), Image.LANCZOS).save(os.path.join(OUT, 'e_' + slot + '.png'))
    return True

if __name__ == '__main__':
    args = sys.argv[1:]
    with open(os.path.join(ROOT, 'art', 'item_keys.txt')) as f:
        ks = [l.split('\t')[0] for l in f if l.strip()]
    done = 0
    for k in ks:
        if args and not any(k.startswith(a) for a in args): continue
        ok = paint_empty(k[2:]) if k.startswith('e_') else paint(k)
        done += ok
    print('painted', done)
