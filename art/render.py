"""
Ashvale sprite renderer — turns a 3D model + animations into game sprite frames.

    python3 art/render.py art/jobs/knight.json            # render every direction/animation of a job
    python3 art/render.py art/jobs/knight.json --dirs 4   # only direction 4 (south, facing the camera)
    python3 art/render.py art/jobs/knight.json --anims idle,walk --quick   # fast preview (few samples)

Needs the `bpy` Python module (pip install bpy==4.5.*). Renders with Cycles on the CPU; ~1–2 s a frame.
Output: art/_render/<job name>/<anim>_<dir>_<frame>.png plus meta.json; then run art/pack.py to build
the atlas the game loads (assets/sprites/<name>.png + .json).

The camera matches the game's world: an orthographic view pitched so that a 1×1 ground tile appears
48 px wide and 32 px tall (Legend of Mir 2's tile), and 8 facing directions numbered clockwise from
north (0 = facing away from the camera, 4 = facing the camera). The sun is fixed in the world (upper
left), so a character's lit side changes as it turns — as it should.
"""
import bpy, sys, os, json, math, time, argparse
from mathutils import Vector, Euler, Matrix

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ELEV = math.degrees(math.asin(32 / 48))          # camera elevation above the horizon: 41.81°

def parse():
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser()
    ap.add_argument('job'); ap.add_argument('--dirs'); ap.add_argument('--anims'); ap.add_argument('--quick', action='store_true')
    ap.add_argument('--out')
    return ap.parse_args(argv)

def load_job(path):
    job = json.load(open(path))
    base = {"size": 320, "ortho": 6.125, "shift": 0.2, "dirs": 8, "render_dirs": None, "samples": 16, "kind": "character",
            "hide": [], "parts": None, "sun": [28, 0, 0], "key": 3.6, "fill": 1.4, "ambient": 1.0, "shadow": False, "tint": None, "denoise": True, "dnfast": True}
    base.update(job); return base

def import_model(path):
    before = set(bpy.data.objects)
    ext = os.path.splitext(path)[1].lower()
    if ext in ('.glb', '.gltf'): bpy.ops.import_scene.gltf(filepath=path)
    elif ext == '.fbx': bpy.ops.import_scene.fbx(filepath=path)
    elif ext == '.blend':
        with bpy.data.libraries.load(path) as (src, dst): dst.objects = src.objects; dst.actions = src.actions
        for o in dst.objects:
            if o is not None: bpy.context.scene.collection.objects.link(o)
    else: raise SystemExit('unsupported model ' + path)
    return [o for o in bpy.data.objects if o not in before]

def setup_scene(job):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'
    sc.cycles.samples = 4 if job.get('_quick') else job['samples']
    sc.cycles.use_denoising = job['denoise'] and not job.get('_quick'); sc.cycles.use_adaptive_sampling = True
    if job.get('dnfast'): sc.cycles.denoising_prefilter = 'FAST'; sc.cycles.denoising_quality = 'FAST'
    if job.get('bounces'):
        c = sc.cycles; c.max_bounces = job['bounces']; c.diffuse_bounces = min(2, job['bounces']); c.glossy_bounces = 1
        c.transmission_bounces = 0; c.volume_bounces = 0; c.transparent_max_bounces = 4
        c.caustics_reflective = False; c.caustics_refractive = False; c.sample_clamp_indirect = 2.0
    sc.render.film_transparent = True
    sc.render.resolution_x = sc.render.resolution_y = job['size']; sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGBA'
    sc.view_settings.view_transform = 'Standard'; sc.view_settings.look = 'None'
    # camera
    cd = bpy.data.cameras.new('cam'); cd.type = 'ORTHO'; cd.ortho_scale = job['ortho']; cd.shift_y = job['shift']
    cam = bpy.data.objects.new('cam', cd); sc.collection.objects.link(cam); sc.camera = cam
    d = 30.0
    cam.location = Vector((0, -d * math.cos(math.radians(ELEV)), d * math.sin(math.radians(ELEV))))
    cam.rotation_euler = Euler((math.radians(90 - ELEV), 0, 0), 'XYZ')
    # lights: warm key from the upper left front, cool fill from behind right, soft ambient
    def sun(name, energy, rot, color, angle):
        ld = bpy.data.lights.new(name, 'SUN'); ld.energy = energy; ld.color = color; ld.angle = math.radians(angle)
        lo = bpy.data.objects.new(name, ld); sc.collection.objects.link(lo); lo.location = (0, 0, 10)
        lo.rotation_euler = Euler([math.radians(a) for a in rot]); return lo
    sun('key', job['key'], job['sun'], (1.0, 0.94, 0.84), 5)
    sun('fill', job['fill'], (60, 30, 150), (0.72, 0.82, 1.0), 25)
    sun('rim', job['fill'] * 0.9, (35, 0, 180), (0.95, 0.95, 1.0), 10)
    sc.world = bpy.data.worlds.new('w'); sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes['Background']; bg.inputs[0].default_value = (0.42, 0.44, 0.5, 1); bg.inputs[1].default_value = job['ambient']
    # ground shadow catcher
    if job['shadow']:
        bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0)); g = bpy.context.object; g.name = 'ground'; g.is_shadow_catcher = True
    # turntable
    tt = bpy.data.objects.new('turntable', None); sc.collection.objects.link(tt)
    return sc, tt

