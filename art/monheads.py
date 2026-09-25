"""
Heads for the humanoid monsters (goblins, minotaurs, wildcats, scarecrows), built in the same chunky
style and fitted to the KayKit head bone, so a monster is a real body + armour + weapon paper doll with
its own head, like Legend of Mir's monster sets.

    python3 art/monheads.py              # writes art/models/monheads/<key>.blend
Rendered as mhead_<key> layers (make_jobs.py); sprites.js draws them instead of face + hair.
"""
import bpy, sys, os, math
from mathutils import Vector, Matrix, Euler
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import helmets as H
from helmets import blob, cone, horn, gem, C
from weapons import mat

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'art', 'models', 'monheads'); os.makedirs(OUT, exist_ok=True)

def eyes(c, sep, r, iris, pupil='#120e10', slit=False, brow=None):
    for s in (-1, 1):
        e = c + Vector((s * sep, 0, 0))
        blob(e, (r, r * .6, r * 1.05), dict(col=iris, rough=.25, glow=.6))
        blob(e + Vector((0, -r * .45, 0)), (r * (.25 if slit else .5), r * .3, r * (.95 if slit else .55)), dict(col=pupil, rough=.25))
        blob(e + Vector((-s * r * .2, -r * .62, r * .4)), (r * .2, r * .12, r * .2), dict(col='#ffffff', rough=.3))
        if brow: blob(e + Vector((s * r * .1, -r * .3, r * 1.1)), (r * 1.4, r * .5, r * .35), dict(col=brow, rough=.7), rot=(0, s * -18, 0))

def M_goblin():
    G = dict(col='#7c9a3a', rough=.7); D = dict(col='#4a6a22', rough=.7)
    blob(C + Vector((0, 0, -.04)), (.5, .47, .46), G)
    blob(C + Vector((0, -.18, .12)), (.46, .32, .16), G)                                   # heavy brow
    cone(C + Vector((0, -.42, -.02)), C + Vector((0, -.78, -.2)), .1, .02, G)              # long nose
    for s in (-1, 1):
        cone(C + Vector((s * .4, .02, .02)), C + Vector((s * 1.05, .18, .22)), .16, .01, G, 8)   # big pointy ears
        blob(C + Vector((s * .62, .04, .06)), (.22, .04, .09), dict(col='#b86a5a', rough=.7), rot=(0, s * -15, s * 12))
    eyes(C + Vector((0, -.4, .02)), .17, .07, '#f4d030', brow='#3a4a1a')
    blob(C + Vector((0, -.4, -.26)), (.22, .06, .035), dict(col='#2a1a14', rough=.6))    # mouth
    for s in (-1, 1): cone(C + Vector((s * .12, -.43, -.28)), C + Vector((s * .13, -.45, -.14)), .035, .005, dict(col='#f0e8c8', rough=.5), 6)
    for k in range(3): cone(C + Vector(((k - 1) * .12, .1, .42)), C + Vector(((k - 1) * .2, .3, .66)), .05, .005, dict(col='#2a2018', rough=.8), 5)   # tufts
def M_bull():
    F = dict(col='#5a4030', rough=.8); T = dict(col='#a88060', rough=.7)
    blob(C + Vector((0, .02, -.02)), (.52, .5, .5), F)
    blob(C + Vector((0, -.46, -.18)), (.34, .28, .25), T)                                  # muzzle
    for s in (-1, 1): blob(C + Vector((s * .12, -.72, -.14)), (.06, .03, .045), dict(col='#1a1010', rough=.5))
    bpy.ops.mesh.primitive_torus_add(major_radius=.09, minor_radius=.02, location=tuple(C + Vector((0, -.74, -.28))))
    o = bpy.context.object; o.rotation_euler = Euler((0, math.radians(90), 0)); H._fin(o, dict(col='#e0b040', rough=.3, metal=.7))
    for s in (-1, 1):
        horn(C + Vector((s * .42, -.02, .28)), (s * 1, -.05, .15), 1.0, .13, dict(col='#ece0c4', rough=.45), bend=(-s * .2, -.3, 1.1), n=7)
        blob(C + Vector((s * .56, .05, .02)), (.2, .06, .1), F, rot=(0, s * -25, 0))       # ears
    eyes(C + Vector((0, -.4, .14)), .22, .055, '#e83020', brow='#3a2a20')
    blob(C + Vector((0, .0, .45)), (.2, .2, .1), dict(col='#3a2820', rough=.8))            # forelock
