"""
Icons for Ashvale Online, rendered in Blender (Cycles): every ability, item and material gets a little
lit scene — a real object or a real effect, with a key light, a rim light, glow and a soft painted
background — so the icons look like finished art, not symbols.

    python3 art/icons.py                  # everything
    python3 art/icons.py fireball sword   # only these
Writes godot/assets/icons/<name>.png (256 x 256). The game frames them (quality border, cooldown sweep).
"""
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, Euler

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'godot', 'assets', 'icons'); os.makedirs(OUT, exist_ok=True)
WEAPONS = os.path.join(ROOT, 'godot', 'assets', 'weapons')
SIZE = 256

def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def rgb(h):
    h = h.lstrip('#'); return tuple(lin(int(h[i:i + 2], 16) / 255) for i in (0, 2, 4))

# ------------------------------------------------------------------ the stage

def reset(bg_top='#2a2230', bg_bot='#0c0a10', glare=0.55):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = 64
    sc.cycles.use_denoising = True; sc.cycles.use_adaptive_sampling = True
    sc.render.resolution_x = SIZE; sc.render.resolution_y = SIZE; sc.render.film_transparent = False
    sc.view_settings.view_transform = 'AgX'; sc.view_settings.look = 'AgX - Punchy'
    sc.cycles.max_bounces = 6; sc.cycles.transparent_max_bounces = 12
    # the painted background: a vertical gradient with a soft glow behind the subject
    w = bpy.data.worlds.new('W'); sc.world = w; w.use_nodes = True
    nt = w.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputWorld'); bgn = nt.nodes.new('ShaderNodeBackground'); bgn.inputs[1].default_value = 1.0
    nt.links.new(bgn.outputs[0], out.inputs[0])
    bgn.inputs[0].default_value = (*rgb(bg_bot), 1)
    cam_data = bpy.data.cameras.new('C'); cam_data.type = 'ORTHO'; cam_data.ortho_scale = 2.0
    cam = bpy.data.objects.new('Cam', cam_data); bpy.context.collection.objects.link(cam)
    cam.location = (0, -6, 0); cam.rotation_euler = (math.radians(90), 0, 0); sc.camera = cam
    backdrop(bg_top, bg_bot)
    # compositor: bloom for anything that glows, and a gentle vignette
    sc.use_nodes = True; ct = sc.node_tree; ct.nodes.clear()
    rl = ct.nodes.new('CompositorNodeRLayers'); comp = ct.nodes.new('CompositorNodeComposite')
    gl = ct.nodes.new('CompositorNodeGlare'); gl.glare_type = 'FOG_GLOW'; gl.quality = 'HIGH'; gl.size = 7; gl.mix = glare - 1.0 if glare < 1 else 0.0
    gl.threshold = 0.9
    ellipse = ct.nodes.new('CompositorNodeEllipseMask'); ellipse.width = 0.95; ellipse.height = 0.95
    blur = ct.nodes.new('CompositorNodeBlur'); blur.size_x = 60; blur.size_y = 60
    mix = ct.nodes.new('CompositorNodeMixRGB'); mix.blend_type = 'MULTIPLY'
    ct.links.new(rl.outputs[0], gl.inputs[0])
    ct.links.new(ellipse.outputs[0], blur.inputs[0])
    vig = ct.nodes.new('CompositorNodeMapRange'); vig.inputs[3].default_value = 0.6; vig.inputs[4].default_value = 1.0
    ct.links.new(blur.outputs[0], vig.inputs[0])
    ct.links.new(gl.outputs[0], mix.inputs[1]); ct.links.new(vig.outputs[0], mix.inputs[2])
    ct.links.new(mix.outputs[0], comp.inputs[0])
    return sc