def hide(o, on=True):
    o.hide_render = on; o.hide_viewport = on

def tint_materials(objs, rgb):
    """Multiply every material's base colour by rgb (for cheap tier/variant recolours)."""
    for o in objs:
        if o.type != 'MESH': continue
        for slot in o.material_slots:
            m = slot.material
            if not m or not m.use_nodes: continue
            bsdf = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
            if not bsdf: continue
            base = bsdf.inputs['Base Color']
            if base.is_linked:
                src = base.links[0].from_socket
                mix = m.node_tree.nodes.new('ShaderNodeMix'); mix.data_type = 'RGBA'; mix.blend_type = 'MULTIPLY'; mix.inputs[0].default_value = 1.0
                mix.inputs[7].default_value = (*rgb, 1)
                m.node_tree.links.new(src, mix.inputs[6]); m.node_tree.links.new(mix.outputs[2], base)
            else:
                c = base.default_value; base.default_value = (c[0] * rgb[0], c[1] * rgb[1], c[2] * rgb[2], 1)

def uv_filter(o, keep=None, drop=None):
    """Delete faces of mesh object o by which palette cell (8 cols x 4 rows) their UVs sit in.
    KayKit textures are palettes, so a cell is a material: (0,0) skin, (1,0) hair, (2,0) eyes..."""
    import bmesh
    bm = bmesh.new(); bm.from_mesh(o.data); uvl = bm.loops.layers.uv.active
    keep = [tuple(c) for c in keep] if keep else None; drop = [tuple(c) for c in drop] if drop else []
    kill = []
    for f in bm.faces:
        u = sum(l[uvl].uv[0] for l in f.loops) / len(f.loops); v = sum(l[uvl].uv[1] for l in f.loops) / len(f.loops)
        cell = (min(7, max(0, int(u * 8))), min(3, max(0, int((1 - v) * 4))))
        if (keep is not None and cell not in keep) or cell in drop: kill.append(f)
    bmesh.ops.delete(bm, geom=kill, context='FACES'); bm.to_mesh(o.data); bm.free(); o.data.update()

def make_holdouts(sc, rig_objs, specs):
    """Copies of meshes from the rig file rendered as holdouts: invisible, but they hide whatever is
    behind them. A layer rendered this way carries its own occlusion, so it can be drawn on top."""
    outs = []
    for sp in specs:
        if isinstance(sp, str): sp = {"mesh": sp}
        src = next((o for o in rig_objs if o.name == sp['mesh']), None)
        if src is None: print('!! holdout mesh not found', sp['mesh']); continue
        c = src.copy(); c.data = src.data.copy(); sc.collection.objects.link(c)
        if sp.get('uv_keep') or sp.get('uv_drop'): uv_filter(c, sp.get('uv_keep'), sp.get('uv_drop'))
        hide(c, False); c.is_holdout = True; outs.append(c)
        # occlude only: no shadows or bounce light, so both passes of a layer are lit identically
        c.visible_shadow = False; c.visible_diffuse = False; c.visible_glossy = False; c.visible_transmission = False
    return outs

