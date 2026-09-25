"""
Builds the animals and beasts as low-poly Blender models with simple bone rigs and keyframed
animations, in the same chunky flat-colour style as the KayKit characters, and saves each as a
.blend that render.py can render like any other model.

    python3 art/creatures.py            # writes art/models/creatures/<name>.blend for every spec
    python3 art/creatures.py boar hen   # only these

Body plans: quad (boar, deer, wolf, bear), hen, spider, flyer (bat, moth), snake, worm.
Each has actions Idle, Walk, Attack, Hit, Die, Dead. Forward is −Y (facing the camera at yaw 0).
"""
import bpy, sys, os, math
from mathutils import Vector, Matrix, Euler

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'art', 'models', 'creatures'); os.makedirs(OUT, exist_ok=True)

def hexc(h): h = h.lstrip('#'); return tuple((int(h[i:i + 2], 16) / 255) ** 2.2 for i in (0, 2, 4))   # sRGB → linear
MATS = {}
def mat(col, rough=0.75):
    if col in MATS: return MATS[col]
    m = bpy.data.materials.new('m_' + col.lstrip('#')); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']; b.inputs['Base Color'].default_value = (*hexc(col), 1); b.inputs['Roughness'].default_value = rough
    MATS[col] = m; return m

PARTS = []
def box(name, size, loc, col, bevel=0.06, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc); o = bpy.context.object; o.name = name
    o.data.transform(Matrix.Diagonal((size[0], size[1], size[2], 1)))
    if bevel: m = o.modifiers.new('bevel', 'BEVEL'); m.width = bevel; m.segments = 2; m.limit_method = 'NONE'
    o.rotation_euler = Euler([math.radians(a) for a in rot]); o.data.materials.append(mat(col)); PARTS.append(o); return o
def ball(name, r, loc, col, sub=2, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, subdivisions=sub, location=loc); o = bpy.context.object; o.name = name
    o.data.transform(Matrix.Diagonal((*scale, 1))); o.data.materials.append(mat(col)); PARTS.append(o); return o
def cyl(name, r, h, loc, col, rot=(0, 0, 0), verts=8):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, vertices=verts, location=loc); o = bpy.context.object; o.name = name
    o.rotation_euler = Euler([math.radians(a) for a in rot]); o.data.materials.append(mat(col)); PARTS.append(o); return o
def cone(name, r, h, loc, col, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(radius1=r, radius2=0, depth=h, vertices=6, location=loc); o = bpy.context.object; o.name = name
    o.rotation_euler = Euler([math.radians(a) for a in rot]); o.data.materials.append(mat(col)); PARTS.append(o); return o
def seg(name, p1, p2, r, col, verts=6):
    p1, p2 = Vector(p1), Vector(p2); d = p2 - p1
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=d.length, vertices=verts, location=(p1 + p2) / 2); o = bpy.context.object; o.name = name
    o.rotation_mode = 'QUATERNION'; o.rotation_quaternion = d.to_track_quat('Z', 'Y'); o.data.materials.append(mat(col)); PARTS.append(o); return o
def eyes(prefix, loc, sep, r=0.06, col='#141014'):
    ball(prefix + 'EyeL', r, (loc[0] - sep, loc[1], loc[2]), col, 1); ball(prefix + 'EyeR', r, (loc[0] + sep, loc[1], loc[2]), col, 1)

# ---- rig helpers -----------------------------------------------------------------------
def make_rig(bones):
    """bones: {name: (head, tail, parent)} → armature object"""
    ad = bpy.data.armatures.new('Rig'); arm = bpy.data.objects.new('Rig', ad); bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode='EDIT')
    ebs = {}
    for n, (h, t, p) in bones.items():
        eb = ad.edit_bones.new(n); eb.head = Vector(h); eb.tail = Vector(t); ebs[n] = eb
    for n, (h, t, p) in bones.items():
        if p: ebs[n].parent = ebs[p]
    bpy.ops.object.mode_set(mode='OBJECT')
    for pb in arm.pose.bones: pb.rotation_mode = 'XYZ'
    return arm
