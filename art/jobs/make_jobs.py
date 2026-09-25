"""Writes the render job files. Edit here, then: python3 art/jobs/make_jobs.py

The character is LAYERS on one skeleton (Mir 2 style): body armour, face, hair, helmet, cape and weapon
are separate sprite sets sharing the same animations, so any combination composes in the game.

Every set renders all 8 directions (no mirroring: the sun is fixed in the world and the weapon hand
must stay the right hand). Occlusion is baked in with holdouts: a layer is rendered with the layers
that are always under it (body, face) as invisible occluders, so it can simply be drawn on top.
Capes and weapons, which pass in front of and behind the body, render twice ("two_pass"); pack.py
splits them into a behind-the-body part (drawn first) and an in-front part (drawn last).
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
TWO_H["idle2h"] = {"action": "2H_Melee_Idle",               "frames": 4, "fps": 5,  "loop": True}
EXTRA = {
    "raise":    {"action": "Spellcast_Raise",                "frames": 6, "fps": 12, "events": {"hit": 3}},   # heals, buffs, summons, shouts
    "use":      {"action": "Use_Item",                       "frames": 5, "fps": 10, "events": {"hit": 3}},   # potions, food
    "shoot":    {"action": "1H_Ranged_Shoot",                "frames": 5, "fps": 12, "events": {"hit": 2}},   # crossbows, bows
    "stab":     {"action": "1H_Melee_Attack_Stab",           "frames": 6, "fps": 16, "events": {"hit": 3}},   # daggers
    "block":    {"action": "Block_Hit",                      "frames": 3, "fps": 12},                         # parry
}
HUMAN = {**CORE, **TWO_H, **EMOTES, **EXTRA}  # every human layer gets everything so any combination composes
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
def layer(name, model, parts, anims=HUMAN, texture=None, **kw):
    j = {"name": name, "kind": "character", "model": K + model, "parts": parts, "anims": anims}
    if texture: j["texture"] = texture
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
MODEL = {"knight": "Knight.glb", "barbarian": "Barbarian.glb", "mage": "Mage.glb", "rogue": "Rogue.glb"}
HEAD = {"knight": "Knight_Head", "barbarian": "Barbarian_Head", "mage": "Mage_Head", "rogue": "Rogue_Head"}
HAT = {"knight": "Knight_Helmet", "barbarian": "Barbarian_Hat", "mage": "Mage_Hat", "rogue": None}
CAPE = {b: b.capitalize() + "_Cape" for b in BODY}
HAIR = [[1, 0]]                                   # palette cell every KayKit head keeps its hair in
def face_of(b): return {"mesh": HEAD[b], "uv_drop": HAIR}

# --- body armour sets: one per variant texture ---------------------------------------------
for vname, v in VAR.items():
    if vname.startswith(('helm_', 'cape_', 'hat_', 'hair_', 'hood_')): continue
    layer('body_' + vname, MODEL[v['base']], BODY[v['base']], texture=v['texture'])

# --- heads and hair ------------------------------------------------------------------------
# A KayKit head is one shell: the hair IS the top of the skull, so it can't be removed. The head set
# is the whole head with its hair rendered neutral grey; the hair set is the hair alone with the face
# as a holdout (only the visible hair pixels), drawn over the head tinted to the character's colour.
for b in BODY:
    layer('head_' + b, MODEL[b], [HEAD[b]], texture=VAR['hair_neutral_' + b]['texture'], holdout=BODY[b])
    layer('hair_' + b, MODEL[b], [HEAD[b]], uv_keep={HEAD[b]: HAIR}, texture=VAR['hair_neutral_' + b]['texture'],
          holdout=BODY[b] + [face_of(b)])
# the Taoist hood: the hooded rogue head, hood in palette cell (1,1), tinted live like hair
HOOD = [[1, 1]]
layer('head_hood', 'Rogue_Hooded.glb', ['Rogue_Head_Hooded'], texture=VAR['hood_neutral_rogue']['texture'], holdout=BODY['rogue'])
layer('hair_hood', 'Rogue_Hooded.glb', ['Rogue_Head_Hooded'], uv_keep={'Rogue_Head_Hooded': HOOD},
      texture=VAR['hood_neutral_rogue']['texture'], holdout=BODY['rogue'] + [{"mesh": "Rogue_Head_Hooded", "uv_drop": HOOD}])

# --- helmets and capes: rendered neutral grey, tinted live in the game --------------------
layer('helm_knight',    'Knight.glb',    [HAT['knight']],    texture=VAR['helm_neutral_knight']['texture'],   holdout=BODY['knight'] + [face_of('knight')])
layer('hat_mage',       'Mage.glb',      [HAT['mage']],      texture=VAR['hat_neutral_mage']['texture'],      holdout=BODY['mage'] + [face_of('mage')])
layer('hat_barbarian',  'Barbarian.glb', [HAT['barbarian']], texture=VAR['hat_neutral_barbarian']['texture'], holdout=BODY['barbarian'] + [face_of('barbarian')])
for b in BODY:   # capes pass behind and in front of the body: two passes
    layer('cape_' + b, MODEL[b], [CAPE[b]], texture=VAR['cape_neutral_' + b]['texture'], two_pass=True,
          holdout=BODY[b] + [HEAD[b]] + ([HAT[b]] if HAT[b] else []))

# our own helmets, hats and crowns (art/helmets.py), fitted to the head bone: helm_<look.k>
import glob as _g
for _p in sorted(_g.glob(os.path.join(HERE, '..', 'models', 'helmets', '*.blend'))):
    _k = os.path.basename(_p)[:-6]
    layer('helm_' + _k, 'Knight.glb', [], attach_rest=[{"model": 'art/models/helmets/' + _k + '.blend', "bone": "head"}], holdout=BODY['knight'] + [HEAD['knight']])

# monster heads (art/monheads.py): goblin, bull (minotaur), cat (wildcat), sack (scarecrow): mhead_<k>
for _p in sorted(_g.glob(os.path.join(HERE, '..', 'models', 'monheads', '*.blend'))):
    _k = os.path.basename(_p)[:-6]
    layer('mhead_' + _k, 'Barbarian.glb', [], attach_rest=[{"model": 'art/models/monheads/' + _k + '.blend', "bone": "head"}], holdout=BODY['barbarian'])

# --- weapons: shared rig, two passes (behind / in front of the body) -----------------------
def weapon(name, base, obj=None, model=None, anims=HUMAN, **kw):
    j = {"name": name, "kind": "weapon", "rig": K + MODEL[base], "prefix": base.capitalize(), "anims": anims, "bone": "handslot.r",
         "model": K + (MODEL[base] if obj else model), "two_pass": True,
         "holdout": BODY[base] + [HEAD[base], CAPE[base]] + ([HAT[base]] if HAT[base] else [])}
    if obj: j["weapon_object"] = obj
    else: j["weapon_rot"] = [-90, 0, 0]
    j.update(kw); jobs[name] = j
weapon("w_sword_1h", "knight",    obj="1H_Sword")
weapon("w_sword_2h", "knight",    obj="2H_Sword")
weapon("w_axe_1h",   "barbarian", obj="1H_Axe")
weapon("w_axe_2h",   "barbarian", obj="2H_Axe")
weapon("w_staff",    "mage",      obj="2H_Staff")
weapon("w_wand",     "mage",      obj="1H_Wand")
weapon("w_dagger",   "rogue",     obj="Knife")
weapon("w_crossbow", "rogue",     obj="1H_Crossbow")
weapon("w_bone_blade", "knight",  model="Skeleton_Blade.gltf")
weapon("w_bone_axe",   "knight",  model="Skeleton_Axe.gltf")
weapon("w_bone_staff", "knight",  model="Skeleton_Staff.gltf", weapon_rot=[90, 0, 0])
# our own weapon models (art/weapons.py), one per item look: wpn_<look.k>
import glob as _g
for _p in sorted(_g.glob(os.path.join(HERE, '..', 'models', 'weapons', '*.blend'))):
    _k = os.path.basename(_p)[:-6]
    weapon('wpn_' + _k, 'knight', model='', weapon_quat=[0, 0, -0.7071068, -0.7071068])
    jobs['wpn_' + _k]['model'] = 'art/models/weapons/' + _k + '.blend'; jobs['wpn_' + _k].pop('weapon_rot', None)

# --- monsters: whole figure in one set ----------------------------------------------------
def monster(name, model, prefix, anims=SKELETON, **kw):
    j = {"name": name, "kind": "character", "model": K + model, "prefix": prefix, "anims": anims}; j.update(kw); jobs[name] = j
monster("sk_warrior", "Skeleton_Warrior.glb", "Skeleton_Warrior",
        attach=[{"model": K + "Skeleton_Blade.gltf", "bone": "handslot.r"}, {"model": K + "Skeleton_Shield_Small_A.gltf", "bone": "handslot.l"}])
monster("sk_mage",   "Skeleton_Mage.glb",   "Skeleton_Mage",   attach=[{"model": K + "Skeleton_Staff.gltf", "bone": "handslot.r", "rot": [90, 0, 0]}])   # the staff model points the other way
monster("sk_rogue",  "Skeleton_Rogue.glb",  "Skeleton_Rogue",  attach=[{"model": K + "Skeleton_Axe.gltf", "bone": "handslot.r"}])
monster("sk_minion", "Skeleton_Minion.glb", "Skeleton_Minion", anims={k: v for k, v in SKELETON.items() if k != 'cast'})
# bosses: the Bone King (crowned warrior with a greatsword) and the Lich Emperor (crowned mage)
SKULL_FIT = {"bone": "head", "scale": .82, "offset": [0, 0, -.03]}
monster("sk_king", "Skeleton_Warrior.glb", "Skeleton_Warrior", hide=["Skeleton_Warrior_Helmet"],
        attach=[{"model": K + "Skeleton_Blade.gltf", "bone": "handslot.r", "scale": 1.35}],
        attach_rest=[dict(SKULL_FIT, model="art/models/helmets/crown.blend")])
monster("sk_lich", "Skeleton_Mage.glb", "Skeleton_Mage", hide=["Skeleton_Mage_Hat"],
        attach=[{"model": K + "Skeleton_Staff.gltf", "bone": "handslot.r", "rot": [90, 0, 0]}],
        attach_rest=[dict(SKULL_FIT, model="art/models/helmets/abyss.blend")])

# --- creatures built by art/creatures.py (forward is -Y, like the KayKit characters) ------
CREATURE = {
    "idle":   {"action": "Idle",   "frames": 4, "fps": 6,  "loop": True},
    "walk":   {"action": "Walk",   "frames": 8, "fps": 14, "loop": True},
    "attack": {"action": "Attack", "frames": 6, "fps": 14, "events": {"hit": 3}},
    "hit":    {"action": "Hit",    "frames": 3, "fps": 12},
    "die":    {"action": "Die",    "frames": 6, "fps": 10},
    "dead":   {"action": "Dead",   "frames": 1},
}
for cr in ['boar', 'deer', 'wolf', 'bear', 'hen', 'spider', 'bat', 'moth', 'snake', 'maggot']:
    jobs['cr_' + cr] = {"name": 'cr_' + cr, "kind": "character", "model": f"art/models/creatures/{cr}.blend", "prefix": cr.capitalize() + '_', "anims": CREATURE}

for f in os.listdir(HERE):
    if f.endswith('.json') and not f.startswith('props_'): os.remove(os.path.join(HERE, f))   # prop jobs come from make_props.py
for name, j in jobs.items():
    json.dump(j, open(os.path.join(HERE, name + '.json'), 'w'), indent=1)
print('wrote', len(jobs), 'jobs:', ' '.join(jobs))