def sample_frames(a0, a1, n, loop):
    if n <= 1: return [a0]
    span = a1 - a0
    if loop: return [a0 + span * i / n for i in range(n)]
    return [a0 + span * i / (n - 1) for i in range(n)]

def main():
    args = parse(); job = load_job(args.job); job['_quick'] = args.quick
    name = job['name']; out = args.out or os.path.join(ROOT, 'art', '_render', name); os.makedirs(out, exist_ok=True)
    sc, tt = setup_scene(job)

    # --- the rig (character) ---
    rig_path = os.path.join(ROOT, job.get('rig') or job['model'])
    rig_objs = import_model(rig_path)
    arm = next(o for o in rig_objs if o.type == 'ARMATURE')
    prefix = job.get('prefix')  # body meshes start with this; others in the file (spare weapons) are hidden
    parts = job.get('parts')    # or an explicit list of mesh names (a layer: body only, helmet only, ...)
    for o in rig_objs:
        if o.type == 'MESH':
            spare = (parts is not None and o.name not in parts) or (parts is None and prefix and not o.name.startswith(prefix)) or o.name in job['hide']
            if spare: hide(o)
    # holdouts (occluders that render transparent) are copied before the visible meshes are trimmed
    holds = make_holdouts(sc, rig_objs, job.get('holdout', []))
    two_pass = bool(job.get('two_pass')) and bool(holds)
    for mname, cells in (job.get('uv_keep') or {}).items(): uv_filter(bpy.data.objects[mname], keep=cells)
    for mname, cells in (job.get('uv_drop') or {}).items(): uv_filter(bpy.data.objects[mname], drop=cells)
    # parent the rig to the turntable so rotating the turntable turns the whole character
    arm.parent = tt
    if job.get('tint'): tint_materials(rig_objs, job['tint'])
    if job.get('texture'):  # swap the body texture (tiers / variants)
        img = bpy.data.images.load(os.path.join(ROOT, job['texture']))
        for o in rig_objs:
            if o.type != 'MESH': continue
            for slot in o.material_slots:
                m = slot.material
                if m and m.use_nodes:
                    for n in m.node_tree.nodes:
                        if n.type == 'TEX_IMAGE': n.image = img

    # --- extra meshes rendered together with the body (monsters holding weapons) ---
    for att in job.get('attach', []):
        aobjs = import_model(os.path.join(ROOT, att['model']))
        for w in aobjs:
            if w.type == 'MESH':
                w.parent = arm; w.parent_type = 'BONE'; w.parent_bone = att.get('bone', 'handslot.r')
                w.matrix_parent_inverse = Matrix.Identity(4); w.rotation_mode = 'XYZ'
                w.location = tuple(att.get('loc', (0, -0.079, 0)))
                w.rotation_euler = Euler([math.radians(a) for a in att.get('rot', (-90, 0, 0))])
                w.scale = (att.get('scale', 1.0),) * 3

    # --- extra models built in the rig's rest space (helmets, crowns, monster heads): parent them to a
    #     bone so they follow it, keeping exactly where they were modelled ---
    for att in job.get('attach_rest', []):
        bone = arm.data.bones[att.get('bone', 'head')]
        rest = arm.matrix_world @ bone.matrix_local @ Matrix.Translation((0, bone.length, 0))   # bone children hang from the tail
        for w in import_model(os.path.join(ROOT, att['model'])):
            if w.type != 'MESH': continue
            mw = w.matrix_world.copy()
            if att.get('scale') or att.get('offset'):   # refit (e.g. a crown made for the adventurer head onto a skull)
                pc = Vector(att.get('pivot', (0, -.02, 1.76))); sc_ = att.get('scale', 1)
                mw = Matrix.Translation(Vector(att.get('offset', (0, 0, 0))) + pc) @ Matrix.Scale(sc_, 4) @ Matrix.Translation(-pc) @ mw
            w.parent = arm; w.parent_type = 'BONE'; w.parent_bone = bone.name
            w.matrix_parent_inverse = rest.inverted(); w.matrix_basis = mw
            if att.get('tint'): tint_materials([w], att['tint'])

    # --- weapon layer: attach a mesh to a hand bone, hide the body ---
    if job['kind'] == 'weapon':
        bone = job.get('bone', 'handslot.r')
        if job.get('weapon_object'):
            # a weapon mesh that ships inside the character file, already attached to the hand
            wobjs = [bpy.data.objects[job['weapon_object']]]
            hide(wobjs[0], False)
        else:
            wobjs = import_model(os.path.join(ROOT, job['model']))
            for w in wobjs:
                if w.type == 'MESH':
                    w.parent = arm; w.parent_type = 'BONE'; w.parent_bone = bone
                    w.matrix_parent_inverse = Matrix.Identity(4); w.rotation_mode = 'XYZ'
                    # same placement KayKit uses for its own hand-slot weapons
                    w.location = tuple(job.get('weapon_loc', (0, -0.079, 0)))
                    if job.get('weapon_quat'): w.rotation_mode = 'QUATERNION'; w.rotation_quaternion = job['weapon_quat']   # KayKit's own hand-slot rotation
                    else: w.rotation_euler = Euler([math.radians(a) for a in job.get('weapon_rot', (0, 0, 0))])
                    w.scale = (job.get('weapon_scale', 1.0),) * 3
        if job.get('tint'): tint_materials(wobjs, job['tint'])
        for o in rig_objs:
            if o.type == 'MESH' and o not in wobjs: hide(o)
        # no ground shadow for weapon layers (the body's shadow covers it)
        g = bpy.data.objects.get('ground')
        if g: hide(g)

    # --- animations ---
    anims = job['anims']
    if args.anims: anims = {k: v for k, v in anims.items() if k in args.anims.split(',')}
    nd = job['render_dirs'] or job['dirs']
    dirs = list(range(nd)) if not args.dirs else [int(x) for x in args.dirs.split(',')]
    arm.animation_data_create()
    meta = {"name": name, "kind": job['kind'], "size": job['size'], "ortho": job['ortho'],
            "px_per_unit": job['size'] / job['ortho'], "anchor": [job['size'] / 2, job['size'] * (0.5 + job['shift'])],
            "dirs": job['dirs'], "mirror": bool(job['render_dirs'] and job['render_dirs'] < job['dirs']), "anims": {}, "frames": []}
    t0 = time.time(); n = 0
    for aname, a in anims.items():
        act = bpy.data.actions.get(a['action'])
        if not act: print('!! missing action', a['action'], 'in', rig_path); continue
        # back to the rest pose first: a bone this action doesn't key must not keep the last action's pose
        for pb in arm.pose.bones:
            pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0); pb.rotation_euler = (0, 0, 0); pb.scale = (1, 1, 1)
        arm.animation_data.action = act
        try: arm.animation_data.action_slot = act.slots[0]
        except Exception: pass
        f0, f1 = act.frame_range
        frames = sample_frames(f0, f1, a.get('frames', 1), a.get('loop', False))
        meta['anims'][aname] = {"frames": len(frames), "fps": a.get('fps', 10), "loop": a.get('loop', False), "events": a.get('events', {})}
        for d in dirs:
            tt.rotation_euler = Euler((0, 0, math.radians(180 - d * 45 + job.get('yaw', 0))))
            for i, f in enumerate(frames):
                sc.frame_set(int(round(f)))
                sc.frame_current = int(round(f)); sc.frame_subframe = 0.0
                fn = f'{aname}_{d}_{i}.png'
                sc.render.filepath = os.path.join(out, fn)
                bpy.ops.render.render(write_still=True)
                fr = {"anim": aname, "dir": d, "i": i, "file": fn}
                if two_pass:   # second pass without the occluders: pack.py splits it into behind/in-front parts
                    for h in holds: hide(h)
                    fr['full'] = f'{aname}_{d}_{i}_full.png'; sc.render.filepath = os.path.join(out, fr['full'])
                    bpy.ops.render.render(write_still=True)
                    for h in holds: hide(h, False)
                meta['frames'].append(fr); n += 1
                if n % 20 == 0: print(f'[{name}] {n} frames, {(time.time() - t0) / n:.2f}s/frame', flush=True)
    json.dump(meta, open(os.path.join(out, 'meta.json'), 'w'), indent=1)
    print(f'[{name}] done: {n} frames in {time.time() - t0:.0f}s → {out}')

if __name__ == '__main__': main()
