"""Line-up of weapon models for a quick look (not used by the game).
    python3 art/wpnpreview.py out.png sword moon kris ...      (all built weapons when none given)"""
import bpy, sys, os, math, glob
from mathutils import Vector, Euler
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
out = argv[0]; keys = argv[1:] or sorted(os.path.basename(p)[:-6] for p in glob.glob(os.path.join(ROOT, 'art/models/weapons/*.blend')))
bpy.ops.wm.read_factory_settings(use_empty=True); sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.samples = 16; sc.cycles.use_denoising = True; sc.cycles.denoising_prefilter = 'FAST'; sc.cycles.denoising_quality = 'FAST'
sc.render.film_transparent = True; sc.view_settings.view_transform = 'Standard'
gap = .75; W = len(keys) * gap
sc.render.resolution_x = int(90 * len(keys)); sc.render.resolution_y = 330
for i, k in enumerate(keys):
    with bpy.data.libraries.load(os.path.join(ROOT, f'art/models/weapons/{k}.blend')) as (s, d): d.objects = s.objects
    for o in d.objects:
        sc.collection.objects.link(o); o.location = (i * gap - W / 2 + gap / 2, 0, 0); o.rotation_euler = Euler((0, math.radians(-12), math.radians(-35)))
cd = bpy.data.cameras.new('c'); cd.type = 'ORTHO'; cd.ortho_scale = W; cam = bpy.data.objects.new('c', cd); sc.collection.objects.link(cam); sc.camera = cam
cam.location = (0, -20, .75 + 20 * math.tan(math.radians(15))); cam.rotation_euler = Euler((math.radians(75), 0, 0))
def sun(e, rot, col):
    l = bpy.data.lights.new('s', 'SUN'); l.energy = e; l.color = col; o = bpy.data.objects.new('s', l); sc.collection.objects.link(o); o.rotation_euler = Euler([math.radians(a) for a in rot])
sun(3.6, (28, 0, -30), (1, .94, .84)); sun(1.4, (60, 30, 150), (.72, .82, 1)); sun(1.2, (35, 0, 180), (.95, .95, 1))
sc.world = bpy.data.worlds.new('w'); sc.world.use_nodes = True; bg = sc.world.node_tree.nodes['Background']; bg.inputs[0].default_value = (.42, .44, .5, 1)
sc.render.filepath = out; bpy.ops.render.render(write_still=True); print('wrote', out)
