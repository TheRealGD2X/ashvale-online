"""
Contact sheet of a composed character straight from rendered frames (no game needed): draws the
layers in the same order as the game (ATLAS.drawEntity) so layering problems show up before packing.

    python3 art/preview.py out.png --anim attack --frame 3 body_plate_iron head_knight hair_knight:#6a4a2a cape_knight:#8a2020 w_sword_1h
    (layer:colour tints the layer; frames come from art/_render/<layer>/ or --root)

One column per direction (0..7), one row per frame when --frame is omitted.
"""
import sys, os, json, argparse
from PIL import Image, ImageChops

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ap = argparse.ArgumentParser()
ap.add_argument('out'); ap.add_argument('layers', nargs='+')
ap.add_argument('--anim', default='idle'); ap.add_argument('--frame', type=int); ap.add_argument('--root', default=os.path.join(ROOT, 'art', '_render'))
ap.add_argument('--bg', default='#5a6e46'); ap.add_argument('--scale', type=float, default=1.0); ap.add_argument('--crop', type=int, default=150)
a = ap.parse_args()

def tint(im, hexc):
    if not hexc: return im
    c = tuple(int(hexc.lstrip('#')[i:i + 2], 16) for i in (0, 2, 4))
    solid = Image.new('RGBA', im.size, c + (255,))
    rgb = ImageChops.multiply(im.convert('RGB'), solid.convert('RGB')).convert('RGBA'); rgb.putalpha(im.getchannel('A')); return rgb

layers = []
for spec in a.layers:
    name, _, col = spec.partition(':')
    meta = json.load(open(os.path.join(a.root, name, 'meta.json')))
    layers.append((name, col or None, meta))
nframes = layers[0][2]['anims'][a.anim]['frames']
rows = [a.frame] if a.frame is not None else list(range(nframes))
S = 256; C = a.crop; off = (S - C) // 2
sheet = Image.new('RGBA', (C * 8, C * len(rows)), a.bg)
for r, fi in enumerate(rows):
    for d in range(8):
        canvas = Image.new('RGBA', (S, S), (0, 0, 0, 0))
        backs, mids, fronts = [], [], []
        for name, col, meta in layers:
            fr = next((f for f in meta['frames'] if f['anim'] == a.anim and f['dir'] == d and f['i'] == fi), None)
            if not fr: continue
            im = tint(Image.open(os.path.join(a.root, name, fr['file'])).convert('RGBA'), col)
            if fr.get('full'):   # two-pass layer: behind-the-body part first, in-front part last
                full = tint(Image.open(os.path.join(a.root, name, fr['full'])).convert('RGBA'), col)
                back = full.copy(); back.putalpha(ImageChops.subtract(full.getchannel('A'), im.getchannel('A')))
                backs.append(back); fronts.append(im)
            else: mids.append(im)
        for im in backs + mids + fronts: canvas.alpha_composite(im)
        sheet.alpha_composite(canvas.crop((off, off + 5, off + C, off + 5 + C)), (d * C, r * C))
if a.scale != 1: sheet = sheet.resize((int(sheet.width * a.scale), int(sheet.height * a.scale)), Image.LANCZOS)
sheet.save(a.out); print('wrote', a.out, sheet.size)
