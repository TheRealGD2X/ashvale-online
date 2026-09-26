"""
Landmark buildings the village kit has no pieces for, built low-poly in the same chunky style and
exported straight to Godot (godot/assets/buildings/<name>.glb):

    windmill   the Mill's stone tower with a timber cap; its sails are a separate node "Sails"
               (spin it about its local Z in the game)
    granary    a timber store on staddle stones with a thatched roof and a cellar hatch
    shrine     the Old Shrine: a round stone floor, broken pillars, an altar and a weathered statue
    well       a stone well with a little roof and a bucket
    haybale    a round bale

    python3 art/buildings.py            # all
    python3 art/buildings.py windmill   # one

Blender is Z-up with the front facing -Y; the glTF exporter turns that into Godot's +Z front.
"""
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, Matrix, Euler

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'godot', 'assets', 'buildings'); os.makedirs(OUT, exist_ok=True)

def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
MATS = {}
def mat(col, rough=0.85, metal=0.0):
    key = (col, rough, metal)
    if key in MATS: return MATS[key]
    m = bpy.data.materials.new('m_' + col.lstrip('#')); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    h = col.lstrip('#'); r, g, bl = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    b.inputs['Base Color'].default_value = (lin(r), lin(g), lin(bl), 1)
    b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metal
    MATS[key] = m; return m

STONE = '#9d968b'; STONE2 = '#857e74'; DSTONE = '#6c665e'; MOSS = '#6f8a45'
WOOD = '#8a5a32'; DWOOD = '#5a3a22'; PLANK = '#a2754a'; THATCH = '#c7a45e'; THATCH2 = '#a9853f'
CANVAS = '#eae0c6'; SHINGLE = '#7b4a30'; IRON = '#4a4a50'

def _fin(o, col, bevel=0.0, seg=1, rough=0.85, smooth=False):
    if bevel:
        m = o.modifiers.new('bevel', 'BEVEL'); m.width = bevel; m.segments = seg; m.limit_method = 'ANGLE'; m.angle_limit = math.radians(35)
    o.data.materials.append(mat(col, rough))
    for p in o.data.polygons: p.use_smooth = smooth
    return o

def box(size, loc, col, rot=(0, 0, 0), bevel=0.03, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc); o = bpy.context.object
    o.data.transform(Matrix.Diagonal((size[0], size[1], size[2], 1)))
    o.rotation_euler = Euler([math.radians(a) for a in rot])
    if parent: o.parent = parent
    return _fin(o, col, bevel)

def cyl(r1, r2, h, loc, col, verts=8, rot=(0, 0, 0), bevel=0.0, smooth=False, parent=None):
    bpy.ops.mesh.primitive_cone_add(radius1=r1, radius2=r2, depth=h, vertices=verts, location=loc); o = bpy.context.object
    o.rotation_euler = Euler([math.radians(a) for a in rot])
    if parent: o.parent = parent
    return _fin(o, col, bevel, smooth=smooth)

def ball(r, loc, col, scale=(1, 1, 1), sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, subdivisions=sub, location=loc); o = bpy.context.object
    o.data.transform(Matrix.Diagonal((*scale, 1)))
    return _fin(o, col, smooth=True)

def jitter(o, amt, seed=1):
    """rough stone: nudge every vertex a little"""
    rnd = random.Random(seed)
    for v in o.data.vertices: v.co += Vector((rnd.uniform(-amt, amt), rnd.uniform(-amt, amt), rnd.uniform(-amt, amt)))

def reset():
    global MATS; MATS = {}
    bpy.ops.wm.read_factory_settings(use_empty=True)

def export(name):
    path = os.path.join(OUT, name + '.glb')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', export_apply=True, export_animations=False)
    print('exported', path)

