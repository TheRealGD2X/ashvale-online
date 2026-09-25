"""Writes the world prop jobs (art/render_props.py). Edit here, then: python3 art/jobs/make_props.py

Sizes are in game tiles: "fit": [w, d] scales a building to fill a w x d footprint (anchored at its
south-west corner, like the world's multi-tile objects); "height" scales a prop to that many tiles tall
(anchored at the centre of its tile)."""
import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
HEX = 'art/models/hexpack/'; NAT = 'art/models/nature/'
def bld(colour, kind): return HEX + f'buildings/{colour}/building_{kind}_{colour}.gltf'

TOWN = [
    # the eight shops of Ashvale (5 x 3 footprints, the door faces the street to the south)
    dict(key='house_weapons', model=bld('red', 'archeryrange'), fit=[5, 3], anchor='corner'),
    dict(key='house_armour', model=bld('blue', 'barracks'), fit=[5, 3], anchor='corner'),
    dict(key='house_jeweler', model=bld('yellow', 'market'), fit=[5, 3], anchor='corner'),
    dict(key='house_potions', model=bld('green', 'home_B'), fit=[5, 3], anchor='corner'),
    dict(key='house_books', model=bld('blue', 'tower_A'), fit=[5, 3], anchor='corner'),
    dict(key='house_smith', model=bld('red', 'blacksmith'), fit=[5, 3], anchor='corner'),
    dict(key='house_storage', model=bld('yellow', 'home_A'), fit=[5, 3], anchor='corner'),
    dict(key='house_guild', model=bld('red', 'tavern'), fit=[5, 3], anchor='corner'),
    dict(key='cave_mouth', model=bld('blue', 'mine'), fit=[5, 3], anchor='corner', fill=1.1),
    dict(key='fountain', model=NAT + 'fountain.blend', fit=[3, 3], anchor='corner'),
    dict(key='lamp', model=NAT + 'lamp.blend', height=2.4),
    dict(key='sign', model=NAT + 'sign.blend', height=1.5),
    dict(key='barrel', model=HEX + 'decoration/props/barrel.gltf', height=.8),
    dict(key='crate', model=HEX + 'decoration/props/crate_A_big.gltf', height=.85),
    dict(key='crate_long', model=HEX + 'decoration/props/crate_long_A.gltf', height=.6),
    dict(key='sack', model=HEX + 'decoration/props/sack.gltf', height=.5),
    dict(key='weaponrack', model=HEX + 'decoration/props/weaponrack.gltf', height=1.2),
    dict(key='wheelbarrow', model=HEX + 'decoration/props/wheelbarrow.gltf', height=.8),
    dict(key='tent', model=HEX + 'decoration/props/tent.gltf', height=1.8),
    dict(key='target', model=HEX + 'decoration/props/target.gltf', height=1.3),
    dict(key='lumber', model=HEX + 'decoration/props/resource_lumber.gltf', height=.7),
]
NATURE = [
    dict(key='oak0', model=NAT + 'oak.blend', height=4.4), dict(key='oak1', model=NAT + 'oak2.blend', height=4.0),
    dict(key='oak2', model=NAT + 'oak3.blend', height=4.8), dict(key='oak3', model=NAT + 'birch.blend', height=4.6),
    dict(key='darkoak', model=NAT + 'darkoak.blend', height=5.0), dict(key='deadtree', model=NAT + 'dead.blend', height=3.6),
    dict(key='pine0', model=HEX + 'decoration/nature/tree_single_A.gltf', height=4.6), dict(key='pine1', model=HEX + 'decoration/nature/tree_single_B.gltf', height=4.2),
    dict(key='pine_dark', model=HEX + 'decoration/nature/tree_single_A.gltf', height=5.2, tint=[.62, .78, .7]),
    dict(key='stump', model=HEX + 'decoration/nature/tree_single_A_cut.gltf', height=.6),
    dict(key='bush0', model=NAT + 'bush.blend', height=1.0), dict(key='bush1', model=NAT + 'bush2.blend', height=.9),
    dict(key='crop0', model=NAT + 'crop_green.blend', height=.55), dict(key='crop1', model=NAT + 'crop_green.blend', height=.7), dict(key='crop2', model=NAT + 'crop.blend', height=1.0),
    dict(key='mushroom0', model=NAT + 'mushroom.blend', height=.45), dict(key='mushroom1', model=NAT + 'mushroom.blend', height=.35, tint=[.8, .6, .4]),
    dict(key='grass', model=NAT + 'grass.blend', height=.45),
] + [dict(key='rock%d' % i, model=HEX + f'decoration/nature/rock_single_{c}.gltf', scale=2.6, anchor='foot', tint=[.72, .7, .66]) for i, c in enumerate('ABCDE')]

for name, props in (('props_town', TOWN), ('props_nature', NATURE)):
    json.dump({"name": name, "shadow": True, "samples": 24, "props": props}, open(os.path.join(HERE, name + '.json'), 'w'), indent=1)
    print('wrote', name, len(props), 'props')