def backdrop(top, bot, strength=1.6):
    """a card behind everything: a soft radial glow (top colour) fading to the edge colour, with painterly noise"""
    bpy.ops.mesh.primitive_plane_add(size=2.4, location=(0, 3, 0), rotation=(math.radians(90), 0, 0))
    p = bpy.context.active_object
    m = bpy.data.materials.new('bg'); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); em = nt.nodes.new('ShaderNodeEmission')
    tc = nt.nodes.new('ShaderNodeTexCoord')
    mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Location'].default_value = (0.0, -0.15, 0); mp.inputs['Scale'].default_value = (0.95, 0.95, 1.0)
    grad = nt.nodes.new('ShaderNodeTexGradient'); grad.gradient_type = 'SPHERICAL'
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].color = (*rgb(bot), 1); ramp.color_ramp.elements[1].color = (*rgb(top), 1)
    ramp.color_ramp.elements[0].position = 0.0; ramp.color_ramp.elements[1].position = 0.85
    noise = nt.nodes.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value = 5.0; noise.inputs['Detail'].default_value = 8.0; noise.inputs['Roughness'].default_value = 0.6
    mixn = nt.nodes.new('ShaderNodeMixRGB'); mixn.blend_type = 'OVERLAY'; mixn.inputs[0].default_value = 0.3
    nt.links.new(tc.outputs['Object'], mp.inputs[0]); nt.links.new(mp.outputs[0], grad.inputs[0])
    nt.links.new(grad.outputs['Fac'], ramp.inputs[0])
    nt.links.new(tc.outputs['Object'], noise.inputs['Vector'])
    nt.links.new(ramp.outputs[0], mixn.inputs[1]); nt.links.new(noise.outputs['Color'], mixn.inputs[2])
    nt.links.new(mixn.outputs[0], em.inputs[0]); em.inputs[1].default_value = strength
    nt.links.new(em.outputs[0], out.inputs[0])
    p.data.materials.append(m)
    p.visible_shadow = False; p.visible_diffuse = False; p.visible_glossy = False
    return p

def light(kind, loc, energy, color='#ffffff', size=1.0, target=(0, 0, 0)):
    d = bpy.data.lights.new('L', kind); d.energy = energy; d.color = rgb(color)
    if kind == 'AREA': d.size = size
    o = bpy.data.objects.new('L', d); bpy.context.collection.objects.link(o); o.location = loc
    direction = Vector(target) - Vector(loc); o.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    return o

def studio(key='#fff1dc', rim='#8fb4ff', key_e=260, rim_e=380):
    light('AREA', (-2.5, -3.5, 3.0), key_e, key, 2.5)
    light('AREA', (2.8, 1.5, 1.8), rim_e, rim, 1.5)
    light('AREA', (0.5, -3.0, -2.5), key_e * 0.25, '#ffd9b0', 3.0)

def mat_emit(name, color, strength):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial'); em = nt.nodes.new('ShaderNodeEmission')
    em.inputs[0].default_value = (*rgb(color), 1); em.inputs[1].default_value = strength
    nt.links.new(em.outputs[0], out.inputs[0]); return m

def mat_pbr(name, color, metal=0.0, rough=0.5, emit=None, emit_s=0.0, transmission=0.0, ior=1.45):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*rgb(color), 1); b.inputs['Metallic'].default_value = metal; b.inputs['Roughness'].default_value = rough
    if transmission: b.inputs['Transmission Weight'].default_value = transmission; b.inputs['IOR'].default_value = ior
    if emit: b.inputs['Emission Color'].default_value = (*rgb(emit), 1); b.inputs['Emission Strength'].default_value = emit_s
    return m