def attach(arm, part, bone):
    bpy.ops.object.select_all(action='DESELECT'); part.select_set(True); arm.select_set(True)
    bpy.context.view_layer.objects.active = arm; arm.data.bones.active = arm.data.bones[bone]
    bpy.ops.object.parent_set(type='BONE')

# ---- animation helpers ---------------------------------------------------------------
class Anim:
    def __init__(self, arm, name, length, loop=False):
        self.arm = arm; self.act = bpy.data.actions.new(name); self.act.use_fake_user = True
        arm.animation_data_create(); arm.animation_data.action = self.act; self.length = length
        for pb in arm.pose.bones: pb.rotation_euler = (0, 0, 0); pb.location = (0, 0, 0); pb.scale = (1, 1, 1)
    def key(self, bone, frame, rot=None, loc=None, scale=None):
        pb = self.arm.pose.bones[bone]
        if rot is not None: pb.rotation_euler = Euler([math.radians(a) for a in rot]); pb.keyframe_insert('rotation_euler', frame=frame)
        if loc is not None: pb.location = Vector(loc); pb.keyframe_insert('location', frame=frame)
        if scale is not None: pb.scale = Vector(scale); pb.keyframe_insert('scale', frame=frame)
    def wave(self, bone, amp, cycles=1, phase=0, axis=0, n=None):
        """sinusoidal rotation over the action length"""
        n = n or self.length
        for f in range(0, n + 1, 2):
            a = amp * math.sin(2 * math.pi * (cycles * f / n) + phase); r = [0, 0, 0]; r[axis] = a; self.key(bone, f, rot=r)
    def bob(self, bone, amp, cycles=2, n=None, axis=2):
        n = n or self.length
        for f in range(0, n + 1, 2):
            l = [0, 0, 0]; l[axis] = amp * abs(math.sin(2 * math.pi * (cycles * f / n))); self.key(bone, f, loc=l)
    def done(self):
        self.act.frame_range = (0, self.length)

