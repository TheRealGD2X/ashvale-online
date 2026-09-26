class_name Zones
## The zones of the world, each its own 256 m map, joined by roads (WORLD-LAYOUT.md F2/F3). Walking
## off the end of a road that leads out of a zone takes you to the next one (a short loading
## screen). A dungeon is a zone too: a cave cut into rock, lit by lanterns, with no sky.
##
## What a zone definition holds:
##   name, band [lo, hi]           the name on the map and the levels it's for
##   seed, relief, edge            the lie of the land: noise seed, hill height, how high the rim rises
##   plateaus [{at, r0, r1, h}]    level ground (a town, a camp): full inside r0, blending out to r1
##   ridges [{pts, h, w}]          cliffs and rock walls raised along a line
##   pond {at, r} | null           a pond (with reflections, reeds...)
##   square {at, r} | null         a cobbled square
##   roads [{pts, w, kind}]        roads (kind 0 dirt, 1 cobbles); roads through the rim cut a pass
##   cave {halls, rooms, wall}     dungeons: floor where halls and rooms are, rock wall elsewhere
##   palette                       ground colours for the terrain shader
##   builders                      the scripts that dress the zone (houses, trees, water...)
##   exits [{at, r, to, arrive, name}]   where roads leave, and where you arrive in the next zone
##   graveyard, inn, start         where you rise after dying, the inn (hearth), where new arrivals stand
##   sky "day" | "cave"            open sky, or darkness with lanterns

