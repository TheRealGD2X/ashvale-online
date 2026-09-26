"""
Item icon models for Ashvale Online, built and lit in Blender (Cycles), one per icon key
(see godot/src/ui/item_icon.gd key_of, and art/item_keys.txt for the full list).

    python3 art/item_models.py                 # every key in art/item_keys.txt
    python3 art/item_models.py w_ m_ore_1      # keys starting with these
Writes art/_items/<key>.png (transparent, lit object). art/item_paint.py then paints the
backdrop, shadow and glow and writes the game's icons (godot/assets/icons/items/<key>.png).
"""
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, Euler, Matrix, noise as mnoise
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import icons as I

ROOT = I.ROOT
SPR = os.path.join(ROOT, 'art', '_items'); os.makedirs(SPR, exist_ok=True)
CHARS = os.path.join(ROOT, 'godot', 'assets', 'licensed', 'chars')
RES = 320
rgb = I.rgb

# ================================================================== stage

def stage(samples=48):
    I.reset()
    sc = bpy.context.scene; sc.render.film_transparent = True
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and o.name.startswith('Plane'): bpy.data.objects.remove(o)
    sc.use_nodes = False
    sc.render.resolution_x = sc.render.resolution_y = RES
    sc.cycles.samples = samples
    sc.view_settings.look = 'AgX - Medium High Contrast'
    # a studio "room" for metal and glass to reflect: bright softbox overhead, warm floor bounce, dark sides
    nt = sc.world.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputWorld'); bg = nt.nodes.new('ShaderNodeBackground')
    tc = nt.nodes.new('ShaderNodeTexCoord'); sep = nt.nodes.new('ShaderNodeSeparateXYZ')
    nt.links.new(tc.outputs['Generated'], sep.inputs[0])
    r = nt.nodes.new('ShaderNodeValToRGB'); cr = r.color_ramp
    cr.elements[0].position = 0.0; cr.elements[0].color = (*rgb('#3a3028'), 1)
    cr.elements[1].position = 1.0; cr.elements[1].color = (*rgb('#f4f0ea'), 1)
    e = cr.elements.new(0.45); e.color = (*rgb('#141418'), 1)
    e = cr.elements.new(0.62); e.color = (*rgb('#2a2c34'), 1)
    e = cr.elements.new(0.8); e.color = (*rgb('#b8b8c0'), 1)
    # Generated coords for the world run -1..1 along the view direction; map z to 0..1
    mp = nt.nodes.new('ShaderNodeMapRange'); mp.inputs['From Min'].default_value = -1.0; mp.inputs['From Max'].default_value = 1.0
    nt.links.new(sep.outputs['Z'], mp.inputs['Value']); nt.links.new(mp.outputs['Result'], r.inputs[0])
    nt.links.new(r.outputs['Color'], bg.inputs['Color']); bg.inputs['Strength'].default_value = 0.8
    nt.links.new(bg.outputs[0], out.inputs[0])
    return sc

def shoot(key, rot=(0, 0, 0), fill=0.86, keyc='#fff1dc', rim='#9fc0ff', key_e=260, rim_e=380, objs=None):
    objs = objs or [o for o in bpy.data.objects if o.type == 'MESH']
    I.frame_objects(objs, fill, rot)
    I.studio(keyc, rim, key_e, rim_e)
    sc = bpy.context.scene
    sc.render.filepath = os.path.join(SPR, key + '.png')
    bpy.ops.render.render(write_still=True)
    print('item', key, flush=True)

# ================================================================== materials

def _nodes(name):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes['Principled BSDF']
    return m, nt, b

def _tex_coord(nt):
    return nt.nodes.new('ShaderNodeTexCoord').outputs['Object']

def _noise(nt, scale=6.0, detail=6.0, rough=0.55, dist=0.0, vec=None):
    n = nt.nodes.new('ShaderNodeTexNoise'); n.inputs['Scale'].default_value = scale
    n.inputs['Detail'].default_value = detail; n.inputs['Roughness'].default_value = rough; n.inputs['Distortion'].default_value = dist
    nt.links.new(vec or _tex_coord(nt), n.inputs['Vector'])
    return n

def _ramp(nt, fac, stops):
    r = nt.nodes.new('ShaderNodeValToRGB'); cr = r.color_ramp
    cr.elements[0].position = stops[0][0]; cr.elements[0].color = (*rgb(stops[0][1]), 1)
    cr.elements[1].position = stops[-1][0]; cr.elements[1].color = (*rgb(stops[-1][1]), 1)
    for p, c in stops[1:-1]:
        e = cr.elements.new(p); e.color = (*rgb(c), 1)
    nt.links.new(fac, r.inputs[0])
    return r

def _bump(nt, b, height, strength=0.3, dist=0.02):
    bm = nt.nodes.new('ShaderNodeBump'); bm.inputs['Strength'].default_value = strength; bm.inputs['Distance'].default_value = dist
    nt.links.new(height, bm.inputs['Height']); nt.links.new(bm.outputs['Normal'], b.inputs['Normal'])
    return bm

def metal(col, rough=0.3, var=0.25, scratches=0.15, name='metal', dark=None):
    """metal with a little tarnish in the crevices and fine brushed scratches"""
    m, nt, b = _nodes(name)
    n = _noise(nt, 7.0, 8.0, 0.6)
    dk = dark or _shade(col, 0.45)
    r = _ramp(nt, n.outputs['Fac'], [(0.3, dk), (0.6, col), (1.0, _shade(col, 1.15))])
    nt.links.new(r.outputs['Color'], b.inputs['Base Color'])
    b.inputs['Metallic'].default_value = 1.0
    rr = nt.nodes.new('ShaderNodeMapRange'); rr.inputs['To Min'].default_value = rough * (1 - var); rr.inputs['To Max'].default_value = rough * (1 + var)
    nt.links.new(n.outputs['Fac'], rr.inputs['Value']); nt.links.new(rr.outputs['Result'], b.inputs['Roughness'])
    if scratches:
        s = _noise(nt, 40.0, 2.0, 0.5)
        mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (1.0, 1.0, 30.0)
        nt.links.new(_tex_coord(nt), mp.inputs[0]); nt.links.new(mp.outputs[0], s.inputs['Vector'])
        _bump(nt, b, s.outputs['Fac'], scratches, 0.005)
    return m

def gem(col, glow=0.6, rough=0.02, name='gem'):
    """cut stone: clear, coloured, a little inner light so it sparkles on the dark tiles"""
    m, nt, b = _nodes(name)
    b.inputs['Base Color'].default_value = (*rgb(col), 1)
    b.inputs['Transmission Weight'].default_value = 1.0; b.inputs['IOR'].default_value = 1.75
    b.inputs['Roughness'].default_value = rough
    b.inputs['Emission Color'].default_value = (*rgb(col), 1); b.inputs['Emission Strength'].default_value = glow
    b.inputs['Coat Weight'].default_value = 0.5
    return m

def glass(col='#dfe8ee', rough=0.03, name='glass', tint_k=1.0):
    m, nt, b = _nodes(name)
    b.inputs['Base Color'].default_value = (*rgb(col), 1)
    b.inputs['Transmission Weight'].default_value = 1.0; b.inputs['IOR'].default_value = 1.45
    b.inputs['Roughness'].default_value = rough
    return m

def liquid(col, glow=0.8, name='liquid'):
    m, nt, b = _nodes(name)
    b.inputs['Base Color'].default_value = (*rgb(col), 1)
    b.inputs['Transmission Weight'].default_value = 0.85; b.inputs['IOR'].default_value = 1.33
    b.inputs['Roughness'].default_value = 0.05
    b.inputs['Subsurface Weight'].default_value = 0.3
    b.inputs['Emission Color'].default_value = (*rgb(col), 1); b.inputs['Emission Strength'].default_value = glow
    return m

def _shade(h, k):
    c = rgb(h)
    c = [min(1.0, v * k) for v in c]
    # back to hex (in sRGB)
    def s(v): return v * 12.92 if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055
    return '#%02x%02x%02x' % tuple(int(max(0, min(1, s(v))) * 255) for v in c)