# =========================================================================================
def build_quad(spec):
    L, W, H = spec['body']; legL = spec['leg']; z0 = legL + H * .5           # body centre height
    col, belly = spec['col'], spec.get('belly', spec['col'])
    box('Body', (W, L, H), (0, 0, z0), col, .08)
    box('Belly', (W * .8, L * .8, H * .3), (0, 0, z0 - H * .38), belly, .05)
    hy = -L * .5 - spec['head'][1] * .35; hz = z0 + H * .15
    box('Head', (spec['head'][0], spec['head'][1], spec['head'][2]), (0, hy, hz), col, .07)
    sn = spec.get('snout');
    if sn: box('Snout', (sn[0], sn[1], sn[2]), (0, hy - spec['head'][1] * .5 - sn[1] * .4, hz - spec['head'][2] * .2), spec.get('snoutCol', belly), .04)
    eyes('', (0, hy - spec['head'][1] * .35, hz + spec['head'][2] * .15), spec['head'][0] * .32, .06 * spec.get('eye', 1))
    ear = spec.get('ears', [.14, .06, .2])
    for sx in (-1, 1): box('Ear' + ('L' if sx < 0 else 'R'), ear, (sx * spec['head'][0] * .35, hy + spec['head'][1] * .2, hz + spec['head'][2] * .55), col, .02, rot=(0, sx * 15, 0))
    if spec.get('tusks'):
        for sx in (-1, 1): cone('Tusk' + ('L' if sx < 0 else 'R'), .05, .22, (sx * .13, hy - spec['head'][1] * .55, hz - spec['head'][2] * .25), '#f2ecd8', rot=(-70, 0, sx * 20))
    if spec.get('antlers'):
        for sx in (-1, 1):
            cyl('Antler' + ('L' if sx < 0 else 'R'), .03, .5, (sx * .16, hy + .05, hz + .45), '#c8b48a', rot=(0, sx * 25, 0), verts=5)
            cyl('Tine' + ('L' if sx < 0 else 'R'), .025, .28, (sx * .26, hy + .05, hz + .62), '#c8b48a', rot=(0, sx * 70, 0), verts=5)
    if spec.get('mane'): box('Mane', (W * 1.1, L * .3, H * .4), (0, -L * .3, z0 + H * .4), spec['mane'], .06)
    r = spec.get('legR', .11)
    legs = {}
    for name, sx, sy in (('LegFL', -1, -1), ('LegFR', 1, -1), ('LegBL', -1, 1), ('LegBR', 1, 1)):
        legs[name] = cyl(name, r, legL, (sx * (W * .5 - r * 1.1), sy * (L * .5 - r * 1.6), legL * .5), spec.get('legCol', col))
    tail = spec.get('tail', 'short')
    if tail == 'bushy': ball('Tail', .16, (0, L * .5 + .15, z0 + .05), col, 1, (1, 1.8, 1))
    elif tail == 'long': cyl('Tail', .04, .55, (0, L * .5 + .25, z0 + .1), col, rot=(70, 0, 0), verts=6)
    else: cyl('Tail', .03, .18, (0, L * .5 + .08, z0 + .1), col, rot=(60, 0, 0), verts=6)
    # rig
    sh = legL  # shoulder height
    arm = make_rig({'root': ((0, 0, 0), (0, 0, .3), None), 'body': ((0, 0, z0), (0, 0, z0 + .3), 'root'), 'head': ((0, -L * .5, hz - .1), (0, -L * .5, hz + .3), 'body'),
                    'tail': ((0, L * .5, z0 + .1), (0, L * .5 + .3, z0 + .1), 'body'),
                    'LegFL': ((-1, -1, sh), (-1, -1, sh - .2), 'body'), 'LegFR': ((1, -1, sh), (1, -1, sh - .2), 'body'), 'LegBL': ((-1, 1, sh), (-1, 1, sh - .2), 'body'), 'LegBR': ((1, 1, sh), (1, 1, sh - .2), 'body')})
    # fix leg bone positions to the actual leg tops
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode='EDIT')
    for name, o in legs.items():
        eb = arm.data.edit_bones[name]; x, y = o.location.x, o.location.y; eb.head = (x, y, sh); eb.tail = (x, y, sh - .2)
    bpy.ops.object.mode_set(mode='OBJECT')
    for o in PARTS:
        b = 'body'
        if o.name in legs: b = o.name
        elif o.name.startswith(('Head', 'Snout', 'Eye', 'Ear', 'Tusk', 'Antler', 'Tine')): b = 'head'
        elif o.name == 'Tail': b = 'tail'
        attach(arm, o, b)
    # animations
    a = Anim(arm, 'Idle', 48, True); a.key('body', 0, scale=(1, 1, 1)); a.key('body', 24, scale=(1.02, 1, 1.04)); a.key('body', 48, scale=(1, 1, 1))
    a.key('head', 0, rot=(0, 0, 0)); a.key('head', 16, rot=(4, 0, 8)); a.key('head', 32, rot=(-3, 0, -8)); a.key('head', 48, rot=(0, 0, 0)); a.wave('tail', 15, 2, axis=2); a.done()
    a = Anim(arm, 'Walk', 24, True); amp = spec.get('stride', 32)
    a.wave('LegFL', amp, 1, 0); a.wave('LegBR', amp, 1, 0); a.wave('LegFR', amp, 1, math.pi); a.wave('LegBL', amp, 1, math.pi)
    a.bob('root', .05, 2); a.wave('head', 4, 2, axis=0); a.wave('tail', 12, 2, axis=2); a.done()
    a = Anim(arm, 'Attack', 24)
    a.key('root', 0, loc=(0, 0, 0)); a.key('root', 8, loc=(0, .18, -.04)); a.key('root', 13, loc=(0, -.45, .08)); a.key('root', 24, loc=(0, 0, 0))
    a.key('body', 0, rot=(0, 0, 0)); a.key('body', 8, rot=(-10, 0, 0)); a.key('body', 13, rot=(14, 0, 0)); a.key('body', 24, rot=(0, 0, 0))
    a.key('head', 0, rot=(0, 0, 0)); a.key('head', 8, rot=(-18, 0, 0)); a.key('head', 13, rot=(28, 0, 0)); a.key('head', 24, rot=(0, 0, 0)); a.done()
    a = Anim(arm, 'Hit', 16); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 4, loc=(0, .16, .02)); a.key('root', 16, loc=(0, 0, 0))
    a.key('body', 0, rot=(0, 0, 0)); a.key('body', 4, rot=(10, 0, 6)); a.key('body', 16, rot=(0, 0, 0)); a.done()
    a = Anim(arm, 'Die', 20); a.key('root', 0, rot=(0, 0, 0), loc=(0, 0, 0)); a.key('root', 6, rot=(0, -30, 0), loc=(0, 0, .12)); a.key('root', 14, rot=(0, -92, 0), loc=(.25, 0, -z0 + H * .5))
    a.key('root', 20, rot=(0, -92, 0), loc=(.25, 0, -z0 + H * .5)); a.done()
    a = Anim(arm, 'Dead', 1); a.key('root', 0, rot=(0, -92, 0), loc=(.25, 0, -z0 + H * .5)); a.done()
    return arm

