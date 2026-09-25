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
def mat(col, rough=0.75, grad=0.28):
    """KayKit-style material: the colour runs light at the top of each part to darker at the bottom
    (KayKit bakes the same gradient into its palette cells), soft and slightly glossy."""
    key = (col, rough, grad)
    if key in MATS: return MATS[key]
    m = bpy.data.materials.new('m_' + col.lstrip('#')); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes['Principled BSDF']; b.inputs['Roughness'].default_value = rough
    base = hexc(col)
    if grad:
        tc = nt.nodes.new('ShaderNodeTexCoord'); sep = nt.nodes.new('ShaderNodeSeparateXYZ'); ramp = nt.nodes.new('ShaderNodeValToRGB')
        nt.links.new(tc.outputs['Generated'], sep.inputs[0]); nt.links.new(sep.outputs['Z'], ramp.inputs['Fac'])
        lo = tuple(max(0, c * (1 - grad)) for c in base); hi = tuple(min(1, c * (1 + grad * .8) + .015) for c in base)
        ramp.color_ramp.elements[0].position = 0.0; ramp.color_ramp.elements[0].color = (*lo, 1)
        ramp.color_ramp.elements[1].position = 0.85; ramp.color_ramp.elements[1].color = (*hi, 1)
        nt.links.new(ramp.outputs['Color'], b.inputs['Base Color'])
    else: b.inputs['Base Color'].default_value = (*base, 1)
    MATS[key] = m; return m

ROUND = 2.2     # how soft box corners are (x the per-part bevel)
PARTS = []
def box(name, size, loc, col, bevel=0.06, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc); o = bpy.context.object; o.name = name
    o.data.transform(Matrix.Diagonal((size[0], size[1], size[2], 1)))
    if bevel: m = o.modifiers.new('bevel', 'BEVEL'); m.width = min(bevel * ROUND, min(size) * .45); m.segments = 4; m.limit_method = 'NONE'; m.harden_normals = False
    o.rotation_euler = Euler([math.radians(a) for a in rot]); o.data.materials.append(mat(col)); PARTS.append(o); return o
def ball(name, r, loc, col, sub=2, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, subdivisions=max(sub, 3), location=loc); o = bpy.context.object; o.name = name
    o.data.transform(Matrix.Diagonal((*scale, 1))); o.data.materials.append(mat(col)); PARTS.append(o); return o
def cyl(name, r, h, loc, col, rot=(0, 0, 0), verts=12):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, vertices=max(verts, 10), location=loc); o = bpy.context.object; o.name = name
    m = o.modifiers.new('bevel', 'BEVEL'); m.width = r * .45; m.segments = 3; m.limit_method = 'ANGLE'
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
        # every bone points +Y with no roll, so pose rotations and offsets are in world axes:
        # x = pitch/right, y = roll/back, z = yaw/up (animations below are written that way)
        eb = ad.edit_bones.new(n); eb.head = Vector(h); eb.tail = Vector(h) + Vector((0, .2, 0)); eb.roll = 0; ebs[n] = eb
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

def taper(name, p1, p2, r1, r2, col, verts=14, rough=0.75):
    """A rounded tapered limb from p1 (radius r1) to p2 (radius r2)."""
    p1, p2 = Vector(p1), Vector(p2); d = p2 - p1
    bpy.ops.mesh.primitive_cone_add(radius1=r1, radius2=r2, depth=d.length, vertices=verts, location=(p1 + p2) / 2); o = bpy.context.object; o.name = name
    o.rotation_mode = 'QUATERNION'; o.rotation_quaternion = d.to_track_quat('Z', 'Y')
    m = o.modifiers.new('bevel', 'BEVEL'); m.width = min(r1, r2 if r2 > .01 else r1) * .5; m.segments = 3; m.limit_method = 'ANGLE'
    o.data.materials.append(mat(col, rough)); PARTS.append(o); return o
def blob(name, loc, radii, col, rough=0.75, rot=(0, 0, 0)):
    """A smooth ellipsoid (the building block of every animal body)."""
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1, segments=24, ring_count=14, location=loc); o = bpy.context.object; o.name = name
    o.data.transform(Matrix.Diagonal((*radii, 1))); o.rotation_euler = Euler([math.radians(a) for a in rot])
    o.data.materials.append(mat(col, rough)); PARTS.append(o); return o
