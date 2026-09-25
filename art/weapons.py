"""
Builds every weapon in the game as its own low-poly model, in KayKit's chunky style, so each item
shows its own shape on the character (not a recoloured stock sword).

    python3 art/weapons.py                 # writes art/models/weapons/<key>.blend for every weapon
    python3 art/weapons.py moon kris       # only these

Axes match KayKit's hand-slot weapons: the grip is at the origin, the blade points +Z, the flat of
the blade faces ±Y, the guard runs along X. render.py attaches the model to the `handslot.r` bone
with KayKit's own offset, so a weapon fits every body.
Keys are the item `look.k` values from src/sim/data.js (sprites.js maps k -> wpn_<k>).
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector, Matrix, Euler

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'art', 'models', 'weapons'); os.makedirs(OUT, exist_ok=True)

def hexc(h): h = h.lstrip('#'); return tuple((int(h[i:i + 2], 16) / 255) ** 2.2 for i in (0, 2, 4))
MATS = {}
def mat(col, rough=.5, metal=0., grad=.25, glow=0.):
    """KayKit-style material: light-to-dark gradient along each part (like KayKit's palette cells);
    metal gives a soft sheen; glow makes it emissive (magic crystals, embers)."""
    key = (col, rough, metal, grad, glow)
    if key in MATS: return MATS[key]
    m = bpy.data.materials.new('m_%s_%d' % (col.lstrip('#'), len(MATS))); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes['Principled BSDF']; b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metal
    base = hexc(col)
    tc = nt.nodes.new('ShaderNodeTexCoord'); sep = nt.nodes.new('ShaderNodeSeparateXYZ'); ramp = nt.nodes.new('ShaderNodeValToRGB')
    nt.links.new(tc.outputs['Generated'], sep.inputs[0]); nt.links.new(sep.outputs['Z'], ramp.inputs['Fac'])
    lo = tuple(max(0, c * (1 - grad)) for c in base); hi = tuple(min(1, c * (1 + grad * .7) + .01) for c in base)
    ramp.color_ramp.elements[0].color = (*lo, 1); ramp.color_ramp.elements[1].position = .9; ramp.color_ramp.elements[1].color = (*hi, 1)
    nt.links.new(ramp.outputs['Color'], b.inputs['Base Color'])
    if glow:
        b.inputs['Emission Color'].default_value = (*base, 1); b.inputs['Emission Strength'].default_value = min(1.6, glow * .45)
    MATS[key] = m; return m

# material presets
STEEL = dict(col='#c4ccd4', rough=.32, metal=.55); DSTEEL = dict(col='#555a66', rough=.35, metal=.5)
GOLD = dict(col='#e8b440', rough=.3, metal=.7); BRONZE = dict(col='#c8844a', rough=.35, metal=.6)
WOOD = dict(col='#8a5a32', rough=.7); DWOOD = dict(col='#5a3a24', rough=.7); LEATHER = dict(col='#5a3826', rough=.8)
BONE = dict(col='#eadfc6', rough=.6); IRON = dict(col='#8a8e96', rough=.45, metal=.4)

PARTS = []
def _fin(o, m, bevel=0., seg=2, smooth=True):
    if bevel: b = o.modifiers.new('bevel', 'BEVEL'); b.width = bevel; b.segments = seg; b.limit_method = 'ANGLE'; b.angle_limit = math.radians(40)
    o.data.materials.append(mat(**m))
    PARTS.append(o); return o

def slab(outline, thick, m, y=0., bevel=None, taper_edge=.35):
    """A flat piece (blade, axe head, guard) from a 2D outline [(x, z), ...] in the XZ plane, `thick`
    deep in Y. The rim is pinched thinner than the middle so it reads as a sharpened edge."""
    me = bpy.data.meshes.new('slab'); o = bpy.data.objects.new('slab', me); bpy.context.scene.collection.objects.link(o)
    bm = bmesh.new()
    cx = sum(p[0] for p in outline) / len(outline); cz = sum(p[1] for p in outline) / len(outline)
    front = [bm.verts.new((x, y - thick / 2, z)) for x, z in outline]; back = [bm.verts.new((x, y + thick / 2, z)) for x, z in outline]
    # a raised centre ridge: an inset ring in the middle on both faces
    fi = [bm.verts.new((cx + (x - cx) * .55, y - thick * .5 - thick * .0, cz + (z - cz) * .55)) for x, z in outline]
    bi = [bm.verts.new((cx + (x - cx) * .55, y + thick * .5, cz + (z - cz) * .55)) for x, z in outline]
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((front[i], front[j], back[j], back[i]))
        bm.faces.new((front[j], front[i], fi[i], fi[j])); bm.faces.new((back[i], back[j], bi[j], bi[i]))
    bm.faces.new(list(reversed(fi))); bm.faces.new(bi)
    # pinch the rim: outer ring is thinner than the inset (sharpened look)
    for v in front: v.co.y = y - thick * taper_edge / 2
    for v in back: v.co.y = y + thick * taper_edge / 2
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:]); bm.to_mesh(me); bm.free()
    return _fin(o, m, bevel if bevel is not None else thick * .18)

def cyl(p1, p2, r1, r2, m, verts=10, bevel=None):
    p1, p2 = Vector(p1), Vector(p2); d = p2 - p1
    bpy.ops.mesh.primitive_cone_add(radius1=r1, radius2=r2, depth=d.length, vertices=verts, location=(p1 + p2) / 2); o = bpy.context.object
    o.rotation_mode = 'QUATERNION'; o.rotation_quaternion = d.to_track_quat('Z', 'Y')
    return _fin(o, m, bevel if bevel is not None else min(r1, r2 if r2 > .005 else r1) * .35)
def ball(c, r, m, scale=(1, 1, 1), sub=3, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, subdivisions=sub, location=c); o = bpy.context.object
    o.data.transform(Matrix.Diagonal((*scale, 1))); o.rotation_euler = Euler([math.radians(a) for a in rot]); return _fin(o, m)
def box(c, size, m, bevel=.03, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c); o = bpy.context.object
    o.data.transform(Matrix.Diagonal((*size, 1))); o.rotation_euler = Euler([math.radians(a) for a in rot])
    b = o.modifiers.new('bevel', 'BEVEL'); b.width = bevel; b.segments = 2; b.limit_method = 'NONE'
    o.data.materials.append(mat(**m)); PARTS.append(o); return o
def gem(c, r, col, glow=2.5, scale=(1, 1, 1.3), rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, subdivisions=1, location=c); o = bpy.context.object
    o.data.transform(Matrix.Diagonal((*scale, 1))); o.rotation_euler = Euler([math.radians(a) for a in rot])
    o.data.materials.append(mat(col, .15, .1, .2, glow)); PARTS.append(o); return o
def crystal(c, r, h, col, glow=3., tilt=(0, 0, 0)):
    """A hexagonal crystal point."""
    base = Vector(c); o = cyl(base, base + Vector((0, 0, h * .7)), r, r * .9, dict(col=col, rough=.15, glow=glow), verts=6, bevel=0)
    o.rotation_mode = 'XYZ'; t = cyl(base + Vector((0, 0, h * .7)), base + Vector((0, 0, h)), r * .9, .005, dict(col=col, rough=.15, glow=glow), verts=6, bevel=0)
    for p in (o, t):
        p.matrix_world = Matrix.Translation(base) @ Euler([math.radians(a) for a in tilt]).to_matrix().to_4x4() @ Matrix.Translation(-base) @ p.matrix_world
    return o

def inlay(z0, z1, w, col, thick, glow=2.5, x=0.):
    """A glowing rune strip set into both faces of a blade."""
    for s in (-1, 1): slab([(x + w, z0), (x + w * .6, z1), (x, z1 + w), (x - w * .6, z1), (x - w, z0)], .012, dict(col=col, rough=.2, glow=glow), y=s * (thick * .5 + .004), bevel=.003, taper_edge=1)
def mirror_x(pts): return pts + [(-x, z) for x, z in reversed(pts)]

# ---- hilts ---------------------------------------------------------------------------------
def hilt(grip=.32, guard=.24, gm=LEATHER, cm=STEEL, pm=None, gz=.0, pommel=.07, guard_shape='bar', guard_col=None):
    cyl((0, 0, -grip), (0, 0, gz), .045, .045, gm, 10)
    for k in range(3): cyl((0, 0, -grip * (.2 + .3 * k)), (0, 0, -grip * (.2 + .3 * k) + .04), .052, .052, gm, 10, 0)   # wrap bands
    ball((0, 0, -grip - pommel * .6), pommel, pm or cm)
    gcm = guard_col or cm
    if guard_shape == 'bar': box((0, 0, gz + .03), (guard * 2, .09, .07), gcm, .025)
    elif guard_shape == 'wing': slab([(0, gz - .02), (guard, gz + .1), (guard * 1.1, gz + .2), (guard * .6, gz + .08), (0, gz + .08)] + [(-guard * .6, gz + .08), (-guard * 1.1, gz + .2), (-guard, gz + .1)], .08, gcm)
    elif guard_shape == 'disc': cyl((0, -.05, gz + .03), (0, .05, gz + .03), guard * .7, guard * .7, gcm, 16)
    elif guard_shape == 'claw': slab([(0, gz - .03), (guard, gz), (guard * 1.15, gz + .16), (guard * .7, gz + .06), (0, gz + .1), (-guard * .7, gz + .06), (-guard * 1.15, gz + .16), (-guard, gz)], .08, gcm)

# ---- the weapons -----------------------------------------------------------------------------
def sword_blade(length, width, tip=.22, m=STEEL, thick=.07, base=.05, curve=0., waves=0, serr=0):
    """Outline of a blade from base to tip; curve bends it, waves makes a kris, serr adds teeth."""
    n = 10; right = []; left = []
    for i in range(n + 1):
        t = i / n; z = base + (length - tip) * t
        off = curve * (t ** 2) * length
        w = width * (1 - .12 * t) + (math.sin(t * math.pi * waves * 2) * width * .25 if waves else 0)
        right.append((off + w, z)); left.append((off - w, z))
        if serr and 0 < i < n and i % 2 == 1: right[-1] = (off + w + width * .45 * serr, z - .03)
    tipp = (curve * length * 1.02, length)
    return slab(right + [tipp] + list(reversed(left)), thick, m)

def W_wood():
    slab([(.1, .05), (.11, 1.1), (0, 1.28), (-.11, 1.1), (-.1, .05)], .09, WOOD); hilt(.3, .2, LEATHER, DWOOD, DWOOD)
def W_sword():
    sword_blade(1.36, .11); inlay(.1, 1.0, .018, '#7a808c', .07, 0); hilt(.33, .26, LEATHER, STEEL, GOLD)
def W_leaf():
    slab([(.06, .05), (.16, .5), (.15, .85), (0, 1.3), (-.15, .85), (-.16, .5), (-.06, .05)], .08, BRONZE); hilt(.3, .2, LEATHER, BRONZE, BRONZE)
def W_curved():
    sword_blade(1.36, .12, .3, STEEL, curve=-.22); hilt(.32, .24, dict(col='#3a2a4a', rough=.7), GOLD, GOLD, guard_shape='wing')
def W_serrated():
    sword_blade(1.42, .14, .26, dict(col='#7a2424', rough=.35, metal=.5), serr=1); inlay(.15, 1.0, .025, '#ff4a2a', .07)
    hilt(.33, .28, dict(col='#2a1a1a', rough=.7), DSTEEL, dict(col='#ff3a2a', rough=.2, glow=2), guard_shape='claw')
def W_moon():
    sword_blade(1.4, .12, .3, dict(col='#dfe6ff', rough=.25, metal=.4), curve=.12); ball((0, 0, .12), .12, dict(col='#bcd0ff', rough=.2, glow=1.2), scale=(1, .5, 1))
    hilt(.32, .3, dict(col='#2a3a6a', rough=.7), dict(col='#c8d4f0', rough=.3, metal=.6), dict(col='#e8f0ff', rough=.2, glow=1.5), guard_shape='wing')
def W_fang():
    slab([(.1, .05), (.17, .55), (.12, 1.05), (-.06, 1.42), (-.03, 1.0), (-.08, .5), (-.1, .05)], .1, BONE); hilt(.32, .25, dict(col='#6a2a1a', rough=.7), GOLD, dict(col='#ffb030', rough=.2, glow=2), guard_shape='claw')
def W_kris():
    sword_blade(1.2, .085, .22, dict(col='#9adfa0', rough=.3, metal=.4), waves=2.5); hilt(.3, .2, dict(col='#2a5a3a', rough=.7), GOLD, dict(col='#6fef8f', rough=.2, glow=1.5))
def W_jade():
    sword_blade(1.38, .11, .24, dict(col='#9fe8b3', rough=.2, metal=.1)); inlay(.12, .95, .022, '#3ac878', .07, 1.5)
    hilt(.33, .26, dict(col='#1a4a2a', rough=.7), GOLD, dict(col='#3ac878', rough=.2, glow=1.5), guard_shape='disc')
def W_reaver():
    slab([(.06, .05), (.1, .8), (.3, 1.1), (.42, 1.28), (.2, 1.26), (0, 1.35), (-.08, 1.0), (-.08, .05)], .08, dict(col='#3a5a4a', rough=.35, metal=.5))
    inlay(.12, .85, .022, '#50ff80', .08); hilt(.34, .24, dict(col='#1a2a22', rough=.7), DSTEEL, dict(col='#50ff80', rough=.2, glow=2.5), guard_shape='claw')
def W_long():
    sword_blade(1.95, .13, .28, STEEL); inlay(.12, 1.5, .02, '#6a7080', .07, 0); hilt(.46, .36, LEATHER, STEEL, STEEL, guard_shape='bar')
def W_dragonblade():
    sword_blade(2.0, .17, .34, dict(col='#f0c060', rough=.3, metal=.6)); inlay(.15, 1.45, .035, '#ff6a1a', .07)
    hilt(.48, .42, dict(col='#6a1a0a', rough=.7), dict(col='#b0301a', rough=.35, metal=.5), dict(col='#ff8a2a', rough=.2, glow=2.5), guard_shape='wing')
def W_abyssblade():
    slab([(.1, .05), (.2, .6), (.26, .7), (.18, .8), (.2, 1.35), (.28, 1.45), (.14, 1.6), (0, 2.05), (-.14, 1.6), (-.24, 1.5), (-.18, 1.3), (-.2, .75), (-.26, .62), (-.1, .05)], .1, dict(col='#3a2a5a', rough=.3, metal=.5))
    inlay(.15, 1.65, .04, '#b050ff', .1); hilt(.46, .4, dict(col='#1a0a2a', rough=.7), dict(col='#2a1a3a', rough=.35, metal=.5), dict(col='#c070ff', rough=.2, glow=3), guard_shape='claw')
def axe_head(pts, m, thick=.09): return slab(pts, thick, m, taper_edge=.25)
def W_axe():
    cyl((0, 0, -.28), (0, 0, 1.0), .05, .045, WOOD, 10); ball((0, 0, -.3), .06, BRONZE)
    axe_head([(0, .62), (-.2, .6), (-.46, .45), (-.52, .7), (-.46, .98), (-.2, .86), (0, .88)], BRONZE); box((0, 0, .75), (.12, .14, .3), BRONZE, .03)
def W_greataxe():
    cyl((0, 0, -.42), (0, 0, 1.55), .06, .055, DWOOD, 10); ball((0, 0, -.45), .07, IRON); cyl((0, 0, 1.55), (0, 0, 1.7), .05, .01, IRON, 8)
    for s in (-1, 1): axe_head([(0, 1.0), (s * .2, .98), (s * .55, .78), (s * .64, 1.15), (s * .55, 1.52), (s * .2, 1.34), (0, 1.36)], STEEL)
    box((0, 0, 1.18), (.16, .16, .42), IRON, .03)
def W_worldbreaker():
    cyl((0, 0, -.45), (0, 0, 1.6), .07, .065, dict(col='#3a2a22', rough=.7), 10); ball((0, 0, -.5), .09, dict(col='#ff6a1a', rough=.2, glow=2.5))
    for s in (-1, 1):
        axe_head([(0, .95), (s * .25, .92), (s * .7, .7), (s * .82, 1.18), (s * .7, 1.66), (s * .25, 1.42), (0, 1.45)], dict(col='#4a3226', rough=.4, metal=.5), .12)
        slab([(s * .3, 1.0), (s * .66, .86), (s * .7, 1.2), (s * .62, 1.5), (s * .3, 1.35)], .135, dict(col='#ff6a1a', rough=.3, glow=3.5), taper_edge=.9)
    box((0, 0, 1.2), (.2, .2, .5), dict(col='#2a1a14', rough=.4, metal=.4), .04); cyl((0, 0, 1.45), (0, 0, 1.8), .06, .01, dict(col='#4a3226', rough=.4, metal=.5), 8)
def W_dagger():
    slab([(.07, .03), (.08, .55), (0, .78), (-.08, .55), (-.07, .03)], .06, STEEL); hilt(.22, .15, LEATHER, STEEL, STEEL)
def W_abyssfang():
    slab([(.08, .03), (.1, .4), (.02, .7), (-.1, .86), (-.05, .5), (-.08, .03)], .07, dict(col='#4a3a6a', rough=.3, metal=.5)); inlay(.06, .45, .018, '#b050ff', .07)
    hilt(.22, .16, dict(col='#1a0a2a', rough=.7), DSTEEL, dict(col='#b050ff', rough=.2, glow=2.5), guard_shape='claw')
def W_wand():
    cyl((0, 0, -.25), (0, 0, .62), .035, .025, DWOOD, 8); cyl((0, 0, -.1), (0, 0, .02), .045, .045, GOLD, 10); ball((0, 0, .64), .05, GOLD); gem((0, 0, .72), .065, '#9a6aff')
def staff_shaft(top=1.25, m=WOOD, r=.05): cyl((0, 0, -.9), (0, 0, top), r, r * .85, m, 10); ball((0, 0, -.92), r * 1.1, IRON)
def W_staff():
    staff_shaft(); ball((0, 0, 1.3), .1, DWOOD); gem((0, 0, 1.42), .08, '#8ad0ff', 2)
def W_skullstaff():
    staff_shaft(1.1, BONE, .045)
    ball((0, 0, 1.28), .15, BONE, scale=(1, 1.05, .95)); box((0, -.09, 1.18), (.16, .08, .08), BONE, .03)
    for s in (-1, 1): ball((s * .055, -.12, 1.3), .038, dict(col='#1a0a14', rough=.4)); ball((s * .055, -.14, 1.3), .02, dict(col='#9aff9a', rough=.2, glow=3))
def W_crystalstaff():
    staff_shaft(1.15, dict(col='#6a4a7a', rough=.6))
    for k, (tx, ty) in enumerate([(0, 0), (22, 10), (-20, -8), (8, -25), (-6, 24)]):
        crystal((0, 0, 1.12), .085 - .01 * k, .5 - .06 * k, '#6ac8ff', 1.2, (tx, ty, 0))
    cyl((0, 0, 1.05), (0, 0, 1.15), .075, .075, dict(col='#c8d4f0', rough=.3, metal=.6), 12)
def W_emberstaff():
    staff_shaft(1.1, dict(col='#4a2a1a', rough=.6))
    for a in range(3):
        ang = a * 2.094; p = Vector((math.cos(ang) * .1, math.sin(ang) * .1, 1.1)); cyl(p, Vector((p.x * .5, p.y * .5, 1.42)), .02, .01, BRONZE, 6)
    ball((0, 0, 1.3), .1, dict(col='#ff7a2a', rough=.2, glow=5)); ball((0, 0, 1.3), .065, dict(col='#fff0a0', rough=.2, glow=6))
def W_dragonstaff():
    staff_shaft(1.1, dict(col='#b08030', rough=.35, metal=.6), .055)
    for a in range(4):
        ang = a * 1.571 + .4; p = Vector((math.cos(ang) * .06, math.sin(ang) * .06, 1.08)); tip = Vector((math.cos(ang) * .14, math.sin(ang) * .14, 1.45))
        cyl(p, tip, .025, .008, GOLD, 6)
    ball((0, 0, 1.3), .12, dict(col='#ffd257', rough=.15, glow=3)); ball((0, 0, 1.12), .08, GOLD)
def W_abyssstaff():
    staff_shaft(1.2, dict(col='#2a1a3a', rough=.4, metal=.4), .05)
    for a in range(5):
        ang = a * 1.2566; p = Vector((math.cos(ang) * .07, math.sin(ang) * .07, 1.15)); tip = Vector((math.cos(ang) * .2, math.sin(ang) * .2, 1.52))
        cyl(p, tip, .028, .005, dict(col='#3a2a4a', rough=.3, metal=.5), 6)
    ball((0, 0, 1.36), .11, dict(col='#b050ff', rough=.1, glow=5)); ball((0, 0, 1.36), .07, dict(col='#f0d0ff', rough=.1, glow=6))
def W_bough():
    pts = [(0, 0, -.9), (.04, 0, -.3), (-.03, 0, .3), (.05, 0, .8), (0, 0, 1.2)]
    for a, b in zip(pts, pts[1:]): cyl(a, b, .06, .05, dict(col='#6a4a2a', rough=.8), 8)
    for k, (dx, dz) in enumerate([(.25, 1.35), (-.22, 1.3), (.1, 1.5), (-.08, 1.45)]):
        cyl((0, 0, 1.15), (dx, 0, dz), .03, .012, dict(col='#6a4a2a', rough=.8), 6)
        ball((dx, 0, dz + .03), .09, dict(col='#5ad07a', rough=.6, glow=.6), scale=(1, .4, 1.4), rot=(0, (-1 if dx > 0 else 1) * 30, 0))
    ball((0, 0, 1.28), .07, dict(col='#b0ffb0', rough=.2, glow=4))
def W_eternity():
    cyl((0, 0, -.3), (0, 0, .75), .04, .035, dict(col='#f0f4ff', rough=.3, metal=.5), 10); ball((0, 0, -.32), .055, GOLD)
    for k in range(3): cyl((0, 0, .75 + k * .0), (0, 0, .8), .08, .08, GOLD, 12)
    for a in range(4):
        ang = a * 1.571; cyl((math.cos(ang) * .05, math.sin(ang) * .05, .8), (math.cos(ang) * .12, math.sin(ang) * .12, 1.05), .02, .01, GOLD, 6)
    crystal((0, 0, .82), .07, .38, '#6ae0ff', 3.5)
# monster weapons
def W_stick(): cyl((0, 0, -.5), (0, 0, 1.2), .045, .035, dict(col='#7a5a3a', rough=.8), 7); cyl((0, 0, .6), (.18, 0, .82), .025, .012, dict(col='#7a5a3a', rough=.8), 6)
def W_club():
    cyl((0, 0, -.3), (0, 0, .9), .05, .12, dict(col='#6a4a2a', rough=.8), 9); ball((0, 0, .95), .13, dict(col='#6a4a2a', rough=.8))
    for a in range(5): ang = a * 1.2566; cyl((math.cos(ang) * .1, math.sin(ang) * .1, .8), (math.cos(ang) * .2, math.sin(ang) * .2, .82), .025, .004, IRON, 5)
def W_hook():
    cyl((0, 0, -.3), (0, 0, .45), .04, .035, DWOOD, 8)
    slab([(.03, .4), (.05, .8), (-.12, 1.02), (-.3, .95), (-.18, .9), (-.05, .78), (-.03, .4)], .06, IRON)

BUILDERS = {k[2:]: v for k, v in globals().items() if k.startswith('W_')}

def build(key):
    global PARTS, MATS; PARTS = []; MATS = {}
    bpy.ops.wm.read_factory_settings(use_empty=True)
    BUILDERS[key]()
    # apply modifiers and join into one object named after the weapon
    dg = bpy.context.evaluated_depsgraph_get()
    for o in PARTS:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.ops.object.select_all(action='DESELECT')
    for o in PARTS: o.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]; bpy.ops.object.join()
    w = bpy.context.object; w.name = 'wpn_' + key
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(42))   # round parts smooth, blade edges crisp
    path = os.path.join(OUT, key + '.blend'); bpy.ops.wm.save_as_mainfile(filepath=path)
    zs = [v.co.z for v in w.data.vertices]; print('saved', path, 'length %.2f' % (max(zs) - min(zs)))

if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    for k in (argv or list(BUILDERS)): build(k)