def build_hen(spec):
    col = spec['col']
    ball('Body', .3, (0, 0, .42), col, 2, (1, 1.25, .95)); box('Tail', (.22, .16, .2), (0, .3, .55), spec.get('tail', '#8a7a68'), .04, rot=(35, 0, 0))
    ball('Head', .16, (0, -.36, .66), col, 2); cone('Beak', .05, .14, (0, -.55, .64), '#e8b040', rot=(-90, 0, 0))
    box('Comb', (.05, .16, .1), (0, -.36, .82), '#d83a2a', .02); box('Wattle', (.05, .06, .08), (0, -.48, .55), '#d83a2a', .02)
    eyes('', (0, -.46, .7), .1, .035)
    for sx in (-1, 1): box('Wing' + ('L' if sx < 0 else 'R'), (.08, .34, .2), (sx * .26, .02, .42), spec.get('wing', col), .03)
    for sx in (-1, 1): cyl('Leg' + ('L' if sx < 0 else 'R'), .025, .26, (sx * .1, 0, .13), '#e8b040', verts=5)
    arm = make_rig({'root': ((0, 0, 0), (0, 0, .3), None), 'body': ((0, 0, .42), (0, 0, .7), 'root'), 'head': ((0, -.3, .55), (0, -.3, .8), 'body'),
                    'LegL': ((-.1, 0, .26), (-.1, 0, .1), 'body'), 'LegR': ((.1, 0, .26), (.1, 0, .1), 'body'), 'WingL': ((-.2, 0, .5), (-.4, 0, .5), 'body'), 'WingR': ((.2, 0, .5), (.4, 0, .5), 'body')})
    for o in PARTS:
        b = 'body'
        if o.name in ('LegL', 'LegR', 'WingL', 'WingR'): b = o.name
        elif o.name.startswith(('Head', 'Beak', 'Comb', 'Wattle', 'Eye')): b = 'head'
        attach(arm, o, b)
    a = Anim(arm, 'Idle', 48, True); a.key('head', 0, rot=(0, 0, 0)); a.key('head', 12, rot=(0, 0, 25)); a.key('head', 24, rot=(0, 0, 0)); a.key('head', 30, rot=(35, 0, 0)); a.key('head', 36, rot=(0, 0, 0)); a.key('head', 48, rot=(0, 0, 0)); a.done()
    a = Anim(arm, 'Walk', 20, True); a.wave('LegL', 35, 1, 0); a.wave('LegR', 35, 1, math.pi); a.bob('root', .04, 2); a.wave('head', 12, 2, axis=0); a.wave('body', 6, 1, axis=1); a.done()
    a = Anim(arm, 'Attack', 20); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 6, loc=(0, .1, 0)); a.key('root', 11, loc=(0, -.3, 0)); a.key('root', 20, loc=(0, 0, 0))
    a.key('head', 0, rot=(0, 0, 0)); a.key('head', 6, rot=(-25, 0, 0)); a.key('head', 11, rot=(45, 0, 0)); a.key('head', 20, rot=(0, 0, 0))
    for w, sgn in (('WingL', 1), ('WingR', -1)): a.key(w, 0, rot=(0, 0, 0)); a.key(w, 8, rot=(0, sgn * 60, 0)); a.key(w, 14, rot=(0, sgn * 10, 0)); a.key(w, 20, rot=(0, 0, 0))
    a.done()
    a = Anim(arm, 'Hit', 14); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 4, loc=(0, .15, .1)); a.key('root', 14, loc=(0, 0, 0)); a.done()
    a = Anim(arm, 'Die', 18); a.key('root', 0, rot=(0, 0, 0), loc=(0, 0, 0)); a.key('root', 8, rot=(0, -60, 0), loc=(0, 0, .15)); a.key('root', 16, rot=(0, -95, 0), loc=(.2, 0, -.2)); a.key('root', 18, rot=(0, -95, 0), loc=(.2, 0, -.2)); a.done()
    a = Anim(arm, 'Dead', 1); a.key('root', 0, rot=(0, -95, 0), loc=(.2, 0, -.2)); a.done()
    return arm