def toon_eyes(center, sepx, r, fwd=-1):
    """Glossy black eyes with a white catch-light, KayKit style."""
    for sx, n in ((-1, 'L'), (1, 'R')):
        c = Vector((center[0] + sx * sepx, center[1], center[2]))
        blob('Eye' + n, c, (r, r * .8, r * 1.15), '#120e10', rough=0.25)
        blob('EyeHi' + n, c + Vector((sx * r * .15 - r * .25, fwd * r * .7, r * .45)), (r * .32, r * .2, r * .32), '#ffffff', rough=0.3)

# =========================================================================================
def build_quad2(spec):
    """Chunky stylised four-legged animal from smooth ellipsoids: chest and hips, a big head with a
    snout, tapered legs with hooves or paws. Forward is -Y."""
    sp = spec; col = sp['col']; belly = sp.get('belly', col); dark = sp.get('dark', '#2a2020')
    legH = sp['legH']; cr = Vector(sp['chest']); hr = Vector(sp.get('hips', sp['chest'])); blen = sp['len']
    z0 = legH + cr.z * .55
    chest = Vector((0, -blen / 2, z0 + sp.get('chestUp', .04))); hip = Vector((0, blen / 2, z0))
    blob('Chest', chest, cr, col); blob('Hips', hip, hr, col)
    blob('Mid', chest.lerp(hip, .5) + Vector((0, 0, .01)), ((cr.x + hr.x) * .49, blen * .55, (cr.z + hr.z) * .48), col)   # one continuous barrel
    blob('Belly', (0, 0, z0 - cr.z * .36), (min(cr.x, hr.x) * .72, blen * .6, cr.z * .6), belly)
    if sp.get('ruff'): blob('Ruff', chest + Vector((0, -cr.y * .35, cr.z * .15)), (cr.x * 1.08, cr.y * .7, cr.z * 1.05), sp['ruff'])
    if sp.get('hump'): blob('Hump', chest + Vector((0, cr.y * .15, cr.z * .55)), (cr.x * .62, cr.y * .7, cr.z * .42), col)
    # head
    H = Vector(sp['head']); hc = chest + Vector((0, -cr.y * .75 - H.y * .55, sp.get('headUp', cr.z * .55)))
    taper('Neck', chest + Vector((0, -cr.y * .3, cr.z * .2)), hc + Vector((0, H.y * .2, -H.z * .2)), cr.x * .6, H.x * .7, col)
    blob('Head', hc, H, col)
    sn = sp.get('snout')
    if sn:
        s0 = hc + Vector((0, -H.y * .55, -H.z * .25)); s1 = s0 + Vector((0, -sn[0], -sn[3] if len(sn) > 3 else -.02))
        taper('Snout', s0, s1, sn[1], sn[2], sp.get('snoutCol', col))
        if sp.get('disk'): blob('Nose', s1 + Vector((0, -.01, 0)), (sn[2] * 1.05, .04, sn[2] * .85), sp['disk'])
        else: blob('Nose', s1 + Vector((0, 0, sn[2] * .45)), (sn[2] * .6, sn[2] * .45, sn[2] * .4), '#1a1416', rough=.35)
    toon_eyes(hc + Vector((0, -H.y * .72, H.z * .22)), H.x * .5, sp.get('eye', .055))
    ea = sp.get('ears')     # (length, width, spread angle, style)
    if ea:
        for sx, n in ((-1, 'L'), (1, 'R')):
            base = hc + Vector((sx * H.x * .55, H.y * .15, H.z * .65))
            if ea[3] == 'round': blob('Ear' + n, base, (ea[1], ea[1] * .45, ea[1]), col, rot=(0, 0, 0))
            else:
                tip = base + Vector((sx * math.sin(math.radians(ea[2])) * ea[0], ea[0] * .15, math.cos(math.radians(ea[2])) * ea[0]))
                taper('Ear' + n, base, tip, ea[1], .01, col, verts=4 if ea[3] == 'sharp' else 10)
    if sp.get('tusks'):
        for sx, n in ((-1, 'L'), (1, 'R')):
            b = hc + Vector((sx * sn[1] * .8, -H.y * .75 - sn[0] * .5, -H.z * .45)); taper('Tusk' + n, b, b + Vector((sx * .06, -.08, .2)), .045, .005, '#f4ecd6', verts=8, rough=.4)
    if sp.get('antlers'):
        for sx, n in ((-1, 'L'), (1, 'R')):
            a0 = hc + Vector((sx * H.x * .35, H.y * .1, H.z * .8)); a1 = a0 + Vector((sx * .22, .08, .42)); a2 = a1 + Vector((sx * .12, .12, .25))
            taper('Antler' + n, a0, a1, .035, .026, '#d8c49a', 8); taper('AntlerB' + n, a1, a2, .026, .012, '#d8c49a', 8)
            taper('AntlerT' + n, a1 + (a0 - a1) * .45, a1 + Vector((-sx * .02, -.18, .18)), .022, .01, '#d8c49a', 8)
            taper('AntlerU' + n, a1, a1 + Vector((sx * .2, -.08, .12)), .022, .01, '#d8c49a', 8)
    if sp.get('mane'):   # a ridge of stiff bristles along the spine
        for k in range(9):
            t = k / 8; p = chest.lerp(hip, t * .8) + Vector((0, -cr.y * .25 * (1 - t), (cr.z if t < .5 else hr.z) * (.97 - .1 * t)))
            taper('Mane%d' % k, p - Vector((0, 0, .04)), p + Vector((0, .05, .13 - .05 * t)), .055, .008, sp['mane'], verts=6)
    # legs
    legs = {}
    lr = sp.get('legR', (.1, .07)); foot = sp.get('foot', 'hoof'); fcol = sp.get('footCol', dark)
    for name, sx, at, R in (('LegFL', -1, chest, cr), ('LegFR', 1, chest, cr), ('LegBL', -1, hip, hr), ('LegBR', 1, hip, hr)):
        top = at + Vector((sx * R.x * .58, (-.25 if name[3] == 'F' else .15) * R.y, -R.z * .35)); bot = Vector((top.x, top.y - (.03 if name[3] == 'F' else -.02), .09))
        legs[name] = taper(name, top, bot, lr[0] * (1.25 if name[3] == 'B' else 1.1), lr[1], sp.get('legCol', col))
        if foot == 'paw': blob(name + '_foot', bot + Vector((0, -.03, -.03)), (lr[1] * 1.45, lr[1] * 1.7, lr[1] * 1.0), fcol)
        else: blob(name + '_foot', bot + Vector((0, -.01, -.04)), (lr[1] * 1.2, lr[1] * 1.3, .06), fcol, rough=.5)
    # tail
    t = sp.get('tail', 'short'); tb = hip + Vector((0, hr.y * .9, hr.z * .3))
    if t == 'bushy': blob('Tail', tb + Vector((0, .22, -.08)), (.13, .3, .13), col, rot=(-35, 0, 0)); blob('TailTip', tb + Vector((0, .42, -.2)), (.09, .13, .09), sp.get('tailTip', belly), rot=(-35, 0, 0))
    elif t == 'tuft': taper('Tail', tb, tb + Vector((0, .2, -.15)), .035, .02, col, 8); blob('TailTip', tb + Vector((0, .21, -.17)), (.05, .05, .08), dark)
    elif t == 'flag': blob('Tail', tb + Vector((0, .07, .02)), (.07, .1, .09), belly)
    else: blob('Tail', tb + Vector((0, .06, 0)), (.06, .1, .06), col)
    # rig
    arm = make_rig({'root': ((0, 0, 0), (0, 0, .3), None), 'body': (tuple(chest.lerp(hip, .5)), tuple(chest.lerp(hip, .5) + Vector((0, 0, .3))), 'root'),
                    'head': (tuple(chest + Vector((0, -cr.y * .5, cr.z * .2))), tuple(chest + Vector((0, -cr.y * .5, cr.z * .2 + .3))), 'body'),
                    'tail': (tuple(tb), tuple(tb + Vector((0, .3, 0))), 'body'),
                    **{n: (tuple(o.location + (o.location - legs[n].location) * 0), (0, 0, 0), 'body') for n, o in legs.items()}})
    bpy.context.view_layer.objects.active = arm; bpy.ops.object.mode_set(mode='EDIT')
    for n, o in legs.items():
        # leg bone from the top of the leg straight down
        top = [p for p in PARTS if p.name == n][0]; eb = arm.data.edit_bones[n]
        v = top.data.vertices; zt = max((top.matrix_world @ vv.co).z for vv in v); x, y = top.location.x, top.location.y
        eb.head = (x, y, zt); eb.tail = (x, y + .2, zt); eb.roll = 0
    bpy.ops.object.mode_set(mode='OBJECT')
    for o in PARTS:
        b = 'body'
        if o.name.startswith('Leg'): b = o.name.split('_')[0]
        elif o.name.startswith(('Head', 'Snout', 'Nose', 'Eye', 'Ear', 'Tusk', 'Antler')): b = 'head'
        elif o.name.startswith('Tail'): b = 'tail'
        attach(arm, o, b)
    quad_anims(arm, sp, z0, cr.z, cr.x)
    return arm

