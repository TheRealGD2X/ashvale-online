"""
World props the KayKit packs don't have, built in the same chunky style: round-crowned trees, bushes,
a town fountain, lamp posts, crops, mushrooms and a signpost.

    python3 art/nature.py                  # writes art/models/nature/<key>.blend
Rendered by art/render_props.py (jobs in art/jobs/make_props.py).
"""
import bpy, sys, os, math, random
from mathutils import Vector, Matrix, Euler
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import helmets as H
from helmets import blob, cone
from weapons import mat

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'art', 'models', 'nature'); os.makedirs(OUT, exist_ok=True)
BARK = dict(col='#6a4a30', rough=.85); BARK_D = dict(col='#4a3424', rough=.85)
def leaf(col): return dict(col=col, rough=.8, grad=.35)

def canopy(center, r, col, rng, lumps=7, squash=.8):
    """a cloud of overlapping soft blobs: a KayKit-style tree crown"""
    c = Vector(center)
    blob(c, (r, r, r * squash), leaf(col))
    for k in range(lumps):
        a = rng.random() * 2 * math.pi; e = rng.uniform(-.2, .7); d = r * rng.uniform(.55, .8)
        p = c + Vector((math.cos(a) * math.cos(e) * d, math.sin(a) * math.cos(e) * d, math.sin(e) * d * squash))
        s = r * rng.uniform(.45, .65); blob(p, (s, s, s * .9), leaf(col))

def trunk(h, r, m=BARK, lean=(0, 0), branches=0, rng=None):
    top = Vector((lean[0], lean[1], h)); cone((0, 0, 0), top, r, r * .6, m, 10)
    for s in (-1, 1): cone((0, 0, .02), (s * r * 1.6, rng.uniform(-.1, .1) if rng else 0, 0), r * .7, r * .2, m, 6)   # roots
    tips = []
    for k in range(branches):
        a = k / branches * 2 * math.pi + (rng.random() if rng else 0); z0 = h * (.55 + .12 * k)
        tip = Vector((math.cos(a) * h * .32, math.sin(a) * h * .32, z0 + h * .25)); cone((lean[0] * .6, lean[1] * .6, z0), tip, r * .45, r * .2, m, 7); tips.append(tip)
    return top, tips

def T_oak(seed=1, col='#3f8a36'):
    rng = random.Random(seed); top, tips = trunk(1.5, .16, branches=3, rng=rng)
    canopy(top + Vector((0, 0, .45)), .95, col, rng, 9)
    for t in tips: canopy(t + Vector((0, 0, .2)), .55, col, rng, 3)
def T_oak2(): T_oak(7, '#4f9a3c')
def T_oak3(): T_oak(13, '#357a34')
def T_birch():
    rng = random.Random(5); W = dict(col='#e8e4d8', rough=.7)
    top, tips = trunk(2.0, .1, W, lean=(.08, 0), branches=2, rng=rng)
    for k in range(5): blob((0.04 * k / 5, 0, .3 + k * .35), (.105, .105, .025), dict(col='#3a3430', rough=.8))
    canopy(top + Vector((0, 0, .3)), .7, '#7aac48', rng, 6, .95)
def T_dead():
    rng = random.Random(3); top, tips = trunk(1.7, .15, BARK_D, lean=(.1, .05), branches=4, rng=rng)
    for t in tips: cone(t, t + Vector((rng.uniform(-.3, .3), rng.uniform(-.3, .3), .35)), .04, .01, BARK_D, 5)
def T_darkoak(): T_oak(21, '#285c34')
def T_bush():
    rng = random.Random(2); canopy((0, 0, .32), .42, '#3e7e34', rng, 6, .75)
def T_bush2():
    rng = random.Random(4); canopy((0, 0, .28), .36, '#4a8a3a', rng, 5, .75)
    for k in range(6):
        a = rng.random() * 6.28; blob((math.cos(a) * .3, math.sin(a) * .3 - .1, .42 + rng.random() * .15), (.05, .05, .05), dict(col='#e8506a', rough=.5))