def M_cat():
    O = dict(col='#c98a3e', rough=.75); W = dict(col='#f2e6d0', rough=.75); D = dict(col='#6a3a1a', rough=.75)
    blob(C + Vector((0, 0, -.02)), (.52, .47, .46), O)
    blob(C + Vector((0, -.4, -.18)), (.26, .18, .16), W)                                   # muzzle
    blob(C + Vector((0, -.56, -.1)), (.07, .04, .05), dict(col='#e07a8a', rough=.4))       # nose
    for s in (-1, 1):
        cone(C + Vector((s * .3, -.02, .32)), C + Vector((s * .46, .02, .8)), .2, .01, O, 4)
        cone(C + Vector((s * .3, -.07, .36)), C + Vector((s * .43, -.03, .7)), .12, .01, dict(col='#e8a0a8', rough=.7), 4)
        for k in range(3): cone(C + Vector((s * .2, -.52, -.16 + k * .05)), C + Vector((s * .62, -.5, -.2 + k * .09)), .008, .003, W, 4)   # whiskers
    for k in range(3): blob(C + Vector(((k - 1) * .13, -.25, .38)), (.035, .15, .05), D, rot=(-30, 0, 0))   # stripes
    eyes(C + Vector((0, -.38, .06)), .19, .075, '#a8e040', slit=True)
def M_sack():
    B = dict(col='#d6b86a', rough=.9); S = dict(col='#8a6a3a', rough=.85)
    blob(C + Vector((0, 0, -.04)), (.47, .45, .5), B)
    for s in (-1, 1):
        bpy.ops.mesh.primitive_cylinder_add(radius=.07, depth=.03, vertices=12, location=tuple(C + Vector((s * .17, -.44, .05))))
        o = bpy.context.object; o.rotation_euler = Euler((math.radians(90), 0, 0)); H._fin(o, dict(col='#1a1414', rough=.5))
    for k in range(-3, 4): blob(C + Vector((k * .07, -.44, -.2 + abs(k) * .02)), (.02, .02, .06), dict(col='#2a1a14', rough=.7))   # stitched grin
    blob(C + Vector((0, -.46, -.17)), (.22, .015, .012), dict(col='#2a1a14', rough=.7))
    bpy.ops.mesh.primitive_torus_add(major_radius=.3, minor_radius=.04, location=tuple(C + Vector((0, 0, -.44))))
    H._fin(bpy.context.object, dict(col='#9a7a4a', rough=.9))                               # rope at the neck
    for k in range(10):
        a = k / 10 * 2 * math.pi; p = C + Vector((math.cos(a) * .3, math.sin(a) * .3, -.46))
        cone(p, p + Vector((math.cos(a) * .18, math.sin(a) * .18, -.1)), .03, .005, dict(col='#e8c860', rough=.8), 4)   # straw
    bpy.ops.mesh.primitive_cylinder_add(radius=.75, depth=.04, vertices=24, location=tuple(C + Vector((0, 0, .34))))
    o = bpy.context.object; o.rotation_euler = Euler((math.radians(-8), 0, 0)); H._fin(o, S, .015)                  # hat brim
    cone(C + Vector((0, .02, .34)), C + Vector((.08, .18, 1.0)), .42, .04, S, 16)                                     # hat crown
    blob(C + Vector((0, 0, .4)), (.43, .43, .06), dict(col='#6a2a2a', rough=.8))                                      # hat band

BUILDERS = {k[2:]: v for k, v in globals().items() if k.startswith('M_')}

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
    w = bpy.context.object; w.name = 'mhead_' + key
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(45))
    path = os.path.join(OUT, key + '.blend'); bpy.ops.wm.save_as_mainfile(filepath=path); print('saved', path)

if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    for k in (argv or list(BUILDERS)): build(k)