def quad_anims(arm, sp, z0, H, W=.3):
    a = Anim(arm, 'Idle', 48, True); a.key('body', 0, scale=(1, 1, 1)); a.key('body', 24, scale=(1.015, 1, 1.03)); a.key('body', 48, scale=(1, 1, 1))
    a.key('head', 0, rot=(0, 0, 0)); a.key('head', 16, rot=(5, 0, 9)); a.key('head', 32, rot=(-4, 0, -9)); a.key('head', 48, rot=(0, 0, 0)); a.wave('tail', 14, 2, axis=2); a.done()
    a = Anim(arm, 'Walk', 24, True); amp = sp.get('stride', 32)
    a.wave('LegFL', amp, 1, 0); a.wave('LegBR', amp, 1, 0); a.wave('LegFR', amp, 1, math.pi); a.wave('LegBL', amp, 1, math.pi)
    a.bob('root', .04, 2); a.wave('body', 2.5, 2, axis=0); a.wave('head', 5, 2, axis=0, phase=.8); a.wave('tail', 14, 2, axis=2); a.done()
    a = Anim(arm, 'Attack', 24)
    a.key('root', 0, loc=(0, 0, 0)); a.key('root', 8, loc=(0, .16, -.03)); a.key('root', 12, loc=(0, -.42, .07)); a.key('root', 24, loc=(0, 0, 0))
    a.key('body', 0, rot=(0, 0, 0)); a.key('body', 8, rot=(-9, 0, 0)); a.key('body', 12, rot=(12, 0, 0)); a.key('body', 24, rot=(0, 0, 0))
    a.key('head', 0, rot=(0, 0, 0)); a.key('head', 8, rot=(-22, 0, 0)); a.key('head', 12, rot=(26, 0, 0)); a.key('head', 24, rot=(0, 0, 0))
    for n in ('LegFL', 'LegFR'): a.key(n, 0, rot=(0, 0, 0)); a.key(n, 8, rot=(-25, 0, 0)); a.key(n, 12, rot=(30, 0, 0)); a.key(n, 24, rot=(0, 0, 0))
    a.done()
    a = Anim(arm, 'Hit', 16); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 4, loc=(0, .16, .02)); a.key('root', 16, loc=(0, 0, 0))
    a.key('body', 0, rot=(0, 0, 0)); a.key('body', 4, rot=(8, 0, 6)); a.key('body', 16, rot=(0, 0, 0)); a.key('head', 0, rot=(0, 0, 0)); a.key('head', 4, rot=(-15, 0, 10)); a.key('head', 16, rot=(0, 0, 0)); a.done()
    drop = (0, 0, -(z0 - W * .92))   # roll onto the side around the body's own centre, then settle on the ground
    a = Anim(arm, 'Die', 20); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 6, loc=(0, 0, .06)); a.key('root', 14, loc=drop); a.key('root', 20, loc=drop)
    a.key('body', 0, rot=(0, 0, 0)); a.key('body', 6, rot=(0, -18, 0)); a.key('body', 14, rot=(0, -90, 0)); a.key('body', 20, rot=(0, -90, 0))
    for n in ('LegFL', 'LegFR', 'LegBL', 'LegBR'): a.key(n, 0, rot=(0, 0, 0)); a.key(n, 14, rot=(20 if 'F' in n else -20, 0, 0)); a.key(n, 20, rot=(20 if 'F' in n else -20, 0, 0))
    a.key('head', 0, rot=(0, 0, 0)); a.key('head', 14, rot=(15, 0, 0)); a.key('head', 20, rot=(15, 0, 0)); a.done()
    a = Anim(arm, 'Dead', 1); a.key('root', 0, loc=drop); a.key('body', 0, rot=(0, -90, 0)); a.key('head', 0, rot=(15, 0, 0))
    for n in ('LegFL', 'LegFR', 'LegBL', 'LegBR'): a.key(n, 0, rot=(20 if 'F' in n else -20, 0, 0))
    a.done()

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
        eb = arm.data.edit_bones[name]; x, y = o.location.x, o.location.y; eb.head = (x, y, sh); eb.tail = (x, y + .2, sh); eb.roll = 0
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
    a = Anim(arm, 'Die', 18); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 8, loc=(0, 0, .12)); a.key('root', 16, loc=(0, 0, -.16)); a.key('root', 18, loc=(0, 0, -.16))
    a.key('body', 0, rot=(0, 0, 0)); a.key('body', 8, rot=(0, -50, 0)); a.key('body', 16, rot=(0, -95, 0)); a.key('body', 18, rot=(0, -95, 0))
    a.key('LegL', 0, rot=(0, 0, 0)); a.key('LegL', 16, rot=(-40, 0, 0)); a.key('LegR', 0, rot=(0, 0, 0)); a.key('LegR', 16, rot=(-40, 0, 0)); a.done()
    a = Anim(arm, 'Dead', 1); a.key('root', 0, loc=(0, 0, -.16)); a.key('body', 0, rot=(0, -95, 0)); a.key('LegL', 0, rot=(-40, 0, 0)); a.key('LegR', 0, rot=(-40, 0, 0)); a.done()
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
        if o.name in legs: eb = arm.data.edit_bones[o.name]; sx = -1 if o.name.endswith('L') else 1; eb.head = (sx * .22, o.location.y, z0); eb.tail = (sx * .22, o.location.y + .2, z0); eb.roll = 0
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

