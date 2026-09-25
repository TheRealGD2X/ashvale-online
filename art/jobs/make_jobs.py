"""Writes the render job files. Edit here, then: python3 art/jobs/make_jobs.py

The character is LAYERS on one skeleton (Mir 2 style): body armour, head, helmet, cape and weapon are
separate sprite sets sharing the same animations, so any combination composes in the game.
Symmetric layers (bodies, heads, helmets, capes, monsters) render 5 directions and are mirrored for
the other three; weapons (held in the right hand) render all 8.
"""
import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
K = 'art/models/kaykit/'
VAR = json.load(open(os.path.join(HERE, '..', 'models', 'variants', 'variants.json')))

# --- animation sets --------------------------------------------------------
# events.hit = the frame on which the blow lands (the view fires impact sound/FX then)
CORE = {
    "idle":     {"action": "Idle",                           "frames": 4, "fps": 5,  "loop": True},
    "walk":     {"action": "Running_A",                      "frames": 8, "fps": 14, "loop": True},
    "attack":   {"action": "1H_Melee_Attack_Slice_Diagonal", "frames": 6, "fps": 16, "events": {"hit": 3}},
    "attack2":  {"action": "1H_Melee_Attack_Chop",           "frames": 6, "fps": 16, "events": {"hit": 3}},
    "cast":     {"action": "Spellcast_Shoot",                "frames": 6, "fps": 14, "events": {"hit": 3}},
    "casting":  {"action": "Spellcasting",                   "frames": 4, "fps": 8,  "loop": True},
    "hit":      {"action": "Hit_A",                          "frames": 3, "fps": 12},
    "die":      {"action": "Death_A",                        "frames": 6, "fps": 10},
    "dead":     {"action": "Death_A_Pose",                   "frames": 1},
    "sit":      {"action": "Sit_Floor_Idle",                 "frames": 2, "fps": 1,  "loop": True},
}
EMOTES = {
    "cheer":    {"action": "Cheer",                          "frames": 5, "fps": 10},
    "interact": {"action": "Interact",                       "frames": 4, "fps": 10},
}
TWO_H = {
    "attack2h": {"action": "2H_Melee_Attack_Slice",          "frames": 6, "fps": 16, "events": {"hit": 3}},
    "spin":     {"action": "2H_Melee_Attack_Spin",           "frames": 8, "fps": 16, "events": {"hit": 4}},
}
HUMAN = {**CORE, **TWO_H, **EMOTES}          # every human layer gets everything so any combination composes
SKELETON = {
    "idle":     {"action": "Idle_Combat",                    "frames": 4, "fps": 5,  "loop": True},
    "walk":     {"action": "Running_A",                      "frames": 8, "fps": 12, "loop": True},
    "attack":   {"action": "1H_Melee_Attack_Slice_Horizontal","frames": 6, "fps": 14, "events": {"hit": 3}},
    "attack2":  {"action": "1H_Melee_Attack_Jump_Chop",      "frames": 6, "fps": 14, "events": {"hit": 4}},
    "cast":     {"action": "Spellcast_Shoot",                "frames": 6, "fps": 14, "events": {"hit": 3}},
    "hit":      {"action": "Hit_A",                          "frames": 3, "fps": 12},
    "die":      {"action": "Death_C_Skeletons",              "frames": 6, "fps": 10},
    "dead":     {"action": "Death_C_Pose",                   "frames": 1},
    "spawn":    {"action": "Skeletons_Awaken_Standing",      "frames": 6, "fps": 10},
}

jobs = {}
def layer(name, model, parts, anims=HUMAN, texture=None, dirs5=True, **kw):
    j = {"name": name, "kind": "character", "model": K + model, "parts": parts, "anims": anims}
    if texture: j["texture"] = texture
    if dirs5: j["render_dirs"] = 5
    j.update(kw); jobs[name] = j
def weapon(name, rig, prefix, obj=None, model=None, anims=HUMAN, **kw):
    j = {"name": name, "kind": "weapon", "rig": K + rig, "prefix": prefix, "anims": anims, "bone": "handslot.r", "model": K + (rig if obj else model)}
    if obj: j["weapon_object"] = obj
    else: j["weapon_rot"] = [-90, 0, 0]
    j.update(kw); jobs[name] = j

BODY = {"knight": ["Knight_Body", "Knight_ArmLeft", "Knight_ArmRight", "Knight_LegLeft", "Knight_LegRight"],
        "barbarian": ["Barbarian_Body", "Barbarian_ArmLeft", "Barbarian_ArmRight", "Barbarian_LegLeft", "Barbarian_LegRight"],
        "mage": ["Mage_Body", "Mage_ArmLeft", "Mage_ArmRight", "Mage_LegLeft", "Mage_LegRight"],
        "rogue": ["Rogue_Body", "Rogue_ArmLeft", "Rogue_ArmRight", "Rogue_LegLeft", "Rogue_LegRight"]}
MODEL = {"knight": "Knight.glb", "barbarian": "Barbarian.glb", "mage": "Mage.glb", "rogue": "Rogue_Hooded.glb"}

# --- body armour sets: one per variant texture ---------------------------------------------
for vname, v in VAR.items():
    if vname.startswith(('helm_', 'cape_', 'hat_')): continue
    layer('body_' + vname, MODEL[v['base']], BODY[v['base']], texture=v['texture'])

