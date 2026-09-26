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
		"music": {"town": "town", "wild": "wilds"},
	},
	"hollow": {
		"name": "Hollow Cliffs", "band": [10, 16], "seed": 31, "relief": 11.0, "edge": 34.0,
		"plateaus": [{"at": Vector2(8, 26), "r0": 20.0, "r1": 40.0, "h": 9.0}, {"at": Vector2(24, -84), "r0": 12.0, "r1": 22.0, "h": 12.0},
			{"at": Vector2(-84, -84), "r0": 14.0, "r1": 26.0, "h": 22.0}],
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
			{"at": Vector2(122, 20), "r": 7.0, "to": "", "arrive": Vector2.ZERO, "name": "Cliff Road", "sign": "Mirewood (14–22) — the road is washed out"},
			{"at": Vector2(24, -92), "r": 3.5, "to": "mine", "arrive": Vector2(0, 104), "name": "The Hollow Mine", "sign": "Dungeon (12–16), groups of 2+", "no_post": true}],

		"graveyard": Vector2(0, 50), "inn": Vector2(4, 30), "start": Vector2(-2, 108), "sky": "day",
		"music": {"town": "wilds", "wild": "wilds"}, "forest": 0.35, "pines": true,
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
		"exits": [{"at": Vector2(0, 114), "r": 4.0, "to": "hollow", "arrive": Vector2(24, -74), "name": "The way out", "sign": "Hollow Cliffs"}],
		"graveyard": Vector2(0, 104), "inn": Vector2(0, 104), "start": Vector2(0, 104), "sky": "cave",
		"music": {"town": "night", "wild": "night"},
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["ashvale"])

static func v2(d: Dictionary, key: String) -> Vector2:
	return d.get(key, Vector2.ZERO)