def membrane(name, pts, col, thick=.018):
    """A flat wing membrane from an outline (list of (x, y, z)), given a little thickness."""
    import bmesh
    me = bpy.data.meshes.new(name); o = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(o)
    bm = bmesh.new(); vs = [bm.verts.new(p) for p in pts]; bm.faces.new(vs); bmesh.ops.triangulate(bm, faces=bm.faces[:]); bm.to_mesh(me); bm.free()
    m = o.modifiers.new('solid', 'SOLIDIFY'); m.thickness = thick; m.offset = 0
    o.data.materials.append(mat(col, .6, .18)); PARTS.append(o); return o
def build_flyer(spec):
    col, wing = spec['col'], spec.get('wing', spec['col']); z0 = spec.get('hover', 1.2); moth = spec.get('moth')
    if moth:
        blob('Body', (0, .06, z0), (.13, .3, .13), col); blob('Thorax', (0, -.12, z0 + .02), (.16, .14, .15), spec.get('fur', col)); blob('Head', (0, -.26, z0 + .04), (.11, .1, .1), col)
        toon_eyes((0, -.33, z0 + .06), .07, .04)
        for sx in (-1, 1):
            nme = 'L' if sx < 0 else 'R'; a0 = Vector((sx * .04, -.32, z0 + .12))
            taper('Antenna' + nme, a0, a0 + Vector((sx * .12, -.14, .2)), .012, .006, '#4a3a2a', 6); blob('AntTip' + nme, a0 + Vector((sx * .12, -.14, .2)), (.03, .03, .03), '#4a3a2a')
    else:
        blob('Body', (0, .02, z0), (.18, .22, .2), col); blob('Head', (0, -.2, z0 + .08), (.15, .14, .14), col)
        blob('Snout', (0, -.32, z0 + .05), (.07, .06, .055), spec.get('snout', col))
        for sx in (-1, 1):
            nme = 'L' if sx < 0 else 'R'
            taper('Ear' + nme, (sx * .09, -.18, z0 + .17), (sx * .17, -.16, z0 + .38), .07, .01, col, 10)
            blob('EarIn' + nme, (sx * .125, -.21, z0 + .25), (.03, .015, .06), '#c07a8a')
            taper('Fang' + nme, (sx * .03, -.35, z0 + .01), (sx * .03, -.36, z0 - .06), .014, .003, '#f4ecd8', 6)
            blob('Eye' + nme, (sx * .075, -.3, z0 + .12), (.035, .025, .035), '#ffd040', rough=.2)
    for sx in (-1, 1):
        n = 'Wing' + ('L' if sx < 0 else 'R')
        if moth:
            blob(n, (sx * .34, -.04, z0 + .02), (.3, .22, .02), wing, rot=(0, 0, sx * -18))
            blob(n + 'Hind', (sx * .24, .2, z0), (.2, .16, .018), wing, rot=(0, 0, sx * 25))
            blob(n + 'Spot', (sx * .4, -.06, z0 + .035), (.07, .07, .012), spec.get('spot', '#3a2a1a'))
        else:   # leathery membrane between finger bones, scalloped trailing edge
            P = lambda x, y, z=0: (sx * x, y, z0 + z)
            wrist = P(.4, -.12, .16); tips = [P(.82, .02, .08), P(.72, .3, .02), P(.48, .4, -.02), P(.24, .32, -.02)]
            out = [P(.12, -.06, .02), wrist, tips[0], P(.66, .16, .04), tips[1], P(.52, .28, .0), tips[2], P(.34, .3, -.01), tips[3], P(.14, .2, 0)]
            membrane(n, out, wing)
            taper(n + 'Arm', P(.12, -.06, .02), wrist, .03, .022, col, 8)
            for k, t in enumerate(tips): taper(n + 'Bone%d' % k, wrist, t, .016, .006, col, 6)
    arm = make_rig({'root': ((0, 0, 0), (0, 0, .3), None), 'body': ((0, 0, z0), (0, 0, z0 + .3), 'root'), 'WingL': ((-.12, 0, z0), (-.4, 0, z0), 'body'), 'WingR': ((.12, 0, z0), (.4, 0, z0), 'body')})
    for o in PARTS: attach(arm, o, o.name[:5] if o.name.startswith(('WingL', 'WingR')) else 'body')
    def flap(a, n, amp=45, cycles=None):
        cycles = cycles or n // 6
        for f in range(0, n + 1, 1):
            s = math.sin(2 * math.pi * cycles * f / n); a.key('WingL', f, rot=(0, -amp * s - 10, 0)); a.key('WingR', f, rot=(0, amp * s + 10, 0))
    a = Anim(arm, 'Idle', 36, True); flap(a, 36, 40, 6); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 18, loc=(0, 0, .12)); a.key('root', 36, loc=(0, 0, 0)); a.done()
    a = Anim(arm, 'Walk', 24, True); flap(a, 24, 50, 4); a.key('body', 0, rot=(15, 0, 0)); a.key('body', 24, rot=(15, 0, 0)); a.done()
    a = Anim(arm, 'Attack', 20); flap(a, 20, 55, 3); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 6, loc=(0, .15, .15)); a.key('root', 10, loc=(0, -.45, -.35)); a.key('root', 20, loc=(0, 0, 0)); a.done()
    a = Anim(arm, 'Hit', 12); flap(a, 12, 30, 2); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 4, loc=(0, .2, .1)); a.key('root', 12, loc=(0, 0, 0)); a.done()
    a = Anim(arm, 'Die', 18); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 6, loc=(0, 0, .1)); a.key('root', 18, loc=(0, 0, -z0 + .16)); a.key('body', 0, rot=(0, 0, 0)); a.key('body', 18, rot=(0, 160, 30)); a.key('WingL', 0, rot=(0, 0, 0)); a.key('WingL', 18, rot=(0, 70, 0)); a.key('WingR', 0, rot=(0, 0, 0)); a.key('WingR', 18, rot=(0, -70, 0)); a.done()
    a = Anim(arm, 'Dead', 1); a.key('root', 0, loc=(0, 0, -z0 + .16)); a.key('body', 0, rot=(0, 160, 30)); a.key('WingL', 0, rot=(0, 70, 0)); a.key('WingR', 0, rot=(0, -70, 0)); a.done()
    return arm