# ---------------------------------------------------------------- the windmill
def windmill():
    reset()
    H = 9.0
    # the tower: an eight-sided stone cone, courses of darker stone, a timber band under the cap
    t = cyl(3.3, 2.5, H, (0, 0, H / 2), STONE, verts=8); jitter(t, 0.05, 3)
    for z in (1.6, 4.2, 6.8):
        r = 3.3 - (3.3 - 2.5) * z / H + 0.04
        cyl(r, r - 0.02, 0.28, (0, 0, z), STONE2, verts=8)
    cyl(3.45, 3.45, 0.6, (0, 0, 0.3), DSTONE, verts=8)            # plinth
    cyl(2.62, 2.62, 0.35, (0, 0, H - 0.1), DWOOD, verts=8)          # gallery beam
    # door and windows (front = -Y)
    box((1.3, 0.3, 2.2), (0, -3.18, 1.2), DWOOD, bevel=0.05)
    box((1.55, 0.25, 0.25), (0, -3.25, 2.4), WOOD)
    box((0.3, 0.35, 0.3), (0.45, -3.3, 1.2), IRON)                   # latch
    for z, ang in ((4.5, 30), (6.3, -40), (5.4, 150)):
        a = math.radians(ang - 90); r = 3.3 - 0.8 * z / H
        box((0.55, 0.3, 0.8), (math.cos(a) * r, math.sin(a) * r, z), DWOOD, rot=(0, 0, ang))
    # the cap: a timber boat-shaped roof of shingles, turned to face the wind (front)
    cap = cyl(2.9, 0.4, 2.6, (0, 0.2, H + 1.25), SHINGLE, verts=8, rot=(0, 0, 22.5))
    cap.scale = (1.0, 1.25, 1.0)
    cyl(0.45, 0.1, 0.8, (0, 0.2, H + 2.8), DWOOD, verts=6)
    # the windshaft sticking out the front
    cyl(0.28, 0.28, 2.0, (0, -2.6, H + 0.9), DWOOD, verts=8, rot=(90, 0, 0))
    # the sails: a separate object with its origin on the shaft, so the game can spin it
    bpy.ops.object.empty_add(location=(0, -3.55, H + 0.9)); piv = bpy.context.object; piv.name = 'Sails'
    hub = cyl(0.42, 0.42, 0.5, (0, 0, 0), DWOOD, verts=8, rot=(90, 0, 0), parent=piv)
    for k in range(4):
        a = k * math.pi / 2 + math.radians(15)
        arm = Vector((math.cos(a), 0, math.sin(a)))
        side = Vector((-math.sin(a), 0, math.cos(a)))
        L = 6.2
        # the stock (main spar)
        b = box((0.18, 0.16, L), (0, 0, 0), WOOD); b.parent = piv
        b.location = arm * (L / 2 + 0.3); b.rotation_euler = Euler((0, -a + math.pi / 2, 0))
        # a lattice frame with canvas on one side
        w = 1.35
        c = box((w, 0.05, L - 1.2), (0, 0, 0), CANVAS, bevel=0.0); c.parent = piv
        c.location = arm * (L / 2 + 0.9) + side * (w / 2 + 0.08) + Vector((0, -0.05, 0)); c.rotation_euler = Euler((0, -a + math.pi / 2, 0))
        for j in range(6):
            s = box((w + 0.1, 0.1, 0.07), (0, 0, 0), WOOD, bevel=0.0); s.parent = piv
            s.location = arm * (1.3 + j * (L - 1.6) / 5.0) + side * (w / 2 + 0.08) + Vector((0, -0.1, 0)); s.rotation_euler = Euler((0, -a + math.pi / 2, 0))
        e = box((0.07, 0.1, L - 1.1), (0, 0, 0), WOOD, bevel=0.0); e.parent = piv
        e.location = arm * (L / 2 + 0.85) + side * (w + 0.12) + Vector((0, -0.1, 0)); e.rotation_euler = Euler((0, -a + math.pi / 2, 0))
    # a few sacks and a cart wheel against the wall
    for i, (x, y) in enumerate(((1.4, -3.3), (1.9, -3.0), (-1.5, -3.2))):
        ball(0.42, (x, y, 0.42), '#c9b58a', scale=(1, 0.85, 1.1), sub=2)
    w2 = cyl(0.7, 0.7, 0.14, (-2.2, -2.6, 0.72), DWOOD, verts=12, rot=(0, 75, 30))
    export('windmill')