def rough_mat(col, rough=0.6, var=0.35, bumpk=0.25, scale=8.0, name='rough', col2=None, sheen=0.0, sss=0.0, bscale=None, coat=0.0):
    """general surface: colour variation, roughness, a noise bump (stone, wood, leather, bone...)"""
    m, nt, b = _nodes(name)
    n = _noise(nt, scale, 8.0, 0.6)
    c2 = col2 or _shade(col, 0.55)
    r = _ramp(nt, n.outputs['Fac'], [(0.25, c2), (0.55, col), (0.85, _shade(col, 1.2))])
    nt.links.new(r.outputs['Color'], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = rough
    if sheen: b.inputs['Sheen Weight'].default_value = sheen
    if sss:
        b.inputs['Subsurface Weight'].default_value = sss; b.inputs['Subsurface Radius'].default_value = (1.0, 0.4, 0.25)
    if coat: b.inputs['Coat Weight'].default_value = coat
    if bumpk:
        n2 = _noise(nt, bscale or scale * 3, 10.0, 0.65)
        _bump(nt, b, n2.outputs['Fac'], bumpk, 0.02)
    return m

def cloth(col, col2=None, weave=60.0, stripes=None, name='cloth', sheen=0.6, trim=None):
    """woven cloth: fine weave bump, soft sheen, colour mottling; optional stripes"""
    m, nt, b = _nodes(name)
    n = _noise(nt, 5.0, 6.0, 0.5)
    c2 = col2 or _shade(col, 0.6)
    r = _ramp(nt, n.outputs['Fac'], [(0.3, c2), (0.7, col)])
    base = r.outputs['Color']
    if stripes:
        w = nt.nodes.new('ShaderNodeTexWave'); w.inputs['Scale'].default_value = stripes[0]; w.wave_profile = 'SAW'
        nt.links.new(_tex_coord(nt), w.inputs['Vector'])
        st = nt.nodes.new('ShaderNodeMath'); st.operation = 'GREATER_THAN'; st.inputs[1].default_value = 0.8
        nt.links.new(w.outputs['Fac'], st.inputs[0])
        mx = nt.nodes.new('ShaderNodeMixRGB'); mx.inputs[2].default_value = (*rgb(stripes[1]), 1)
        nt.links.new(st.outputs[0], mx.inputs[0]); nt.links.new(base, mx.inputs[1]); base = mx.outputs[0]
    nt.links.new(base, b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.85; b.inputs['Sheen Weight'].default_value = sheen
    b.inputs['Sheen Tint'].default_value = (*rgb(_shade(col, 1.6)), 1)
    wv = nt.nodes.new('ShaderNodeTexWave'); wv.inputs['Scale'].default_value = weave; wv.wave_type = 'BANDS'; wv.bands_direction = 'DIAGONAL'
    nt.links.new(_tex_coord(nt), wv.inputs['Vector'])
    _bump(nt, b, wv.outputs['Fac'], 0.12, 0.01)
    return m

def fur(col, col2=None, k=0.8, name='fur'):
    """fur/wool: strand-like streaky bump, sheen, soft colour breakup"""
    m, nt, b = _nodes(name)
    tc = _tex_coord(nt)
    mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (1.0, 1.0, 8.0)
    nt.links.new(tc, mp.inputs[0])
    n = _noise(nt, 30.0, 12.0, 0.7, 2.0, mp.outputs[0])
    n2 = _noise(nt, 4.0, 4.0, 0.5)
    r = _ramp(nt, n2.outputs['Fac'], [(0.25, col2 or _shade(col, 0.5)), (0.75, col)])
    st = nt.nodes.new('ShaderNodeMixRGB'); st.blend_type = 'MULTIPLY'; st.inputs[0].default_value = 0.6
    sr = _ramp(nt, n.outputs['Fac'], [(0.2, '#707070'), (0.8, '#ffffff')])
    nt.links.new(r.outputs['Color'], st.inputs[1]); nt.links.new(sr.outputs['Color'], st.inputs[2])
    nt.links.new(st.outputs[0], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.95; b.inputs['Sheen Weight'].default_value = 1.0
    b.inputs['Sheen Tint'].default_value = (*rgb(_shade(col, 1.5)), 1)
    _bump(nt, b, n.outputs['Fac'], k, 0.04)
    return m

def wood(col='#7a4e2a', col2=None, rings=6.0, name='wood', rough=0.6):
    m, nt, b = _nodes(name)
    tc = _tex_coord(nt)
    mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (1.0, 1.0, 0.12)
    nt.links.new(tc, mp.inputs[0])
    w = nt.nodes.new('ShaderNodeTexWave'); w.wave_type = 'RINGS'; w.inputs['Scale'].default_value = rings
    w.inputs['Distortion'].default_value = 6.0; w.inputs['Detail'].default_value = 4.0
    nt.links.new(mp.outputs[0], w.inputs['Vector'])
    r = _ramp(nt, w.outputs['Fac'], [(0.0, col2 or _shade(col, 0.55)), (0.6, col), (1.0, _shade(col, 1.2))])
    nt.links.new(r.outputs['Color'], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = rough
    _bump(nt, b, w.outputs['Fac'], 0.15, 0.01)
    return m

def emit(col, s=6.0, name='emit'):
    return I.mat_emit(name, col, s)

def glow_mat(col, s=6.0, base='#202020', name='glowm'):
    """a surface lit from inside along noise veins (embers in coal, runes in stone)"""
    m, nt, b = _nodes(name)
    b.inputs['Base Color'].default_value = (*rgb(base), 1); b.inputs['Roughness'].default_value = 0.7
    v = nt.nodes.new('ShaderNodeTexVoronoi'); v.feature = 'DISTANCE_TO_EDGE'; v.inputs['Scale'].default_value = 5.0
    nt.links.new(_tex_coord(nt), v.inputs['Vector'])
    r = _ramp(nt, v.outputs['Distance'], [(0.0, '#ffffff'), (0.06, '#000000')])
    mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; mul.inputs[1].default_value = s
    nt.links.new(r.outputs['Color'], mul.inputs[0])
    b.inputs['Emission Color'].default_value = (*rgb(col), 1)
    nt.links.new(mul.outputs[0], b.inputs['Emission Strength'])
    return m

def veined(base, vein, glow=0.0, scale=4.0, width=0.05, metal_vein=True, rough=0.75, name='veined', bumpk=0.5):
    """rock with veins of something else (ore in stone, fire in slag, void in crystal)"""
    m, nt, b = _nodes(name)
    tc = _tex_coord(nt)
    wn = _noise(nt, 3.0, 4.0, 0.5, 0.0, tc)
    add = nt.nodes.new('ShaderNodeVectorMath'); add.operation = 'ADD'
    sc = nt.nodes.new('ShaderNodeVectorMath'); sc.operation = 'SCALE'; sc.inputs['Scale'].default_value = 0.4
    nt.links.new(wn.outputs['Color'], sc.inputs[0]); nt.links.new(tc, add.inputs[0]); nt.links.new(sc.outputs[0], add.inputs[1])
    v = nt.nodes.new('ShaderNodeTexVoronoi'); v.feature = 'DISTANCE_TO_EDGE'; v.inputs['Scale'].default_value = scale
    nt.links.new(add.outputs[0], v.inputs['Vector'])
    mask = _ramp(nt, v.outputs['Distance'], [(0.0, '#ffffff'), (width, '#000000')])
    rn = _noise(nt, 9.0, 8.0, 0.6)
    stone = _ramp(nt, rn.outputs['Fac'], [(0.3, _shade(base, 0.5)), (0.6, base), (0.9, _shade(base, 1.3))])
    mx = nt.nodes.new('ShaderNodeMixRGB'); mx.inputs[2].default_value = (*rgb(vein), 1)
    nt.links.new(mask.outputs['Color'], mx.inputs[0]); nt.links.new(stone.outputs['Color'], mx.inputs[1])
    nt.links.new(mx.outputs[0], b.inputs['Base Color'])
    if metal_vein: nt.links.new(mask.outputs['Color'], b.inputs['Metallic'])
    rr = nt.nodes.new('ShaderNodeMapRange'); rr.inputs['To Min'].default_value = rough; rr.inputs['To Max'].default_value = 0.25
    nt.links.new(mask.outputs['Color'], rr.inputs['Value']); nt.links.new(rr.outputs['Result'], b.inputs['Roughness'])
    if glow:
        b.inputs['Emission Color'].default_value = (*rgb(vein), 1)
        mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; mul.inputs[1].default_value = glow
        nt.links.new(mask.outputs['Color'], mul.inputs[0]); nt.links.new(mul.outputs[0], b.inputs['Emission Strength'])
    n2 = _noise(nt, 20.0, 10.0, 0.7)
    sub = nt.nodes.new('ShaderNodeMath'); sub.operation = 'SUBTRACT'
    nt.links.new(n2.outputs['Fac'], sub.inputs[0]); nt.links.new(mask.outputs['Color'], sub.inputs[1])
    _bump(nt, b, sub.outputs[0], bumpk, 0.03)
    return m

def paper(col='#e8dcc0', ink=None, lines=0.0, name='paper', stain=0.4):
    """parchment: mottled, stained at random, optional lines of writing"""
    m, nt, b = _nodes(name)
    n = _noise(nt, 4.0, 8.0, 0.6)
    r = _ramp(nt, n.outputs['Fac'], [(0.2, _shade(col, 0.62)), (0.55, col), (1.0, _shade(col, 1.1))])
    base = r.outputs['Color']
    if lines:
        tc = _tex_coord(nt)
        w = nt.nodes.new('ShaderNodeTexWave'); w.wave_profile = 'SIN'; w.inputs['Scale'].default_value = lines; w.bands_direction = 'Z'
        nt.links.new(tc, w.inputs['Vector'])
        wn = _noise(nt, 60.0, 2.0, 0.5, 0.0, tc)
        th = nt.nodes.new('ShaderNodeMath'); th.operation = 'GREATER_THAN'; th.inputs[1].default_value = 0.85
        nt.links.new(w.outputs['Fac'], th.inputs[0])
        th2 = nt.nodes.new('ShaderNodeMath'); th2.operation = 'GREATER_THAN'; th2.inputs[1].default_value = 0.45
        nt.links.new(wn.outputs['Fac'], th2.inputs[0])
        mm = nt.nodes.new('ShaderNodeMath'); mm.operation = 'MULTIPLY'
        nt.links.new(th.outputs[0], mm.inputs[0]); nt.links.new(th2.outputs[0], mm.inputs[1])
        mx = nt.nodes.new('ShaderNodeMixRGB'); mx.inputs[2].default_value = (*rgb(ink or '#2a1a10'), 1)
        nt.links.new(mm.outputs[0], mx.inputs[0]); nt.links.new(base, mx.inputs[1]); base = mx.outputs[0]
    nt.links.new(base, b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.9
    n2 = _noise(nt, 25.0, 6.0, 0.6)
    _bump(nt, b, n2.outputs['Fac'], 0.08, 0.01)
    return m

# ================================================================== geometry

def link(o):
    bpy.context.collection.objects.link(o); return o

def from_bm(bm, name='obj', mat=None, smooth=True):
    me = bpy.data.meshes.new(name)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    o = link(bpy.data.objects.new(name, me))
    if smooth:
        for p in me.polygons: p.use_smooth = True
    if mat: me.materials.append(mat)
    return o

def mod(o, kind, **kw):
    m = o.modifiers.new(kind.lower(), kind)
    for k, v in kw.items(): setattr(m, k, v)
    return m

def apply(o):
    """bake the modifiers into the mesh (so framing sees the real shape)"""
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
    o.modifiers.clear(); o.data = me
    return o

def place(o, loc=(0, 0, 0), rot=(0, 0, 0), scale=None):
    o.location = loc; o.rotation_euler = Euler([math.radians(a) for a in rot])
    if scale is not None: o.scale = scale if isinstance(scale, (tuple, list)) else (scale,) * 3
    return o

def group(objs, loc=(0, 0, 0), rot=(0, 0, 0), scale=1.0):
    """move a set of objects together (baked into their transforms)"""
    M = Matrix.Translation(loc) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4() @ Matrix.Scale(scale, 4)
    for o in objs: o.matrix_world = M @ o.matrix_world
    return objs

def lathe(profile, mat=None, seg=48, name='lathe', smooth=True, sub=0):
    """a turned shape: profile [(radius, z), ...] spun around Z"""
    bm = bmesh.new()
    vs = [bm.verts.new((r, 0, z)) for r, z in profile]
    es = [bm.edges.new((vs[i], vs[i + 1])) for i in range(len(vs) - 1)]
    bmesh.ops.spin(bm, geom=vs + es, cent=(0, 0, 0), axis=(0, 0, 1), angle=2 * math.pi, steps=seg, use_merge=True)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    o = from_bm(bm, name, mat, smooth)
    if sub: mod(o, 'SUBSURF', levels=sub, render_levels=sub)
    return o

def prim(kind, mat=None, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), smooth=True, **kw):
    getattr(bpy.ops.mesh, 'primitive_%s_add' % kind)(**kw)
    o = bpy.context.active_object
    place(o, loc, rot, scale)
    if smooth: bpy.ops.object.shade_smooth()
    if mat: o.data.materials.append(mat)
    return o

def sphere(r, mat, loc=(0, 0, 0), scale=(1, 1, 1), seg=48):
    return prim('uv_sphere', mat, loc, (0, 0, 0), scale, radius=r, segments=seg, ring_count=seg // 2)

def cyl(r, h, mat, loc=(0, 0, 0), rot=(0, 0, 0), seg=40, bevel=0.0, scale=(1, 1, 1)):
    o = prim('cylinder', mat, loc, rot, scale, radius=r, depth=h, vertices=seg)
    if bevel: mod(o, 'BEVEL', width=bevel, segments=3, limit_method='ANGLE'); apply(o)
    return o

def box(size, mat, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.02, seg=3):
    o = prim('cube', mat, loc, rot, (size[0] / 2, size[1] / 2, size[2] / 2), smooth=False)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel: mod(o, 'BEVEL', width=bevel, segments=seg, limit_method='ANGLE'); apply(o)
    for p in o.data.polygons: p.use_smooth = True
    return o

def torus(R, r, mat, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), seg=64, mseg=24):
    return prim('torus', mat, loc, rot, scale, major_radius=R, minor_radius=r, major_segments=seg, minor_segments=mseg)

def tube(pts, radius, mat, taper=None, res=12, name='tube', profile=None, twist=0.0, smooth=True):
    """a swept tube through points (3D); taper = [(t, k), ...] radius along it; profile=(w,h) makes a flat band"""
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '3D'; cu.resolution_u = res
    sp = cu.splines.new('BEZIER'); sp.bezier_points.add(len(pts) - 1)
    for i, p in enumerate(pts):
        bp = sp.bezier_points[i]; bp.co = p; bp.handle_left_type = bp.handle_right_type = 'AUTO'
        bp.tilt = twist * i
        if taper:
            t = i / max(1, len(pts) - 1)
            bp.radius = _interp(taper, t)
    if profile:
        # a rectangle cross-section: a flat band (belts, straps, ribbons)
        pc = bpy.data.curves.new(name + 'p', 'CURVE'); ps = pc.splines.new('POLY'); ps.points.add(3)
        w, h = profile
        for i, (x, y) in enumerate([(-w, -h), (w, -h), (w, h), (-w, h)]): ps.points[i].co = (x, y, 0, 1)
        ps.use_cyclic_u = True
        po = link(bpy.data.objects.new(name + 'p', pc))
        cu.bevel_mode = 'OBJECT'; cu.bevel_object = po
    else:
        cu.bevel_depth = radius; cu.bevel_resolution = 6
    cu.use_fill_caps = True
    o = link(bpy.data.objects.new(name, cu))
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
    bpy.data.objects.remove(o)
    if profile: bpy.data.objects.remove(po)
    ob = link(bpy.data.objects.new(name, me))
    if smooth:
        for p in me.polygons: p.use_smooth = True
    if mat: me.materials.append(mat)
    return ob

def _interp(stops, t):
    for i in range(len(stops) - 1):
        a, b = stops[i], stops[i + 1]
        if a[0] <= t <= b[0]:
            k = (t - a[0]) / max(1e-6, b[0] - a[0]); return a[1] + (b[1] - a[1]) * k
    return stops[-1][1] if t > stops[-1][0] else stops[0][1]

def rock(r, mat, seed=0, strength=0.35, size=0.7, scale=(1, 1, 1), loc=(0, 0, 0), rot=(0, 0, 0), kind='VORONOI', sub=5, facets=True):
    """a stone: an ico sphere pushed about by noise (voronoi gives chipped facets, clouds gives lumps)"""
    o = prim('ico_sphere', mat, loc, rot, scale, radius=r, subdivisions=sub, smooth=not facets)
    t = bpy.data.textures.new('rk', kind)
    if kind == 'VORONOI': t.noise_scale = size; t.distance_metric = 'DISTANCE'
    else: t.noise_scale = size; t.noise_depth = 4
    e = link(bpy.data.objects.new('rkc', None)); e.location = (seed * 3.1, seed * 1.7, seed * 2.3)
    mod(o, 'DISPLACE', texture=t, strength=strength, texture_coords='OBJECT', texture_coords_object=e, mid_level=0.5)
    if kind == 'VORONOI':
        t2 = bpy.data.textures.new('rk2', 'CLOUDS'); t2.noise_scale = size * 0.5
        mod(o, 'DISPLACE', texture=t2, strength=strength * 0.25, texture_coords='OBJECT', texture_coords_object=e)
    apply(o)
    return o

def crystal(h, r, mat, sides=6, tip=0.35, loc=(0, 0, 0), rot=(0, 0, 0), jitter=0.12, seed=0):
    """a crystal prism with a pointed tip (and a slightly uneven cut)"""
    rnd = random.Random(seed)
    prof = []
    bm = bmesh.new()
    rings = []
    for z, k in [(0.0, 0.85), (h * (1 - tip), 1.0)]:
        ring = []
        for i in range(sides):
            a = 2 * math.pi * i / sides + rnd.uniform(-0.1, 0.1)
            rr = r * k * (1 + rnd.uniform(-jitter, jitter))
            ring.append(bm.verts.new((math.cos(a) * rr, math.sin(a) * rr, z)))
        rings.append(ring)
    top = bm.verts.new((rnd.uniform(-0.1, 0.1) * r, rnd.uniform(-0.1, 0.1) * r, h))
    bm.faces.new(list(reversed(rings[0])))
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new((rings[0][i], rings[0][j], rings[1][j], rings[1][i]))
        bm.faces.new((rings[1][i], rings[1][j], top))
    o = from_bm(bm, 'crystal', mat, smooth=False)
    mod(o, 'BEVEL', width=r * 0.04, segments=2, limit_method='ANGLE'); apply(o)
    return place(o, loc, rot)

def sheet(outline, mat, res=72, thick=0.02, bump=0.04, bscale=2.5, seed=0, bend=None, name='sheet', solid=True):
    """a flat piece (hide, cloth, paper, leaf, wing) cut to an outline [(x, y), ...] in -0.5..0.5,
    rippled by noise and optionally bent: bend(x, y) -> z offset. Lies in the XZ plane facing the camera."""
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=res, y_segments=res, size=0.5)
    poly = outline
    def inside(x, y):
        c = False; j = len(poly) - 1
        for i in range(len(poly)):
            xi, yi = poly[i]; xj, yj = poly[j]
            if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi + 1e-12) + xi): c = not c
            j = i
        return c
    kill = [v for v in bm.verts if not inside(v.co.x, v.co.y)]
    bmesh.ops.delete(bm, geom=kill, context='VERTS')
    # snap the boundary onto the outline so edges are smooth, not stair-stepped
    def nearest(x, y):
        best = None; bd = 1e9
        for i in range(len(poly)):
            ax, ay = poly[i]; bx, by = poly[(i + 1) % len(poly)]
            vx, vy = bx - ax, by - ay; L = vx * vx + vy * vy + 1e-12
            t = max(0, min(1, ((x - ax) * vx + (y - ay) * vy) / L))
            px, py = ax + vx * t, ay + vy * t; d = (px - x) ** 2 + (py - y) ** 2
            if d < bd: bd = d; best = (px, py)
        return best
    for v in bm.verts:
        if v.is_boundary: v.co.x, v.co.y = nearest(v.co.x, v.co.y)
    off = Vector((seed * 7.3, seed * 3.1, seed * 5.7))
    for v in bm.verts:
        z = mnoise.fractal(Vector((v.co.x * bscale, v.co.y * bscale, 0)) + off, 1.0, 2.0, 4) * bump
        if bend: z += bend(v.co.x, v.co.y)
        v.co.z = z
    o = from_bm(bm, name, mat)
    if solid and thick: mod(o, 'SOLIDIFY', thickness=thick, offset=0.0); apply(o)
    o.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.view_layer.update()
    o.data.transform(o.matrix_world); o.matrix_world = Matrix.Identity(4)
    return o

def blob_outline(n=40, rx=0.45, ry=0.45, wob=0.12, seed=0, lobes=None):
    """an irregular round outline (hides, scraps, puddles); lobes adds legs/points at given angles"""
    rnd = random.Random(seed)
    ph = [rnd.uniform(0, 6.28) for _ in range(4)]
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        k = 1 + wob * (math.sin(a * 3 + ph[0]) * 0.5 + math.sin(a * 5 + ph[1]) * 0.3 + math.sin(a * 7 + ph[2]) * 0.2)
        if lobes:
            for la, lk, lw in lobes:
                d = math.atan2(math.sin(a - la), math.cos(a - la))
                k += lk * math.exp(-(d / lw) ** 2)
        pts.append((math.cos(a) * rx * k, math.sin(a) * ry * k))
    return pts

def resample(pts, n=80, closed=True):
    """even points along a polyline (for smooth outlines from a few control points)"""
    P = pts + ([pts[0]] if closed else [])
    L = [0.0]
    for i in range(1, len(P)): L.append(L[-1] + math.dist(P[i - 1], P[i]))
    out = []
    for k in range(n):
        s = L[-1] * k / n
        for i in range(1, len(P)):
            if L[i] >= s:
                t = (s - L[i - 1]) / max(1e-9, L[i] - L[i - 1])
                out.append((P[i - 1][0] + (P[i][0] - P[i - 1][0]) * t, P[i - 1][1] + (P[i][1] - P[i - 1][1]) * t)); break
    return out

def smooth_outline(ctrl, n=120):
    """a Catmull-Rom loop through control points"""
    out = []; m = len(ctrl)
    for i in range(m):
        p0, p1, p2, p3 = ctrl[(i - 1) % m], ctrl[i], ctrl[(i + 1) % m], ctrl[(i + 2) % m]
        for k in range(n // m):
            t = k / (n // m); t2 = t * t; t3 = t2 * t
            out.append(tuple(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2 + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3) for j in range(2)))
    return out

def gem_cut(r, mat, loc=(0, 0, 0), rot=(0, 0, 0), sides=8, crown=0.35, pav=0.6, table=0.55):
    """a faceted (brilliant-ish) gem: table, crown, girdle, pavilion"""
    bm = bmesh.new()
    t = [bm.verts.new((math.cos(2 * math.pi * (i + 0.5) / sides) * r * table, math.sin(2 * math.pi * (i + 0.5) / sides) * r * table, r * crown)) for i in range(sides)]
    g = [bm.verts.new((math.cos(2 * math.pi * i / sides) * r, math.sin(2 * math.pi * i / sides) * r, 0)) for i in range(sides)]
    p = bm.verts.new((0, 0, -r * pav))
    bm.faces.new(t)
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new((g[i], g[j], t[i])); bm.faces.new((t[i], g[j], t[j]))
        bm.faces.new((g[j], g[i], p))
    o = from_bm(bm, 'gem', mat, smooth=False)
    return place(o, loc, rot)

def cabochon(r, mat, loc=(0, 0, 0), rot=(0, 0, 0), h=0.55, sy=1.0):
    o = sphere(r, mat, loc, (1, sy, h))
    o.rotation_euler = Euler([math.radians(a) for a in rot])
    return o

def rivets(pts, r, mat):
    return [sphere(r, mat, p, (1, 1, 0.6), seg=16) for p in pts]

def import_part(name, variant=1, half=False, tint=None):
    """one of the licensed outfit pieces (skinned, in its rest pose), in a colour variant"""
    path = os.path.join(CHARS, name + '.gltf')
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o not in before]
    keep = []
    for o in objs:
        if o.type == 'MESH' and not o.name.startswith('Icosphere'): keep.append(o)
        elif o.type == 'MESH': bpy.data.objects.remove(o)
    for o in keep:
        for ms in o.material_slots:
            m = ms.material
            if not m or not m.use_nodes: continue
            for n in m.node_tree.nodes:
                if n.type == 'TEX_IMAGE' and n.image and 'BaseColor' in n.image.name:
                    if variant > 1:
                        fam = n.image.name.split('_')[1]
                        p = os.path.join(CHARS, 'T_%s_%d_BaseColor.png' % (fam, variant))
                        if os.path.exists(p): n.image = bpy.data.images.load(p, check_existing=True)
                    if tint:
                        nt = m.node_tree; b = nt.nodes.get('Principled BSDF')
                        mx = nt.nodes.new('ShaderNodeMixRGB'); mx.blend_type = 'MULTIPLY'; mx.inputs[0].default_value = 1.0
                        mx.inputs[2].default_value = (*rgb(tint), 1)
                        nt.links.new(n.outputs['Color'], mx.inputs[1]); nt.links.new(mx.outputs[0], b.inputs['Base Color'])
        if half == 'hand':
            dg = bpy.context.evaluated_depsgraph_get()
            me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
            o.modifiers.clear(); o.parent = None; o.data = me
            bm = bmesh.new(); bm.from_mesh(me); mw = o.matrix_world
            xs = [(mw @ v.co).x for v in bm.verts]; hi = max(xs)
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if (mw @ v.co).x < hi * 0.62], context='VERTS')
            bm.to_mesh(me); bm.free()
        elif half:
            # keep one side (sleeves and shoulder pieces come in pairs, far apart in the rest pose)
            dg = bpy.context.evaluated_depsgraph_get()
            me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
            o.modifiers.clear(); o.parent = None; o.data = me
            bm = bmesh.new(); bm.from_mesh(me)
            mw = o.matrix_world
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if (mw @ v.co).x < 0.0], context='VERTS')
            bm.to_mesh(me); bm.free()
    return keep

# ================================================================== palettes

HUE = {  # metal, gem, cloth, cloth2
    'fire': ('#d8a040', '#ff2a18', '#8a1a12', '#e07a20'),
    'sea': ('#c8d4dc', '#20c8d8', '#1a4a6a', '#6ac0c8'),
    'void': ('#6a5a70', '#a040ff', '#2a1438', '#9a60d0'),
    'frost': ('#d8e4f0', '#8ad8ff', '#d8e6f0', '#6aa8d8'),
    'nature': ('#b89040', '#30c060', '#2a4a22', '#8ab050'),
    'gold': ('#e0b050', '#ffb020', '#2a3a7a', '#d8b050'),
}
TIER_METAL = {1: ('#d0804a', '#6a3a1a'), 2: ('#5a5a60', '#1a1a1e'), 3: ('#7a6a50', '#3a3020'), 4: ('#4a4448', '#ff6a20'),
    5: ('#d8dce4', '#6a7080'), 6: ('#b8c8f0', '#6070c0'), 7: ('#7ac0b8', '#205a58'), 8: ('#4a3060', '#b050ff')}
TIER_HIDE = {1: '#8a5a34', 2: '#6a4428', 3: '#5a5a34', 4: '#3a3230', 5: '#b08a60', 6: '#4a6a3a', 7: '#8a2a1a', 8: '#c8d8e8'}
TIER_CLOTH = {1: ('#d8c8a0', None), 2: ('#a8a090', None), 3: ('#6a8a4a', None), 4: ('#5a5a60', '#e07020'), 5: ('#a8d0f0', '#ffffff'),
    6: ('#5a3a8a', '#d0b0ff'), 7: ('#c03a18', '#ffb040'), 8: ('#2a1a40', '#a060ff')}