def fire_material(name, hot='#fff2b0', mid='#ff8a1c', cool='#b3200a', scale=3.0, strength=14.0, seed=0.0):
    """flame: layered noise driving a colour ramp and emission; alpha follows the ramp so edges fray"""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    tc = nt.nodes.new('ShaderNodeTexCoord'); noise = nt.nodes.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = scale; noise.inputs['Detail'].default_value = 8.0; noise.inputs['Distortion'].default_value = 1.4
    noise.noise_dimensions = '4D'; noise.inputs['W'].default_value = seed
    lw = nt.nodes.new('ShaderNodeLayerWeight'); lw.inputs[0].default_value = 0.35
    mul = nt.nodes.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'
    inv = nt.nodes.new('ShaderNodeMath'); inv.operation = 'SUBTRACT'; inv.inputs[0].default_value = 1.0
    nt.links.new(lw.outputs['Facing'], inv.inputs[1])
    nt.links.new(tc.outputs['Object'], noise.inputs['Vector'])
    nt.links.new(noise.outputs['Fac'], mul.inputs[0]); nt.links.new(inv.outputs[0], mul.inputs[1])
    ramp = nt.nodes.new('ShaderNodeValToRGB'); r = ramp.color_ramp
    r.elements[0].position = 0.12; r.elements[0].color = (*rgb(cool), 0)
    r.elements[1].position = 0.62; r.elements[1].color = (*rgb(hot), 1)
    e = r.elements.new(0.34); e.color = (*rgb(mid), 1)
    nt.links.new(mul.outputs[0], ramp.inputs[0])
    em = nt.nodes.new('ShaderNodeEmission'); em.inputs[1].default_value = strength
    nt.links.new(ramp.outputs['Color'], em.inputs[0])
    tr = nt.nodes.new('ShaderNodeBsdfTransparent'); mix = nt.nodes.new('ShaderNodeMixShader')
    nt.links.new(ramp.outputs['Alpha'], mix.inputs[0]); nt.links.new(tr.outputs[0], mix.inputs[1]); nt.links.new(em.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs[0])
    m.blend_method = 'BLEND' if hasattr(m, 'blend_method') else None
    return m

def ball(r, loc, material, sub=4, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=48, ring_count=24)
    o = bpy.context.active_object; o.scale = scale
    bpy.ops.object.shade_smooth()
    o.data.materials.append(material); return o

def render(name):
    sc = bpy.context.scene
    sc.render.filepath = os.path.join(OUT, name + '.png')
    bpy.ops.render.render(write_still=True)
    print('icon', name)

def import_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o not in before]
    return objs

def frame_objects(objs, fill=0.82, rot=(0, 0, 0)):
    """parent the meshes to an empty, turn it, and scale it to fill the icon"""
    root = bpy.data.objects.new('root', None); bpy.context.collection.objects.link(root)
    for o in objs:
        if o.parent is None: o.parent = root
    root.rotation_euler = Euler([math.radians(a) for a in rot])
    bpy.context.view_layer.update()
    lo = Vector((1e9, 1e9, 1e9)); hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        if o.type != 'MESH': continue
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector((min(lo.x, w.x), min(lo.y, w.y), min(lo.z, w.z))); hi = Vector((max(hi.x, w.x), max(hi.y, w.y), max(hi.z, w.z)))
    size = max(hi.x - lo.x, hi.z - lo.z)
    s = 2.0 * fill / size
    root.scale = (s, s, s)
    bpy.context.view_layer.update()
    ctr = (lo + hi) / 2.0
    root.location = -ctr * s
    return root