def build_snake(spec, worm=False):
    """Snake: many overlapping body beads (one bone each) so it reads as one smooth tapering body and
    can slither; a flat wedge head. Worm: fewer, fatter, visibly segmented beads."""
    col, belly = spec['col'], spec.get('belly', spec['col'])
    n = 13 if not worm else 7; seg = .12 if not worm else .19; r0 = .15 if not worm else .21
    y0 = -n * seg * .42
    Y = lambda i: y0 + i * seg
    for i in range(n):
        r = r0 * (1 - .6 * (i / n) ** 1.4) if not worm else r0 * (1 - .07 * abs(i - n / 2.4))
        blob('Seg%d' % i, (0, Y(i), r * .92), (r, r * 1.05, r * .92), col)
        if not worm and i % 2 == 0 and 0 < i < n - 1: blob('Dia%d' % i, (0, Y(i), r * 1.72), (r * .55, r * .5, r * .12), spec.get('pattern', belly))
        if worm: blob('Dia%d' % i, (0, Y(i), r * .5), (r * 1.04, r * .35, r * .7), spec.get('ring', col))
    hz = r0 * .95
    if not worm:
        blob('Head', (0, y0 - .17, hz + .02), (.17, .22, .12), col); blob('HeadJaw', (0, y0 - .2, hz - .05), (.13, .17, .07), belly)
        for sx, nme in ((-1, 'L'), (1, 'R')):
            blob('Eye' + nme, (sx * .1, y0 - .26, hz + .08), (.04, .035, .045), '#e8c830', rough=.2)
            blob('Pupil' + nme, (sx * .115, y0 - .285, hz + .085), (.012, .02, .035), '#120e10', rough=.2)
        taper('Tongue', (0, y0 - .38, hz - .03), (0, y0 - .52, hz - .02), .012, .006, '#d83a5a', 6)
    else:
        blob('Head', (0, y0 - .2, hz), (r0 * 1.02, r0 * .95, r0 * .9), spec.get('headCol', col))
        toon_eyes((0, y0 - .36, hz + .05), .09, .035)
        for sx in (-1, 1): taper('Mand' + ('L' if sx < 0 else 'R'), (sx * .07, y0 - .36, hz - .08), (sx * .03, y0 - .46, hz - .1), .035, .008, '#4a3a2a', 8)
    bones = {'root': ((0, 0, 0), (0, 0, .3), None), 'head': ((0, y0 - .05, hz), (0, y0 - .35, hz), 'root')}
    for i in range(n): bones['Seg%d' % i] = ((0, Y(i), hz), (0, Y(i) + .15, hz), 'root')
    arm = make_rig(bones)
    for o in PARTS: attach(arm, o, o.name if o.name.startswith('Seg') else ('Seg' + o.name[3:] if o.name.startswith('Dia') else 'head'))
    def slither(a, length, amp, cycles=1):
        for f in range(0, length + 1, 2):
            for i in range(n):
                ph = 2 * math.pi * (cycles * f / length) - i * (.5 if not worm else .9)
                loc = [amp * math.sin(ph) + .1 * math.sin(i * .5 + .6) - .1 * math.sin(.6), 0, 0] if not worm else [0, 0, amp * max(0, math.sin(ph))]   # a resting S-curve
                a.key('Seg%d' % i, f, loc=loc)
            a.key('head', f, loc=[amp * math.sin(2 * math.pi * cycles * f / length + .9), 0, 0] if not worm else [0, 0, 0])
    a = Anim(arm, 'Idle', 48, True); slither(a, 48, .05, 1); a.done()
    a = Anim(arm, 'Walk', 24, True); slither(a, 24, .14 if not worm else .12, 1); a.done()
    a = Anim(arm, 'Attack', 22)   # rear back, strike forward; the front of the body follows the head
    a.key('head', 0, loc=(0, 0, 0), rot=(0, 0, 0)); a.key('head', 8, loc=(0, .1, .24), rot=(-30, 0, 0)); a.key('head', 12, loc=(0, -.24, .02), rot=(22, 0, 0)); a.key('head', 22, loc=(0, 0, 0), rot=(0, 0, 0))
    for i in range(4):
        w = (4 - i) / 4.5
        a.key('Seg%d' % i, 0, loc=(0, 0, 0)); a.key('Seg%d' % i, 8, loc=(0, .08 * w, .18 * w)); a.key('Seg%d' % i, 12, loc=(0, -.18 * w, .01)); a.key('Seg%d' % i, 22, loc=(0, 0, 0))
    a.done()
    a = Anim(arm, 'Hit', 12); a.key('root', 0, loc=(0, 0, 0)); a.key('root', 4, loc=(0, .12, 0)); a.key('root', 12, loc=(0, 0, 0)); a.done()
    a = Anim(arm, 'Die', 18); a.key('root', 0, rot=(0, 0, 0)); a.key('root', 18, rot=(0, 75, 0)); a.key('head', 0, rot=(0, 0, 0)); a.key('head', 18, rot=(40, 0, 0)); a.done()
    a = Anim(arm, 'Dead', 1); a.key('root', 0, rot=(0, 75, 0)); a.key('head', 0, rot=(40, 0, 0)); a.done()
    return arm

