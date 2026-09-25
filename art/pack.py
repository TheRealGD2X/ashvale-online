"""
Packs rendered frames (art/_render/<name>/) into a sprite atlas the game loads:
    assets/sprites/<name>.webp (one or more pages: <name>.webp, <name>.1.webp, ...)
    assets/sprites/<name>.json

    python3 art/pack.py art/_render/knight

Each frame is trimmed to its opaque bounds; the JSON stores, per frame, where it sits in the page and
its offset from the sprite's anchor (the point on the ground under the character's feet), so the game
can draw any frame with one drawImage and no per-frame maths.

JSON shape:
{ "name": "knight", "pages": ["knight.png", "knight.1.png"], "scale": 0.75,
  "anims": { "walk": { "frames": 8, "fps": 14, "loop": true, "events": {} }, ... },
  "frames": { "walk/4/0": [page, x, y, w, h, ox, oy], ... } }
    ox, oy = offset of the frame's top-left from the anchor, in atlas pixels (before scale).
"scale" is the size the game should draw at so that a character stands about 1.5 tiles tall.
"""
import sys, os, json
from PIL import Image

PAGE = 2048; PAD = 2
src = sys.argv[1].rstrip('/')
meta = json.load(open(os.path.join(src, 'meta.json')))
name = meta['name']
out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'sprites')
os.makedirs(out_dir, exist_ok=True)
ax, ay = meta['anchor']

# load + trim
items = []
for f in meta['frames']:
    im = Image.open(os.path.join(src, f['file'])).convert('RGBA')
    bbox = im.getbbox()
    if not bbox: bbox = (int(ax) - 1, int(ay) - 1, int(ax) + 1, int(ay) + 1)
    crop = im.crop(bbox)
    items.append((f"{f['anim']}/{f['dir']}/{f['i']}", crop, bbox[0] - ax, bbox[1] - ay))

# shelf packing, tallest first
items.sort(key=lambda t: -t[1].height)
pages = []; frames = {}
def new_page(): pages.append({'img': Image.new('RGBA', (PAGE, PAGE), (0, 0, 0, 0)), 'x': PAD, 'y': PAD, 'row_h': 0})
new_page()
for key, im, ox, oy in items:
    w, h = im.size
    p = pages[-1]
    if p['x'] + w + PAD > PAGE:
        p['x'] = PAD; p['y'] += p['row_h'] + PAD; p['row_h'] = 0
    if p['y'] + h + PAD > PAGE:
        new_page(); p = pages[-1]
    p['img'].paste(im, (p['x'], p['y']))
    frames[key] = [len(pages) - 1, p['x'], p['y'], w, h, round(ox, 1), round(oy, 1)]
    p['x'] += w + PAD; p['row_h'] = max(p['row_h'], h)

# crop the last page to its used height (saves bytes)
last = pages[-1]; used_h = min(PAGE, last['y'] + last['row_h'] + PAD)
last['img'] = last['img'].crop((0, 0, PAGE, used_h))

page_files = []
for i, p in enumerate(pages):
    fn = f'{name}.webp' if i == 0 else f'{name}.{i}.webp'
    p['img'].save(os.path.join(out_dir, fn), 'WEBP', quality=90, method=6); page_files.append(fn)

# draw scale: the renderer used size/ortho px per world unit; a KayKit character is ~2.4 units tall and
# should stand ~72 px tall at zoom 1 (1.5 tiles of 48 px). 2.4 * cos(41.8°) = 1.79 projected units.
px_per_unit = meta['px_per_unit']; scale = round(68 / (1.79 * px_per_unit), 3)
atlas_json = {"name": name, "kind": meta['kind'], "pages": page_files, "scale": scale, "dirs": meta['dirs'], "mirror": meta.get('mirror', False),
           "anims": meta['anims'], "frames": frames}
json.dump(atlas_json, open(os.path.join(out_dir, name + '.json'), 'w'), separators=(',', ':'))
# script-tag loadable copy (works from file:// where fetch() does not)
open(os.path.join(out_dir, name + '.js'), 'w').write('ATLAS.register(' + json.dumps(atlas_json, separators=(',', ':')) + ');\n')
total = sum(os.path.getsize(os.path.join(out_dir, f)) for f in page_files)
print(f'[{name}] packed {len(frames)} frames into {len(pages)} page(s), {total // 1024} KB, draw scale {scale}')