# ================================================================== recipes
R = {}          # key -> function(key)
def recipe(*keys):
    def deco(f):
        for k in keys: R[k] = f
        return f
    return deco

def xform(o, loc=(0, 0, 0), rot=(0, 0, 0), scale=1.0):
    """bake a transform into the mesh (so later placing starts from here)"""
    s = scale if isinstance(scale, (tuple, list)) else (scale,) * 3
    M = Matrix.Translation(loc) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4() @ Matrix.Diagonal((*s, 1.0))
    o.data.transform(M); o.data.update()
    return o

def all_meshes():
    return [o for o in bpy.data.objects if o.type in ('MESH', 'EMPTY', 'ARMATURE') and not o.name.startswith('rkc')]

# ------------------------------------------------------------------ weapons (the game's own models)
WPN_ROT = {'club': 40, 'axe': 40, 'greataxe': 40, 'worldbreaker': 40, 'abyssfang': 40, 'moon': 35, 'wand': 40}
@recipe(*['w_' + m for m in ['abyssblade', 'abyssfang', 'abyssstaff', 'axe', 'bough', 'club', 'crystalstaff', 'curved', 'dagger', 'dragonblade',
        'emberstaff', 'eternity', 'fang', 'greataxe', 'hook', 'jade', 'kris', 'leaf', 'long', 'moon', 'pickaxe', 'reaver', 'serrated',
        'skullstaff', 'staff', 'stick', 'sword', 'wand', 'wood', 'worldbreaker']])
def r_weapon(key):
    model = key[2:]
    I.import_glb(os.path.join(I.WEAPONS, model + '.glb'))
    shoot(key, (0, WPN_ROT.get(model, 45), 0), 0.98, objs=all_meshes())

# ------------------------------------------------------------------ armour (the outfit pieces the characters wear)
PART_FILE = {'Knight_Feet': 'Knight_Feet_Armor', 'Knight_Legs': 'Knight_Legs_Armor', 'Knight_Acc_Pauldron_Round': 'Knight_Acc_Pauldrons_Round',
    'Knight_Acc_Pauldron_Spike': 'Knight_Acc_Pauldrons_Spike', 'Ranger_Feet': 'Ranger_Feet_Boots', 'Ranger_Acc_Pauldron': 'Ranger_Acc_Pauldrons'}
def part_rot(look):
    if 'Arms' in look: return (0, -40, -35)
    if 'Pauldron' in look: return (10, 0, -40)
    if 'Head' in look: return (5, 0, -30)
    if 'Gorget' in look: return (15, 0, -25)
    if 'Feet' in look: return (5, 0, -40)
    return (0, 0, -25)

def armour(key, look, v, tint=None, fill=0.9):
    half = 'hand' if 'Arms' in look else 'Pauldron' in look
    f = 'Male_' + look
    if not os.path.exists(os.path.join(CHARS, f + '.gltf')): f = 'Male_' + PART_FILE.get(look, look)
    import_part(f, v, half, tint)
    shoot(key, part_rot(look), fill, objs=all_meshes())

def r_armour(key):
    body, v = key[2:].rsplit('_', 1)
    armour(key, body, int(v))
for _p in ['Knight_Acc_Pauldron_Round', 'Knight_Acc_Pauldron_Spike', 'Knight_Arms', 'Knight_Body_Armor', 'Knight_Feet', 'Knight_Head_Armet',
        'Knight_Head_Horns', 'Knight_Legs', 'Noble_Acc_Pauldron', 'Noble_Acc_Gorget', 'Noble_Arms', 'Noble_Body', 'Noble_Feet', 'Noble_Legs',
        'Ranger_Acc_Pauldron', 'Ranger_Arms', 'Ranger_Body', 'Ranger_Feet', 'Ranger_Head_Hood', 'Ranger_Legs', 'Wizard_Arms', 'Wizard_Body',
        'Wizard_Feet', 'Wizard_Legs']:
    for _v in (1, 2, 3): R['a_%s_%d' % (_p, _v)] = r_armour

TOKEN_PART = {'chest': 'Knight_Body_Armor', 'head': 'Knight_Head_Horns', 'legs': 'Knight_Legs', 'hands': 'Knight_Arms', 'shoulders': 'Knight_Acc_Pauldron_Spike'}
@recipe(*['tok_' + s for s in TOKEN_PART])
def r_token(key):
    armour(key, TOKEN_PART[key[4:]], 3, tint='#ffd890')

@recipe(*['g_cowl_' + h for h in HUE])
def r_cowl(key):
    armour(key, 'Ranger_Head_Hood', 1, tint=_shade(HUE[key[7:]][3], 2.2))

@recipe('g_gloves')
def r_gloves(key):
    armour(key, 'Ranger_Arms', 2)

# ------------------------------------------------------------------ jewellery
def chain(pts, mat, r=0.018):
    """a fine chain: a thin tube with a link pattern pressed into it"""
    return tube(pts, r, mat, res=24)

def chain_mat(col):
    m = metal(col, 0.25, scratches=0)
    nt = m.node_tree; b = nt.nodes['Principled BSDF']
    w = nt.nodes.new('ShaderNodeTexWave'); w.inputs['Scale'].default_value = 60.0; w.wave_profile = 'SIN'
    nt.links.new(_tex_coord(nt), w.inputs['Vector'])
    _bump(nt, b, w.outputs['Fac'], 0.8, 0.02)
    return m

def setting(r, mt, gm, loc, up=(0, 0, 1), cut=True, prongs=4):
    """a gem in a metal cup with claws"""
    ob = []
    cup = lathe([(0, -r * 0.5), (r * 0.7, -r * 0.45), (r * 1.08, -r * 0.05), (r * 1.1, r * 0.08), (r * 0.95, r * 0.1), (0, r * 0.1)], mt, 32)
    ob.append(cup)
    ob.append(gem_cut(r, gm, (0, 0, r * 0.12)) if cut else cabochon(r * 0.95, gm, (0, 0, r * 0.1), h=0.6))
    for i in range(prongs):
        a = 2 * math.pi * (i + 0.5) / prongs
        ob.append(tube([(math.cos(a) * r * 1.05, math.sin(a) * r * 1.05, -r * 0.1), (math.cos(a) * r * 1.0, math.sin(a) * r * 1.0, r * 0.3),
            (math.cos(a) * r * 0.8, math.sin(a) * r * 0.8, r * 0.42)], r * 0.09, mt, res=8))
    q = Vector((0, 0, 1)).rotation_difference(Vector(up)).to_euler()
    for o in ob:
        o.data.transform(q.to_matrix().to_4x4()); o.data.transform(Matrix.Translation(loc))
    return ob

@recipe(*['j_band_' + h for h in HUE] + ['j_signet_' + h for h in HUE])
def r_ring(key):
    h = key.rsplit('_', 1)[1]; sig = 'signet' in key
    mt = metal(HUE[h][0], 0.22); gm = gem(HUE[h][1], 0.8)
    torus(0.5, 0.075 if not sig else 0.09, mt, rot=(90, 0, 0), scale=(1, 1, 1.9 if not sig else 2.4))
    if sig:
        cyl(0.26, 0.12, mt, (0, 0, 0.58), bevel=0.03, scale=(1, 0.85, 1))
        cabochon(0.2, gm, (0, 0, 0.64), h=0.45, sy=0.85)
    else:
        setting(0.16, mt, gm, (0, 0, 0.6))
        for s in (-1, 1): gem_cut(0.06, gm, (s * 0.26, -0.02, 0.53), (0, s * 40, 0))
    shoot(key, (22, 0, 32), 0.86)

@recipe(*['j_pendant_' + h for h in HUE])
def r_pendant(key):
    h = key.rsplit('_', 1)[1]
    mt = metal(HUE[h][0], 0.22); gm = gem(HUE[h][1], 0.35)
    chain([(-0.42, 0.1, 0.62), (-0.36, 0, 0.2), (-0.14, -0.02, -0.08), (0, -0.03, -0.14), (0.14, -0.02, -0.08), (0.36, 0, 0.2), (0.42, 0.1, 0.62)], chain_mat(HUE[h][0]))
    # teardrop frame with the stone in it
    fr = torus(0.2, 0.035, mt, (0, -0.06, -0.42), (90, 0, 0), (1, 1.3, 1))
    xform(fr)
    cabochon(0.19, gm, (0, -0.07, -0.42), (90, 0, 0), h=0.45, sy=1.25)
    torus(0.05, 0.015, mt, (0, -0.05, -0.17), (0, 90, 0))
    for a in range(6):
        t = a / 6 * 2 * math.pi
        sphere(0.025, mt, (math.cos(t) * 0.24, -0.08, -0.42 + math.sin(t) * 0.31))
    shoot(key, (8, 0, 18), 0.9)

@recipe('j_beads')
def r_beads(key):
    wd = rough_mat('#8a5a30', 0.35, bumpk=0.05, coat=0.6); pale = rough_mat('#e8dcc0', 0.3, bumpk=0.02, coat=0.8)
    mt = metal('#e0b050', 0.25)
    for i in range(26):
        a = 2 * math.pi * i / 26
        x, z = math.cos(a) * 0.42, math.sin(a) * 0.3 + 0.18
        sphere(0.055 if i % 5 else 0.07, pale if i % 5 == 0 else wd, (x, -math.sin(a) * 0.12, z))
    for i in range(3): sphere(0.05, wd, (0, -0.05, -0.18 - i * 0.1))
    d = cyl(0.14, 0.03, mt, (0, -0.06, -0.55), (90, 0, 0), bevel=0.01)
    for k in range(8):
        a = 2 * math.pi * k / 8
        crystal(0.1, 0.02, mt, 4, 0.8, (math.cos(a) * 0.12, -0.06, -0.55 + math.sin(a) * 0.12), (0, 90 - math.degrees(a), 0), 0.0)
    sphere(0.05, gem('#fff0a0', 1.5), (0, -0.09, -0.55))
    shoot(key, (15, 0, 10), 0.9)

@recipe('j_bell')
def r_neck_bell(key):
    brass = metal('#c89a40', 0.3)
    tube([(-0.45, 0.1, 0.6), (-0.3, 0, 0.15), (0, -0.02, 0.0), (0.3, 0, 0.15), (0.45, 0.1, 0.6)], 0.025, rough_mat('#6a3a20', 0.7))
    lathe([(0, 0.12), (0.06, 0.12), (0.12, 0.05), (0.16, -0.15), (0.24, -0.32), (0.26, -0.36), (0.22, -0.36), (0, -0.36)], brass, 48, sub=1)
    torus(0.05, 0.018, brass, (0, 0, 0.14), (90, 0, 0))
    sphere(0.06, brass, (0.03, -0.05, -0.38))
    shoot(key, (10, 0, 20), 0.9)

@recipe('j_pearl')
def r_pearl(key):
    mt = metal('#e8c070', 0.2)
    chain([(-0.4, 0.1, 0.62), (-0.32, 0, 0.2), (0, -0.03, -0.05), (0.32, 0, 0.2), (0.4, 0.1, 0.62)], chain_mat('#e8c070'))
    pm, nt, b = _nodes('pearl')
    b.inputs['Base Color'].default_value = (*rgb('#f4eee8'), 1); b.inputs['Roughness'].default_value = 0.15
    b.inputs['Coat Weight'].default_value = 1.0; b.inputs['Sheen Weight'].default_value = 0.8
    b.inputs['Sheen Tint'].default_value = (*rgb('#ffc0e0'), 1); b.inputs['Thin Film Thickness'].default_value = 450.0
    sphere(0.22, pm, (0, -0.05, -0.36))
    lathe([(0, 0.0), (0.09, 0.0), (0.12, -0.06), (0.0, -0.08)], mt, 24).location = (0, -0.05, -0.1)
    for k in range(4):
        a = 2 * math.pi * k / 4 + 0.4
        tube([(0, -0.05, -0.12), (math.cos(a) * 0.14, -0.05 + math.sin(a) * 0.14, -0.2), (math.cos(a) * 0.19, -0.05 + math.sin(a) * 0.19, -0.3)], 0.014, mt, res=8)
    torus(0.05, 0.015, mt, (0, -0.05, -0.04), (0, 90, 0))
    shoot(key, (8, 0, 15), 0.9)

def feather(length, col, col2, loc, rot, seed=0):
    """a feather: a vane with a few splits, and the quill"""
    ctrl = [(0, -0.5), (0.1, -0.32), (0.16, -0.05), (0.13, 0.2), (0.06, 0.42), (0, 0.5), (-0.07, 0.4), (-0.15, 0.15), (-0.17, -0.1), (-0.11, -0.33)]
    pts = smooth_outline(ctrl, 120)
    rnd = random.Random(seed)
    # notches in the vane
    for _ in range(3):
        i = rnd.randrange(10, 110); j = i + 3
        mx, my = pts[i]
        pts[i + 1] = (mx * 0.6, my - 0.02)
    fm = fur(col, col2, k=0.3)
    o = sheet(pts, fm, 70, 0.006, 0.01, 3.0, seed, bend=lambda x, y: -0.12 * (y + 0.5) ** 2 + 0.05 * x * x)
    q = tube([(0, 0.0, -0.62), (0, -0.01, -0.3), (0, -0.02, 0.2), (0, -0.03, 0.48)], 0.012, rough_mat('#e8e0cc', 0.4, bumpk=0), taper=[(0, 1.0), (1, 0.3)])
    for ob in (o, q): xform(ob, (0, 0, 0), (0, 0, 0), length); xform(ob, loc, rot)
    return [o, q]

@recipe('j_charm')
def r_charm(key):
    tube([(-0.35, 0.1, 0.62), (-0.25, 0, 0.3), (0, -0.02, 0.18), (0.25, 0, 0.3), (0.35, 0.1, 0.62)], 0.02, rough_mat('#5a3420', 0.7))
    bone = rough_mat('#e0d6bc', 0.5, bumpk=0.2)
    cyl(0.12, 0.04, bone, (0, -0.03, 0.02), (90, 0, 0), bevel=0.015)
    torus(0.06, 0.012, emit('#60e0ff', 3.0), (0, -0.06, 0.02), (90, 0, 0))
    for i, (x, rz) in enumerate([(-0.1, 12), (0.02, -4), (0.13, -16)]):
        feather(0.62, ['#f0eadc', '#6a4a30', '#c05a2a'][i], None, (x, -0.02 - i * 0.01, -0.34), (0, rz, 0), i)
    for i in range(4): sphere(0.035, gem(['#20a0c0', '#e0b040', '#a02020', '#20a0c0'][i], 0.3, 0.2), (-0.1 + i * 0.07, -0.06, -0.06))
    shoot(key, (5, 0, 10), 0.9)

# ------------------------------------------------------------------ trinkets
@recipe('t_lantern')
def r_lantern(key):
    iron = metal('#4a4440', 0.45, dark='#1a1614')
    lathe([(0, 0), (0.3, 0), (0.32, 0.04), (0.28, 0.08), (0, 0.08)], iron, 8)
    lathe([(0, 0.7), (0.3, 0.7), (0.33, 0.74), (0.2, 0.86), (0.08, 0.92), (0.08, 0.96), (0, 0.96)], iron, 8)
    for i in range(8):
        a = 2 * math.pi * i / 8
        cyl(0.02, 0.64, iron, (math.cos(a) * 0.27, math.sin(a) * 0.27, 0.39), seg=8)
    lathe([(0, 0.06), (0.25, 0.06), (0.25, 0.72), (0, 0.72)], glass('#fff0d0', 0.12), 8)
    fire = I.fire_volume('flame', (0, 0, 0.36), (0.1, 0.1, 0.17), seed=2.0, glow=500.0, dens=40.0, falloff=0.8)
    cyl(0.05, 0.12, rough_mat('#e8e0c8', 0.6), (0, 0, 0.14))
    sphere(0.07, emit('#fff2c0', 18.0), (0, 0, 0.3), (1, 1, 1.6))
    torus(0.12, 0.018, iron, (0, 0, 1.06), (90, 0, 0))
    bpy.context.scene.cycles.volume_step_rate = 0.5
    I.light('POINT', (0, 0, 0.36), 60, '#ffb060')
    shoot(key, (10, 0, 22), 0.9)

@recipe('t_whistle')
def r_whistle(key):
    brass = metal('#d0a050', 0.25)
    w = lathe([(0, -0.5), (0.1, -0.5), (0.12, -0.46), (0.1, -0.42), (0.11, 0.2), (0.16, 0.26), (0.17, 0.4), (0.12, 0.46), (0, 0.46)], brass, 48)
    box((0.1, 0.12, 0.1), rough_mat('#101010', 0.8, bumpk=0), (0, -0.12, 0.25), bevel=0.01)
    torus(0.08, 0.02, brass, (0, 0, -0.56), (0, 90, 0))
    tube([(0, 0, -0.64), (0.1, -0.05, -0.8), (0.25, -0.02, -0.82), (0.36, 0.05, -0.7)], 0.018, rough_mat('#8a3020', 0.7))
    for z in (-0.3, 0.05): torus(0.115, 0.012, metal('#8a6020', 0.4), (0, 0, z))
    shoot(key, (15, -35, 20), 0.9)

@recipe('t_ember_heart')
def r_ember_heart(key):
    rock(0.45, veined('#2a1a16', '#ff7a20', glow=8.0, scale=3.0, width=0.045, metal_vein=False, rough=0.6), 3, 0.3, 0.6, (1, 0.9, 1.15))
    sphere(0.2, emit('#ff9a30', 1.0), (0, 0, 0))
    shoot(key, (0, 0, 15), 0.8)