SPECS = {
    'boar':    dict(plan='quad2', legH=.36, chest=(.36, .42, .35), hips=(.33, .37, .31), len=.55, head=(.31, .31, .27), headUp=.12, snout=(.2, .15, .13, .02),
                    disk='#e0a090', tusks=1, ears=(.17, .08, 38, 'sharp'), mane='#3e2c22', col='#6e4c38', belly='#9a7a62', dark='#2a2020', legR=(.095, .06), tail='tuft', eye=.048, stride=30),
    'wolf':    dict(plan='quad2', legH=.44, chest=(.27, .35, .29), hips=(.22, .29, .24), len=.5, head=(.22, .26, .2), headUp=.3, snout=(.24, .1, .06, .04),
                    ears=(.21, .08, 14, 'sharp'), ruff='#7c7c86', col='#6a6a74', belly='#c0c0c8', foot='paw', footCol='#55555e', legR=(.075, .05), tail='bushy', tailTip='#d8d8e0', eye=.045, stride=40),
    'deer':    dict(plan='quad2', legH=.68, chest=(.21, .31, .25), hips=(.2, .29, .24), len=.5, head=(.15, .19, .15), headUp=.52, snout=(.15, .09, .06, .03),
                    ears=(.2, .085, 62, 'leaf'), antlers=1, col='#a0703e', belly='#eadcc0', dark='#3a2a20', legR=(.055, .035), tail='flag', eye=.045, stride=38),
    'bear':    dict(plan='quad2', legH=.48, chest=(.44, .48, .42), hips=(.4, .42, .38), len=.55, head=(.33, .32, .3), headUp=.22, snout=(.17, .15, .12, .04), snoutCol='#a08060',
                    ears=(.1, .1, 0, 'round'), hump=1, col='#3e2e24', belly='#4e3e30', foot='paw', footCol='#221a14', legR=(.15, .11), tail='short', eye=.05, stride=24),
    'hen':     dict(plan='hen', col='#f1eadc', wing='#e0d6c4', tail='#8a7a68'),
    'spider':  dict(plan='spider', col='#3a2e2a', mark='#c93a2a'),
    'bat':     dict(plan='flyer', col='#4e3e56', wing='#33263c', snout='#6a5070', hover=1.1),
    'moth':    dict(plan='flyer', col='#c8b88a', fur='#e8dcc0', wing='#9a845a', spot='#4a3222', moth=1, hover=1.2),
    'snake':   dict(plan='snake', col='#4e8a3a', belly='#d8cf8a', pattern='#2e4a22'),
    'maggot':  dict(plan='worm', col='#e2d2a8', ring='#c8b48a', headCol='#8a6a4a'),
}

def build(name):
    global PARTS, MATS; PARTS = []; MATS = {}
    bpy.ops.wm.read_factory_settings(use_empty=True)
    spec = SPECS[name]; plan = spec['plan']
    arm = {'quad': build_quad, 'quad2': build_quad2, 'hen': build_hen, 'spider': build_spider, 'flyer': build_flyer}.get(plan, None)
    if arm: arm = arm(spec)
    elif plan == 'snake': arm = build_snake(spec)
    elif plan == 'worm': arm = build_snake(spec, worm=True)
    for o in PARTS: o.name = name.capitalize() + '_' + o.name
    for o in bpy.data.objects:
        if o.type == 'MESH':
            for p in o.data.polygons: p.use_smooth = True
    for pb in arm.pose.bones: pb.rotation_euler = (0, 0, 0); pb.location = (0, 0, 0); pb.scale = (1, 1, 1)
    arm.animation_data.action = bpy.data.actions['Idle']
    path = os.path.join(OUT, name + '.blend'); bpy.ops.wm.save_as_mainfile(filepath=path); print('saved', path)

if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    for n in (argv or list(SPECS)): build(n)