# ---------------------------------------------------------------- the granary
def granary():
    reset()
    W, D, H = 6.0, 4.4, 2.6
    # staddle stones: mushroom-shaped, to keep rats out (they didn't)
    for x in (-2.5, 0, 2.5):
        for y in (-1.8, 1.8):
            cyl(0.3, 0.18, 0.7, (x, y, 0.35), STONE, verts=7)
            cyl(0.45, 0.45, 0.14, (x, y, 0.75), STONE2, verts=8)
    # the floor frame and plank walls
    box((W + 0.3, D + 0.3, 0.25), (0, 0, 0.95), DWOOD)
    b = box((W, D, H), (0, 0, 0.95 + H / 2 + 0.1), PLANK, bevel=0.02)
    for x in (-W / 2, -W / 6, W / 6, W / 2):
        box((0.22, D + 0.1, H + 0.1), (x, 0, 0.95 + H / 2 + 0.1), DWOOD)
    for y in (-D / 2, D / 2):
        box((W + 0.1, 0.22, 0.22), (0, y, 0.95 + H + 0.05), DWOOD)
    # door with steps
    box((1.2, 0.2, 1.9), (0, -D / 2 - 0.06, 1.1 + 0.95), DWOOD)
    for i in range(3):
        box((1.3, 0.45, 0.2), (0, -D / 2 - 0.45 - i * 0.4, 0.8 - i * 0.28), WOOD)
    # thatched roof
    me = bpy.data.meshes.new('roof'); o = bpy.data.objects.new('roof', me); bpy.context.scene.collection.objects.link(o)
    bm = bmesh.new(); z0 = 0.95 + H + 0.1; ov = 0.6
    v = [bm.verts.new(p) for p in [(-W / 2 - ov, -D / 2 - ov, z0 - 0.3), (W / 2 + ov, -D / 2 - ov, z0 - 0.3), (W / 2 + ov, D / 2 + ov, z0 - 0.3),
                                   (-W / 2 - ov, D / 2 + ov, z0 - 0.3), (-W / 2 + 0.4, 0, z0 + 2.2), (W / 2 - 0.4, 0, z0 + 2.2)]]
    for f in ((0, 1, 5, 4), (2, 3, 4, 5), (1, 2, 5), (3, 0, 4), (0, 3, 2, 1)): bm.faces.new([v[i] for i in f])
    bm.to_mesh(me); bm.free()
    sol = o.modifiers.new('s', 'SOLIDIFY'); sol.thickness = 0.35
    _fin(o, THATCH)
    box((W - 0.4, 0.4, 0.3), (0, 0, z0 + 2.25), THATCH2)
    # the cellar hatch at the side, half open
    box((1.3, 1.0, 0.12), (W / 2 + 1.2, 0.8, 0.08), DWOOD)
    box((1.3, 0.12, 1.0), (W / 2 + 1.2, 0.3, 0.55), WOOD, rot=(-25, 0, 0))
    # sacks of grain
    for x, y in ((-W / 2 - 0.8, -1.0), (-W / 2 - 0.9, -0.1), (-W / 2 - 0.5, -0.6)):
        ball(0.45, (x, y, 0.42), '#d6c291', scale=(1, 0.85, 1.05))
    export('granary')