@recipe('t_golem')
def r_golem(key):
    st = rough_mat('#6a6660', 0.8, bumpk=0.6, scale=6.0)
    box((0.7, 0.7, 0.7), st, (0, 0, 0), (0, 0, 0), bevel=0.08)
    rune = emit('#50d0ff', 8.0)
    for ang in (0, 90, 180, 270):
        for (x, z, w, h) in [(0, 0.12, 0.3, 0.035), (0, -0.12, 0.3, 0.035), (-0.13, 0, 0.035, 0.24), (0.1, 0.02, 0.035, 0.12)]:
            o = box((w, 0.02, h), rune, (x, -0.355, z), bevel=0.005)
            xform(o, (0, 0, 0), (0, 0, ang))
    sphere(0.12, emit('#a0f0ff', 10.0), (0, -0.36, 0), (1, 0.4, 1))
    for (x, y, z) in [(-0.35, -0.35, 0.35), (0.35, -0.35, 0.35), (-0.35, -0.35, -0.35), (0.35, 0.35, 0.35)]:
        rock(0.12, st, int(x * 10 + z * 5), 0.1, 0.4, loc=(x, y, z))
    shoot(key, (20, 0, 30), 0.85, rim='#80d8ff')

@recipe('t_tome')
def r_tome(key):
    lea = rough_mat('#5a1a18', 0.55, bumpk=0.4, scale=12.0)
    pg = paper('#efe2c4')
    box((0.8, 0.22, 1.0), pg, (0.02, 0, 0), bevel=0.02)
    box((0.86, 0.04, 1.08), lea, (0, -0.13, 0), bevel=0.02)
    box((0.86, 0.04, 1.08), lea, (0, 0.13, 0), bevel=0.02)
    cyl(0.14, 1.08, lea, (-0.42, 0, 0), scale=(0.6, 1, 1))
    gold = metal('#e0b050', 0.25)
    for (x, z) in [(-0.38, 0.48), (0.38, 0.48), (-0.38, -0.48), (0.38, -0.48)]:
        box((0.16, 0.05, 0.16), gold, (x, -0.16, z), bevel=0.02)
    cyl(0.18, 0.03, gold, (0.02, -0.16, 0), (90, 0, 0), bevel=0.01)
    gem_cut(0.1, gem('#a040ff', 2.0), (0.02, -0.18, 0), (-90, 0, 0))
    box((0.18, 0.3, 0.1), gold, (0.44, 0, 0), bevel=0.02)
    for k in range(5):
        a = 2 * math.pi * k / 5
        box((0.02, 0.02, 0.12), emit('#d090ff', 6.0), (0.02 + math.cos(a) * 0.26, -0.155, math.sin(a) * 0.26), (0, -math.degrees(a), 0), bevel=0)
    shoot(key, (15, 0, -30), 0.88)

@recipe('t_eye')
def r_eye(key):
    em, nt, b = _nodes('eye')
    tc = _tex_coord(nt)
    grad = nt.nodes.new('ShaderNodeTexGradient'); grad.gradient_type = 'SPHERICAL'
    mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Location'].default_value = (0, 0.0, 0); mp.inputs['Scale'].default_value = (2.6, 1.0, 2.6)
    nt.links.new(tc, mp.inputs[0])
    # the iris faces -Y: a radial gradient in X/Z
    sep = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(tc, sep.inputs[0])
    comb = nt.nodes.new('ShaderNodeCombineXYZ'); nt.links.new(sep.outputs['X'], comb.inputs['X']); nt.links.new(sep.outputs['Z'], comb.inputs['Y'])
    ln = nt.nodes.new('ShaderNodeVectorMath'); ln.operation = 'LENGTH'; nt.links.new(comb.outputs[0], ln.inputs[0])
    r = _ramp(nt, ln.outputs['Value'], [(0.0, '#000000'), (0.07, '#000000'), (0.09, '#ffd040'), (0.2, '#c02aff'), (0.26, '#300a40'), (0.28, '#e8d8d8'), (1.0, '#b8a0a0')])
    nt.links.new(r.outputs['Color'], b.inputs['Base Color'])
    em2 = _ramp(nt, ln.outputs['Value'], [(0.0, '#000000'), (0.08, '#000000'), (0.1, '#ffffff'), (0.22, '#8020c0'), (0.26, '#000000')])
    nt.links.new(em2.outputs['Color'], b.inputs['Emission Color']); b.inputs['Emission Strength'].default_value = 1.2
    b.inputs['Roughness'].default_value = 0.2; b.inputs['Coat Weight'].default_value = 1.0
    b.inputs['Subsurface Weight'].default_value = 0.2
    o = sphere(0.42, em, (0, 0, 0))
    o.rotation_euler = (0, 0, 0)
    # veins and a cradle of dark claws
    vm = rough_mat('#1a0a1e', 0.4, bumpk=0.3)
    for k in range(5):
        a = 2 * math.pi * k / 5 + 0.3
        tube([(math.cos(a) * 0.3, 0.3, math.sin(a) * 0.3), (math.cos(a) * 0.45, 0.0, math.sin(a) * 0.45), (math.cos(a) * 0.38, -0.25, math.sin(a) * 0.38),
            (math.cos(a) * 0.22, -0.4, math.sin(a) * 0.22)], 0.05, vm, taper=[(0, 1.0), (1, 0.15)])
    shoot(key, (0, 0, 0), 0.85, rim='#c080ff')

@recipe('t_frost_shard', 'rime_crystal')
def r_frost_shard(key):
    ice = gem('#9ad8ff', 0.35, 0.08)
    for i, (h, r, rot) in enumerate([(1.1, 0.16, (0, 8, 0)), (0.75, 0.12, (0, -28, 10)), (0.65, 0.11, (0, 34, -15)), (0.45, 0.09, (-20, -55, 0)), (0.5, 0.08, (15, 55, 0))]):
        crystal(h, r, ice, 6, 0.3, (0, 0, -0.45), rot, seed=i)
    rock(0.22, rough_mat('#c8d8e8', 0.4, bumpk=0.3), 2, 0.1, 0.5, (1.6, 1, 0.6), (0, 0, -0.5))
    shoot(key, (10, 0, 20), 0.88, rim='#a0e0ff')

@recipe('t_obsidian')
def r_obsidian(key):
    ob, nt, b = _nodes('obs')
    b.inputs['Base Color'].default_value = (*rgb('#0a080c'), 1); b.inputs['Roughness'].default_value = 0.05; b.inputs['Coat Weight'].default_value = 1.0
    b.inputs['Emission Color'].default_value = (*rgb('#ff5010'), 1); b.inputs['Emission Strength'].default_value = 0.0
    sphere(0.36, ob, (0, 0, 0.18))
    sphere(0.14, emit('#ff6020', 4.0), (0, 0.05, 0.18))
    gold = metal('#b08040', 0.35)
    lathe([(0, -0.32), (0.3, -0.32), (0.32, -0.28), (0.22, -0.22), (0.12, -0.14), (0.2, -0.08), (0.26, -0.02), (0.0, -0.02)], gold, 48)
    for k in range(3):
        a = 2 * math.pi * k / 3
        tube([(math.cos(a) * 0.2, math.sin(a) * 0.2, -0.05), (math.cos(a) * 0.33, math.sin(a) * 0.33, 0.1), (math.cos(a) * 0.3, math.sin(a) * 0.3, 0.28)], 0.03, gold, taper=[(0, 1.0), (1, 0.4)])
    shoot(key, (12, 0, 20), 0.85, rim='#ffa060')

@recipe('t_voidglass')
def r_voidglass(key):
    mt = metal('#5a4a6a', 0.3)
    torus(0.4, 0.05, mt, (0, 0, 0), (90, 0, 0))
    cabochon(0.39, gem('#6a20c0', 0.5, 0.05), (0, 0, 0), (90, 0, 0), h=0.2)
    cyl(0.05, 0.6, rough_mat('#2a1a20', 0.5), (0.0, 0.0, -0.7), (0, 0, 0))
    lathe([(0, -0.44), (0.08, -0.44), (0.06, -0.4), (0, -0.4)], mt, 24)
    for k in range(10):
        a = 2 * math.pi * k / 10
        crystal(0.1, 0.03, mt, 4, 0.8, (math.cos(a) * 0.44, 0, math.sin(a) * 0.44), (0, 90 - math.degrees(a), 0), 0.0)
    shoot(key, (0, 30, 20), 0.9, rim='#c080ff')

@recipe('t_bowstring')
def r_bowstring(key):
    s = rough_mat('#e0d0a8', 0.6, bumpk=0.4, scale=40)
    pts = [(math.cos(t * 0.5) * (0.35 - t * 0.004), math.sin(t * 0.5) * 0.12, math.sin(t * 0.5) * (0.3 - t * 0.003)) for t in range(0, 40)]
    pts = [(p[0], p[1] + i * 0.004, p[2]) for i, p in enumerate(pts)]
    tube(pts, 0.018, s, res=6)
    feather(0.55, '#f0eadc', '#707070', (0.1, -0.1, -0.45), (0, -30, 0), 3)
    torus(0.06, 0.02, rough_mat('#6a3a20', 0.7), (0.32, -0.05, 0.02), (0, 90, 0))
    shoot(key, (10, 0, 10), 0.9)

@recipe('t_charm')
def r_witch_charm(key):
    tw = wood('#5a4028', rings=12)
    for i in range(5):
        a = (i - 2) * 6
        tube([(0, 0, -0.5), (0.02 * i - 0.04, 0, 0), (0.03 * (i - 2), 0, 0.5)], 0.035, tw, taper=[(0, 0.9), (1, 0.6)]).rotation_euler = (0, math.radians(a), 0)
    cord = rough_mat('#8a2a1a', 0.8, bumpk=0.3, scale=30)
    for z in (-0.25, 0.25): torus(0.1, 0.03, cord, (0, 0, z), scale=(1, 1, 1.5))
    bone = rough_mat('#e8dcc0', 0.5, bumpk=0.3)
    sk = sphere(0.14, bone, (0, -0.05, 0.02), (1, 0.9, 1.1))
    for x in (-0.05, 0.05): sphere(0.035, rough_mat('#0a0404', 0.9, bumpk=0), (x, -0.17, 0.05))
    for i in range(3): sphere(0.04, gem(['#40c080', '#e0b040', '#40c080'][i], 0.3, 0.3), (0.15 + i * 0.02, -0.05, -0.1 - i * 0.09))
    feather(0.4, '#302a30', '#101010', (-0.18, -0.02, -0.4), (0, 25, 0), 5)
    shoot(key, (8, 0, 15), 0.9)

# ------------------------------------------------------------------ worn gear without an outfit model
@recipe(*['g_circlet_' + h for h in HUE])
def r_circlet(key):
    h = key.rsplit('_', 1)[1]
    mt = metal(HUE[h][0], 0.2); gm = gem(HUE[h][1], 1.0)
    torus(0.5, 0.035, mt, scale=(1, 0.9, 2.2))
    torus(0.5, 0.018, mt, (0, 0, 0.06), scale=(1.02, 0.92, 1))
    # the brow piece: a pointed crest over the stone, with two leaves of metal either side
    crest = crystal(0.34, 0.1, mt, 4, 0.6, (0, -0.47, -0.02), (-12, 0, 45), 0.0)
    crest.scale = (1, 0.35, 1); crest.rotation_euler = (math.radians(-12), 0, 0)
    setting(0.1, mt, gm, (0, -0.52, 0.08), up=(0, -1, 0.25))
    for s in (-1, 1):
        o = crystal(0.24, 0.06, mt, 4, 0.7, (s * 0.14, -0.45, 0.0), (0, s * 50, 0), 0.0)
        o.scale = (1, 0.4, 1)
        gem_cut(0.035, gm, (s * 0.3, -0.42, 0.03), (-90, 0, 0))
    shoot(key, (28, 0, 0), 0.9)

@recipe('g_crown_bone')
def r_crown_bone(key):
    bone = rough_mat('#e4d8bc', 0.5, bumpk=0.35, col2='#9a8a6a')
    iron = metal('#4a4440', 0.5)
    torus(0.46, 0.05, iron, scale=(1, 0.9, 2.0))
    for i in range(9):
        a = 2 * math.pi * i / 9 - math.pi / 2
        h = 0.5 if i % 2 == 0 else 0.3
        tube([(math.cos(a) * 0.46, math.sin(a) * 0.42, 0.05), (math.cos(a) * 0.5, math.sin(a) * 0.46, 0.05 + h * 0.5), (math.cos(a) * 0.56, math.sin(a) * 0.5, 0.05 + h)],
            0.055, bone, taper=[(0, 1.0), (1, 0.08)])
    setting(0.1, iron, gem('#60ff90', 2.0), (0, -0.47, 0.02), up=(0, -1, 0.1))
    shoot(key, (22, 0, 0), 0.9)

def bell_shape(mat, scale=1.0, loc=(0, 0, 0)):
    o = lathe([(0, 0.1), (0.05, 0.1), (0.1, 0.05), (0.13, -0.12), (0.2, -0.28), (0.21, -0.31), (0.18, -0.31), (0.16, -0.26), (0, -0.26)], mat, 40)
    xform(o, loc, (0, 0, 0), scale)
    return o

@recipe('g_crown_bell')
def r_crown_bell(key):
    brass = metal('#c89a40', 0.3)
    torus(0.46, 0.05, rough_mat('#6a2a50', 0.8, bumpk=0.2), scale=(1, 0.9, 2.2))
    torus(0.47, 0.02, brass, (0, 0, 0.09), scale=(1, 0.9, 1))
    for i in range(7):
        a = 2 * math.pi * i / 7 - math.pi / 2
        bell_shape(brass, 0.45, (math.cos(a) * 0.5, math.sin(a) * 0.46, -0.1))
        crystal(0.2, 0.04, brass, 4, 0.8, (math.cos(a) * 0.47, math.sin(a) * 0.43, 0.08), (0, 0, 0), 0.0)
    shoot(key, (22, 0, 0), 0.9)

CLOAK = [(-0.14, 0.5), (0.14, 0.5), (0.3, 0.2), (0.4, -0.2), (0.44, -0.45), (0.2, -0.5), (0.0, -0.47), (-0.2, -0.5), (-0.44, -0.45), (-0.4, -0.2), (-0.3, 0.2)]
def cloak(key, mat, collar_mat, trim=None, seed=0):
    out = resample(CLOAK, 140)
    bend = lambda x, y: 0.05 * math.sin(x * 22 + seed) * (0.55 - y) + 0.35 * x * x
    sheet(out, mat, 90, 0.025, 0.02, 3.0, seed, bend)
    tube([(-0.26, 0.05, 0.44), (-0.12, -0.02, 0.5), (0.12, -0.02, 0.5), (0.26, 0.05, 0.44)], 0.07, collar_mat, taper=[(0, 0.7), (0.5, 1.0), (1, 0.7)])
    gold = metal('#e0b050', 0.25)
    for s in (-1, 1): cyl(0.07, 0.03, gold, (s * 0.13, -0.09, 0.42), (90, 0, 0), bevel=0.01)
    tube([(-0.12, -0.11, 0.42), (0, -0.12, 0.36), (0.12, -0.11, 0.42)], 0.012, chain_mat('#e0b050'))
    if trim:
        edge = [(p[0] * 0.985, -0.0, p[1]) for p in resample(CLOAK, 60) if p[1] < -0.3]
    shoot(key, (8, 0, -15), 0.92)

@recipe(*['g_cloak_' + h for h in HUE])
def r_cloak(key):
    h = key.rsplit('_', 1)[1]
    cloak(key, cloth(HUE[h][2], stripes=(3.0, HUE[h][3]) if h == 'gold' else None), fur('#d8d0c0' if h != 'void' else '#2a2030'), seed=len(h))

@recipe('g_cloak_fur', 'g_cloak_hide')
def r_cloak_fur(key):
    white = key.endswith('fur')
    cloak(key, fur('#e8e8ec' if white else '#7a5230', '#a0a8b8' if white else '#3a2414', 0.6), fur('#f4f4f8' if white else '#4a3020'), seed=3)

def belt_loop(mat, w=0.075, t=0.018, rx=0.5, ry=0.38, n=24):
    pts = [(math.cos(2 * math.pi * i / n) * rx, math.sin(2 * math.pi * i / n) * ry, 0) for i in range(n)]
    pts.append(pts[0])
    o = tube(pts, 0, mat, profile=(t, w), res=6)
    return o

@recipe(*['g_cord_' + h for h in HUE])
def r_cord(key):
    h = key.rsplit('_', 1)[1]
    c = cloth(HUE[h][2], HUE[h][2], weave=90)
    belt_loop(c, 0.06, 0.012)
    sphere(0.09, c, (0, -0.4, 0), (1.3, 0.8, 1))
    for s, dx in ((-1, -0.06), (1, 0.08)):
        tube([(dx * 0.5, -0.42, -0.02), (dx, -0.44, -0.25), (dx * 1.6, -0.43, -0.55)], 0, c, profile=(0.006, 0.045), res=10)
        lathe([(0, 0.06), (0.04, 0.04), (0.06, -0.12), (0, -0.13)], cloth(HUE[h][3], weave=150), 16).location = (dx * 1.6, -0.43, -0.6)
    shoot(key, (35, 0, 15), 0.9)

@recipe('g_belt', 'g_girdle_mail', 'g_girdle_plate')
def r_belt(key):
    lea = rough_mat('#6a4028', 0.55, bumpk=0.3, scale=14, coat=0.2)
    belt_loop(lea, 0.075, 0.016)
    brass = metal('#c8a050' if key == 'g_belt' else '#9aa0a8', 0.3)
    fr = torus(0.12, 0.022, brass, (0, -0.4, 0), (90, 0, 0), (1.0, 1.3, 1)); xform(fr)
    cyl(0.012, 0.22, brass, (0, -0.42, 0.0), (0, 90, 0))
    if key != 'g_belt':
        steel = metal('#b0b4bc', 0.3)
        for i in range(10):
            a = 2 * math.pi * i / 10 + math.pi / 2 + 0.3
            if abs(math.sin(a) + 1) < 0.25: continue
            o = box((0.16, 0.03, 0.18 if key.endswith('plate') else 0.12), steel, bevel=0.012)
            xform(o, (0, 0, 0), (0, 0, math.degrees(a) + 90)); xform(o, (math.cos(a) * 0.515, math.sin(a) * 0.395, 0))
            rivets([(math.cos(a) * 0.54, math.sin(a) * 0.415, 0.05)], 0.018, brass)
        o = box((0.34, 0.05, 0.26), steel, (0, -0.43, 0), bevel=0.03)
        setting(0.06, steel, gem('#e02030', 0.8), (0, -0.46, 0), up=(0, -1, 0))
    shoot(key, (32, 0, 12), 0.9)