const DEFS := {
	"ashvale": {
		"name": "Ashvale Province", "band": [1, 10], "seed": 7, "relief": 7.0, "edge": 26.0,
		"plateaus": [{"at": Vector2(0, 0), "r0": 34.0, "r1": 58.0, "h": 2.0}],
		"square": {"at": Vector2(0, 0), "r": 13.0},
		"pond": {"at": Vector2(-42, 46), "r": 15.0},
		"roads": [
			{"pts": [Vector2(-128, 8), Vector2(-92, 4), Vector2(-56, 7), Vector2(-26, 3), Vector2(0, 0), Vector2(30, -2), Vector2(62, 5), Vector2(96, 2), Vector2(128, 6)], "w": 2.4, "kind": 0},
			{"pts": [Vector2(0, 0), Vector2(-3, -24), Vector2(-9, -52), Vector2(2, -86), Vector2(-4, -128)], "w": 2.0, "kind": 0, "cut": true},
			{"pts": [Vector2(2, 6), Vector2(-8, 22), Vector2(-24, 34), Vector2(-29, 37.5)], "w": 1.4, "kind": 0},
			{"pts": [Vector2(22, -1), Vector2(36, 16), Vector2(46, 34)], "w": 1.5, "kind": 0},
			{"pts": [Vector2(60, 4), Vector2(64, -20), Vector2(62, -46), Vector2(68, -66), Vector2(72, -77)], "w": 1.2, "kind": 0},
			{"pts": [Vector2(-30, 3), Vector2(-14, 1), Vector2(14, -1), Vector2(30, -2)], "w": 2.6, "kind": 1},
			{"pts": [Vector2(0, 0), Vector2(-2, -22)], "w": 2.2, "kind": 1},
		],
		"builders": ["village", "landmarks", "water", "vegetation", "life"],
		"exits": [{"at": Vector2(-4, -122), "r": 7.0, "to": "hollow", "arrive": Vector2(-2, 112), "name": "Hollow Road", "sign": "Hollow Cliffs (10–16)"}],
		"graveyard": Vector2(-18, -14), "inn": Vector2(-17.5, 8.5), "start": Vector2(3, 16), "sky": "day",
		"stations": [["forge", Vector2(19.5, -17.5), 2.4], ["tannery", Vector2(75, 18), 3.6], ["loom", Vector2(-11, -13.5), 0.3], ["alchemy", Vector2(-3.5, -19.5), 0.0]],
		"tier": 1,
		"music": {"town": "town", "wild": "wilds"},
	},
	"hollow": {
		"name": "Hollow Cliffs", "band": [10, 16], "seed": 31, "relief": 11.0, "edge": 34.0,
		"plateaus": [{"at": Vector2(8, 26), "r0": 20.0, "r1": 40.0, "h": 9.0}, {"at": Vector2(24, -84), "r0": 12.0, "r1": 34.0, "h": 11.0},
			{"at": Vector2(-84, -84), "r0": 13.0, "r1": 42.0, "h": 13.0}],

		"ridges": [
			# the cliff the mine is cut into, running across the north
			{"pts": [Vector2(-128, -104), Vector2(-60, -96), Vector2(0, -102), Vector2(24, -98), Vector2(60, -106), Vector2(128, -100)], "h": 26.0, "w": 16.0},
			# a broken spine of rock west of the camp (the Scree lies under it)
			{"pts": [Vector2(-40, 70), Vector2(-52, 30), Vector2(-46, -10), Vector2(-60, -50)], "h": 12.0, "w": 7.0},
		],
		"pond": null, "square": null,
		"roads": [
			{"pts": [Vector2(-4, 128), Vector2(-2, 100), Vector2(4, 70), Vector2(6, 44), Vector2(8, 26)], "w": 2.0, "kind": 0, "cut": true},
			{"pts": [Vector2(8, 26), Vector2(14, 0), Vector2(18, -30), Vector2(22, -60), Vector2(24, -80)], "w": 1.8, "kind": 0},
			{"pts": [Vector2(8, 26), Vector2(40, 22), Vector2(70, 12), Vector2(100, 16), Vector2(128, 20)], "w": 1.8, "kind": 0, "cut": true},
			{"pts": [Vector2(8, 26), Vector2(-20, 20), Vector2(-40, 12)], "w": 1.3, "kind": 0},
			{"pts": [Vector2(14, 0), Vector2(-20, -30), Vector2(-50, -60), Vector2(-80, -80)], "w": 1.2, "kind": 0},
		],
		"palette": {"grass_a": Color(0.42, 0.47, 0.3), "grass_b": Color(0.55, 0.53, 0.38), "grass_c": Color(0.33, 0.38, 0.25),
			"dirt_a": Color(0.42, 0.38, 0.33), "dirt_b": Color(0.52, 0.48, 0.42)},
		"builders": ["camp", "vegetation"],
		"exits": [{"at": Vector2(-4, 122), "r": 7.0, "to": "ashvale", "arrive": Vector2(-3, -112), "name": "Hollow Road", "sign": "Ashvale Province (1–10)"},
			{"at": Vector2(122, 20), "r": 7.0, "to": "mirewood", "arrive": Vector2(-112, 18), "name": "Cliff Road", "sign": "Mirewood (14–22)"},
			{"at": Vector2(24, -92), "r": 3.5, "to": "mine", "arrive": Vector2(0, 104), "name": "The Hollow Mine", "sign": "Dungeon (12–16), groups of 2+", "no_post": true}],

		"graveyard": Vector2(0, 50), "inn": Vector2(4, 30), "start": Vector2(-2, 108), "sky": "day",
		"stations": [["forge", Vector2(23, 25), -1.2], ["alchemy", Vector2(19, 38), -2.2], ["tannery", Vector2(-10, 40), 1.0]],
		"tier": 2,

		"music": {"town": "wilds", "wild": "wilds"}, "forest": 0.35, "pines": true,
	},
	"mirewood": {
		"name": "Mirewood", "band": [14, 22], "seed": 51, "relief": 3.0, "edge": 22.0,
		"plateaus": [{"at": Vector2(-40, 28), "r0": 16.0, "r1": 30.0, "h": 1.2}, {"at": Vector2(90, -84), "r0": 8.0, "r1": 20.0, "h": 2.5}],
		"pond": {"at": Vector2(20, -6), "r": 30.0}, "square": null,
		"roads": [
			{"pts": [Vector2(-128, 18), Vector2(-96, 22), Vector2(-64, 26), Vector2(-40, 28)], "w": 2.0, "kind": 0, "cut": true},
			{"pts": [Vector2(-40, 28), Vector2(-20, 48), Vector2(14, 44), Vector2(56, 40), Vector2(84, 20), Vector2(104, -8), Vector2(128, -30)], "w": 1.8, "kind": 0, "cut": true},
			{"pts": [Vector2(-40, 28), Vector2(-54, -10), Vector2(-40, -50), Vector2(-10, -70)], "w": 1.2, "kind": 0},
			{"pts": [Vector2(56, 40), Vector2(70, -20), Vector2(84, -60), Vector2(90, -78)], "w": 1.2, "kind": 0},
		],
		"palette": {"grass_a": Color(0.28, 0.36, 0.2), "grass_b": Color(0.36, 0.38, 0.22), "grass_c": Color(0.2, 0.28, 0.16),
			"dirt_a": Color(0.3, 0.26, 0.18), "dirt_b": Color(0.38, 0.33, 0.24)},
		"builders": ["marsh", "water", "vegetation"],
		"exits": [{"at": Vector2(-122, 18), "r": 7.0, "to": "hollow", "arrive": Vector2(112, 18), "name": "Cliff Road", "sign": "Hollow Cliffs (10–16)"},
			{"at": Vector2(122, -28), "r": 7.0, "to": "ashslopes", "arrive": Vector2(-112, 30), "name": "Ashwater Crossing", "sign": "Ash Slopes (20–28)"},
			{"at": Vector2(90, -86), "r": 3.5, "to": "warrens", "arrive": Vector2(0, 100), "name": "The Warrens", "sign": "Dungeon (16–22), groups of 2+", "no_post": true}],
		"graveyard": Vector2(-50, 40), "inn": Vector2(-36, 30), "start": Vector2(-108, 20), "sky": "day",
		"music": {"town": "wilds", "wild": "night"}, "forest": 0.55, "dead_trees": true, "fog": Color(0.45, 0.55, 0.4),
		"stations": [["tannery", Vector2(-30, 38), 0.5], ["alchemy", Vector2(-48, 18), 1.4]], "tier": 3,
	},
	"warrens": {
		"name": "The Warrens", "band": [16, 22], "seed": 9, "dungeon": true, "group": 2,
		"cave": {"wall": 4.2,
			"halls": [{"pts": [Vector2(0, 108), Vector2(10, 70), Vector2(-20, 40), Vector2(-30, 0)], "w": 4.0},
				{"pts": [Vector2(-30, 0), Vector2(0, -30), Vector2(30, -40), Vector2(40, -80)], "w": 4.0},
				{"pts": [Vector2(-20, 40), Vector2(30, 30), Vector2(50, 0)], "w": 3.5}],
			"rooms": [{"at": Vector2(0, 100), "r": 9.0}, {"at": Vector2(-24, 38), "r": 10.0}, {"at": Vector2(50, 0), "r": 12.0},
				{"at": Vector2(-30, 0), "r": 11.0}, {"at": Vector2(30, -40), "r": 10.0}, {"at": Vector2(40, -86), "r": 15.0}]},
		"relief": 0.6, "edge": 0.0, "plateaus": [], "ridges": [], "pond": null, "square": null, "roads": [],
		"palette": {"grass_a": Color(0.25, 0.3, 0.18), "grass_b": Color(0.3, 0.32, 0.2), "grass_c": Color(0.2, 0.24, 0.15),
			"dirt_a": Color(0.28, 0.24, 0.17), "dirt_b": Color(0.34, 0.29, 0.2)},
		"builders": ["mine"], "roots": true,
		"exits": [{"at": Vector2(0, 107), "r": 3.5, "to": "mirewood", "arrive": Vector2(88, -76), "name": "The way out", "sign": "Mirewood"}],
		"graveyard": Vector2(0, 100), "inn": Vector2(0, 100), "start": Vector2(0, 100), "sky": "cave",
		"music": {"town": "night", "wild": "night"},
	},
	"ashslopes": {
		"name": "Ash Slopes", "band": [20, 28], "seed": 71, "relief": 9.0, "edge": 30.0,
		"plateaus": [{"at": Vector2(24, 36), "r0": 18.0, "r1": 34.0, "h": 7.0}, {"at": Vector2(10, -84), "r0": 16.0, "r1": 32.0, "h": 12.0}],
		"ridges": [{"pts": [Vector2(-128, -106), Vector2(-40, -100), Vector2(10, -104), Vector2(60, -98), Vector2(128, -108)], "h": 24.0, "w": 16.0},
			{"pts": [Vector2(70, 80), Vector2(60, 40), Vector2(80, 0)], "h": 10.0, "w": 7.0}],
		"pond": null, "square": {"at": Vector2(24, 36), "r": 8.0},
		"roads": [
			{"pts": [Vector2(-128, 30), Vector2(-80, 34), Vector2(-30, 40), Vector2(24, 36)], "w": 2.0, "kind": 0, "cut": true},
			{"pts": [Vector2(24, 36), Vector2(20, 0), Vector2(14, -40), Vector2(10, -76)], "w": 2.2, "kind": 1},
			{"pts": [Vector2(24, 36), Vector2(60, 10), Vector2(96, -30), Vector2(128, -60)], "w": 1.8, "kind": 0, "cut": true},
			{"pts": [Vector2(20, 0), Vector2(-30, -20), Vector2(-70, -50)], "w": 1.3, "kind": 0},
		],
		"palette": {"grass_a": Color(0.42, 0.4, 0.33), "grass_b": Color(0.5, 0.45, 0.34), "grass_c": Color(0.33, 0.31, 0.27),
			"dirt_a": Color(0.3, 0.28, 0.26), "dirt_b": Color(0.38, 0.35, 0.32)},
		"builders": ["temple", "vegetation"],
		"exits": [{"at": Vector2(-122, 30), "r": 7.0, "to": "mirewood", "arrive": Vector2(112, -26), "name": "Ashwater Crossing", "sign": "Mirewood (14–22)"},
			{"at": Vector2(122, -58), "r": 7.0, "to": "highlands", "arrive": Vector2(-112, 50), "name": "The High Pass", "sign": "Ashen Highlands (26–34)"},

			{"at": Vector2(10, -92), "r": 3.5, "to": "temple", "arrive": Vector2(0, 100), "name": "Temple of Ash", "sign": "Dungeon (24–28), groups of 2+", "no_post": true}],
		"graveyard": Vector2(30, 50), "inn": Vector2(28, 40), "start": Vector2(-108, 30), "sky": "day",
		"music": {"town": "wilds", "wild": "wilds"}, "forest": 0.25, "dead_trees": true, "fog": Color(0.75, 0.6, 0.45), "ashfall": true,
		"stations": [["forge", Vector2(32, 30), 2.0], ["loom", Vector2(14, 42), -1.0], ["alchemy", Vector2(18, 28), 0.5]], "tier": 4,
	},
	"temple": {
		"name": "The Temple of Ash", "band": [24, 28], "seed": 13, "dungeon": true, "group": 2,
		"cave": {"wall": 4.4,
			"halls": [{"pts": [Vector2(0, 108), Vector2(0, 60)], "w": 4.5}, {"pts": [Vector2(0, 60), Vector2(-40, 30), Vector2(-40, -10)], "w": 4.0},
				{"pts": [Vector2(0, 60), Vector2(40, 30), Vector2(40, -10)], "w": 4.0}, {"pts": [Vector2(-40, -10), Vector2(0, -40), Vector2(40, -10)], "w": 4.0},
				{"pts": [Vector2(0, -40), Vector2(0, -80)], "w": 5.0}],
			"rooms": [{"at": Vector2(0, 100), "r": 9.0}, {"at": Vector2(0, 60), "r": 12.0}, {"at": Vector2(-40, 0), "r": 11.0}, {"at": Vector2(40, 0), "r": 11.0},
				{"at": Vector2(0, -40), "r": 12.0}, {"at": Vector2(0, -88), "r": 16.0}]},
		"relief": 0.4, "edge": 0.0, "plateaus": [], "ridges": [], "pond": null, "square": null, "roads": [],
		"palette": {"grass_a": Color(0.36, 0.33, 0.3), "grass_b": Color(0.4, 0.36, 0.32), "grass_c": Color(0.3, 0.28, 0.26),
			"dirt_a": Color(0.34, 0.3, 0.27), "dirt_b": Color(0.42, 0.37, 0.32)},
		"builders": ["mine"],
		"exits": [{"at": Vector2(0, 107), "r": 3.5, "to": "ashslopes", "arrive": Vector2(10, -82), "name": "The way out", "sign": "Ash Slopes"}],
		"graveyard": Vector2(0, 100), "inn": Vector2(0, 100), "start": Vector2(0, 100), "sky": "cave",
		"music": {"town": "night", "wild": "night"},
	},
	"highlands": {
		"name": "Ashen Highlands", "band": [26, 34], "seed": 91, "relief": 10.0, "edge": 32.0,
		"plateaus": [{"at": Vector2(-30, 40), "r0": 16.0, "r1": 32.0, "h": 8.0}, {"at": Vector2(80, -70), "r0": 14.0, "r1": 26.0, "h": 14.0}],
		"ridges": [{"pts": [Vector2(40, -128), Vector2(60, -90), Vector2(110, -60), Vector2(128, -40)], "h": 22.0, "w": 14.0}],
		"pond": {"at": Vector2(30, 20), "r": 24.0}, "square": null,
		"roads": [
			{"pts": [Vector2(-128, 50), Vector2(-80, 46), Vector2(-30, 40)], "w": 2.0, "kind": 0, "cut": true},
			{"pts": [Vector2(-30, 40), Vector2(-20, 0), Vector2(0, -40), Vector2(-10, -80), Vector2(-4, -128)], "w": 1.8, "kind": 0, "cut": true},
			{"pts": [Vector2(-30, 40), Vector2(0, 60), Vector2(50, 56), Vector2(64, 40)], "w": 1.4, "kind": 0},
			{"pts": [Vector2(0, -40), Vector2(40, -50), Vector2(76, -66)], "w": 1.3, "kind": 0},
		],
		"palette": {"grass_a": Color(0.4, 0.42, 0.28), "grass_b": Color(0.5, 0.4, 0.42), "grass_c": Color(0.33, 0.3, 0.3),
			"dirt_a": Color(0.38, 0.33, 0.3), "dirt_b": Color(0.46, 0.4, 0.36)},
		"builders": ["highland", "water", "vegetation"],
		"exits": [{"at": Vector2(-122, 50), "r": 7.0, "to": "ashslopes", "arrive": Vector2(112, -56), "name": "The High Pass", "sign": "Ash Slopes (20–28)"},
			{"at": Vector2(-4, -122), "r": 7.0, "to": "varn", "arrive": Vector2(0, 112), "name": "The Plateau Road", "sign": "Varn Plateau (34–40)"},
			{"at": Vector2(66, 44), "r": 3.5, "to": "crypts", "arrive": Vector2(0, 100), "name": "The Sunken Crypts", "sign": "Dungeon (30–34), groups of 2+", "no_post": true}],
		"graveyard": Vector2(-40, 50), "inn": Vector2(-28, 36), "start": Vector2(-108, 50), "sky": "day",
		"music": {"town": "wilds", "wild": "wilds"}, "forest": 0.4, "pines": true, "fog": Color(0.7, 0.75, 0.85),
		"stations": [["forge", Vector2(-22, 44), 1.0], ["tannery", Vector2(-38, 30), 0.0], ["loom", Vector2(-36, 46), 2.0], ["alchemy", Vector2(-24, 30), 0.6]], "tier": 5,
	},
	"crypts": {
		"name": "The Sunken Crypts", "band": [30, 34], "seed": 23, "dungeon": true, "group": 2,
		"cave": {"wall": 4.2,
			"halls": [{"pts": [Vector2(0, 108), Vector2(0, 70), Vector2(-30, 50), Vector2(-30, 0)], "w": 4.0}, {"pts": [Vector2(0, 70), Vector2(30, 50), Vector2(30, 0)], "w": 4.0},
				{"pts": [Vector2(-30, 0), Vector2(0, -30), Vector2(30, 0)], "w": 4.0}, {"pts": [Vector2(0, -30), Vector2(0, -80)], "w": 5.0}],
			"rooms": [{"at": Vector2(0, 100), "r": 9.0}, {"at": Vector2(-30, 20), "r": 11.0}, {"at": Vector2(30, 20), "r": 11.0}, {"at": Vector2(0, -30), "r": 12.0}, {"at": Vector2(0, -88), "r": 16.0}]},
		"relief": 0.4, "edge": 0.0, "plateaus": [], "ridges": [], "pond": null, "square": null, "roads": [],
		"palette": {"grass_a": Color(0.28, 0.32, 0.34), "grass_b": Color(0.32, 0.35, 0.36), "grass_c": Color(0.24, 0.27, 0.29), "dirt_a": Color(0.3, 0.3, 0.3), "dirt_b": Color(0.36, 0.36, 0.35)},
		"builders": ["mine"],
		"exits": [{"at": Vector2(0, 107), "r": 3.5, "to": "highlands", "arrive": Vector2(62, 48), "name": "The way out", "sign": "Ashen Highlands"}],
		"graveyard": Vector2(0, 100), "inn": Vector2(0, 100), "start": Vector2(0, 100), "sky": "cave", "music": {"town": "night", "wild": "night"},
	},
	"varn": {
		"name": "Varn Plateau", "band": [34, 40], "seed": 113, "relief": 6.0, "edge": 30.0,
		"plateaus": [{"at": Vector2(10, 70), "r0": 18.0, "r1": 34.0, "h": 5.0}, {"at": Vector2(0, -80), "r0": 20.0, "r1": 36.0, "h": 9.0}],
		"ridges": [{"pts": [Vector2(-128, -110), Vector2(-40, -104), Vector2(40, -108), Vector2(128, -100)], "h": 20.0, "w": 14.0}],
		"pond": null, "square": null,
		"roads": [
			{"pts": [Vector2(0, 128), Vector2(4, 96), Vector2(10, 70)], "w": 2.0, "kind": 0, "cut": true},
			{"pts": [Vector2(10, 70), Vector2(0, 20), Vector2(-10, -30), Vector2(0, -70)], "w": 2.4, "kind": 0},
			{"pts": [Vector2(10, 70), Vector2(60, 40), Vector2(90, 0)], "w": 1.4, "kind": 0},
			{"pts": [Vector2(0, 20), Vector2(-60, 10), Vector2(-90, -30)], "w": 1.4, "kind": 0},
		],
		"palette": {"grass_a": Color(0.36, 0.33, 0.38), "grass_b": Color(0.42, 0.36, 0.34), "grass_c": Color(0.28, 0.26, 0.3),
			"dirt_a": Color(0.3, 0.27, 0.28), "dirt_b": Color(0.38, 0.33, 0.33)},
		"builders": ["varn", "vegetation"],
		"exits": [{"at": Vector2(0, 122), "r": 7.0, "to": "highlands", "arrive": Vector2(-4, -112), "name": "The Plateau Road", "sign": "Ashen Highlands (26–34)"},
			{"at": Vector2(0, -88), "r": 4.0, "to": "catacombs", "arrive": Vector2(0, 100), "name": "The Catacomb Arch", "sign": "Dungeon (36–40), groups of 2+", "no_post": true}],
		"graveyard": Vector2(20, 80), "inn": Vector2(12, 74), "start": Vector2(0, 108), "sky": "day",
		"music": {"town": "wilds", "wild": "night"}, "forest": 0.15, "dead_trees": true, "fog": Color(0.55, 0.45, 0.65),
		"stations": [["forge", Vector2(20, 64), 1.5], ["tannery", Vector2(0, 78), 0.0], ["loom", Vector2(22, 78), 2.2], ["alchemy", Vector2(-2, 64), 0.6]], "tier": 6,
	},
	"catacombs": {
		"name": "The Varn Catacombs", "band": [36, 40], "seed": 37, "dungeon": true, "group": 2,
		"cave": {"wall": 4.4,
			"halls": [{"pts": [Vector2(0, 108), Vector2(0, 60), Vector2(-40, 40), Vector2(-40, -10), Vector2(0, -40)], "w": 4.0},
				{"pts": [Vector2(0, 60), Vector2(40, 40), Vector2(40, -10), Vector2(0, -40)], "w": 4.0}, {"pts": [Vector2(0, -40), Vector2(0, -84)], "w": 5.0}],
			"rooms": [{"at": Vector2(0, 100), "r": 9.0}, {"at": Vector2(0, 60), "r": 11.0}, {"at": Vector2(-40, 14), "r": 12.0}, {"at": Vector2(40, 14), "r": 12.0},
				{"at": Vector2(0, -40), "r": 12.0}, {"at": Vector2(0, -90), "r": 16.0}]},
		"relief": 0.4, "edge": 0.0, "plateaus": [], "ridges": [], "pond": null, "square": null, "roads": [],
		"palette": {"grass_a": Color(0.3, 0.27, 0.32), "grass_b": Color(0.34, 0.3, 0.35), "grass_c": Color(0.25, 0.22, 0.27), "dirt_a": Color(0.3, 0.27, 0.3), "dirt_b": Color(0.36, 0.32, 0.35)},
		"builders": ["mine"],
		"exits": [{"at": Vector2(0, 107), "r": 3.5, "to": "varn", "arrive": Vector2(0, -80), "name": "The way out", "sign": "Varn Plateau"}],
		"graveyard": Vector2(0, 100), "inn": Vector2(0, 100), "start": Vector2(0, 100), "sky": "cave", "music": {"town": "night", "wild": "night"},
	},
	"mine": {
		"name": "The Hollow Mine", "band": [12, 16], "seed": 5, "dungeon": true, "group": 2,
		"cave": {"wall": 4.2,
			"halls": [{"pts": [Vector2(0, 110), Vector2(0, 80), Vector2(-10, 56), Vector2(-30, 40)], "w": 4.0},
				{"pts": [Vector2(-30, 40), Vector2(-50, 20), Vector2(-52, -10)], "w": 3.5},
				{"pts": [Vector2(-10, 56), Vector2(20, 40), Vector2(40, 20), Vector2(44, -6)], "w": 3.5},
				{"pts": [Vector2(-52, -10), Vector2(-40, -36), Vector2(-10, -44)], "w": 3.5},
				{"pts": [Vector2(44, -6), Vector2(30, -34), Vector2(6, -46)], "w": 3.5},
				{"pts": [Vector2(-2, -48), Vector2(0, -74)], "w": 4.5}],
			"rooms": [{"at": Vector2(0, 104), "r": 9.0}, {"at": Vector2(-32, 40), "r": 10.0}, {"at": Vector2(-54, -12), "r": 12.0},
				{"at": Vector2(44, -8), "r": 12.0}, {"at": Vector2(-2, -46), "r": 11.0}, {"at": Vector2(0, -86), "r": 16.0}]},
		"relief": 0.6, "edge": 0.0, "plateaus": [], "ridges": [], "pond": null, "square": null, "roads": [],
		"palette": {"grass_a": Color(0.3, 0.27, 0.24), "grass_b": Color(0.36, 0.32, 0.27), "grass_c": Color(0.24, 0.22, 0.2),
			"dirt_a": Color(0.33, 0.28, 0.22), "dirt_b": Color(0.4, 0.34, 0.27)},
		"builders": ["mine"],
		"exits": [{"at": Vector2(0, 110), "r": 3.5, "to": "hollow", "arrive": Vector2(24, -74), "name": "The way out", "sign": "Hollow Cliffs"}],
		"graveyard": Vector2(0, 104), "inn": Vector2(0, 104), "start": Vector2(0, 104), "sky": "cave",
		"music": {"town": "night", "wild": "night"},
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["ashvale"])

static func v2(d: Dictionary, key: String) -> Vector2:
	return d.get(key, Vector2.ZERO)