# ---------------------------------------------------------------- the old shrine
def shrine():
    reset()
    rnd = random.Random(7)
    # a round stone floor with two steps
    s1 = cyl(7.2, 7.2, 0.4, (0, 0, 0.2), DSTONE, verts=24); jitter(s1, 0.04, 1)
    s2 = cyl(6.2, 6.2, 0.35, (0, 0, 0.55), STONE2, verts=24); jitter(s2, 0.03, 2)
    # a ring of pillars, most of them broken
    for k in range(8):
        a = k * math.tau / 8 + 0.2
        x, y = math.cos(a) * 5.2, math.sin(a) * 5.2
        h = [4.6, 1.4, 3.2, 0.9, 4.6, 2.1, 1.1, 3.8][k]
        p = cyl(0.42, 0.38, h, (x, y, 0.72 + h / 2), STONE, verts=8); jitter(p, 0.03, k)
        cyl(0.55, 0.55, 0.3, (x, y, 0.85), STONE2, verts=8)
        if h > 4.0: cyl(0.52, 0.6, 0.35, (x, y, 0.72 + h + 0.15), STONE2, verts=8)
        if rnd.random() < 0.5: ball(0.3, (x + 0.3, y + 0.1, 0.72 + h * 0.4), MOSS, scale=(1.3, 1.0, 0.5))
    # a fallen pillar across the floor
    f = cyl(0.4, 0.38, 3.6, (2.0, 2.4, 1.05), STONE, verts=8, rot=(0, 90, 38)); jitter(f, 0.03, 9)
    # a lintel still sitting on the two tall pillars at the back
    a0, a4 = 0.2, 0.2 + math.pi
    # the altar
    box((2.2, 1.2, 1.0), (0, 1.6, 1.22), STONE, bevel=0.06)
    box((2.5, 1.45, 0.2), (0, 1.6, 1.8), STONE2, bevel=0.04)
    ball(0.18, (-0.7, 1.4, 2.0), '#e8d9b0'); ball(0.14, (0.6, 1.7, 1.98), '#e8d9b0')    # candle stubs
    # the statue: a robed figure holding an ember bowl, weathered
    base = box((1.2, 1.2, 1.0), (0, 3.2, 1.2), STONE2, bevel=0.05)
    robe = cyl(0.62, 0.3, 2.3, (0, 3.2, 2.85), STONE, verts=10, smooth=True)
    ball(0.32, (0, 3.2, 4.25), STONE, scale=(1, 1, 1.1))
    cyl(0.35, 0.1, 0.55, (0, 3.18, 4.5), STONE, verts=10)             # hood point
    for sx in (-1, 1):
        cyl(0.13, 0.11, 0.9, (sx * 0.38, 2.95, 3.45), STONE, verts=6, rot=(60, 0, -sx * 20))
    cyl(0.38, 0.22, 0.25, (0, 2.62, 3.75), STONE2, verts=10)           # bowl
    ball(0.5, (0.2, 3.4, 2.1), MOSS, scale=(1.2, 1.0, 0.6))
    # rubble
    for i in range(14):
        a = rnd.uniform(0, math.tau); r = rnd.uniform(3.0, 7.6)
        o = ball(rnd.uniform(0.15, 0.4), (math.cos(a) * r, math.sin(a) * r, 0.7 if r < 6.1 else 0.3), STONE2 if i % 3 else DSTONE, sub=1)
        jitter(o, 0.05, i)
    export('shrine')

# ---------------------------------------------------------------- the well
def well():
    reset()
    w = cyl(1.0, 1.0, 0.9, (0, 0, 0.45), STONE, verts=12); jitter(w, 0.03, 4)
    cyl(1.08, 1.08, 0.16, (0, 0, 0.95), STONE2, verts=12)
    cyl(0.8, 0.8, 0.1, (0, 0, 0.7), '#2a3a48', verts=12)
    for x in (-0.95, 0.95): box((0.16, 0.16, 2.0), (x, 0, 1.9), DWOOD)
    box((2.3, 0.18, 0.18), (0, 0, 2.7), WOOD)
    cyl(0.12, 0.12, 1.7, (0, 0, 2.2), DWOOD, verts=8, rot=(0, 90, 0))
    # roof
    for sy in (-1, 1): box((2.5, 1.0, 0.12), (0, sy * 0.4, 3.05), SHINGLE, rot=(sy * 32, 0, 0))
    box((0.4, 0.3, 0.4), (0.2, 0, 1.25), WOOD)                           # bucket
    export('well')

def haybale():
    reset()
    b = cyl(0.75, 0.75, 1.1, (0, 0, 0.75), THATCH, verts=14, rot=(90, 0, 0), smooth=True)
    for y in (-0.3, 0.3): cyl(0.77, 0.77, 0.06, (0, y, 0.75), THATCH2, verts=14, rot=(90, 0, 0))
    export('haybale')

def pickaxe():
    """a miner's pick, held like a weapon: grip at the origin, handle up +Z, head across X"""
    reset()
    cyl(0.035, 0.03, 0.95, (0, 0, 0.3), '#7a5230', verts=8)
    head = box((0.62, 0.07, 0.08), (0.05, 0, 0.78), '#6e7078', bevel=0.02)
    cone_l = cyl(0.045, 0.005, 0.22, (-0.36, 0, 0.74), '#8a8c94', verts=6, rot=(0, -100, 0))
    cone_r = cyl(0.045, 0.02, 0.16, (0.43, 0, 0.77), '#8a8c94', verts=6, rot=(0, 95, 0))
    box((0.09, 0.09, 0.12), (0, 0, 0.78), '#4a3a2a', bevel=0.01)
    path = os.path.join(ROOT, 'godot', 'assets', 'weapons', 'pickaxe.glb')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', export_apply=True, export_animations=False)
    print('exported', path)