@recipe(*['g_wraps_' + h for h in HUE])
def r_wraps(key):
    h = key.rsplit('_', 1)[1]
    c = cloth(HUE[h][2], weave=100); c2 = cloth(_shade(HUE[h][2], 1.3), weave=100)
    lathe([(0, -0.5), (0.2, -0.5), (0.22, 0.0), (0.26, 0.5), (0, 0.5)], c, 40)
    pts = []
    for i in range(160):
        t = i / 160; a = t * 2 * math.pi * 6
        r = 0.21 + 0.05 * t + 0.015
        pts.append((math.cos(a) * r, math.sin(a) * r, -0.48 + t * 0.96))
    tube(pts, 0, c2, profile=(0.05, 0.008), res=4)
    tube([(0.2, -0.1, -0.4), (0.3, -0.15, -0.55), (0.28, -0.1, -0.75)], 0, c2, profile=(0.045, 0.006))
    shoot(key, (15, -30, 25), 0.9)

@recipe('g_bracers')
def r_bracers(key):
    lea = rough_mat('#5a3820', 0.55, bumpk=0.3, scale=12)
    steel = metal('#b0b4bc', 0.3)
    bm = bmesh.new()
    prof = [(0.22, -0.5), (0.25, 0.0), (0.29, 0.5)]
    vs = [bm.verts.new((r, 0, z)) for r, z in prof]
    es = [bm.edges.new((vs[i], vs[i + 1])) for i in range(2)]
    bmesh.ops.spin(bm, geom=vs + es, cent=(0, 0, 0), axis=(0, 0, 1), angle=math.radians(290), steps=40)
    o = from_bm(bm, 'bracer', lea); mod(o, 'SOLIDIFY', thickness=0.03); apply(o)
    xform(o, (0, 0, 0), (0, 0, 55))
    bm = bmesh.new()
    prof = [(0.26, -0.42), (0.285, 0.0), (0.32, 0.42)]
    vs = [bm.verts.new((r, 0, z)) for r, z in prof]
    es = [bm.edges.new((vs[i], vs[i + 1])) for i in range(2)]
    bmesh.ops.spin(bm, geom=vs + es, cent=(0, 0, 0), axis=(0, 0, 1), angle=math.radians(110), steps=20)
    p = from_bm(bm, 'plate', steel); mod(p, 'SOLIDIFY', thickness=0.03); mod(p, 'BEVEL', width=0.01, segments=2); apply(p)
    xform(p, (0, 0, 0), (0, 0, 215))
    for z in (-0.3, 0.3):
        torus(0.265 + z * 0.06, 0.02, rough_mat('#3a2414', 0.6), (0, 0, z))
    for z in (-0.35, 0.0, 0.35):
        for a in (230, 280):
            r = 0.3 + z * 0.06
            rivets([(math.cos(math.radians(a)) * r, math.sin(math.radians(a)) * r, z)], 0.02, metal('#d0a050', 0.3))
    shoot(key, (15, -25, 0), 0.9)

# ------------------------------------------------------------------ crafting materials (eight tiers each)
def tier(key): return int(key.rsplit('_', 1)[1])

@recipe(*['m_ore_%d' % t for t in range(1, 9)])
def r_ore(key):
    t = tier(key); mc, dk = TIER_METAL[t]
    glow = {4: 5.0, 8: 5.0, 6: 1.2}.get(t, 0.0)
    stone = {4: '#2a2422', 8: '#1e1824', 7: '#3a4a4a'}.get(t, '#5a5652')
    mat = veined(stone, mc if not glow else dk if t != 6 else mc, glow, 2.6, 0.035 if glow else 0.06, metal_vein=not glow or t == 6, rough=0.8)
    rock(0.45, mat, t, 0.32, 0.7, (1.15, 1, 0.85), (0, 0, 0.05))
    rock(0.2, mat, t + 11, 0.3, 0.6, (1, 1, 0.8), (0.46, -0.1, -0.28))
    rock(0.14, mat, t + 23, 0.3, 0.6, (1, 1, 0.8), (-0.44, -0.15, -0.32))
    shoot(key, (10, 0, 15), 0.9)

@recipe(*['m_bar_%d' % t for t in range(1, 9)])
def r_bar(key):
    t = tier(key); mc, dk = TIER_METAL[t]
    m = metal(mc, 0.28, dark=_shade(mc, 0.4))
    if t in (4, 8):
        b = m.node_tree.nodes['Principled BSDF']
        b.inputs['Emission Color'].default_value = (*rgb(dk), 1); b.inputs['Emission Strength'].default_value = 0.12
    def ingot(loc, rz):
        bm = bmesh.new()
        lo = [(-0.5, -0.2, 0), (0.5, -0.2, 0), (0.5, 0.2, 0), (-0.5, 0.2, 0)]
        hi = [(-0.42, -0.13, 0.2), (0.42, -0.13, 0.2), (0.42, 0.13, 0.2), (-0.42, 0.13, 0.2)]
        a = [bm.verts.new(p) for p in lo]; b = [bm.verts.new(p) for p in hi]
        bm.faces.new(list(reversed(a))); bm.faces.new(b)
        for i in range(4):
            j = (i + 1) % 4; bm.faces.new((a[i], a[j], b[j], b[i]))
        o = from_bm(bm, 'ingot', m, smooth=False)
        mod(o, 'BEVEL', width=0.03, segments=4, limit_method='ANGLE'); apply(o)
        for p in o.data.polygons: p.use_smooth = True
        # the smith's stamp
        stamp = box((0.2, 0.08, 0.02), metal(_shade(mc, 0.6), 0.5), (0, 0, 0.2), bevel=0.005)
        for ob in (o, stamp): xform(ob, (0, 0, 0), (0, 0, rz)); xform(ob, loc)
    ingot((0, -0.24, 0), 0); ingot((0, 0.24, 0), 0); ingot((0.0, 0.0, 0.21), 90)
    shoot(key, (28, 0, 30), 0.9)

def scale_mat(col, name='scales', k=0.8):
    m, nt, b = _nodes(name)
    v = nt.nodes.new('ShaderNodeTexVoronoi'); v.inputs['Scale'].default_value = 26.0; v.feature = 'F1'
    nt.links.new(_tex_coord(nt), v.inputs['Vector'])
    r = _ramp(nt, v.outputs['Distance'], [(0.0, _shade(col, 1.35)), (0.5, col), (0.9, _shade(col, 0.35))])
    nt.links.new(r.outputs['Color'], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.35; b.inputs['Coat Weight'].default_value = 0.4
    _bump(nt, b, v.outputs['Distance'], k, 0.03)
    return m

HIDE = [(0, 0.5), (0.12, 0.38), (0.22, 0.4), (0.42, 0.5), (0.36, 0.3), (0.3, 0.1), (0.32, -0.1), (0.42, -0.36), (0.3, -0.34), (0.14, -0.42), (0.04, -0.5),
    (-0.04, -0.5), (-0.14, -0.42), (-0.3, -0.34), (-0.42, -0.36), (-0.32, -0.1), (-0.3, 0.1), (-0.36, 0.3), (-0.42, 0.5), (-0.22, 0.4), (-0.12, 0.38)]
def hide_mat(t):
    c = TIER_HIDE[t]
    if t in (6, 7): return scale_mat(c)
    return fur(c, _shade(c, 0.5), 0.7)

@recipe(*['m_hide_%d' % t for t in range(1, 9)], 'hide', 'fur', 'pelt_white')
def r_hide(key):
    t = tier(key) if key.startswith('m_') else {'hide': 1, 'fur': 2, 'pelt_white': 8}[key]
    out = smooth_outline(HIDE, 160)
    mat = hide_mat(t) if key != 'fur' else fur('#6a5a4a', '#3a2a20', 1.0)
    sheet(out, mat, 90, 0.03, 0.09, 2.5, t, lambda x, y: 0.3 * x * x - 0.15 * y * y + 0.08 * math.sin(x * 9 + y * 4))
    # the flesh side shows along a turned-up corner
    shoot(key, (35, 0, 25), 0.95)

@recipe(*['m_leather_%d' % t for t in range(1, 9)])
def r_leather(key):
    t = tier(key); c = _shade(TIER_HIDE[t], 0.8)
    lea = scale_mat(c) if t in (6, 7) else rough_mat(c, 0.5, bumpk=0.35, scale=14, coat=0.3)
    cyl(0.26, 0.95, lea, (0, 0, 0), (0, 90, 0), bevel=0.02)
    pts = []
    for i in range(90):
        a = i / 90 * 2 * math.pi * 3.2; r = 0.03 + 0.22 * i / 90
        pts.append((-0.48, math.sin(a) * r, math.cos(a) * r))
    tube(pts, 0.008, rough_mat(_shade(c, 0.45), 0.7, bumpk=0), res=4)
    # the loose end lies over the front
    fl = sheet([(-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)], lea, 40, 0.02, 0.01, 2.0, t, lambda x, y: 0.0); xform(fl, (0, 0, 0), (0, 0, 0), (0.94, 1, 0.34)); xform(fl, (0.0, -0.27, -0.2), (-15, 0, 0))
    cord = rough_mat('#c8b890', 0.8, bumpk=0.3, scale=40)
    for x in (-0.25, 0.25): torus(0.28, 0.022, cord, (x, 0, 0), (0, 90, 0))
    shoot(key, (15, 0, 25), 0.9)

@recipe(*['m_linen_%d' % t for t in range(1, 9)], 'robe_scrap')
def r_scraps(key):
    if key == 'robe_scrap': c, c2 = '#6a1418', '#1a0808'
    else: c, c2 = TIER_CLOTH[tier(key)][0], None
    for i, (loc, rz, s) in enumerate([((-0.18, 0.05, 0.1), 15, 0.75), ((0.2, -0.05, -0.05), -20, 0.7), ((0.0, -0.1, -0.2), 5, 0.65)]):
        out = blob_outline(90, 0.46, 0.4, 0.18, i + 5)
        rnd = random.Random(i)
        out = [(x * (1 + rnd.uniform(-0.04, 0.04)), y * (1 + rnd.uniform(-0.04, 0.04))) for x, y in out]    # frayed
        m = cloth(c, c2, weave=70) if key != 'robe_scrap' else veined('#5a1216', '#0a0404', 0.0, 2.5, 0.25, False, 0.9)
        o = sheet(out, m, 60, 0.012, 0.05, 3.0, i, lambda x, y: 0.1 * math.sin(x * 6 + i))
        xform(o, (0, 0, 0), (0, 0, 0), s); xform(o, loc, (0, rz, 0))
    shoot(key, (20, 0, 10), 0.9)

@recipe(*['m_cloth_%d' % t for t in range(1, 9)])
def r_bolt(key):
    t = tier(key); c, c2 = TIER_CLOTH[t]
    cm = cloth(c, stripes=(4.0, c2) if c2 else None, weave=80)
    cyl(0.3, 0.9, cm, (0, 0, 0), (0, 90, 0), bevel=0.04)
    pts = []
    for i in range(120):
        a = i / 120 * 2 * math.pi * 5; r = 0.05 + 0.24 * i / 120
        pts.append((0.455, math.sin(a) * r, math.cos(a) * r))
    tube(pts, 0.006, cloth(_shade(c, 0.6)), res=4)
    # a length unrolled, draping down in front
    o = sheet([(-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)], cm, 50, 0.015, 0.02, 2.0, t, lambda x, y: 0.12 * math.sin((y + 0.5) * 4) * (0.5 - y))
    xform(o, (0, 0, 0), (0, 0, 0), (0.8, 1, 0.38)); xform(o, (0.02, -0.31, -0.2), (-8, 0, 0))
    rib = cloth(c2 or '#c02a2a', weave=120, sheen=1.0)
    torus(0.31, 0.02, rib, (-0.2, 0, 0), (0, 90, 0), (1, 1, 2.2))
    shoot(key, (15, 0, 28), 0.9)

def leaf(length, width, mat, loc, rot, seed=0, curl=0.25, tip=0.5, serr=0.0):
    ctrl = [(0, -0.5), (width * 0.5, -0.3), (width * 0.62, 0.0), (width * 0.4, 0.28), (0, 0.5), (-width * 0.4, 0.28), (-width * 0.62, 0.0), (-width * 0.5, -0.3)]
    out = smooth_outline(ctrl, 120)
    if serr:
        out = [(x * (1 + serr * (i % 6 < 3)), y) for i, (x, y) in enumerate(out)]
    o = sheet(out, mat, 50, 0.008, 0.01, 3.0, seed, lambda x, y: -curl * (y + 0.5) ** 2 + 0.3 * abs(x) * 0.5)
    xform(o, (0, 0, 0.5)); xform(o, (0, 0, 0), (0, 0, 0), length); xform(o, loc, rot)
    return o

def leaf_mat(col, name='leaf'):
    m, nt, b = _nodes(name)
    tc = _tex_coord(nt)
    sep = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(tc, sep.inputs[0])
    ab = nt.nodes.new('ShaderNodeMath'); ab.operation = 'ABSOLUTE'; nt.links.new(sep.outputs['X'], ab.inputs[0])
    r = _ramp(nt, ab.outputs[0], [(0.0, _shade(col, 1.6)), (0.02, _shade(col, 1.3)), (0.05, col), (0.3, _shade(col, 0.6))])
    nt.links.new(r.outputs['Color'], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.45; b.inputs['Subsurface Weight'].default_value = 0.2
    b.inputs['Coat Weight'].default_value = 0.3
    return m

def flower(petals, plen, pw, mat, loc, up=(0, 0, 1), lean=60, center=None, layers=1, seed=0):
    ob = []
    for L in range(layers):
        for i in range(petals):
            a = 360 * i / petals + L * 180 / petals
            ob.append(leaf(plen * (1 - L * 0.25), pw, mat, (0, 0, 0), (0, lean - L * 25, a), seed + i, curl=-0.15))
    if center: ob.append(sphere(plen * 0.22, center, (0, 0, plen * 0.05), (1, 1, 0.6)))
    q = Vector((0, 0, 1)).rotation_difference(Vector(up)).to_matrix().to_4x4()
    for o in ob: o.data.transform(q); o.data.transform(Matrix.Translation(loc))
    return ob

@recipe(*['m_herb_%d' % t for t in range(1, 9)], 'bloom')
def r_herb(key):
    t = tier(key) if key.startswith('m_') else 0
    stem = leaf_mat('#4a7a2a')
    twine = rough_mat('#c8b080', 0.8, bumpk=0.3, scale=40)
    if t == 1:      # hearthleaf: a bunch of broad leaves tied with twine
        for i, a in enumerate([-35, -15, 0, 18, 38]):
            leaf(0.8, 0.5, leaf_mat('#4a9a30'), (0, 0, -0.35), (0, a, 0), i, 0.3)
        tube([(0, 0, -0.6), (0, 0, -0.3)], 0.04, stem)
        torus(0.05, 0.02, twine, (0, 0, -0.42))
    elif t == 2:    # cliffmoss: a cushion of moss on a stone
        rock(0.4, rough_mat('#6a6660', 0.8, bumpk=0.5), 2, 0.2, 0.6, (1.2, 1, 0.6), (0, 0, -0.1))
        rock(0.38, fur('#5a8a2a', '#2a4a14', 1.2), 5, 0.25, 0.3, (1.2, 1, 0.55), (0, -0.02, 0.1), kind='CLOUDS', facets=False)
        for i in range(9):
            rnd = random.Random(i)
            sphere(0.025, emit('#f0f0c0', 1.0), (rnd.uniform(-0.35, 0.35), -0.3, rnd.uniform(0.05, 0.3)))
    elif t in (3, 0):   # bogbell / highland bloom: nodding bell flowers on a stem
        pm = leaf_mat('#8a50d0' if t == 3 else '#4a70e0')
        tube([(0, 0, -0.55), (0.05, 0, -0.1), (0.1, 0, 0.3), (0.25, 0, 0.45)], 0.025, stem)
        for i, (x, z) in enumerate([(0.25, 0.4), (0.1, 0.2), (-0.1, 0.05), (0.18, -0.05)]):
            tube([(0.05 if x > 0 else -0.02, 0, z + 0.1), (x, -0.05, z + 0.08)], 0.012, stem)
            b = lathe([(0, 0.0), (0.06, -0.01), (0.1, -0.08), (0.15, -0.2), (0.13, -0.2), (0, -0.14)], pm, 24)
            xform(b, (x, -0.05, z + 0.08))
        for i, a in enumerate([-30, 25]): leaf(0.6, 0.3, leaf_mat('#4a8a30'), (0, 0, -0.5), (0, a, 0), i + 3, 0.2)
    elif t == 4:    # emberroot: a gnarled root glowing at the tips
        rm = veined('#5a2a1a', '#ff6a20', 6.0, 4.0, 0.06, False, 0.7)
        tube([(0, 0, 0.55), (0.05, 0, 0.2), (-0.05, 0, -0.1), (0.05, 0, -0.5)], 0.12, rm, taper=[(0, 1.0), (1, 0.3)])
        for i, (a, z) in enumerate([(-50, 0.1), (40, -0.1), (-30, -0.3), (60, 0.25)]):
            d = math.radians(a)
            tube([(0, 0, z), (math.sin(d) * 0.25, 0, z - 0.1), (math.sin(d) * 0.45, 0.05, z - 0.3)], 0.05, rm, taper=[(0, 1.0), (1, 0.1)])
            sphere(0.02, emit('#ffa040', 12.0), (math.sin(d) * 0.46, 0.05, z - 0.31))
        for i, a in enumerate([-20, 10, 35]): leaf(0.4, 0.3, leaf_mat('#6a8a2a'), (0, 0, 0.5), (0, a, 0), i, 0.2)
    elif t == 5:    # frostthistle: spiky pale heads
        spk = rough_mat('#b8e0ff', 0.3, bumpk=0, coat=1.0)
        for i, (x, z) in enumerate([(-0.15, 0.35), (0.18, 0.25), (0.0, 0.5)]):
            tube([(0, 0, -0.55), (x * 0.5, 0, 0.0), (x, 0, z)], 0.02, leaf_mat('#6a9a8a'))
            lathe([(0, -0.1), (0.1, -0.08), (0.12, 0.0), (0.0, 0.02)], leaf_mat('#5a8a7a'), 20).location = (x, 0, z)
            for k in range(22):
                rnd = random.Random(k + i * 50)
                a = rnd.uniform(0, 6.28); e = rnd.uniform(0.2, 1.4)
                d = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))
                tube([(x, 0, z), (x + d.x * 0.18, d.y * 0.18, z + d.z * 0.18)], 0.01, spk, taper=[(0, 1.0), (1, 0.1)], res=2)
        for i, a in enumerate([-40, 35]): leaf(0.5, 0.25, leaf_mat('#6a9a8a'), (0, 0, -0.5), (0, a, 0), i, 0.2, serr=0.25)
    elif t == 6:    # starbloom
        pm = leaf_mat('#f8f0d8'); cm = emit('#ffd860', 8.0)
        tube([(0, 0, -0.55), (0, 0, 0.1)], 0.025, stem)
        flower(5, 0.36, 0.45, pm, (0, 0, 0.12), (0, -0.6, 0.8), 65, cm)
        flower(5, 0.22, 0.45, pm, (0.3, 0, -0.2), (0.3, -0.6, 0.7), 60, cm, seed=7)
        tube([(0, 0, -0.3), (0.3, 0, -0.22)], 0.015, stem)
        for i, a in enumerate([-40, 40]): leaf(0.45, 0.28, leaf_mat('#4a8a30'), (0, 0, -0.5), (0, a, 0), i, 0.2)
    elif t == 7:    # firebloom
        pm = veined('#e0401a', '#ffd040', 5.0, 2.0, 0.15, False, 0.5)
        tube([(0, 0, -0.55), (0, 0, 0.05)], 0.025, stem)
        flower(7, 0.4, 0.35, pm, (0, 0, 0.1), (0, -0.5, 0.85), 55, emit('#ffe070', 10.0), layers=2)
        for i, a in enumerate([-40, 40]): leaf(0.45, 0.28, leaf_mat('#4a7a20'), (0, 0, -0.5), (0, a, 0), i, 0.2)
    elif t == 8:    # voidlotus on its pad
        pm = veined('#3a1a5a', '#c070ff', 1.8, 1.5, 0.08, False, 0.4)
        o = sheet(blob_outline(60, 0.5, 0.5, 0.02, 1), leaf_mat('#2a4a3a'), 40, 0.01, 0.01, 2.0, 1)
        xform(o, (0, 0, 0), (-90, 0, 0)); xform(o, (0, 0, -0.25))
        flower(8, 0.45, 0.4, pm, (0, 0, -0.2), (0, 0, 1), 40, emit('#e0a0ff', 3.0), layers=2)
    shoot(key, (8, 0, 12), 0.9)