# --- heads (the face; hair colour is a live tint later) ------------------------------------
layer('head_knight',    'Knight.glb',       ['Knight_Head'])
layer('head_barbarian', 'Barbarian.glb',    ['Barbarian_Head'])
layer('head_mage',      'Mage.glb',         ['Mage_Head'])
layer('head_rogue',     'Rogue_Hooded.glb', ['Rogue_Head_Hooded'])

# --- helmets and capes: rendered neutral grey, tinted live in the game --------------------
layer('helm_knight',    'Knight.glb',       ['Knight_Helmet'],   texture=VAR['helm_neutral_knight']['texture'])
layer('hat_mage',       'Mage.glb',         ['Mage_Hat'],        texture=VAR['hat_neutral_mage']['texture'])
layer('hat_barbarian',  'Barbarian.glb',    ['Barbarian_Hat'],   texture=VAR['hat_neutral_barbarian']['texture'])
layer('cape_knight',    'Knight.glb',       ['Knight_Cape'],     texture=VAR['cape_neutral_knight']['texture'])
layer('cape_mage',      'Mage.glb',         ['Mage_Cape'],       texture=VAR['cape_neutral_mage']['texture'])
layer('cape_rogue',     'Rogue_Hooded.glb', ['Rogue_Cape'],      texture=VAR['cape_neutral_rogue']['texture'])
layer('cape_barbarian', 'Barbarian.glb',    ['Barbarian_Cape'],  texture=VAR['cape_neutral_barbarian']['texture'])

# --- weapons: 8 directions, shared rig ----------------------------------------------------
weapon("w_sword_1h", "Knight.glb", "Knight", obj="1H_Sword")
weapon("w_sword_2h", "Knight.glb", "Knight", obj="2H_Sword")
weapon("w_axe_1h",   "Barbarian.glb", "Barbarian", obj="1H_Axe")
weapon("w_axe_2h",   "Barbarian.glb", "Barbarian", obj="2H_Axe")
weapon("w_staff",    "Mage.glb", "Mage", obj="2H_Staff")
weapon("w_wand",     "Mage.glb", "Mage", obj="1H_Wand")
weapon("w_dagger",   "Rogue_Hooded.glb", "Rogue", obj="Knife")
weapon("w_crossbow", "Rogue_Hooded.glb", "Rogue", obj="1H_Crossbow")
weapon("w_bone_blade", "Knight.glb", "Knight", model="Skeleton_Blade.gltf")
weapon("w_bone_axe",   "Knight.glb", "Knight", model="Skeleton_Axe.gltf")
weapon("w_bone_staff", "Knight.glb", "Knight", model="Skeleton_Staff.gltf")

# --- monsters: whole figure in one set ----------------------------------------------------
def monster(name, model, prefix, anims=SKELETON, **kw):
    j = {"name": name, "kind": "character", "model": K + model, "prefix": prefix, "anims": anims, "render_dirs": 5}; j.update(kw); jobs[name] = j
monster("sk_warrior", "Skeleton_Warrior.glb", "Skeleton_Warrior",
        attach=[{"model": K + "Skeleton_Blade.gltf", "bone": "handslot.r"}, {"model": K + "Skeleton_Shield_Small_A.gltf", "bone": "handslot.l"}])
monster("sk_mage",   "Skeleton_Mage.glb",   "Skeleton_Mage",   attach=[{"model": K + "Skeleton_Staff.gltf", "bone": "handslot.r"}])
monster("sk_rogue",  "Skeleton_Rogue.glb",  "Skeleton_Rogue",  attach=[{"model": K + "Skeleton_Axe.gltf", "bone": "handslot.r"}])
monster("sk_minion", "Skeleton_Minion.glb", "Skeleton_Minion", anims={k: v for k, v in SKELETON.items() if k != 'cast'})

# --- creatures built by art/creatures.py (forward is −X there, hence yaw 90) ------------
CREATURE = {
    "idle":   {"action": "Idle",   "frames": 4, "fps": 6,  "loop": True},
    "walk":   {"action": "Walk",   "frames": 8, "fps": 14, "loop": True},
    "attack": {"action": "Attack", "frames": 6, "fps": 14, "events": {"hit": 3}},
    "hit":    {"action": "Hit",    "frames": 3, "fps": 12},
    "die":    {"action": "Die",    "frames": 6, "fps": 10},
    "dead":   {"action": "Dead",   "frames": 1},
}
for cr in ['boar', 'deer', 'wolf', 'bear', 'hen', 'spider', 'bat', 'moth', 'snake', 'maggot']:
    jobs['cr_' + cr] = {"name": 'cr_' + cr, "kind": "character", "model": f"art/models/creatures/{cr}.blend", "prefix": cr.capitalize() + '_', "anims": CREATURE, "render_dirs": 5, "yaw": 90}

for f in os.listdir(HERE):
    if f.endswith('.json'): os.remove(os.path.join(HERE, f))
for name, j in jobs.items():
    json.dump(j, open(os.path.join(HERE, name + '.json'), 'w'), indent=1)
print('wrote', len(jobs), 'jobs:', ' '.join(jobs))
