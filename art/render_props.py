"""
Renders static world props (buildings, trees, rocks, lamps, crates...) through the game's camera, one
still image per prop, with the soft ground shadow baked in, into one sprite set the world draws from.

    python3 art/render_props.py art/jobs/props_ashvale.json         → art/_render/props_ashvale/
    python3 art/pack.py art/_render/props_ashvale                    → assets/sprites/props_ashvale.*

Same camera, sun and pixels-per-unit as the characters (art/render.py), so a house and the people
walking past it share one light and one scale. World placement: one game tile = TILE world units.
A prop's anchor is where it touches the game's grid:
  * "foot": the centre of its tile (trees, lamps, barrels: drawn at the tile centre, bottom)
  * "corner": the bottom-left corner of its footprint (houses: fw x fh tiles, bottom-left at x, y)
Job: {"name": ..., "props": [{"key": "house_smith", "model": "art/models/...gltf", "fit": [fw, fh] | "height": h,
       "scale": s, "rot": deg, "anchor": "corner"|"foot", "tint": [r,g,b], "offset": [x, y]}]}
"""
import bpy, sys, os, json, math, time
from mathutils import Vector, Euler, Matrix
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render as R

ROOT = R.ROOT
PPU = 320 / 6.125                 # pixels per world unit at frame resolution (same as characters)
TILE = 48 / (PPU * (68 / (1.79 * PPU)))   # world units per game tile: a tile is 48 px wide in game at draw scale
E = math.radians(R.ELEV)

def scene_for(job, p):
    """camera-less scene with the character lights and (optionally) a shadow catcher"""
    base = dict(size=320, ortho=6.125, shift=0, samples=24, denoise=True, dnfast=True, sun=[28, 0, 0], key=3.6, fill=1.4, ambient=1.0, shadow=False, kind='prop')
    base.update({k: v for k, v in job.items() if k in base}); base.update({k: v for k, v in p.items() if k in base and k != 'key'})   # a prop's 'key' is its name, not the key light
    sc, tt = R.setup_scene(base)
    return sc, base

def main():
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    job = json.load(open(argv[0])); only = set(argv[1].split(',')) if len(argv) > 1 else None
    name = job['name']; out = os.path.join(ROOT, 'art', '_render', name); os.makedirs(out, exist_ok=True)
    mpath = os.path.join(out, 'meta.json')
    meta = json.load(open(mpath)) if (only and os.path.exists(mpath)) else {"name": name, "kind": "prop", "px_per_unit": PPU, "anchor": [0, 0], "dirs": 1, "anims": {}, "frames": []}
    t0 = time.time()
    for p in job['props']:
        key = p['key']
        if only and key not in only: continue
        sc, cfg = scene_for(job, p)
        objs = [o for o in R.import_model(os.path.join(ROOT, p['model'])) if o.type == 'MESH']
        if p.get('objects'): objs = [o for o in objs if o.name in p['objects'] or any(o.name.startswith(n) for n in p['objects'])]
        for o in list(sc.objects):
            if o.type == 'MESH' and o not in objs and o.name != 'ground': R.hide(o)
        if p.get('tint'): R.tint_materials(objs, p['tint'])
        # group under one empty: rotate, scale to fit the footprint, sit on the ground at the anchor
        root = bpy.data.objects.new('prop', None); sc.collection.objects.link(root)
        for o in objs:
            if o.parent is None or o.parent not in objs: mw = o.matrix_world.copy(); o.parent = root; o.matrix_world = mw
        root.rotation_euler = Euler((0, 0, math.radians(p.get('rot', 0)))); bpy.context.view_layer.update()
        def bbox():
            pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
            return Vector((min(v.x for v in pts), min(v.y for v in pts), min(v.z for v in pts))), Vector((max(v.x for v in pts), max(v.y for v in pts), max(v.z for v in pts)))
        mn, mx = bbox()
        s = p.get('scale', 1.0)
        if p.get('fit'): s = min(p['fit'][0] * TILE / (mx.x - mn.x), p['fit'][1] * TILE / (mx.y - mn.y) * p.get('deep', 1.15)) * p.get('fill', .96)   # fill the footprint (a little overhang at the back is fine)
        elif p.get('height'): s = p['height'] * TILE / (mx.z - mn.z)
        if p.get('maxh'): s = min(s, p['maxh'] * TILE / (mx.z - mn.z))   # keep tall buildings to a sensible height
        root.scale = (s, s, s); bpy.context.view_layer.update(); mn, mx = bbox()
        anchor = p.get('anchor', 'foot'); off = Vector((*p.get('offset', (0, 0)), 0)) * TILE
        if anchor == 'corner':   # footprint's south-west corner at the origin; the model centred in its footprint
            fw, fh = p.get('fit', [1, 1])[0], p.get('fit', [1, 1])[1]
            target = Vector((fw * TILE / 2, fh * TILE / 2, 0))
        else: target = Vector((0, 0, 0))
        centre = Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
        root.location = root.location + (target - centre) + off; bpy.context.view_layer.update(); mn, mx = bbox()
        # frame the prop: screen-space extents of its (and its shadow's) bounding box
        right = Vector((1, 0, 0)); up = Vector((0, math.sin(E), math.cos(E))); fwd = Vector((0, math.cos(E), -math.sin(E)))
        corners = [Vector((x, y, z)) for x in (mn.x, mx.x) for y in (mn.y, mx.y) for z in (mn.z, mx.z)]
        sh = p.get('shadow_pad', .8) * TILE if cfg['shadow'] else .1
        corners += [Vector((mn.x - sh, mn.y - sh * .3, 0)), Vector((mx.x + sh * .3, mx.y + sh, 0))]   # the sun is upper left: shadows fall right/back
        xs = [c.dot(right) for c in corners]; ys = [c.dot(up) for c in corners]
        pad = 6 / PPU
        x0, x1, y0, y1 = min(xs) - pad, max(xs) + pad, min(ys) - pad, max(ys) + pad
        W = max(8, int(math.ceil((x1 - x0) * PPU))); H = max(8, int(math.ceil((y1 - y0) * PPU)))
        sc.render.resolution_x = W; sc.render.resolution_y = H
        cam = sc.camera; cam.data.ortho_scale = max(W, H) / PPU; cam.data.shift_x = cam.data.shift_y = 0
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        cam.location = right * cx + up * cy - fwd * 40; cam.rotation_euler = Euler((math.radians(90 - R.ELEV), 0, 0))
        # where the origin lands in the image (pixels from the top-left)
        ax = (0 - x0) * PPU; ay = (y1 - 0) * PPU
        fn = key + '.png'; sc.render.filepath = os.path.join(out, fn); bpy.ops.render.render(write_still=True)
        meta['frames'] = [f for f in meta['frames'] if f['anim'] != key]
        meta['frames'].append({"anim": key, "dir": 0, "i": 0, "file": fn, "anchor": [round(ax, 2), round(ay, 2)]})
        meta['anims'][key] = {"frames": 1, "fps": 1, "loop": False, "events": {}, "tiles": p.get('fit'), "anchor": anchor}
        print(f'[{name}] {key}: {W}x{H} px, scale {s:.2f}', flush=True)
    json.dump(meta, open(mpath, 'w'), indent=1)
    print(f'[{name}] done: {len(meta["frames"])} props in {time.time() - t0:.0f}s')

main()