# ------------------------------------------------------------------ consumables
def bottle(profile, liquid_col, level, cork=True, glow=0.8, gl='#e8f0f4', thick=0.015):
    g = lathe(profile, glass(gl, 0.02), 48)
    mod(g, 'SOLIDIFY', thickness=thick); apply(g)
    inner = [(max(0, r - thick * 1.5), z) for r, z in profile if z <= level]
    if inner:
        inner = [(0, inner[0][1] + thick)] + inner[1:] + [(inner[-1][0], level), (0, level)]
        lathe(inner, liquid(liquid_col, glow), 48)
    top = max(z for r, z in profile); rn = profile[-2][0]
    if cork:
        cyl(rn * 0.95, 0.14, rough_mat('#a07a50', 0.8, bumpk=0.6, scale=30), (0, 0, top + 0.02), bevel=0.01)
    return g

@recipe('potion_s', 'potion_m', 'potion_l', 'vial_void', 'blessing', 'water')
def r_potion(key):
    if key == 'potion_s':
        bottle([(0, -0.5), (0.16, -0.5), (0.18, -0.46), (0.18, 0.2), (0.1, 0.3), (0.08, 0.36), (0.1, 0.4), (0.0, 0.4)], '#e01a1a', 0.12)
        torus(0.085, 0.015, rough_mat('#c8a060', 0.7), (0, 0, 0.3))
    elif key in ('potion_m', 'blessing', 'water'):
        col = {'potion_m': '#e01a1a', 'blessing': '#ffd860', 'water': '#80c8ff'}[key]
        bottle([(0, -0.45), (0.2, -0.45), (0.36, -0.32), (0.42, -0.1), (0.36, 0.1), (0.14, 0.24), (0.1, 0.32), (0.1, 0.44), (0.12, 0.46), (0.0, 0.46)],
            col, 0.02 if key != 'water' else 0.1, glow={'potion_m': 0.8, 'blessing': 1.0, 'water': 0.3}[key])
        torus(0.11, 0.018, rough_mat('#6a3a20', 0.7), (0, 0, 0.3))
        if key == 'blessing':
            for k in range(8):
                rnd = random.Random(k)
                sphere(0.012, emit('#fff0b0', 20.0), (rnd.uniform(-0.3, 0.3), rnd.uniform(-0.3, 0.3), rnd.uniform(-0.35, -0.05)))
    elif key == 'potion_l':
        gold = metal('#e0b050', 0.25)
        bottle([(0, -0.5), (0.3, -0.5), (0.44, -0.3), (0.48, -0.05), (0.4, 0.2), (0.16, 0.32), (0.12, 0.42), (0.14, 0.5), (0.0, 0.5)], '#ff1a3a', 0.1, glow=1.5)
        torus(0.14, 0.03, gold, (0, 0, 0.33)); torus(0.31, 0.03, gold, (0, 0, -0.48))
        gem_cut(0.07, gem('#ff2040'), (0, 0, 0.62))
    elif key == 'vial_void':
        bottle([(0, -0.5), (0.12, -0.5), (0.14, -0.46), (0.14, 0.3), (0.08, 0.36), (0.08, 0.42), (0.0, 0.42)], '#a030ff', 0.22, glow=4.0)
        lathe([(0, 0.42), (0.1, 0.42), (0.1, 0.5), (0.04, 0.58), (0, 0.6)], metal('#5a4a6a', 0.3), 24)
    shoot(key, (8, 0, 10), 0.88)

def bowl(r=0.5, h=0.34):
    return lathe([(0, -h), (r * 0.5, -h), (r * 0.55, -h * 0.9), (r * 0.9, -h * 0.45), (r, 0.0), (r * 0.94, 0.02), (r * 0.86, -h * 0.4), (r * 0.46, -h * 0.8), (0, -h * 0.82)],
        wood('#8a5a30', rings=10), 64, sub=1)

@recipe('stew', 'stew_hearty', 'chowder')
def r_stew(key):
    bowl()
    soup = rough_mat({'stew': '#8a3a14', 'stew_hearty': '#6a2a10', 'chowder': '#e8d8b0'}[key], 0.25, bumpk=0.3, scale=6.0, sss=0.3, coat=0.6)
    cyl(0.44, 0.02, soup, (0, 0, -0.04))
    rnd = random.Random(len(key))
    for i in range(9):
        a = rnd.uniform(0, 6.28); r = rnd.uniform(0.05, 0.34)
        c = rnd.choice(['#e07020', '#7a3a20', '#e8c060', '#4a8a30'] if key != 'chowder' else ['#e8a060', '#f0e0c0', '#6a9a40'])
        rock(rnd.uniform(0.04, 0.07), rough_mat(c, 0.4, bumpk=0.2, sss=0.2), i, 0.2, 0.5, (1, 1, 0.8), (math.cos(a) * r, math.sin(a) * r, -0.02))
    sp = wood('#b08050', rings=8)
    lathe([(0, -0.12), (0.08, -0.1), (0.1, 0.0), (0.08, 0.04), (0, 0.03)], sp, 24).location = (0.1, 0.1, 0.0)
    tube([(0.12, 0.1, 0.04), (0.35, 0.05, 0.25), (0.55, 0.0, 0.42)], 0.025, sp)
    if key != 'stew':
        br = rough_mat('#c88a40', 0.6, bumpk=0.5, col2='#7a4a1a')
        rock(0.2, br, 4, 0.08, 0.4, (1.4, 0.7, 0.9), (-0.42, -0.12, 0.05), kind='CLOUDS', facets=False)
    shoot(key, (35, 0, 10), 0.92, keyc='#ffe8c8')