def build_spider(spec):
    col, mark = spec['col'], spec.get('mark')
    z0 = .45
    ball('Thorax', .28, (0, -.1, z0), col, 2, (1.1, 1, .8)); ball('Abdomen', .38, (0, .5, z0 + .05), col, 2, (1, 1.2, .85))
    if mark: ball('Mark', .16, (0, .5, z0 + .38), mark, 1, (1, 1.4, .3))
    for i, sx in enumerate((-.12, -.04, .04, .12)): ball('Eye%d' % i, .05, (sx, -.36, z0 + .1 + (.04 if i in (1, 2) else 0)), '#e83a2a' if i in (1, 2) else '#141014', 1)
    for sx in (-1, 1): cone('Fang' + ('L' if sx < 0 else 'R'), .04, .16, (sx * .1, -.4, z0 - .12), '#2a2020', rot=(-150, 0, 0))
    legs = []; legparts = {}
    for i, (dy1, dy2) in enumerate(((-.42, -.7), (-.15, -.3), (.12, .25), (.4, .62))):
        for sx in (-1, 1):
            n = 'Leg%d%s' % (i, 'L' if sx < 0 else 'R'); y0 = -.08 + i * .1
            hip = (sx * .22, y0, z0 - .02); elbow = (sx * .62, y0 + dy1 * .5, z0 + .3); foot = (sx * .95, y0 + dy2, .0)
            a = seg(n, hip, elbow, .04, col); b = seg(n + '_lo', elbow, foot, .032, col); ball(n + '_k', .05, elbow, col, 1)
            legs.append(n); legparts[n] = [a, b]; legparts[n + '_lo'] = n; legparts[n + '_k'] = n
    bones = {'root': ((0, 0, 0), (0, 0, .3), None), 'body': ((0, 0, z0), (0, 0, z0 + .3), 'root')}
    for n in legs: bones[n] = ((0, 0, z0), (0, 0, z0 - .2), 'body')
    arm = make_rig(bones)
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode='EDIT')
    for o in PARTS:
        if o.name in legs: eb = arm.data.edit_bones[o.name]; sx = -1 if o.name.endswith('L') else 1; eb.head = (sx * .22, o.location.y, z0); eb.tail = (sx * .22, o.location.y, z0 - .2)
    bpy.ops.object.mode_set(mode='OBJECT')
    for o in PARTS:
        b = 'body'
        if o.name in legs: b = o.name
        elif o.name.endswith(('_lo', '_k')): b = o.name.rsplit('_', 1)[0]
        attach(arm, o, b)
    a = Anim(arm, 'Idle', 48, True); a.key('body', 0, loc=(0, 0, 0)); a.key('body', 24, loc=(0, 0, .04)); a.key('body', 48, loc=(0, 0, 0)); a.done()
    a = Anim(arm, 'Walk', 16, True)
    for k, n in enumerate(legs): a.wave(n, 22, 1, 0 if (k // 2 + k) % 2 == 0 else math.pi, axis=2)
    a.bob('root', .03, 2); a.done()
    a = Anim(arm, 'Attack', 22); a.key('body', 0, rot=(0, 0, 0), loc=(0, 0, 0)); a.key('body', 8, rot=(-35, 0, 0), loc=(0, .1, .2)); a.key('body', 12, rot=(15, 0, 0), loc=(0, -.3, 0)); a.key('body', 22, rot=(0, 0, 0), loc=(0, 0, 0))
    for n in legs[:4]: a.key(n, 0, rot=(0, 0, 0)); a.key(n, 8, rot=(0, 0, 0), loc=(0, 0, .3)); a.key(n, 12, loc=(0, 0, 0)); a.key(n, 22, loc=(0, 0, 0))
    a.done()
    a = Anim(arm, 'Hit', 14); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 4, loc=(0, .15, .05)); a.key('root', 14, loc=(0, 0, 0)); a.done()
    a = Anim(arm, 'Die', 18); a.key('root', 0, loc=(0, 0, 0), rot=(0, 0, 0)); a.key('root', 10, loc=(0, 0, .15), rot=(0, 0, 0)); a.key('root', 18, loc=(0, 0, -.25), rot=(0, 0, 0))
    for n in legs: a.key(n, 0, rot=(0, 0, 0)); a.key(n, 18, rot=(0, (-1 if n.endswith('L') else 1) * 60, 0))
    a.done()
    a = Anim(arm, 'Dead', 1); a.key('root', 0, loc=(0, 0, -.25))
    for n in legs: a.key(n, 0, rot=(0, (-1 if n.endswith('L') else 1) * 60, 0))
    a.done()
    return arm

def build_flyer(spec):
    col, wing = spec['col'], spec.get('wing', spec['col']); z0 = spec.get('hover', 1.2); moth = spec.get('moth')
    ball('Body', .22, (0, 0, z0), col, 2, (1, 1.3 if moth else 1.1, 1)); ball('Head', .16, (0, -.25, z0 + .06), col, 2)
    eyes('', (0, -.36, z0 + .1), .08, .04, '#ffd040' if not moth else '#141014')
    if moth:
        for sx in (-1, 1): box('Antenna' + ('L' if sx < 0 else 'R'), (.02, .3, .02), (sx * .06, -.4, z0 + .2), col, 0, rot=(-40, 0, sx * -20))
    else:
        for sx in (-1, 1): cone('Ear' + ('L' if sx < 0 else 'R'), .07, .18, (sx * .1, -.22, z0 + .22), col, rot=(0, sx * 20, 0))
    for sx in (-1, 1):
        n = 'Wing' + ('L' if sx < 0 else 'R')
        if moth: ball(n, .3, (sx * .38, 0, z0 + .02), wing, 1, (1.2, 1, .12))
        else: box(n, (.6, .38, .03), (sx * .42, 0, z0 + .02), wing, .01)
    arm = make_rig({'root': ((0, 0, 0), (0, 0, .3), None), 'body': ((0, 0, z0), (0, 0, z0 + .3), 'root'), 'WingL': ((-.12, 0, z0), (-.4, 0, z0), 'body'), 'WingR': ((.12, 0, z0), (.4, 0, z0), 'body')})
    for o in PARTS: attach(arm, o, o.name if o.name in ('WingL', 'WingR') else 'body')
    def flap(a, n, amp=45, cycles=None):
        cycles = cycles or n // 6
        for f in range(0, n + 1, 1):
            s = math.sin(2 * math.pi * cycles * f / n); a.key('WingL', f, rot=(0, -amp * s - 10, 0)); a.key('WingR', f, rot=(0, amp * s + 10, 0))
    a = Anim(arm, 'Idle', 36, True); flap(a, 36, 40, 6); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 18, loc=(0, 0, .12)); a.key('root', 36, loc=(0, 0, 0)); a.done()
    a = Anim(arm, 'Walk', 24, True); flap(a, 24, 50, 4); a.key('body', 0, rot=(15, 0, 0)); a.key('body', 24, rot=(15, 0, 0)); a.done()
    a = Anim(arm, 'Attack', 20); flap(a, 20, 55, 3); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 6, loc=(0, .15, .15)); a.key('root', 10, loc=(0, -.45, -.35)); a.key('root', 20, loc=(0, 0, 0)); a.done()
    a = Anim(arm, 'Hit', 12); flap(a, 12, 30, 2); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 4, loc=(0, .2, .1)); a.key('root', 12, loc=(0, 0, 0)); a.done()
    a = Anim(arm, 'Die', 18); a.key('root', 0, loc=(0, 0, 0), rot=(0, 0, 0)); a.key('root', 18, loc=(.1, 0, -z0 + .18), rot=(0, 160, 30)); a.key('WingL', 0, rot=(0, 0, 0)); a.key('WingL', 18, rot=(0, 70, 0)); a.key('WingR', 0, rot=(0, 0, 0)); a.key('WingR', 18, rot=(0, -70, 0)); a.done()
    a = Anim(arm, 'Dead', 1); a.key('root', 0, loc=(.1, 0, -z0 + .18), rot=(0, 160, 30)); a.key('WingL', 0, rot=(0, 70, 0)); a.key('WingR', 0, rot=(0, -70, 0)); a.done()
    return arm