def cart():
    """an ore cart on rails"""
    reset()
    for x in (-0.55, 0.55):
        for y in (-0.7, 0.7): cyl(0.22, 0.22, 0.08, (x + (0.06 if x > 0 else -0.06), y, 0.22), '#3c3c42', verts=12, rot=(0, 90, 0))
    box((1.1, 1.7, 0.7), (0, 0, 0.72), '#6a4a2e', bevel=0.04)
    for z in (0.42, 1.02): box((1.16, 1.76, 0.08), (0, 0, z), '#4a4a50')
    box((0.9, 1.5, 0.2), (0, 0, 1.02), '#2e2a2a')                        # ore heaped inside
    for i in range(6): ball(0.16, (random.uniform(-0.35, 0.35), random.uniform(-0.6, 0.6), 1.12), '#3a3638', sub=1)
    export('cart')

def tent():
    """a canvas tent, open at the front"""
    reset()
    me = bpy.data.meshes.new('tent'); o = bpy.data.objects.new('tent', me); bpy.context.scene.collection.objects.link(o)
    bm = bmesh.new(); W, D, H = 1.6, 2.2, 2.0
    v = [bm.verts.new(p) for p in [(-W, -D, 0), (W, -D, 0), (W, D, 0), (-W, D, 0), (0, -D - 0.1, H), (0, D + 0.1, H)]]
    for f in ((0, 3, 5, 4), (1, 4, 5, 2), (3, 2, 5)): bm.faces.new([v[i] for i in f])
    bm.to_mesh(me); bm.free()
    s = o.modifiers.new('s', 'SOLIDIFY'); s.thickness = 0.05
    _fin(o, '#d8cba8')
    cyl(0.05, 0.05, H + 0.3, (0, -D - 0.1, (H + 0.3) / 2), '#6a4a2e', verts=6)
    cyl(0.05, 0.05, H + 0.3, (0, D + 0.1, (H + 0.3) / 2), '#6a4a2e', verts=6)
    box((1.4, 1.8, 0.25), (0.6, 0.6, 0.14), '#7a6a58')                     # bedroll
    export('tent')

def gantry():
    """the timber gantry over the mine mouth: two frames, a beam and a lantern"""
    reset()
    for x in (-2.4, 2.4):
        box((0.35, 0.35, 4.6), (x, 0, 2.3), '#5a3a22')
        box((0.3, 0.3, 3.2), (x, 1.1, 1.6), '#5a3a22', rot=(20, 0, 0))
    box((5.6, 0.4, 0.45), (0, 0, 4.5), '#6a4a2e')
    box((5.2, 0.3, 0.3), (0, 0, 3.9), '#5a3a22')
    box((1.8, 0.1, 0.6), (0, -0.25, 4.95), '#8a6a40')                       # a sign board
    cyl(0.12, 0.12, 0.3, (1.6, -0.3, 3.5), '#e8b060', verts=8)
    # rails running in
    for x in (-0.55, 0.55): box((0.08, 8.0, 0.08), (x, 2.0, 0.05), '#4a4a50')
    for i in range(10): box((1.5, 0.18, 0.08), (0, -1.5 + i * 0.8, 0.02), '#5a3a22')
    export('gantry')

def gravestone():
    reset()
    box((0.7, 0.18, 0.9), (0, 0, 0.45), '#8a8680', bevel=0.05)
    cyl(0.35, 0.35, 0.18, (0, 0, 0.9), '#8a8680', verts=12, rot=(90, 0, 0))
    box((0.9, 1.6, 0.12), (0, 0.9, 0.04), '#5a5048')                        # the mound
    export('gravestone')

BUILD = {'windmill': windmill, 'granary': granary, 'shrine': shrine, 'well': well, 'haybale': haybale,
         'pickaxe': pickaxe, 'cart': cart, 'tent': tent, 'gantry': gantry, 'gravestone': gravestone}

if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    for n in (argv or list(BUILD)): BUILD[n]()