@recipe('fish')
def r_fish(key):
    m, nt, b = _nodes('fishskin')
    tc = _tex_coord(nt); sep = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(tc, sep.inputs[0])
    r = _ramp(nt, sep.outputs['X'], [(0.0, '#d8dcd8'), (0.45, '#a8b0b0'), (0.7, '#4a5a60'), (1.0, '#2a3440')])
    v = nt.nodes.new('ShaderNodeTexVoronoi'); v.inputs['Scale'].default_value = 40.0; nt.links.new(tc, v.inputs['Vector'])
    nt.links.new(r.outputs['Color'], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.3; b.inputs['Metallic'].default_value = 0.45; b.inputs['Coat Weight'].default_value = 0.6
    _bump(nt, b, v.outputs['Distance'], 0.3, 0.01)
    o = lathe([(0, -0.5), (0.06, -0.46), (0.16, -0.3), (0.2, -0.05), (0.17, 0.2), (0.09, 0.38), (0.04, 0.45), (0.0, 0.46)], m, 40)
    xform(o, (0, 0, 0), (0, 0, 0), (1, 0.5, 1))
    fin = rough_mat('#5a6268', 0.5, bumpk=0.4, sss=0.3)
    tl = sheet([(-0.05, -0.5), (0.05, -0.5), (0.5, 0.45), (0.0, 0.2), (-0.5, 0.45)], fin, 40, 0.01, 0.01)
    xform(tl, (0, 0, 0), (0, 0, 180), 0.36); xform(tl, (0, 0, -0.6))
    df = sheet([(-0.5, -0.5), (0.5, -0.5), (0.2, 0.4), (-0.3, 0.2)], fin, 30, 0.01, 0.01)
    xform(df, (0, 0, 0), (0, 0, -90), 0.28); xform(df, (0.22, 0, 0.0))
    sphere(0.04, gem('#101010', 0.0, 0.05), (0.06, -0.09, 0.3))
    torus(0.14, 0.018, rough_mat('#b89a60', 0.8, bumpk=0.3, scale=40), (0, 0, -0.44), scale=(1, 0.6, 1))
    shoot(key, (0, -60, 0), 0.95)

@recipe('egg')
def r_egg(key):
    m = rough_mat('#f0e4cc', 0.45, bumpk=0.08, scale=3.0, sss=0.2)
    lathe([(0, -0.5), (0.25, -0.44), (0.36, -0.2), (0.35, 0.05), (0.26, 0.3), (0.12, 0.44), (0, 0.48)], m, 48, sub=1)
    shoot(key, (0, -15, 0), 0.8)

@recipe('meat')
def r_meat(key):
    rock(0.45, veined('#a02a2a', '#f0e0d0', 0.0, 2.0, 0.12, False, 0.35, bumpk=0.3), 3, 0.2, 0.3, (1.2, 0.8, 0.8), kind='CLOUDS', facets=False)
    bone = rough_mat('#eee4cc', 0.4, bumpk=0.2)
    tube([(0.3, 0, 0.0), (0.7, 0, 0.1)], 0.06, bone)
    for d in (-1, 1): sphere(0.07, bone, (0.72, d * 0.04, 0.1 + d * 0.05))
    shoot(key, (15, 0, 20), 0.9)

@recipe('oats')
def r_oats(key):
    sack = cloth('#b8986a', weave=40, sheen=0.1)
    o = lathe([(0, -0.5), (0.36, -0.48), (0.44, -0.2), (0.4, 0.1), (0.2, 0.3), (0.14, 0.36), (0.26, 0.5), (0, 0.48)], sack, 40)
    mod(o, 'DISPLACE', texture=bpy.data.textures.new('sk', 'CLOUDS'), strength=0.05); apply(o)
    torus(0.15, 0.03, rough_mat('#8a6a3a', 0.8, bumpk=0.4, scale=40), (0, 0, 0.33))
    grain = rough_mat('#e8d090', 0.6, bumpk=0.1)
    for i in range(40):
        rnd = random.Random(i)
        sphere(0.03, grain, (rnd.uniform(-0.2, 0.55), rnd.uniform(-0.45, -0.1), -0.48 + rnd.uniform(0, 0.06)), (1.6, 1, 0.6)).rotation_euler = (0, 0, rnd.uniform(0, 3))
    shoot(key, (20, 0, 15), 0.9)

# ------------------------------------------------------------------ paper, keys and letters
def page(w, h, mat, seed=0, bend=0.05):
    return sheet([(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)], mat, 50, 0.005, 0.01, 2.0, seed, lambda x, y: bend * math.sin(x * 3 + y * 2))

@recipe('letter')
def r_letter(key):
    p = page(0.9, 0.6, paper('#e8dcc0'))
    xform(p, (0, 0, 0), (0, 0, 0))
    fl = sheet([(-0.45, 0.3), (0.45, 0.3), (0.0, -0.05)], paper('#dccfae'), 40, 0.005, 0.005)
    xform(fl, (0, -0.012, 0))
    wax = rough_mat('#a01010', 0.3, bumpk=0.6, scale=10, coat=0.6)
    rock(0.1, wax, 2, 0.04, 0.3, (1, 0.35, 1), (0, -0.04, -0.03), kind='CLOUDS', facets=False)
    cyl(0.065, 0.03, wax, (0, -0.07, -0.03), (90, 0, 0), bevel=0.01)
    shoot(key, (0, 0, -12), 0.92)

def scroll(mat, loc=(0, 0, 0), rot=(0, 0, 0), length=0.9, r=0.16, ribbon='#a01818', seal=True):
    ob = [cyl(r, length, mat, (0, 0, 0), (0, 90, 0), bevel=0.01)]
    pts = []
    for i in range(80):
        a = i / 80 * 2 * math.pi * 3; rr = 0.02 + (r - 0.02) * i / 80
        pts.append((length / 2 + 0.001, math.sin(a) * rr, math.cos(a) * rr))
    ob.append(tube(pts, 0.004, rough_mat('#8a7a5a', 0.8, bumpk=0), res=4))
    rb = cloth(ribbon, weave=120, sheen=1.0)
    ob.append(torus(r + 0.01, 0.015, rb, (0, 0, 0), (0, 90, 0), (1, 1, 2.5)))
    if seal:
        wax = rough_mat('#a01010', 0.3, bumpk=0.6, scale=10, coat=0.6)
        ob.append(cyl(0.08, 0.04, wax, (0, -r - 0.02, 0), (90, 0, 0), bevel=0.015))
        ob.append(tube([(0.02, -r - 0.03, -0.05), (0.05, -r - 0.05, -0.2), (0.02, -r - 0.04, -0.32)], 0, rb, profile=(0.004, 0.03)))
    for o in ob: xform(o, loc, rot)
    return ob

@recipe('dispatch')
def r_dispatch(key):
    scroll(paper('#e8dcc0'))
    shoot(key, (10, 0, 35), 0.92)

@recipe('notes', 'ledger')
def r_notes(key):
    if key == 'notes':
        for i in range(4):
            p = page(0.7, 0.9, paper('#e8dcc0', lines=14.0), i, 0.03)
            xform(p, (0, 0, 0), (0, (i - 1.5) * 8, 0)); xform(p, (i * 0.03, -i * 0.02, -i * 0.02))
        tube([(0.3, -0.12, 0.1), (0.1, -0.12, 0.4), (-0.2, -0.13, 0.62)], 0.012, rough_mat('#303030', 0.4))
        feather(0.6, '#e8e0d0', '#8a8070', (-0.05, -0.14, 0.2), (0, -40, 0), 2)
        shoot(key, (0, 0, 0), 0.92)
    else:
        lea = rough_mat('#3a2a1a', 0.5, bumpk=0.4, scale=12)
        box((0.8, 0.26, 1.0), paper('#e8dcc0'), (0.02, 0, 0), bevel=0.02)
        for y in (-0.15, 0.15): box((0.86, 0.04, 1.06), lea, (0, y, 0), bevel=0.02)
        cyl(0.16, 1.06, lea, (-0.42, 0, 0), scale=(0.6, 1, 1))
        brass = metal('#b08a40', 0.35)
        for z in (-0.3, 0.3): box((0.18, 0.36, 0.08), lea, (0.44, 0, z), bevel=0.02); cyl(0.04, 0.02, brass, (0.5, -0.19, z), (90, 0, 0))
        box((0.3, 0.02, 0.18), paper('#f0e8d0'), (0.05, -0.18, 0.2), bevel=0.01)
        shoot(key, (15, 0, -28), 0.88)

@recipe('map')
def r_map(key):
    m, nt, b = _nodes('mapp')
    n = _noise(nt, 3.0, 6.0, 0.6)
    land = _ramp(nt, n.outputs['Fac'], [(0.45, '#8ab0b8'), (0.47, '#5a4a2a'), (0.5, '#d8c89a'), (0.8, '#c8b080')])
    ctr = nt.nodes.new('ShaderNodeMath'); ctr.operation = 'FRACT'
    mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; mul.inputs[1].default_value = 12.0
    nt.links.new(n.outputs['Fac'], mul.inputs[0]); nt.links.new(mul.outputs[0], ctr.inputs[0])
    ln = _ramp(nt, ctr.outputs[0], [(0.0, '#000000'), (0.06, '#ffffff'), (0.12, '#ffffff')])
    mx = nt.nodes.new('ShaderNodeMixRGB'); mx.blend_type = 'MULTIPLY'; mx.inputs[0].default_value = 0.35
    nt.links.new(land.outputs['Color'], mx.inputs[1]); nt.links.new(ln.outputs['Color'], mx.inputs[2])
    nt.links.new(mx.outputs[0], b.inputs['Base Color']); b.inputs['Roughness'].default_value = 0.9
    p = page(0.95, 0.75, m, 1, 0.03)
    for s in (-1, 1): scroll(paper('#d8c89a'), (s * 0.49, 0.03, 0), (0, 90, 0), 0.8, 0.07, seal=False)
    xm = emit('#c01010', 2.0)
    for a in (45, -45): box((0.14, 0.01, 0.03), xm, (0.18, -0.03, -0.12), (0, a, 0), bevel=0)
    tube([(-0.3, -0.03, 0.2), (-0.1, -0.03, 0.05), (0.05, -0.03, 0.02), (0.15, -0.03, -0.1)], 0.006, rough_mat('#6a1a10', 0.8, bumpk=0))
    shoot(key, (15, 0, 0), 0.95)

@recipe('key_iron', 'key_void')
def r_key(key):
    v = key == 'key_void'
    mt = metal('#5a4a70' if v else '#6a625a', 0.35 if v else 0.55, dark='#1a1010')
    if not v:
        b = mt.node_tree.nodes['Principled BSDF']
    torus(0.2, 0.05, mt, (0, 0, 0.3), (90, 0, 0))
    if v:
        for k in range(6):
            a = 2 * math.pi * k / 6
            crystal(0.14, 0.035, mt, 4, 0.8, (math.cos(a) * 0.24, 0, 0.3 + math.sin(a) * 0.24), (0, 90 - math.degrees(a), 0), 0.0)
        gem_cut(0.1, gem('#a040ff', 3.0), (0, -0.02, 0.3), (90, 0, 0))
    cyl(0.045, 0.8, mt, (0, 0, -0.2), bevel=0.01)
    for z in (0.05, -0.05): torus(0.06, 0.015, mt, (0, 0, z))
    box((0.2, 0.06, 0.08), mt, (0.1, 0, -0.52), bevel=0.01)
    box((0.14, 0.06, 0.06), mt, (0.08, 0, -0.4), bevel=0.01)
    box((0.06, 0.06, 0.12), mt, (0.17, 0, -0.46), bevel=0.01)
    shoot(key, (0, -40, 10), 0.92, rim='#c080ff' if v else '#9fc0ff')

@recipe('seal', 'token_grave', 'coin')
def r_seal(key):
    if key == 'coin':
        gold = metal('#e8b848', 0.22)
        for i in range(4):
            cyl(0.3, 0.06, gold, (0.05 * (i % 2), 0, -0.4 + i * 0.065), bevel=0.012)
            torus(0.26, 0.012, gold, (0.05 * (i % 2), 0, -0.4 + i * 0.065 + 0.03))
        o = cyl(0.3, 0.06, gold, (0.15, -0.25, 0.0), (80, 0, 20), bevel=0.012)
        torus(0.26, 0.012, gold, (0.15, -0.28, 0.0), (80, 0, 20))
        cyl(0.12, 0.03, gold, (0.15, -0.28, 0.0), (80, 0, 20), bevel=0.01)
        shoot(key, (15, 0, 0), 0.9)
        return
    mt = metal('#e0b050', 0.3) if key == 'seal' else metal('#8a8a90', 0.5, dark='#2a2a30')
    cyl(0.42, 0.08, mt, (0, 0, 0), (90, 0, 0), bevel=0.02)
    torus(0.36, 0.022, mt, (0, -0.045, 0), (90, 0, 0))
    if key == 'seal':
        crystal(0.36, 0.08, mt, 4, 0.5, (0, -0.06, -0.18), (-90, 0, 0), 0)
        for s in (-1, 1):
            leaf(0.36, 0.35, mt, (s * 0.02, -0.05, -0.1), (90, s * 50, 0), 1)
        sphere(0.07, gem('#e02030', 0.5), (0, -0.08, 0.02))
        tube([(0.0, 0.03, 0.4), (-0.15, 0.02, 0.55), (-0.3, 0.0, 0.62)], 0, cloth('#8a1a1a'), profile=(0.005, 0.05))
    else:
        bone = mt
        sphere(0.13, bone, (0, -0.06, 0.05), (1, 0.4, 1.05))
        for x in (-0.05, 0.05): sphere(0.035, rough_mat('#101010', 0.9, bumpk=0), (x, -0.1, 0.06))
        for a in (40, -40): box((0.46, 0.04, 0.06), bone, (0, -0.06, -0.14), (0, a, 0), bevel=0.01)
    shoot(key, (10, 0, 25), 0.88)

@recipe('locket')
def r_locket(key):
    gold = metal('#e8b848', 0.22)
    chain([(-0.35, 0.1, 0.65), (-0.28, 0, 0.3), (0, -0.02, 0.18), (0.28, 0, 0.3), (0.35, 0.1, 0.65)], chain_mat('#e8b848'))
    o = cyl(0.26, 0.1, gold, (0, 0, -0.2), (90, 0, 0), bevel=0.04, scale=(1, 1.25, 1)); xform(o)
    torus(0.22, 0.02, gold, (0, -0.06, -0.2), (90, 0, 0), (1, 1.25, 1))
    cabochon(0.1, gem('#20a0a0', 0.4), (0, -0.07, -0.2), (90, 0, 0), h=0.4, sy=1.2)
    torus(0.05, 0.015, gold, (0, 0, 0.12), (0, 90, 0))
    sea = rough_mat('#3a6a5a', 0.6, bumpk=0.3)
    for i in range(6):
        rnd = random.Random(i)
        sphere(0.03, sea, (rnd.uniform(-0.2, 0.2), -0.1, rnd.uniform(-0.45, 0.0)), (1, 0.4, 1))
    shoot(key, (8, 0, 15), 0.9)

@recipe('compass')
def r_compass(key):
    brass = metal('#c8a050', 0.28)
    cyl(0.44, 0.14, brass, (0, 0, 0), (90, 0, 0), bevel=0.03)
    cyl(0.36, 0.02, paper('#e8dcc0'), (0, -0.07, 0), (90, 0, 0))
    for k in range(16):
        a = 2 * math.pi * k / 16
        box((0.012, 0.01, 0.06 if k % 4 else 0.1), rough_mat('#2a1a10', 0.8, bumpk=0), (math.cos(a) * 0.3, -0.085, math.sin(a) * 0.3), (0, 90 - math.degrees(a), 0), bevel=0)
    n = crystal(0.28, 0.035, emit('#e02020', 1.0), 4, 1.0, (0, -0.09, 0), (0, -30, 0), 0.0)
    crystal(0.28, 0.035, metal('#d0d4d8', 0.3), 4, 1.0, (0, -0.09, 0), (0, 150, 0), 0.0)
    cabochon(0.37, glass('#f0f8ff', 0.0), (0, -0.075, 0), (90, 0, 0), h=0.12)
    torus(0.08, 0.025, brass, (0, 0, 0.5), (90, 0, 0))
    cyl(0.05, 0.08, brass, (0, 0, 0.44))
    shoot(key, (10, 0, 20), 0.9)

# ------------------------------------------------------------------ bits of monsters, stones and odds and ends
IVORY = ('#ece2c8', '#9a8a68')
def horn(pts, r, mat, rings=0):
    o = tube(pts, r, mat, taper=[(0, 1.0), (0.7, 0.55), (1, 0.05)], res=16)
    return o

@recipe('tusk', 'fang', 'fang_charred', 'fang_frost', 'claw', 'horn_chip')
def r_tooth(key):
    if key == 'tusk':
        m = rough_mat(*IVORY[:1], 0.35, bumpk=0.25, col2=IVORY[1], coat=0.4)
        horn([(-0.45, 0, -0.35), (-0.2, 0, -0.05), (0.15, 0, 0.2), (0.45, 0, 0.45)], 0.17, m)
        cyl(0.17, 0.06, rough_mat('#8a6a4a', 0.6, bumpk=0.6), (-0.46, 0, -0.37), (0, 55, 0))
    elif key == 'horn_chip':
        m = veined('#3a3028', '#8a7a60', 0.0, 3.0, 0.08, False, 0.5)
        o = horn([(-0.4, 0, -0.3), (-0.1, 0, 0.0), (0.2, 0, 0.3), (0.4, 0, 0.6)], 0.26, m)
        rock(0.26, m, 3, 0.15, 0.3, (0.8, 0.8, 0.5), (-0.4, 0, -0.3), (0, 50, 0))
    elif key == 'claw':
        m = rough_mat('#2a2220', 0.25, bumpk=0.2, col2='#0a0808', coat=0.8)
        horn([(-0.3, 0, -0.45), (0.05, 0, -0.2), (0.3, 0, 0.15), (0.2, 0, 0.5)], 0.16, m)
        rock(0.17, fur('#6a4a30'), 1, 0.08, 0.4, (1, 1, 0.8), (-0.3, 0, -0.47))
    else:
        c = {'fang': IVORY, 'fang_charred': ('#3a2a22', '#0a0605'), 'fang_frost': ('#d8ecff', '#6a9ac8')}[key]
        m = rough_mat(c[0], 0.3, bumpk=0.2, col2=c[1], coat=0.6)
        if key == 'fang_charred':
            m = veined('#2a1a14', '#ff6a20', 5.0, 3.5, 0.05, False, 0.4)
        horn([(-0.1, 0, 0.55), (0.02, 0, 0.2), (0.1, 0, -0.15), (-0.05, 0, -0.55)], 0.17, m)
        rock(0.16, rough_mat('#8a5a4a', 0.6, bumpk=0.4), 2, 0.08, 0.3, (1.1, 1, 0.7), (-0.1, 0, 0.55))
        if key == 'fang_frost':
            for i in range(3): crystal(0.2, 0.04, gem('#a0e0ff', 1.0, 0.1), 6, 0.4, (0.05, 0, 0.1 - i * 0.2), (0, 60 + i * 20, 0), seed=i)
    shoot(key, (10, 0, 20), 0.9)

@recipe('ram_horn', 'war_horn')
def r_ram_horn(key):
    m = rough_mat('#8a7a60', 0.5, bumpk=0.5, col2='#4a3a28', coat=0.3)
    wv = m.node_tree.nodes.new('ShaderNodeTexWave'); wv.inputs['Scale'].default_value = 25.0
    nt = m.node_tree; nt.links.new(_tex_coord(nt), wv.inputs['Vector'])
    _bump(nt, nt.nodes['Principled BSDF'], wv.outputs['Fac'], 0.6, 0.02)
    if key == 'ram_horn':
        pts = []
        for i in range(40):
            t = i / 39; a = t * 2 * math.pi * 1.2; r = 0.45 * (1 - t * 0.6)
            pts.append((math.cos(a) * r, -t * 0.25, math.sin(a) * r))
        tube(pts, 0.2, m, taper=[(0, 1.0), (1, 0.12)], res=6)
    else:
        horn([(-0.5, 0, -0.1), (-0.15, 0, 0.3), (0.25, 0, 0.3), (0.5, 0, -0.1)], 0.2, m)
        brass = metal('#c8a050', 0.3)
        for x, r in ((-0.35, 0.2), (0.0, 0.16)):
            torus(r, 0.03, brass, (x, 0, 0.22 if x == 0 else 0.12), (0, 90 if x == 0 else 50, 0))
        lathe([(0.0, -0.5), (0.05, -0.5), (0.06, -0.42), (0.03, -0.36), (0, -0.36)], brass, 20).location = (0.52, 0, 0.3)
        tube([(-0.4, 0, 0.15), (-0.05, -0.1, -0.35), (0.35, 0, 0.05)], 0, rough_mat('#5a3420', 0.6), profile=(0.006, 0.035))
    shoot(key, (10, 0, 15), 0.9)

@recipe('bones')
def r_bones(key):
    m = rough_mat(*IVORY[:1], 0.55, bumpk=0.4, col2=IVORY[1])
    for i, (loc, rot, L) in enumerate([((0, 0, -0.1), (0, 60, 10), 0.8), ((0.05, -0.1, 0.05), (0, -40, -10), 0.6), ((-0.1, -0.05, -0.3), (0, 95, 30), 0.5)]):
        ob = [cyl(0.06, L, m, (0, 0, 0))]
        for z in (-L / 2, L / 2):
            for x in (-0.05, 0.05): ob.append(sphere(0.07, m, (x, 0, z)))
        for o in ob: xform(o, (0, 0, 0), rot); xform(o, loc)
    for i in range(5):
        rnd = random.Random(i)
        rock(0.07, m, i, 0.1, 0.3, (1, 1, 0.6), (rnd.uniform(-0.4, 0.4), -0.15, rnd.uniform(-0.5, -0.35)))
    shoot(key, (15, 0, 10), 0.9)

@recipe('stone', 'brimstone', 'slag', 'obsidian', 'voidstone', 'sea_glass', 'soul_shard', 'rune_shard', 'hearth', 'core', 'trinket_shiny')
def r_stones(key):
    if key == 'stone':
        rock(0.45, rough_mat('#7a7670', 0.8, bumpk=0.6, scale=6.0), 1, 0.3, 0.8, (1.2, 1, 0.8))
    elif key == 'brimstone':
        m = rough_mat('#e8c830', 0.4, bumpk=0.3, col2='#8a6a10', sss=0.4)
        rock(0.3, rough_mat('#5a5048', 0.8, bumpk=0.5), 2, 0.2, 0.6, (1.4, 1, 0.6), (0, 0, -0.25))
        for i in range(6):
            rnd = random.Random(i)
            crystal(rnd.uniform(0.3, 0.6), rnd.uniform(0.07, 0.12), m, 6, 0.3, (rnd.uniform(-0.25, 0.25), rnd.uniform(-0.1, 0.1), -0.25), (rnd.uniform(-35, 35), rnd.uniform(-35, 35), 0), seed=i)
    elif key == 'slag':
        rock(0.45, veined('#1a1614', '#ff5010', 6.0, 3.0, 0.035, False, 0.3), 5, 0.4, 0.5, (1.2, 1, 0.8), kind='CLOUDS', facets=False)
    elif key == 'obsidian':
        ob, nt, b = _nodes('obs')
        b.inputs['Base Color'].default_value = (*rgb('#0c0a10'), 1); b.inputs['Roughness'].default_value = 0.06; b.inputs['Coat Weight'].default_value = 1.0
        crystal(1.0, 0.24, ob, 5, 0.45, (0, 0, -0.5), (0, 12, 0), 0.3, seed=2)
        crystal(0.6, 0.16, ob, 5, 0.45, (0.1, 0, -0.5), (0, -30, 0), 0.3, seed=5)
    elif key == 'voidstone':
        rock(0.45, veined('#1a1022', '#b050ff', 4.0, 3.5, 0.035, False, 0.3), 7, 0.35, 0.7, (1.1, 1, 0.9))
        sphere(0.15, emit('#c070ff', 2.0), (0, -0.2, 0))
    elif key == 'sea_glass':
        for i, c in enumerate(['#50c0a0', '#80c8e0', '#b0e0c0']):
            rnd = random.Random(i)
            g = glass(c, 0.45); g.node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value = (*rgb(c), 1)
            g.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value = 0.3
            rock(0.22, g, i, 0.2, 0.6, (1.3, 1, 0.5), ((i - 1) * 0.3, -0.05 * i, (i % 2) * 0.2 - 0.1), (rnd.uniform(0, 60), 0, rnd.uniform(0, 90)), kind='CLOUDS', facets=False)
    elif key == 'soul_shard':
        crystal(1.0, 0.24, gem('#b060ff', 0.9, 0.05), 6, 0.35, (0, 0, -0.5), (0, 10, 0), 0.15, seed=3)
        for i in range(10):
            rnd = random.Random(i)
            sphere(0.015, emit('#e0b0ff', 20.0), (rnd.uniform(-0.4, 0.4), -0.3, rnd.uniform(-0.5, 0.5)))
    elif key == 'rune_shard':
        st = rough_mat('#6a6a70', 0.8, bumpk=0.5)
        o = crystal(1.0, 0.3, st, 5, 0.4, (0, 0, -0.5), (0, 15, 0), 0.25, seed=8)
        rune = emit('#60d8ff', 10.0)
        for (x, z, w, h, a) in [(0, 0.0, 0.03, 0.4, 0), (0.07, 0.12, 0.03, 0.18, 45), (-0.07, -0.08, 0.03, 0.18, -45), (0, -0.25, 0.14, 0.03, 0)]:
            box((w, 0.02, h), rune, (x + 0.05, -0.27, z), (0, a, 0), bevel=0)
    elif key == 'hearth':
        st = rough_mat('#6a7080', 0.45, bumpk=0.3, scale=5.0, coat=0.5)
        rock(0.45, st, 4, 0.08, 0.3, (1.1, 0.6, 1.0), kind='CLOUDS', facets=False)
        torus(0.2, 0.018, emit('#60c8ff', 10.0), (0, -0.28, 0), (90, 0, 0))
        for k in range(6):
            a = 2 * math.pi * k / 6
            box((0.05, 0.02, 0.014), emit('#60c8ff', 10.0), (math.cos(a) * 0.12, -0.28, math.sin(a) * 0.12), (0, -math.degrees(a), 0), bevel=0)
        sphere(0.05, emit('#c0ecff', 14.0), (0, -0.28, 0))
    elif key == 'core':
        mt = metal('#6a6a70', 0.35)
        sphere(0.42, mt)
        for rz in (0, 60, 120):
            torus(0.425, 0.012, emit('#60d0ff', 8.0), (0, 0, 0), (90, 0, rz))
        sphere(0.13, emit('#a0f0ff', 10.0), (0, -0.36, 0))
        cyl(0.16, 0.08, mt, (0, -0.4, 0), (90, 0, 0), bevel=0.02)
    elif key == 'trinket_shiny':
        gold = metal('#f0c040', 0.18)
        for k in range(8):
            a = 2 * math.pi * k / 8
            crystal(0.3 if k % 2 else 0.2, 0.06, gold, 4, 0.8, (0, 0, 0), (0, 90 - math.degrees(a), 0), 0.0)
        cyl(0.18, 0.06, gold, (0, 0, 0), (90, 0, 0), bevel=0.02)
        gem_cut(0.13, gem('#20e060', 1.0), (0, -0.05, 0), (90, 0, 0))
        for k in range(4):
            a = 2 * math.pi * k / 4 + 0.4
            sphere(0.03, gem('#ff3040', 0.6), (math.cos(a) * 0.14, -0.05, math.sin(a) * 0.14))
    shoot(key, (10, 0, 15), 0.88)

@recipe('scale_fire', 'scale_sea', 'crab_shell')
def r_scale(key):
    if key == 'crab_shell':
        m = rough_mat('#c04a20', 0.35, bumpk=0.5, col2='#6a1a0a', coat=0.6)
        o = sphere(0.45, m, (0, 0, 0), (1.2, 0.9, 0.45))
        for i in range(7):
            a = math.pi * (0.1 + 0.8 * i / 6)
            crystal(0.14, 0.04, m, 5, 0.8, (math.cos(a) * 0.52, 0, math.sin(a) * 0.2 - 0.02), (0, 90 - math.degrees(a), 0), 0.0)
        shoot(key, (55, 0, 0), 0.9)
        return
    c = '#e04a1a' if key == 'scale_fire' else '#2aa0a0'
    m, nt, b = _nodes('scale')
    tc = _tex_coord(nt)
    sep = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(tc, sep.inputs[0])
    r = _ramp(nt, sep.outputs['Z'], [(-0.5, _shade(c, 0.35)), (0.0, c), (0.5, _shade(c, 1.5))])
    nt.links.new(r.outputs['Color'], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.22; b.inputs['Metallic'].default_value = 0.35; b.inputs['Thin Film Thickness'].default_value = 420.0
    b.inputs['Coat Weight'].default_value = 1.0
    w = nt.nodes.new('ShaderNodeTexWave'); w.inputs['Scale'].default_value = 14.0; w.bands_direction = 'Z'
    nt.links.new(tc, w.inputs['Vector']); _bump(nt, b, w.outputs['Fac'], 0.25, 0.01)
    if key == 'scale_fire':
        b.inputs['Emission Color'].default_value = (*rgb('#ff6010'), 1); b.inputs['Emission Strength'].default_value = 0.15
    out = smooth_outline([(0, 0.5), (0.32, 0.3), (0.4, -0.05), (0.24, -0.35), (0, -0.5), (-0.24, -0.35), (-0.4, -0.05), (-0.32, 0.3)], 100)
    rows = [(-0.28, [-0.24, 0.24]), (0.0, [-0.46, 0.0, 0.46]), (0.28, [-0.24, 0.24])]
    k = 0
    for z, xs in rows:
        for x in xs:
            o = sheet(out, m, 40, 0.03, 0.005, 2.0, k, lambda x2, y2: 0.35 * x2 * x2 + 0.1 * (y2 + 0.5))
            xform(o, (0, 0, 0), (0, 0, 180), 0.5); xform(o, (x, -z * 0.3 - 0.02 * k, -z))
            k += 1
    shoot(key, (25, 0, 10), 0.92)

@recipe('arrow', 'arrow_broken')
def r_arrow(key):
    sh = wood('#a07a4a', rings=20)
    steel = metal('#b0b4bc', 0.3)
    fl = ['#f0eadc', '#a02020']
    def head(loc, rot):
        o = crystal(0.2, 0.06, steel, 4, 0.7, (0, 0, 0), (0, 0, 0), 0.0)
        o.data.transform(Matrix.Diagonal((1, 0.3, 1, 1)))
        xform(o, (0, 0, 0), rot); xform(o, loc)
    if key == 'arrow':
        cyl(0.02, 1.2, sh, (0, 0, 0))
        head((0, 0, 0.58), (0, 0, 0))
        for k in range(3):
            f = feather(0.28, fl[k % 2], None, (0, 0, 0), (0, 0, 0), k)
            for o in f: xform(o, (0, 0, 0), (0, 0, 120 * k)); xform(o, (0, 0, -0.42))
        rot = (0, 45, 0)
    else:
        cyl(0.02, 0.55, sh, (-0.15, 0, 0.3), (0, 20, 0))
        head((-0.05, 0, 0.58), (0, 20, 0))
        cyl(0.02, 0.5, sh, (0.15, 0, -0.25), (0, -25, 0))
        for k in range(2):
            f = feather(0.26, fl[k % 2], None, (0, 0, 0), (0, 0, 0), k)
            for o in f: xform(o, (0, 0, 0), (0, -25, 180 * k)); xform(o, (0.22, 0, -0.38))
        rot = (0, 30, 0)
    shoot(key, rot, 0.95)

@recipe('feather')
def r_feather(key):
    feather(1.0, '#f0e8dc', '#a08a70', (0, 0, 0), (0, 0, 0), 4)
    shoot(key, (0, 35, 0), 0.95)

@recipe('bat_wing', 'moth_wing')
def r_wing(key):
    if key == 'bat_wing':
        m = rough_mat('#3a2a2a', 0.5, bumpk=0.3, sss=0.4, col2='#1a1010')
        out = [(-0.45, 0.45), (0.45, 0.4), (0.3, 0.1), (0.2, -0.05), (0.15, -0.35), (0.0, -0.1), (-0.1, -0.45), (-0.2, -0.1), (-0.35, -0.3), (-0.4, 0.05)]
        sheet(resample(out, 140), m, 70, 0.01, 0.01, 2.0, 1, lambda x, y: 0.08 * math.sin(x * 8))
        bone = rough_mat('#2a1a1a', 0.5)
        for tip in [(0.3, 0.1), (0.15, -0.35), (-0.1, -0.45), (-0.35, -0.3)]:
            tube([(-0.45, -0.02, 0.45), (tip[0], -0.03, tip[1])], 0.018, bone, taper=[(0, 1.0), (1, 0.3)])
        crystal(0.14, 0.03, bone, 4, 0.9, (-0.45, -0.02, 0.45), (0, -50, 0), 0.0)
    else:
        m, nt, b = _nodes('moth')
        tc = _tex_coord(nt)
        sep = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(tc, sep.inputs[0])
        v = nt.nodes.new('ShaderNodeTexVoronoi'); v.inputs['Scale'].default_value = 2.5
        nt.links.new(tc, v.inputs['Vector'])
        r = _ramp(nt, v.outputs['Distance'], [(0.0, '#101010'), (0.08, '#f0e0a0'), (0.14, '#6a4a2a'), (0.3, '#c8a878'), (0.6, '#a08058')])
        nt.links.new(r.outputs['Color'], b.inputs['Base Color'])
        b.inputs['Roughness'].default_value = 0.9; b.inputs['Sheen Weight'].default_value = 1.0
        out = smooth_outline([(-0.45, 0.4), (0.0, 0.48), (0.45, 0.2), (0.35, -0.2), (0.0, -0.45), (-0.4, -0.1)], 120)
        sheet(out, m, 70, 0.006, 0.01, 2.0, 2, lambda x, y: 0.05 * x * x)
        tube([(-0.45, -0.02, 0.4), (0.0, -0.02, 0.1), (0.3, -0.02, -0.1)], 0.01, rough_mat('#3a2a1a', 0.8))
        for i in range(12):
            rnd = random.Random(i)
            sphere(0.01, emit('#f0e0b0', 3.0), (rnd.uniform(-0.3, 0.4), -0.1, rnd.uniform(-0.5, -0.2)))
    shoot(key, (0, 0, 0), 0.92)

@recipe('ear')
def r_ear(key):
    m = rough_mat('#6a9a3a', 0.5, bumpk=0.3, sss=0.5, col2='#3a5a1a')
    out = smooth_outline([(-0.1, -0.5), (0.2, -0.4), (0.35, 0.0), (0.4, 0.5), (0.1, 0.15), (-0.2, 0.0), (-0.3, -0.3)], 120)
    o = sheet(out, m, 60, 0.08, 0.02, 2.0, 1, lambda x, y: -0.2 * (x - 0.05) ** 2 * 4)
    torus(0.06, 0.018, metal('#c8a050', 0.3), (0.08, -0.03, -0.35), (0, 90, 0))
    shoot(key, (0, 0, -20), 0.9)

@recipe('gland', 'goo', 'goo_void')
def r_goo(key):
    c = {'gland': '#6ab040', 'goo': '#9ad040', 'goo_void': '#8a30e0'}[key]
    m = liquid(c, 0.8 if key != 'goo_void' else 1.2)
    m.node_tree.nodes['Principled BSDF'].inputs['Transmission Weight'].default_value = 0.5
    if key == 'gland':
        rock(0.36, rough_mat('#a0c060', 0.3, bumpk=0.3, sss=0.8, col2='#5a7a2a', coat=0.8), 2, 0.1, 0.5, (1.0, 0.9, 1.2), kind='CLOUDS', facets=False)
        tube([(0, 0, 0.4), (0.05, 0, 0.55), (0.15, 0, 0.62)], 0.06, rough_mat('#8a4a4a', 0.4), taper=[(0, 1.0), (1, 0.4)])
        lathe([(0, -0.1), (0.05, -0.05), (0.06, 0.02), (0, 0.1)], m, 24).location = (0.1, -0.1, -0.45)
    else:
        rock(0.36, m, 3, 0.18, 0.4, (1.2, 1.0, 0.7), (0, 0, -0.1), kind='CLOUDS', facets=False)
        for i in range(4):
            rnd = random.Random(i)
            sphere(rnd.uniform(0.05, 0.1), m, (rnd.uniform(-0.45, 0.45), rnd.uniform(-0.2, 0.1), rnd.uniform(-0.35, -0.2)))
            sphere(0.03, glass('#ffffff', 0.0), (rnd.uniform(-0.2, 0.2), -0.3, rnd.uniform(0, 0.15)))
    shoot(key, (15, 0, 10), 0.88)

@recipe('silk', 'wool', 'straw')
def r_fibre(key):
    if key == 'straw':
        m = rough_mat('#d8b860', 0.6, bumpk=0.2, col2='#8a6a2a')
        rnd = random.Random(1)
        for i in range(30):
            x = rnd.uniform(-0.15, 0.15); y = rnd.uniform(-0.1, 0.1); a = rnd.uniform(-12, 12)
            cyl(0.014, 1.0, m, (x, y, 0), (0, a, 0), seg=8)
        torus(0.2, 0.035, rough_mat('#8a4a2a', 0.8, bumpk=0.4, scale=30), (0, 0, 0.05), scale=(1, 0.8, 1.3))
        shoot(key, (0, 30, 0), 0.92)
        return
    c = '#f4f0e8' if key == 'silk' else '#e8dcc0'
    m = fur(c, _shade(c, 0.7), 1.2 if key == 'wool' else 0.5)
    if key == 'silk': m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = 0.5
    rock(0.4, m, 5, 0.25, 0.25, (1.2, 1, 0.9), kind='CLOUDS', facets=False)
    if key == 'wool':
        for i in range(5):
            rnd = random.Random(i)
            rock(0.18, m, i + 2, 0.2, 0.2, (1, 1, 0.8), (rnd.uniform(-0.4, 0.4), -0.1, rnd.uniform(-0.3, 0.3)), kind='CLOUDS', facets=False)
    else:
        for i in range(6):
            rnd = random.Random(i)
            a = rnd.uniform(0, 6.28)
            tube([(math.cos(a) * 0.3, -0.2, math.sin(a) * 0.3), (math.cos(a) * 0.5, -0.15, math.sin(a) * 0.5 - 0.1), (math.cos(a) * 0.6, -0.1, math.sin(a) * 0.4 - 0.3)], 0.006, m, res=6)
    shoot(key, (10, 0, 10), 0.88)

@recipe('tail')
def r_tail(key):
    m = rough_mat('#d89a90', 0.5, bumpk=0.5, sss=0.4, col2='#8a5a50', scale=30)
    pts = [(-0.4 + 0.8 * t / 20, 0, 0.35 * math.sin(t / 20 * 5.5) * (1 - t / 30)) for t in range(21)]
    tube(pts, 0.06, m, taper=[(0, 1.0), (1, 0.1)])
    rock(0.08, fur('#6a5a50'), 1, 0.05, 0.3, (1, 1, 1), (-0.42, 0, 0))
    shoot(key, (0, 20, 0), 0.92)

@recipe('dust', 'purse')
def r_pouch(key):
    lea = rough_mat('#6a4a2a' if key == 'purse' else '#5a4a6a', 0.6, bumpk=0.4, scale=14)
    o = lathe([(0, -0.45), (0.3, -0.42), (0.4, -0.2), (0.34, 0.05), (0.14, 0.18), (0.12, 0.24), (0.22, 0.38), (0.0, 0.34)], lea, 40)
    mod(o, 'DISPLACE', texture=bpy.data.textures.new('pp', 'CLOUDS'), strength=0.04); apply(o)
    torus(0.13, 0.025, rough_mat('#c8a060', 0.7, bumpk=0.3, scale=30), (0, 0, 0.2))
    tube([(0.1, -0.05, 0.2), (0.25, -0.12, 0.0), (0.3, -0.12, -0.15)], 0.015, rough_mat('#c8a060', 0.7))
    if key == 'purse':
        gold = metal('#e8b848', 0.22)
        for i, (x, z, rx) in enumerate([(0.35, -0.42, 70), (0.5, -0.46, 85), (0.2, -0.47, 90)]):
            cyl(0.1, 0.025, gold, (x, -0.2, z), (rx, 0, 30 * i), bevel=0.008)
    else:
        for i in range(30):
            rnd = random.Random(i)
            sphere(rnd.uniform(0.006, 0.014), emit('#f0e0ff', 15.0), (rnd.uniform(0.2, 0.6), rnd.uniform(-0.3, -0.1), rnd.uniform(-0.5, -0.3)))
        rock(0.12, rough_mat('#d8c8e8', 0.9, bumpk=0.2), 1, 0.1, 0.3, (2.0, 1, 0.3), (0.42, -0.2, -0.46), kind='CLOUDS', facets=False)
    shoot(key, (15, 0, 10), 0.88)

@recipe('ink')
def r_ink(key):
    g = glass('#202040', 0.05)
    lathe([(0, -0.4), (0.3, -0.4), (0.34, -0.36), (0.34, -0.05), (0.18, 0.05), (0.14, 0.12), (0.16, 0.16), (0, 0.16)], g, 8)
    lathe([(0, -0.37), (0.28, -0.37), (0.28, -0.1), (0, -0.1)], liquid('#0a0a20', 0.0), 8)
    feather(0.95, '#f4f0e8', '#8a8070', (0.02, 0, 0.35), (0, 25, 0), 1)
    shoot(key, (10, 0, 20), 0.9)

@recipe('cask')
def r_cask(key):
    w = wood('#8a5a30', rings=18)
    w2 = w.copy()
    o = lathe([(0, -0.45), (0.32, -0.45), (0.38, -0.2), (0.4, 0.0), (0.38, 0.2), (0.32, 0.45), (0, 0.45)], w, 16)
    for p in o.data.polygons: p.use_smooth = False
    iron = metal('#3a3634', 0.5)
    for z, r in ((-0.35, 0.35), (0.35, 0.35), (-0.12, 0.395), (0.12, 0.395)): torus(r, 0.02, iron, (0, 0, z), scale=(1, 1, 1.8))
    cyl(0.04, 0.12, wood('#6a4020'), (0, -0.42, -0.1), (90, 0, 0))
    xform_all = [o for o in bpy.data.objects if o.type == 'MESH']
    group(xform_all, (0, 0, 0), (0, 90, 0))
    shoot(key, (15, 0, 25), 0.9)

@recipe('driftwood', 'totem')
def r_wood(key):
    if key == 'driftwood':
        m = wood('#b0a898', '#6a645a', rings=14, rough=0.8)
        tube([(-0.5, 0, -0.2), (-0.2, 0, 0.0), (0.1, 0, -0.05), (0.5, 0, 0.2)], 0.12, m, taper=[(0, 0.8), (0.5, 1.0), (1, 0.5)])
        tube([(-0.05, 0, -0.03), (0.1, 0, 0.2), (0.15, 0.0, 0.4)], 0.06, m, taper=[(0, 1.0), (1, 0.2)])
        tube([(0.2, 0, 0.0), (0.35, 0, -0.2)], 0.04, m, taper=[(0, 1.0), (1, 0.2)])
    else:
        m = wood('#7a5230', rings=10)
        cyl(0.24, 0.9, m, (0, 0, 0), seg=10)
        paint = emit('#c02020', 1.5)
        for z in (0.3, -0.05):
            for x in (-0.1, 0.1): sphere(0.05, rough_mat('#e8e0c0', 0.6, bumpk=0), (x, -0.23, z))
            box((0.3, 0.04, 0.05), paint, (0, -0.23, z - 0.12), bevel=0.01)
        for s in (-1, 1): box((0.25, 0.06, 0.1), m, (s * 0.32, 0, 0.35), (0, s * -20, 0), bevel=0.02)
        o = rock(0.3, m, 4, 0.15, 0.3, (0.85, 0.85, 0.3), (0, 0, 0.48))
        for i in range(4):
            rnd = random.Random(i)
            box((0.12, 0.05, 0.05), m, (rnd.uniform(-0.4, 0.4), -0.1, -0.5), (0, rnd.uniform(0, 90), rnd.uniform(0, 90)), bevel=0.01)
    shoot(key, (10, 0, 15), 0.9)

@recipe('bell')
def r_bell(key):
    brass = metal('#c89a40', 0.28)
    bell_shape(brass, 1.8, (0, 0, 0.1))
    sphere(0.09, brass, (0.05, -0.05, -0.45))
    tube([(0, 0, 0.28), (0.0, 0, 0.45), (-0.15, 0, 0.5), (-0.3, 0, 0.35)], 0, cloth('#a02020', weave=120, sheen=1.0), profile=(0.006, 0.05))
    shoot(key, (10, 0, 20), 0.88)

# ------------------------------------------------------------------ run
def keys():
    with open(os.path.join(ROOT, 'art', 'item_keys.txt')) as f:
        return [l.split('\t')[0] for l in f if l.strip()]

if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    todo = [k for k in keys() if not k.startswith('e_') and (not argv or any(k.startswith(a) for a in argv))]
    missing = [k for k in todo if k not in R]
    if missing: print('NO RECIPE:', missing)
    for k in todo:
        if k not in R: continue
        stage()
        try: R[k](k)
        except Exception as e:
            import traceback; traceback.print_exc(); print('FAILED', k, e, flush=True)