def build_snake(spec, worm=False):
    col, belly = spec['col'], spec.get('belly', spec['col']); n = 7 if not worm else 6; seg = .3
    r0 = .2 if not worm else .22
    parts = []
    for i in range(n):
        r = r0 * (1 - .1 * i / n) if not worm else r0 * (1 - .06 * abs(i - n / 2))
        o = ball('Seg%d' % i, r, (0, i * seg, r), col, 2, (1, 1.2, 1)); parts.append(o)
        if not worm and i % 2 == 1: ball('Dia%d' % i, r * .55, (0, i * seg, r * 1.75), belly, 1, (1, 1.3, .25))
    hz = r0 * 1.1
    if not worm:
        ball('Head', .24, (0, -.3, hz + .05), col, 2, (1.1, 1.3, .8)); eyes('', (0, -.5, hz + .15), .12, .045, '#e8d040')
        box('Tongue', (.03, .25, .01), (0, -.65, hz - .02), '#d83a5a', 0)
    else:
        ball('Head', r0 * 1.05, (0, -.25, hz), spec.get('headCol', col), 2, (1, 1, .9)); eyes('', (0, -.42, hz + .05), .1, .04)
        for sx in (-1, 1): cone('Mand' + ('L' if sx < 0 else 'R'), .04, .12, (sx * .08, -.45, hz - .08), '#5a4a3a', rot=(-100, 0, 0))
    bones = {'root': ((0, 0, 0), (0, 0, .3), None), 'head': ((0, -.2, hz), (0, -.5, hz), 'root')}
    for i in range(n): bones['Seg%d' % i] = ((0, i * seg, hz), (0, i * seg + .2, hz), 'root')
    arm = make_rig(bones)
    for o in PARTS: attach(arm, o, o.name if o.name.startswith('Seg') else ('Seg' + o.name[3:] if o.name.startswith('Dia') else 'head'))
    def slither(a, length, amp, cycles=1):
        for f in range(0, length + 1, 2):
            for i in range(n):
                ph = 2 * math.pi * (cycles * f / length) - i * .9
                loc = [amp * math.sin(ph), 0, 0] if not worm else [0, 0, amp * max(0, math.sin(ph))]
                a.key('Seg%d' % i, f, loc=loc)
            a.key('head', f, loc=[amp * math.sin(2 * math.pi * cycles * f / length + .9), 0, 0] if not worm else [0, 0, 0])
    a = Anim(arm, 'Idle', 48, True); slither(a, 48, .05, 1); a.done()
    a = Anim(arm, 'Walk', 24, True); slither(a, 24, .14 if not worm else .12, 1); a.done()
    a = Anim(arm, 'Attack', 22); a.key('head', 0, loc=(0, 0, 0), rot=(0, 0, 0)); a.key('head', 8, loc=(0, .25, .3), rot=(-35, 0, 0)); a.key('head', 12, loc=(0, -.45, -.05), rot=(30, 0, 0)); a.key('head', 22, loc=(0, 0, 0), rot=(0, 0, 0)); a.done()
    a = Anim(arm, 'Hit', 12); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 4, loc=(0, .12, 0)); a.key('root', 12, loc=(0, 0, 0)); a.done()
    a = Anim(arm, 'Die', 18); a.key('root', 0, rot=(0, 0, 0)); a.key('root', 18, rot=(0, 75, 0)); a.key('head', 0, rot=(0, 0, 0)); a.key('head', 18, rot=(40, 0, 0)); a.done()
    a = Anim(arm, 'Dead', 1); a.key('root', 0, rot=(0, 75, 0)); a.key('head', 0, rot=(40, 0, 0)); a.done()
    return arm