def fire_volume(name, loc, scale, rot=(0, 0, 0), hot='#fff3c0', mid='#ff7a14', cool='#7a1004', dens=9.0, glow=70.0, nscale=2.6, seed=0.0, falloff=1.4):
    """real volumetric fire: noise inside a soft ball, emitting by how dense it is (hot core, dark red edges)"""
    bpy.ops.mesh.primitive_ico_sphere_add(radius=1.0, subdivisions=3, location=loc)
    o = bpy.context.active_object; o.scale = scale; o.rotation_euler = Euler([math.radians(a) for a in rot])
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    tc = nt.nodes.new('ShaderNodeTexCoord')
    ln = nt.nodes.new('ShaderNodeVectorMath'); ln.operation = 'LENGTH'
    nt.links.new(tc.outputs['Object'], ln.inputs[0])
    fall = nt.nodes.new('ShaderNodeMath'); fall.operation = 'SUBTRACT'; fall.inputs[0].default_value = 1.0
    nt.links.new(ln.outputs['Value'], fall.inputs[1])
    powr = nt.nodes.new('ShaderNodeMath'); powr.operation = 'POWER'; powr.inputs[1].default_value = falloff; powr.use_clamp = True
    nt.links.new(fall.outputs[0], powr.inputs[0])
    noise = nt.nodes.new('ShaderNodeTexNoise'); noise.noise_dimensions = '4D'; noise.inputs['W'].default_value = seed
    noise.inputs['Scale'].default_value = nscale; noise.inputs['Detail'].default_value = 12.0; noise.inputs['Roughness'].default_value = 0.62; noise.inputs['Distortion'].default_value = 0.9
    nt.links.new(tc.outputs['Object'], noise.inputs['Vector'])
    sh = nt.nodes.new('ShaderNodeMapRange'); sh.inputs['From Min'].default_value = 0.35; sh.inputs['From Max'].default_value = 0.75
    nt.links.new(noise.outputs['Fac'], sh.inputs['Value'])
    f = nt.nodes.new('ShaderNodeMath'); f.operation = 'MULTIPLY'
    nt.links.new(sh.outputs['Result'], f.inputs[0]); nt.links.new(powr.outputs[0], f.inputs[1])
    ramp = nt.nodes.new('ShaderNodeValToRGB'); r = ramp.color_ramp
    r.elements[0].position = 0.0; r.elements[0].color = (*rgb(cool), 1)
    r.elements[1].position = 0.55; r.elements[1].color = (*rgb(hot), 1)
    e = r.elements.new(0.22); e.color = (*rgb(mid), 1)
    nt.links.new(f.outputs[0], ramp.inputs[0])
    dm = nt.nodes.new('ShaderNodeMath'); dm.operation = 'MULTIPLY'; dm.inputs[1].default_value = dens
    nt.links.new(f.outputs[0], dm.inputs[0])
    sq = nt.nodes.new('ShaderNodeMath'); sq.operation = 'POWER'; sq.inputs[1].default_value = 2.0
    nt.links.new(f.outputs[0], sq.inputs[0])
    gm = nt.nodes.new('ShaderNodeMath'); gm.operation = 'MULTIPLY'; gm.inputs[1].default_value = glow
    nt.links.new(sq.outputs[0], gm.inputs[0])
    vol = nt.nodes.new('ShaderNodeVolumePrincipled')
    vol.inputs['Color'].default_value = (0.05, 0.02, 0.01, 1)
    nt.links.new(dm.outputs[0], vol.inputs['Density'])
    nt.links.new(ramp.outputs['Color'], vol.inputs['Emission Color'])
    nt.links.new(gm.outputs[0], vol.inputs['Emission Strength'])
    nt.links.new(vol.outputs[0], out.inputs['Volume'])
    o.data.materials.append(m)
    return o

# ------------------------------------------------------------------ subjects

