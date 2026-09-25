"""
Builds the 3D game's people (Godot, godot/assets/characters/*.glb) from the Quaternius kits:
an outfit (Modular Character Outfits) + a head (Universal Base Characters) + hair, all skinned to
one skeleton, so every UAL animation plays on every person.

    python3 art/godot/characters.py              # all
    python3 art/godot/characters.py hero_m       # one
Outfits already carry their own hands/arms skin; only the head (cut at the neck) is taken from the
base character, as the kit's readme asks. The cut sits under the collar/hood.
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PACKS = os.environ.get('PACKS', '/home/claude/packs')
OUT = os.path.join(ROOT, 'godot', 'assets', 'characters'); os.makedirs(OUT, exist_ok=True)
UBC = PACKS + '/Universal_Base_Characters/Universal Base Characters[Standard]/'
MCO = PACKS + '/Modular_Character_Outfits_Fantasy/Modular Character Outfits - Fantasy[Standard]/'
BASE = {'m': UBC + 'Base Characters/Godot - UE/Superhero_Male_FullBody.gltf', 'f': UBC + 'Base Characters/Godot - UE/Superhero_Female_FullBody.gltf'}
HAIR = UBC + 'Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)/'
OUTFIT = MCO + 'Exports/glTF (Godot-Unreal)/Outfits/'
TEX = {'ranger3': MCO + 'Textures/Ranger/T_Ranger_3_BaseColor.png', 'peasant2': MCO + 'Textures/Peasant/T_Peasant_2_BaseColor.png',
       'skin_m_light': UBC + 'Base Characters/Textures/T_Superhero_Male_Ligh.png', 'skin_f_light': UBC + 'Base Characters/Textures/T_Superhero_Female_Light_BaseColor.png',
       'hair2': UBC + 'Hairstyles/Textures/T_Hair_2_BaseColor.png'}

# who we build: outfit, body type, hair pieces, texture swaps {material name prefix: texture key}, neck cut height
PEOPLE = {
    'hero_m':      dict(outfit='Male_Ranger', sex='m', hair=[], cut=1.50),
    'hero_f':      dict(outfit='Female_Ranger', sex='f', hair=[], cut=1.42),
    'villager_m1': dict(outfit='Male_Peasant', sex='m', hair=['Hair_SimpleParted', 'Hair_Beard'], cut=1.50),
    'villager_m2': dict(outfit='Male_Peasant', sex='m', hair=['Hair_Buzzed'], cut=1.50, swap={'MI_Peasant': 'peasant2', 'MI_Superhero_Male': 'skin_m_light'}),
    'villager_f1': dict(outfit='Female_Peasant', sex='f', hair=['Hair_Long'], cut=1.42, swap={'MI_Superhero_Female': 'skin_f_light'}),
    'villager_f2': dict(outfit='Female_Peasant', sex='f', hair=['Hair_Buns'], cut=1.42, swap={'MI_Peasant': 'peasant2', 'MI_Hair': 'hair2'}),
    'ranger_m2':   dict(outfit='Male_Ranger', sex='m', hair=[], cut=1.50, swap={'MI_Ranger': 'ranger3', 'MI_Superhero_Male': 'skin_m_light'}),
}

def imp(path):
    before = set(bpy.data.objects); bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.data.objects if o not in before]

def cut_head(o, zcut):
    """keep only the head and upper neck of the base body (vertices above zcut, by rest position)"""
    bm = bmesh.new(); bm.from_mesh(o.data); mw = o.matrix_world
    drop = [v for v in bm.verts if (mw @ v.co).z < zcut]
    bmesh.ops.delete(bm, geom=drop, context='VERTS'); bm.to_mesh(o.data); bm.free()

def swap_tex(objs, swaps):
    for o in objs:
        for slot in o.material_slots:
            m = slot.material
            if not m: continue
            for pre, key in swaps.items():
                if m.name.startswith(pre):
                    m = m.copy(); slot.material = m
                    for n in m.node_tree.nodes:
                        if n.type == 'TEX_IMAGE' and n.image and 'Normal' not in n.image.name and 'ORM' not in n.image.name and 'Rough' not in n.image.name:
                            n.image = bpy.data.images.load(TEX[key], check_existing=True)

def build(key):
    p = PEOPLE[key]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    outfit = imp(OUTFIT + p['outfit'] + '.gltf')
    arm = [o for o in outfit if o.type == 'ARMATURE'][0]
    base = imp(BASE[p['sex']])
    barm = [o for o in base if o.type == 'ARMATURE'][0]
    parts = []
    for o in base:
        if o.type != 'MESH' or o.name.startswith('Icosphere'): continue
        if o.name.startswith('SuperHero') or o.name.startswith('Superhero'): cut_head(o, p['cut'])
        parts.append(o)
    for h in p['hair']:
        for o in imp(HAIR + h + '.gltf'):
            if o.type == 'MESH': parts.append(o)
    # move every borrowed mesh onto the outfit's skeleton (same bone names, same head position)
    for o in parts:
        mw = o.matrix_world.copy(); o.parent = arm; o.matrix_world = mw
        for m in o.modifiers:
            if m.type == 'ARMATURE': m.object = arm
    for o in list(bpy.data.objects):
        if o.type == 'ARMATURE' and o != arm: bpy.data.objects.remove(o)
        elif o.type == 'EMPTY' and not o.children: bpy.data.objects.remove(o)
        elif o.type == 'MESH' and o.name.startswith('Icosphere'): bpy.data.objects.remove(o)
    if p.get('swap'): swap_tex([o for o in bpy.data.objects if o.type == 'MESH'], p['swap'])
    arm.name = 'Armature'
    path = os.path.join(OUT, key + '.gltf')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLTF_SEPARATE', export_texture_dir='textures', export_animations=False, export_skins=True,
                              export_morph=False, export_yup=True, export_apply=False, export_image_format='AUTO')
    shrink(os.path.join(OUT, 'textures'))
    print('saved', path, (os.path.getsize(path) + os.path.getsize(path[:-5] + '.bin')) // 1024, 'KB')

def shrink(d, cap=2048):
    """textures shared by every person, at most cap px (the kits ship 4K; 2K is plenty at game distance)"""
    from PIL import Image
    for f in os.listdir(d):
        fp = os.path.join(d, f); im = Image.open(fp)
        if max(im.size) > cap: im.resize((cap, cap * im.size[1] // im.size[0]), Image.LANCZOS).save(fp, optimize=True)

if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    for k in (argv or list(PEOPLE)): build(k)