SPECS = {
    'boar':    dict(plan='quad', body=(1.4, .72, .68), leg=.42, head=(.55, .5, .5), snout=(.28, .3, .26), col='#6a4a38', belly='#8a6a58', snoutCol='#a08070', tusks=1, ears=[.14, .06, .16], mane='#4a3226', tail='short', stride=30),
    'deer':    dict(plan='quad', body=(1.3, .5, .55), leg=.75, head=(.38, .5, .38), snout=(.2, .22, .2), col='#9a6b3e', belly='#d8c09a', antlers=1, ears=[.1, .05, .22], tail='short', legR=.07, stride=38),
    'wolf':    dict(plan='quad', body=(1.35, .55, .6), leg=.6, head=(.45, .55, .42), snout=(.22, .3, .22), col='#6a6a72', belly='#b8b8c0', ears=[.12, .05, .2], tail='bushy', stride=40, eye=1.1),
    'bear':    dict(plan='quad', body=(1.8, 1.0, .95), leg=.55, head=(.7, .6, .6), snout=(.32, .3, .3), col='#4a3a2e', belly='#6a5a4a', ears=[.16, .08, .16], tail='short', legR=.18, stride=24),
    'hen':     dict(plan='hen', col='#f1eadc', wing='#e0d6c4', tail='#8a7a68'),
    'spider':  dict(plan='spider', col='#3a2e2a', mark='#c93a2a'),
    'bat':     dict(plan='flyer', col='#4a3a52', wing='#2a1f30', hover=1.1),
    'moth':    dict(plan='flyer', col='#b8a87a', wing='#7a6a4a', moth=1, hover=1.2),
    'snake':   dict(plan='snake', col='#4a7a3a', belly='#c9c07a'),
    'maggot':  dict(plan='worm', col='#c9b08a', headCol='#a08a6a'),
}

def build(name):
    global PARTS, MATS; PARTS = []; MATS = {}
    bpy.ops.wm.read_factory_settings(use_empty=True)
    spec = SPECS[name]; plan = spec['plan']
    arm = {'quad': build_quad, 'hen': build_hen, 'spider': build_spider, 'flyer': build_flyer}.get(plan, None)
    if arm: arm = arm(spec)
    elif plan == 'snake': arm = build_snake(spec)
    elif plan == 'worm': arm = build_snake(spec, worm=True)
    for o in PARTS: o.name = name.capitalize() + '_' + o.name
    for o in bpy.data.objects:
        if o.type == 'MESH':
            for p in o.data.polygons: p.use_smooth = False
    arm.animation_data.action = bpy.data.actions['Idle']
    path = os.path.join(OUT, name + '.blend'); bpy.ops.wm.save_as_mainfile(filepath=path); print('saved', path)

if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    for n in (argv or list(SPECS)): build(n)