def icon_fireball():
    reset('#6a2a12', '#140606', glare=0.55)
    bpy.context.scene.cycles.volume_step_rate = 0.5
    random.seed(3)
    # the head, travelling up and to the right, and its tail streaming out behind
    fire_volume('head', (0.16, 0, 0.16), (0.58, 0.58, 0.56), seed=1.0, glow=420.0, dens=40.0, falloff=0.7, nscale=2.2)
    fire_volume('tail', (-0.3, 0.05, -0.3), (0.95, 0.46, 0.4), rot=(0, 45, 0), seed=4.0, glow=260.0, dens=30.0, nscale=2.8, falloff=0.9,
        hot='#ffd27a', mid='#ff5a10', cool='#4a0802')
    fire_volume('wisp', (-0.68, 0.1, -0.64), (0.6, 0.3, 0.24), rot=(0, 45, 0), seed=7.0, glow=160.0, dens=22.0, nscale=3.6, falloff=1.1,
        hot='#ffb050', mid='#e0400a', cool='#300602')
    ball(0.1, (0.18, -0.05, 0.18), mat_emit('core', '#fff8e0', 12.0))
    # a few embers thrown off the tail
    em = mat_emit('ember', '#ffb347', 25.0)
    for k in range(9):
        t = random.uniform(0.2, 1.0)
        base = Vector((0.1 - t * 0.9, -0.4, 0.1 - t * 0.9))
        side = Vector((1, 0, -1)).normalized() * random.uniform(-0.45, 0.45)
        ball(random.uniform(0.008, 0.018) * (1.2 - t * 0.6), base + side, em)
    light('POINT', (0.2, -0.9, 0.2), 90, '#ff9a40')
    render('fireball')

def icon_sword(name='sword_item', model='long', rot=(0, 45, 0)):
    reset('#3a3f4c', '#0d0f14', glare=0.2)
    objs = import_glb(os.path.join(WEAPONS, model + '.glb'))
    frame_objects(objs, 0.9, rot)
    studio()
    render(name)

ICONS = {'fireball': icon_fireball, 'sword': icon_sword}


# ------------------------------------------------------------------ sprites for the painted spell icons
SPRITES = os.path.join(ROOT, 'art', '_sprites'); os.makedirs(SPRITES, exist_ok=True)

def sprite(name, model, rot, fill=0.9, key='#fff1dc', rim='#9fc0ff'):
    """a weapon on a transparent background, lit like the icons (the painter adds motion and magic)"""
    reset()
    sc = bpy.context.scene; sc.render.film_transparent = True
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and o.name.startswith('Plane'): bpy.data.objects.remove(o)
    sc.use_nodes = False
    sc.render.resolution_x = sc.render.resolution_y = 512
    objs = import_glb(os.path.join(WEAPONS, model + '.glb'))
    frame_objects(objs, fill, rot)
    studio(key, rim)
    sc.render.filepath = os.path.join(SPRITES, name + '.png')
    bpy.ops.render.render(write_still=True); print('sprite', name)

def all_sprites():
    for name, model, rot in [('sword', 'long', (0, 45, 0)), ('sword_up', 'long', (0, 0, 0)), ('axe', 'greataxe', (0, 40, 0)), ('mace', 'club', (0, 40, 0)),
            ('staff', 'crystalstaff', (0, 30, 0)), ('wand', 'wand', (0, 40, 0)), ('skullstaff', 'skullstaff', (0, 30, 0)), ('dagger', 'dagger', (0, 45, 0)),
            ('emberstaff', 'emberstaff', (0, 30, 0)), ('worldbreaker', 'worldbreaker', (0, 40, 0)), ('moon', 'moon', (0, 30, 0)), ('eternity', 'eternity', (0, 30, 0))]:
        sprite(name, model, rot)

def creature_sprite(name, path, rot, fill=0.9):
    reset()
    sc = bpy.context.scene; sc.render.film_transparent = True
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and o.name.startswith('Plane'): bpy.data.objects.remove(o)
    sc.use_nodes = False
    sc.render.resolution_x = sc.render.resolution_y = 512
    objs = import_glb(path)
    frame_objects(objs, fill, rot)
    studio('#fff1dc', '#bcd4ff')
    sc.render.filepath = os.path.join(SPRITES, name + '.png')
    bpy.ops.render.render(write_still=True); print('sprite', name)

def creature_sprites():
    creature_sprite('stag', os.path.join(ROOT, 'godot', 'assets', 'creatures', 'deer.glb'), (0, 0, -60))

ICONS['sprites'] = all_sprites
ICONS['creatures'] = creature_sprites

if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    for n in (argv or list(ICONS)): ICONS[n]()