def T_fountain():
    S = dict(col='#b8b0a0', rough=.7); S2 = dict(col='#9a9282', rough=.7); W = dict(col='#5aa8d8', rough=.1, metal=0)
    bpy.ops.mesh.primitive_cylinder_add(radius=1.75, depth=.5, vertices=32, location=(0, 0, .25)); H._fin(bpy.context.object, S, .06)
    bpy.ops.mesh.primitive_torus_add(major_radius=1.72, minor_radius=.14, major_segments=40, minor_segments=10, location=(0, 0, .5)); H._fin(bpy.context.object, S2)
    bpy.ops.mesh.primitive_cylinder_add(radius=1.6, depth=.05, vertices=32, location=(0, 0, .44)); H._fin(bpy.context.object, dict(col='#4a98c8', rough=.05, glow=.15))
    cone((0, 0, .4), (0, 0, 1.5), .28, .2, S2, 16); blob((0, 0, 1.55), (.7, .7, .14), S)
    bpy.ops.mesh.primitive_cylinder_add(radius=.6, depth=.03, vertices=24, location=(0, 0, 1.66)); H._fin(bpy.context.object, dict(col='#4a98c8', rough=.05, glow=.15))
    cone((0, 0, 1.6), (0, 0, 2.2), .1, .07, S2, 12); blob((0, 0, 2.28), (.16, .16, .16), dict(col='#d8c890', rough=.35, metal=.6))
    for k in range(8):   # water spouts
        a = k / 8 * 2 * math.pi; blob((math.cos(a) * .95, math.sin(a) * .95, .62), (.08, .08, .16), dict(col='#a8dcff', rough=.1, glow=.4))
def T_lamp():
    I = dict(col='#2e2a28', rough=.45, metal=.5)
    cone((0, 0, 0), (0, 0, .12), .2, .16, I, 8); cone((0, 0, .1), (0, 0, 2.3), .06, .05, I, 8)
    cone((0, 0, 2.2), (.32, 0, 2.36), .035, .03, I, 6)
    bpy.ops.mesh.primitive_cylinder_add(radius=.14, depth=.3, vertices=6, location=(.36, 0, 2.2)); H._fin(bpy.context.object, dict(col='#ffd890', rough=.2, glow=3), .01)
    cone((.36, 0, 2.35), (.36, 0, 2.5), .2, .02, I, 6); cone((.36, 0, 2.02), (.36, 0, 2.06), .16, .14, I, 6)
def T_crop():
    rng = random.Random(9)
    for k in range(7):
        x, y = rng.uniform(-.35, .35), rng.uniform(-.3, .3); h = rng.uniform(.45, .7)
        cone((x, y, 0), (x + rng.uniform(-.05, .05), y, h), .025, .012, dict(col='#8aa84a', rough=.8), 5)
        blob((x, y, h + .06), (.045, .045, .11), dict(col='#e0c060', rough=.7))
def T_crop_green():
    rng = random.Random(11)
    for k in range(6):
        x, y = rng.uniform(-.35, .35), rng.uniform(-.3, .3)
        for j in range(3): cone((x, y, 0), (x + math.cos(j * 2.1) * .18, y + math.sin(j * 2.1) * .18, .3), .04, .01, dict(col='#5a9a3a', rough=.8), 4)
def T_mushroom():
    blob((0, 0, .12), (.07, .07, .12), dict(col='#efe4cc', rough=.7)); blob((0, 0, .26), (.2, .2, .1), dict(col='#c83a2a', rough=.5))
    for k in range(5): a = k * 1.3; blob((math.cos(a) * .11, math.sin(a) * .11, .33), (.03, .03, .015), dict(col='#fff4e0', rough=.6))
    blob((.2, .08, .07), (.04, .04, .07), dict(col='#efe4cc', rough=.7)); blob((.2, .08, .15), (.09, .09, .05), dict(col='#c83a2a', rough=.5))
def T_sign():
    Wd = dict(col='#8a6440', rough=.8)
    cone((0, 0, 0), (0, 0, 1.4), .06, .05, Wd, 8)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(.02, -.04, 1.15)); o = bpy.context.object; o.data.transform(Matrix.Diagonal((.95, .07, .38, 1))); H._fin(o, dict(col='#a47a4c', rough=.8), .02)
    blob((0, -.02, 1.44), (.06, .06, .04), Wd)
def T_grass():
    rng = random.Random(17)
    for k in range(9):
        x, y = rng.uniform(-.3, .3), rng.uniform(-.25, .25)
        cone((x, y, 0), (x + rng.uniform(-.1, .1), y + rng.uniform(-.05, .05), rng.uniform(.18, .32)), .03, .005, dict(col=rng.choice(['#5e9a40', '#6aa84a', '#4e8a3a']), rough=.8), 3)

BUILDERS = {k[2:]: v for k, v in globals().items() if k.startswith('T_') and not k.startswith('T_oak(')}

def build(key):
    H.PARTS = []
    bpy.ops.wm.read_factory_settings(use_empty=True)
    import weapons; weapons.MATS.clear()
    BUILDERS[key]()
    parts = H.PARTS
    for o in parts:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts: o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]; bpy.ops.object.join()
    w = bpy.context.object; w.name = 'nat_' + key
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(50))
    path = os.path.join(OUT, key + '.blend'); bpy.ops.wm.save_as_mainfile(filepath=path); print('saved', path)

if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    for k in (argv or list(BUILDERS)): build(k)
