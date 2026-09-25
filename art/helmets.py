"""
Builds the helmets, hats and crowns as low-poly models in KayKit's chunky style, fitted to the KayKit
head (every KayKit character shares the same rig and head size), so each helmet item shows its own
shape on the character.

    python3 art/helmets.py               # writes art/models/helmets/<key>.blend for every helmet
    python3 art/helmets.py plume crown   # only these

Models are built in the rig's rest space (character standing at the origin facing -Y; the head is a
chibi ~1.1 units wide centred about (0, 0, 1.74)). render.py parents them to the `head` bone keeping
that placement ("attach_rest"). Keys match item `look.k` (sprites.js maps k -> helm_<k>).
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector, Matrix, Euler
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from weapons import mat, hexc   # same materials as the weapons

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'art', 'models', 'helmets'); os.makedirs(OUT, exist_ok=True)
C = Vector((0, -.02, 1.76))          # centre of the head
PARTS = []

def _fin(o, m, bevel=0.):
    if bevel: b = o.modifiers.new('bevel', 'BEVEL'); b.width = bevel; b.segments = 2; b.limit_method = 'ANGLE'
    o.data.materials.append(mat(**m)); PARTS.append(o); return o
def dome(radii, cut_z, m, center=C, thick=.05, front_cut=None):
    """A helmet shell: an ellipsoid around the head, cut off below world height cut_z (and optionally
    cut away at the front below front_cut to open the face)."""
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1, segments=32, ring_count=18, location=center); o = bpy.context.object
    o.data.transform(Matrix.Diagonal((*radii, 1)))
    bm = bmesh.new(); bm.from_mesh(o.data)
    kill = [v for v in bm.verts if (o.matrix_world @ v.co).z < cut_z or (front_cut and (o.matrix_world @ v.co).y < -radii[1] * .45 and (o.matrix_world @ v.co).z < front_cut)]
    bmesh.ops.delete(bm, geom=kill, context='VERTS'); bm.to_mesh(o.data); bm.free()
    s = o.modifiers.new('solid', 'SOLIDIFY'); s.thickness = thick; s.offset = 1
    return _fin(o, m, thick * .4)
def ring(z, radii, r, m, center=C, tilt=0.):
    """A band around the helmet at height z (a squashed torus)."""
    bpy.ops.mesh.primitive_torus_add(major_radius=1, minor_radius=r, major_segments=40, minor_segments=8, location=(center.x, center.y, z))
    o = bpy.context.object; o.data.transform(Matrix.Diagonal((radii[0], radii[1], 1, 1)))
    o.rotation_euler = Euler((math.radians(tilt), 0, 0)); return _fin(o, m)
def blob(c, radii, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1, segments=20, ring_count=12, location=c); o = bpy.context.object
    o.data.transform(Matrix.Diagonal((*radii, 1))); o.rotation_euler = Euler([math.radians(a) for a in rot]); return _fin(o, m)
def cone(p1, p2, r1, r2, m, verts=12):
    p1, p2 = Vector(p1), Vector(p2); d = p2 - p1
    bpy.ops.mesh.primitive_cone_add(radius1=r1, radius2=r2, depth=d.length, vertices=verts, location=(p1 + p2) / 2); o = bpy.context.object
    o.rotation_mode = 'QUATERNION'; o.rotation_quaternion = d.to_track_quat('Z', 'Y'); return _fin(o, m, min(r1, r2 if r2 > .01 else r1) * .3)
def horn(base, direction, length, r, m, bend=(0, 0, .6), n=5):
    """A curved horn from base: a chain of tapering segments bending toward `bend`."""
    p = Vector(base); d = Vector(direction).normalized(); b = Vector(bend)
    for i in range(n):
        t = i / n; q = p + d * (length / n); cone(p, q, r * (1 - t * .85), r * (1 - (t + 1 / n) * .85) + .004, m, 10)
        d = (d + b * (1.2 / n)).normalized(); p = q
def plate(outline, thick, m, y=0., axis='y'):
    """A flat plate from an outline in the XZ plane (axis y) or YZ plane (axis x)."""
    me = bpy.data.meshes.new('p'); o = bpy.data.objects.new('p', me); bpy.context.scene.collection.objects.link(o)
    bm = bmesh.new()
    if axis == 'y': f = bm.faces.new([bm.verts.new((a, y, b)) for a, b in outline])
    else: f = bm.faces.new([bm.verts.new((y, a, b)) for a, b in outline])
    bm.to_mesh(me); bm.free(); s = o.modifiers.new('solid', 'SOLIDIFY'); s.thickness = thick; s.offset = 0
    return _fin(o, m, thick * .3)
def gem(c, r, col, glow=2.):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, subdivisions=1, location=c); o = bpy.context.object
    o.data.materials.append(mat(col, .15, .1, .2, glow)); PARTS.append(o); return o

LEATHER = dict(col='#7a5534', rough=.75); BRONZE = dict(col='#c08040', rough=.5, metal=.45); STEEL = dict(col='#9aa6c0', rough=.32, metal=.55)
GOLD = dict(col='#e0b040', rough=.3, metal=.7); BONE = dict(col='#ece4d0', rough=.6); DARK = dict(col='#3a2a4a', rough=.35, metal=.5)

def H_cap():
    dome((.6, .58, .56), 1.9, LEATHER, thick=.05)
    ring(1.92, (.6, .58), .035, dict(col='#5a3a24', rough=.8))
    for a in (-35, 0, 35):      # seams over the crown
        bpy.ops.mesh.primitive_torus_add(major_radius=.57, minor_radius=.014, major_segments=40, minor_segments=6, location=tuple(C + Vector((0, 0, .04))))
        o = bpy.context.object; o.rotation_euler = Euler((0, math.radians(90), math.radians(a))); _fin(o, dict(col='#5a3a24', rough=.8))
    blob((0, -.5, 1.9), (.36, .16, .035), LEATHER, rot=(-18, 0, 0))                     # brim
    blob(C + Vector((0, 0, .57)), (.06, .06, .04), dict(col='#5a3a24', rough=.8))
def H_nasal():
    dome((.62, .6, .62), 1.7, BRONZE, thick=.06)
    ring(1.72, (.63, .61), .045, dict(col='#9a6030', rough=.35, metal=.6))
    bpy.ops.mesh.primitive_torus_add(major_radius=.62, minor_radius=.03, major_segments=40, minor_segments=6, location=tuple(C + Vector((0, 0, .02))))
    o = bpy.context.object; o.rotation_euler = Euler((0, math.radians(90), 0)); _fin(o, dict(col='#9a6030', rough=.35, metal=.6))   # crest ridge front to back
    plate([(-.06, 1.95), (.06, 1.95), (.07, 1.5), (0, 1.44), (-.07, 1.5)], .05, BRONZE, y=-.64)   # nose guard
    for k in range(10):
        a = k / 10 * 2 * math.pi; gem((C.x + math.cos(a) * .64, C.y + math.sin(a) * .62, 1.72), .025, '#e0b070', 0)
def H_plume():
    dome((.62, .6, .62), 1.66, STEEL, thick=.06, front_cut=1.95)
    ring(1.68, (.63, .61), .04, dict(col='#d8b060', rough=.3, metal=.7))
    for s in (-1, 1): plate([(-.2, 1.72), (.22, 1.72), (.16, 1.38), (-.12, 1.4)], .05, STEEL, y=s * .6, axis='x')      # cheek guards
    for k in range(9):                                                    # the plume: feathers along the crest
        t = k / 8; ang = math.radians(-70 + t * 170); p = C + Vector((0, math.sin(ang) * .66, math.cos(ang) * .66 * .95))
        blob(p + Vector((0, .05, .1)), (.07, .16, .07 + .02 * math.sin(t * 3)), dict(col='#c8302a', rough=.8), rot=(math.degrees(ang) - 20, 0, 0))
    gem(C + Vector((0, -.62, .1)), .05, '#d8b060', 0)
def H_skull():
    dome((.64, .62, .64), 1.62, BONE, thick=.07, front_cut=1.88)
    for s in (-1, 1):
        blob(C + Vector((s * .22, -.58, .2)), (.14, .06, .12), dict(col='#1a1014', rough=.5))       # eye sockets
        gem(C + Vector((s * .22, -.63, .2)), .035, '#9aff9a', 2.5)
    blob(C + Vector((0, -.6, .02)), (.06, .05, .08), dict(col='#1a1014', rough=.5))                 # nose hole
    for k in range(-3, 4): blob(C + Vector((k * .085, -.6, -.1)), (.035, .03, .06), BONE)            # teeth along the brow
    for s in (-1, 1): horn(C + Vector((s * .5, -.1, .35)), (s * .6, .2, .5), .45, .08, BONE, bend=(s * .2, 0, .8))
def H_dragon():
    dome((.63, .61, .63), 1.66, GOLD, thick=.06, front_cut=1.95)
    ring(1.68, (.64, .62), .045, dict(col='#b03020', rough=.35, metal=.5))
    for s in (-1, 1): horn(C + Vector((s * .45, .05, .4)), (s * .4, .9, .25), .85, .11, dict(col='#3a2a22', rough=.4, metal=.3), bend=(0, .3, .9))
    for k in range(5):
        t = k / 4; ang = math.radians(-30 + t * 120); p = C + Vector((0, math.sin(ang) * .6, math.cos(ang) * .6))
        cone(p, p + Vector((0, .1, .22 - .06 * t)), .06, .005, dict(col='#b03020', rough=.35, metal=.5), 6)
    gem(C + Vector((0, -.64, .18)), .07, '#ff3a1a', 2.5)
    for s in (-1, 1): plate([(-.25, 1.78), (.2, 1.78), (.1, 1.4), (-.2, 1.46)], .05, GOLD, y=s * .6, axis='x')
def H_abyss():
    ring(2.02, (.5, .48), .06, DARK)
    for k in range(9):
        a = k / 9 * 2 * math.pi; base = Vector((math.cos(a) * .5, math.sin(a) * .48 + C.y, 2.02)); h = .42 if k % 2 == 0 else .26
        cone(base, base + Vector((math.cos(a) * .08, math.sin(a) * .08, h)), .07, .005, DARK, 5)
        if k % 2 == 0: gem(base + Vector((math.cos(a) * .04, math.sin(a) * .04, .08)), .045, '#c060ff', 3)
    gem(Vector((0, C.y - .5, 2.1)), .08, '#c060ff', 3.5)
def H_crown():
    ring(2.02, (.5, .48), .055, GOLD)
    for k in range(8):
        a = k / 8 * 2 * math.pi; base = Vector((math.cos(a) * .5, math.sin(a) * .48 + C.y, 2.05))
        cone(base, base + Vector((0, 0, .26)), .075, .006, GOLD, 4); blob(base + Vector((0, 0, .28)), (.03, .03, .03), GOLD)
        gem(base + Vector((math.cos(a) * .03, math.sin(a) * .03, .0)), .035, '#ff2a3a' if k % 2 else '#3a8aff', 1)
def H_horned():
    dome((.62, .6, .6), 1.72, dict(col='#8a8e96', rough=.45, metal=.4), thick=.06)
    ring(1.74, (.63, .61), .05, dict(col='#6a5a4a', rough=.6))
    for s in (-1, 1): horn(C + Vector((s * .52, -.05, .22)), (s * 1, 0, .25), .6, .12, BONE, bend=(0, -.2, 1.2))

BUILDERS = {k[2:]: v for k, v in globals().items() if k.startswith('H_')}

def build(key):
    global PARTS; PARTS = []
    bpy.ops.wm.read_factory_settings(use_empty=True)
    import weapons; weapons.MATS.clear()   # the material cache belongs to the previous (reset) file
    BUILDERS[key]()
    for o in PARTS:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.ops.object.select_all(action='DESELECT')
    for o in PARTS: o.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]; bpy.ops.object.join()
    w = bpy.context.object; w.name = 'helm_' + key
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
    path = os.path.join(OUT, key + '.blend'); bpy.ops.wm.save_as_mainfile(filepath=path); print('saved', path)

if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    for k in (argv or list(BUILDERS)): build(k)
