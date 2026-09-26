extends Node3D
## Who lives where in Ashvale Province (docs/QUESTS.md, part A): the townsfolk who give quests,
## the monster camps the quests send you to, and the things on the ground you pick up.
## Level 1 near town, harder further out, like a WoW starting zone. Camps pull together when one
## member is hit.

const CAMPS := {"ashvale": [
		# ---- around town (1–4)
		{"kind": "field_rat", "lv": [1, 2], "n": 9, "at": Vector2(-27, 25), "r": 9.0},
		{"kind": "hen", "lv": [1, 1], "n": 7, "at": Vector2(-5, 10), "r": 5.0},
		{"kind": "scarecrow", "lv": [2, 3], "n": 8, "at": Vector2(-64, 14), "r": 11.0},
		{"kind": "grizzled_rat", "lv": [4, 4], "n": 1, "at": Vector2(-11, -35), "r": 0.5},
		# ---- the Mill (4–10)
		{"kind": "wild_boar", "lv": [3, 5], "n": 12, "at": Vector2(73, 40), "r": 13.0},
		{"kind": "wildcat", "lv": [4, 6], "n": 9, "at": Vector2(99, -12), "r": 15.0},
		{"kind": "old_scratch", "lv": [8, 8], "n": 1, "at": Vector2(105, -36), "r": 0.5},
		{"kind": "skeleton_a", "lv": [5, 6], "n": 4, "at": Vector2(66, -82), "r": 9.0},
		{"kind": "skeleton_b", "lv": [6, 7], "n": 4, "at": Vector2(80, -90), "r": 9.0},
	
		{"kind": "hogtooth", "lv": [9, 9], "n": 1, "at": Vector2(100, 52), "r": 0.5, "elite": true},
		{"kind": "old_tusk", "lv": [10, 10], "n": 1, "at": Vector2(96, 70), "r": 0.5},
		# ---- the north road, where the wolves are (the way to the Miners' Camp)
		{"kind": "wolf", "lv": [8, 10], "n": 5, "at": Vector2(-12, -86), "r": 12.0},
	],
	"hollow": [
		# ---- the Hollow Road up from Ashvale
		{"kind": "wolf", "lv": [10, 11], "n": 4, "at": Vector2(4, 82), "r": 12.0},
		# ---- the Scree and the Upper Tunnels, west of the camp
		{"kind": "cave_bat", "lv": [10, 11], "n": 10, "at": Vector2(-54, 12), "r": 15.0},
		{"kind": "cave_maggot", "lv": [10, 12], "n": 9, "at": Vector2(-36, -40), "r": 16.0},

		# ---- Lantern Row: the old cart rails up to the mine
		{"kind": "rail_spider", "lv": [12, 13], "n": 7, "at": Vector2(36, -54), "r": 12.0},
		# ---- Skarr's Cut, east
		{"kind": "hollow_digger", "lv": [12, 14], "n": 8, "at": Vector2(62, -12), "r": 12.0},
		{"kind": "skarr", "lv": [15, 15], "n": 1, "at": Vector2(74, -22), "r": 0.5},
		{"kind": "brak", "lv": [15, 15], "n": 1, "at": Vector2(86, -34), "r": 0.5, "elite": true},
		# ---- Rockjaw's Den, south-east
		{"kind": "mountain_bear", "lv": [12, 13], "n": 4, "at": Vector2(60, 58), "r": 12.0},
		{"kind": "rockjaw", "lv": [14, 14], "n": 1, "at": Vector2(78, 70), "r": 0.5, "elite": true},
		# ---- the Cairn Field, the high north-west
		{"kind": "skeleton_a", "lv": [12, 13], "n": 5, "at": Vector2(-78, -70), "r": 12.0, "as": "cairn_dead"},
	],
	"mirewood": [
		{"kind": "mire_goblin", "lv": [14, 16], "n": 6, "at": Vector2(28, 62), "r": 9.0},
		{"kind": "goblin_shaman", "lv": [15, 16], "n": 2, "at": Vector2(28, 62), "r": 5.0},
		{"kind": "mire_goblin", "lv": [15, 17], "n": 6, "at": Vector2(62, 62), "r": 9.0},
		{"kind": "goblin_shaman", "lv": [16, 17], "n": 2, "at": Vector2(62, 62), "r": 5.0},
		{"kind": "mire_goblin", "lv": [16, 18], "n": 6, "at": Vector2(100, -16), "r": 9.0},
		{"kind": "goblin_lieutenant", "lv": [18, 18], "n": 1, "at": Vector2(104, -20), "r": 0.5},
		{"kind": "goblin_warlord", "lv": [20, 20], "n": 1, "at": Vector2(100, 44), "r": 0.5, "elite": true},
		{"kind": "mire_goblin", "lv": [18, 19], "n": 4, "at": Vector2(96, 44), "r": 7.0, "elite": true},
		{"kind": "viper", "lv": [14, 16], "n": 9, "at": Vector2(-60, -30), "r": 16.0},
		{"kind": "temple_moth", "lv": [15, 17], "n": 9, "at": Vector2(-62, -76), "r": 15.0},
		{"kind": "marsh_stalker", "lv": [17, 19], "n": 7, "at": Vector2(96, 10), "r": 14.0},
		{"kind": "wolf", "lv": [14, 15], "n": 4, "at": Vector2(-96, 30), "r": 10.0},
	],
	"warrens": [
		{"kind": "rail_spider", "lv": [17, 18], "n": 4, "at": Vector2(-24, 40), "r": 6.0, "elite": true},
		{"kind": "temple_moth", "lv": [17, 18], "n": 3, "at": Vector2(0, 60), "r": 5.0, "elite": true},
		{"kind": "broodmother", "lv": [20, 20], "n": 1, "at": Vector2(52, -2), "r": 0.5, "boss": true},
		{"kind": "viper", "lv": [18, 19], "n": 4, "at": Vector2(-30, 2), "r": 6.0, "elite": true},
		{"kind": "marsh_stalker", "lv": [19, 20], "n": 3, "at": Vector2(30, -40), "r": 5.0, "elite": true},
		{"kind": "rootmaw", "lv": [22, 22], "n": 1, "at": Vector2(40, -90), "r": 0.5, "boss": true},
	],
	"ashslopes": [
		{"kind": "stone_sentinel", "lv": [20, 22], "n": 9, "at": Vector2(-56, 20), "r": 16.0},
		{"kind": "khar_cultist", "lv": [21, 23], "n": 5, "at": Vector2(-66, -48), "r": 10.0},
		{"kind": "khar_zealot", "lv": [22, 23], "n": 4, "at": Vector2(-70, -56), "r": 9.0},
		{"kind": "temple_archer", "lv": [21, 23], "n": 7, "at": Vector2(84, -26), "r": 14.0},
		{"kind": "cinder_imp", "lv": [23, 25], "n": 9, "at": Vector2(70, 60), "r": 14.0},
		{"kind": "stone_warden", "lv": [26, 26], "n": 1, "at": Vector2(96, -84), "r": 0.5, "elite": true},
		{"kind": "khar_cultist", "lv": [24, 25], "n": 4, "at": Vector2(14, -60), "r": 8.0},
		{"kind": "temple_moth", "lv": [20, 21], "n": 6, "at": Vector2(-90, 60), "r": 14.0},
	],
	"highlands": [
		{"kind": "khar_beastman", "lv": [26, 28], "n": 9, "at": Vector2(-8, -64), "r": 14.0},
		{"kind": "khar_elite", "lv": [29, 30], "n": 5, "at": Vector2(82, -68), "r": 9.0},
		{"kind": "brandmaster", "lv": [31, 31], "n": 1, "at": Vector2(84, -76), "r": 0.5},
		{"kind": "bull_of_khar", "lv": [33, 33], "n": 1, "at": Vector2(84, -18), "r": 0.5, "elite": true},
		{"kind": "highland_wolf", "lv": [27, 28], "n": 10, "at": Vector2(-84, 10), "r": 16.0},
		{"kind": "highland_bear", "lv": [28, 30], "n": 6, "at": Vector2(40, 84), "r": 14.0},
		{"kind": "khar_beastman", "lv": [28, 29], "n": 6, "at": Vector2(60, -30), "r": 12.0},
	],
	"crypts": [
		{"kind": "drowned_dead", "lv": [30, 31], "n": 4, "at": Vector2(0, 70), "r": 6.0, "elite": true},
		{"kind": "drowned_dead", "lv": [31, 32], "n": 4, "at": Vector2(30, 24), "r": 6.0, "elite": true},
		{"kind": "lady_silt", "lv": [33, 33], "n": 1, "at": Vector2(-30, 16), "r": 0.5, "boss": true},
		{"kind": "drowned_dead", "lv": [32, 33], "n": 4, "at": Vector2(0, -30), "r": 6.0, "elite": true},
		{"kind": "crypt_lord", "lv": [34, 34], "n": 1, "at": Vector2(0, -92), "r": 0.5, "boss": true},
	],
	"varn": [
		{"kind": "fallen_wraith", "lv": [34, 36], "n": 12, "at": Vector2(-60, 10), "r": 18.0},
		{"kind": "circle_acolyte", "lv": [37, 37], "n": 3, "at": Vector2(60, -30), "r": 7.0},
		{"kind": "lich_acolyte", "lv": [35, 36], "n": 4, "at": Vector2(60, -30), "r": 11.0},
		{"kind": "abyssal_knight", "lv": [36, 38], "n": 8, "at": Vector2(0, -46), "r": 16.0},
		{"kind": "vaals_herald", "lv": [40, 40], "n": 1, "at": Vector2(-84, -26), "r": 0.5, "elite": true},
		{"kind": "lich_acolyte", "lv": [37, 38], "n": 4, "at": Vector2(-80, -40), "r": 8.0},
	],
	"catacombs": [
		{"kind": "fallen_wraith", "lv": [37, 38], "n": 4, "at": Vector2(0, 60), "r": 6.0, "elite": true},
		{"kind": "lich_acolyte", "lv": [37, 38], "n": 3, "at": Vector2(-40, 30), "r": 5.0, "elite": true},
		{"kind": "gravewarden", "lv": [39, 39], "n": 1, "at": Vector2(-40, 8), "r": 0.5, "boss": true},
		{"kind": "abyssal_knight", "lv": [38, 39], "n": 4, "at": Vector2(40, 14), "r": 6.0, "elite": true},
		{"kind": "fallen_wraith", "lv": [38, 39], "n": 4, "at": Vector2(0, -40), "r": 6.0, "elite": true},
		{"kind": "lord_varn", "lv": [41, 41], "n": 1, "at": Vector2(0, -94), "r": 0.5, "boss": true},
	],
	"temple": [
		{"kind": "khar_zealot", "lv": [24, 25], "n": 4, "at": Vector2(0, 60), "r": 7.0, "elite": true},
		{"kind": "khar_cultist", "lv": [24, 25], "n": 3, "at": Vector2(-40, 20), "r": 5.0, "elite": true},
		{"kind": "bellringer", "lv": [26, 26], "n": 1, "at": Vector2(-40, -4), "r": 0.5, "boss": true},
		{"kind": "cinder_imp", "lv": [25, 26], "n": 4, "at": Vector2(40, 20), "r": 5.0, "elite": true},
		{"kind": "ashmaw", "lv": [27, 27], "n": 1, "at": Vector2(40, -4), "r": 0.5, "boss": true},
		{"kind": "stone_sentinel", "lv": [26, 27], "n": 3, "at": Vector2(0, -40), "r": 6.0, "elite": true},
		{"kind": "mora", "lv": [28, 28], "n": 1, "at": Vector2(0, -92), "r": 0.5, "boss": true},
	],
	"mine": [
		{"kind": "hollow_digger", "lv": [13, 14], "n": 4, "at": Vector2(-32, 40), "r": 6.0, "elite": true},
		{"kind": "cave_bat", "lv": [13, 13], "n": 3, "at": Vector2(-18, 50), "r": 4.0, "elite": true},
		{"kind": "grub_mother", "lv": [15, 15], "n": 1, "at": Vector2(-56, -14), "r": 0.5, "boss": true},
		{"kind": "cave_maggot", "lv": [13, 14], "n": 4, "at": Vector2(-46, 8), "r": 5.0, "elite": true},
		{"kind": "rail_spider", "lv": [13, 14], "n": 4, "at": Vector2(40, 8), "r": 6.0, "elite": true},
		{"kind": "hollow_digger", "lv": [14, 14], "n": 3, "at": Vector2(44, -12), "r": 5.0, "elite": true},
		{"kind": "gault", "lv": [16, 16], "n": 1, "at": Vector2(-2, -50), "r": 0.5, "boss": true},
		{"kind": "skeleton_b", "lv": [14, 15], "n": 4, "at": Vector2(0, -66), "r": 4.0, "elite": true},
		{"kind": "bone_king", "lv": [17, 17], "n": 1, "at": Vector2(0, -90), "r": 0.5, "boss": true},
	],
}

## quest things lying on the ground, by zone
const PICKUPS := {"ashvale": [
		{"item": "lamb_bell", "quest": "lost_lamb", "at": Vector2(104, 31), "look": "bell"},
		{"item": "old_coin", "quest": "rowans_history", "at": Vector2(69, -81)},
		{"item": "old_coin", "quest": "rowans_history", "at": Vector2(75, -87)},
		{"item": "old_coin", "quest": "rowans_history", "at": Vector2(66, -88)},
		{"item": "old_coin", "quest": "rowans_history", "at": Vector2(78, -80)},
		{"item": "old_coin", "quest": "rowans_history", "at": Vector2(71, -91)},
		{"item": "old_coin", "quest": "rowans_history", "at": Vector2(64, -78)},
		{"item": "old_coin", "quest": "rowans_history", "at": Vector2(80, -89)},
	],
	"hollow": [
		{"item": "black_iron_ore", "quest": "digging_where", "at": Vector2(20, -34), "look": "ore"},
		{"item": "black_iron_ore", "quest": "digging_where", "at": Vector2(24, -46), "look": "ore"},
		{"item": "black_iron_ore", "quest": "digging_where", "at": Vector2(16, -58), "look": "ore"},
		{"item": "black_iron_ore", "quest": "digging_where", "at": Vector2(-26, -30), "look": "ore"},
		{"item": "black_iron_ore", "quest": "digging_where", "at": Vector2(-44, -46), "look": "ore"},
		{"item": "black_iron_ore", "quest": "digging_where", "at": Vector2(-30, -52), "look": "ore"},
		{"item": "black_iron_ore", "quest": "digging_where", "at": Vector2(28, -70), "look": "ore"},
		{"item": "black_iron_ore", "quest": "digging_where", "at": Vector2(-18, -20), "look": "ore"},
		{"item": "grave_blessing", "quest": "rest_for_restless", "at": Vector2(-90, -80), "look": "grave"},
		{"item": "grave_blessing", "quest": "rest_for_restless", "at": Vector2(-82, -92), "look": "grave"},
		{"item": "grave_blessing", "quest": "rest_for_restless", "at": Vector2(-74, -86), "look": "grave"},
		{"item": "grave_blessing", "quest": "rest_for_restless", "at": Vector2(-92, -70), "look": "grave"},
		{"item": "grave_blessing", "quest": "rest_for_restless", "at": Vector2(-78, -76), "look": "grave"},
		{"item": "grave_blessing", "quest": "rest_for_restless", "at": Vector2(-86, -62), "look": "grave"},
	],
	"mine": [],
	"mirewood": [
		{"item": "totem_smashed", "quest": "shamans_totems", "at": Vector2(28, 66), "look": "totem"},
		{"item": "totem_smashed", "quest": "shamans_totems", "at": Vector2(24, 58), "look": "totem"},
		{"item": "totem_smashed", "quest": "shamans_totems", "at": Vector2(62, 66), "look": "totem"},
		{"item": "totem_smashed", "quest": "shamans_totems", "at": Vector2(58, 58), "look": "totem"},
		{"item": "totem_smashed", "quest": "shamans_totems", "at": Vector2(66, 58), "look": "totem"},
		{"item": "totem_smashed", "quest": "shamans_totems", "at": Vector2(32, 58), "look": "totem"},
	],
	"warrens": [],
	"ashslopes": [], "temple": [], "crypts": [], "varn": [], "catacombs": [],
	"highlands": [
		{"item": "highland_oats", "quest": "a_horse_is_a_horse", "at": Vector2(-72, 74), "look": "oats"},
		{"item": "highland_oats", "quest": "a_horse_is_a_horse", "at": Vector2(-66, 78), "look": "oats"},
		{"item": "highland_oats", "quest": "a_horse_is_a_horse", "at": Vector2(-76, 80), "look": "oats"},
		{"item": "highland_oats", "quest": "a_horse_is_a_horse", "at": Vector2(-84, -28), "look": "oats"},
		{"item": "highland_oats", "quest": "a_horse_is_a_horse", "at": Vector2(-90, -32), "look": "oats"},
		{"item": "highland_bloom", "quest": "highland_bloom", "at": Vector2(-60, 0), "look": "bloom"},
		{"item": "highland_bloom", "quest": "highland_bloom", "at": Vector2(-40, -20), "look": "bloom"},
		{"item": "highland_bloom", "quest": "highland_bloom", "at": Vector2(20, 80), "look": "bloom"},
		{"item": "highland_bloom", "quest": "highland_bloom", "at": Vector2(-20, 90), "look": "bloom"},
		{"item": "highland_bloom", "quest": "highland_bloom", "at": Vector2(-96, 60), "look": "bloom"},
		{"item": "highland_bloom", "quest": "highland_bloom", "at": Vector2(10, -20), "look": "bloom"},
	],
}




static func camps() -> Array: return CAMPS.get(WorldData.zone_id, [])
static func pickups() -> Array: return PICKUPS.get(WorldData.zone_id, [])

var monsters: Array = []
var npcs: Array = []

func _ready() -> void:
	add_to_group("spawns")
	var args: Dictionary = get_parent().args if "args" in get_parent() else {}
	_people()
	for pk in pickups():
		var p := Pickup.new(); p.setup(pk["item"], pk["quest"], pk.get("look", "coin"))
		add_child(p)
		var at := Vector3(pk["at"].x, 0, pk["at"].y); at.y = WorldData.h(at.x, at.z) + 0.02
		p.global_position = at
	_resources()
	if args.has("nomonsters"): return
	var rng := RandomNumberGenerator.new(); rng.seed = 1234
	var near := Vector2.INF
	if WorldData.lite and args.has("hero"):
		var hz: PackedStringArray = args["hero"].split(","); near = Vector2(float(hz[0]), float(hz[1]))
	for c in camps():
		var d: Dictionary = Monster.KINDS[c["kind"]]
		if d.has("model") and not ResourceLoader.exists("res://assets/licensed/monsters/%s.glb" % d["model"]): continue
		# slow test machines only get the camps near where the test starts
		if near != Vector2.INF and near.distance_to(c["at"]) > 45.0: continue
		var camp: Array = []
		for i in int(c["n"]):
			var m := Monster.new()
			m.setup(c["kind"], rng.randi_range(c["lv"][0], c["lv"][1]), c.get("elite", false) or c.get("boss", false))
			if c.get("boss", false): m.boss = true
			var a := rng.randf() * TAU; var dd := sqrt(rng.randf()) * float(c["r"])
			var p := Vector3(c["at"].x + cos(a) * dd, 0, c["at"].y + sin(a) * dd)
			p = Nav.nearest_open(p); p.y = WorldData.h(p.x, p.z)
			add_child(m)
			m.global_position = p; m.home = p
			m.yaw = rng.randf() * TAU
			camp.append(m); monsters.append(m)
		for m in camp: m.camp = camp

## monsters that appear because of something you did (the shrine's dead climbing out of the ground)
func rise(kind: String, n: int, lv: int, near: Vector3, at_whom: Unit) -> void:
	for i in n:
		var m := Monster.new(); m.setup(kind, lv)
		add_child(m)
		var p := Nav.nearest_open(near + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5)) + (near - at_whom.global_position).normalized() * 3.0)
		p.y = WorldData.h(p.x, p.z)
		m.global_position = p - Vector3(0, 1.6, 0); m.home = p
		m.respawn_t = 1e9
		var tw := m.create_tween(); tw.tween_property(m, "global_position:y", p.y, 1.2)
		get_tree().call_group("fx", "burst", p + Vector3(0, 0.2, 0), Color(0.45, 0.4, 0.35), 30, 3.0, 0.5, 1.0, -3.0, Fx.smoke, 70.0, Vector3.UP, false, 0.6)
		m.get_tree().create_timer(1.3).timeout.connect(func(): if is_instance_valid(m) and is_instance_valid(at_whom): m.aggro(at_whom))
		# they don't come back once put down
		m.died.connect(func(_u): m.get_tree().create_timer(20.0).timeout.connect(m.queue_free))

## ore veins on the rougher ground, herbs in the grass: scattered by the zone's seed
func _resources() -> void:
	var tier := int(WorldData.Z.get("tier", 0))
	if tier == 0: return
	var rng := RandomNumberGenerator.new(); rng.seed = int(WorldData.Z.get("seed", 1)) * 31
	for kind in ["ore", "herb"]:
		var placed := 0; var tries := 0
		while placed < (14 if kind == "ore" else 18) and tries < 3000:
			tries += 1
			var p := Vector2(rng.randf_range(-110, 110), rng.randf_range(-110, 110))
			if WorldData.town_w(p) > 0.15 or WorldData.road(p).x < 4.0 or WorldData.in_water(p.x, p.y): continue
			var steep := 1.0 - WorldData.n(p.x, p.y).y
			if kind == "ore" and steep < 0.06 and rng.randf() < 0.7: continue
			if kind == "herb" and steep > 0.12: continue
			var at := Vector3(p.x, 0, p.y)
			if not Nav.walkable(at): continue
			var n := ResourceNode.new(); n.setup(kind, tier); add_child(n)
			at.y = WorldData.h(p.x, p.y); n.global_position = at
			placed += 1

func _people() -> void:


	for id in Npcs.LIST:
		var info: Dictionary = Npcs.LIST[id]
		if info.get("zone", "ashvale") != WorldData.zone_id: continue
		var n := Npc.new(); n.setup(id)
		add_child(n)
		var at := Vector3(info["at"][0], 0, info["at"][1])
		at.y = WorldData.h(at.x, at.z)
		n.global_position = at; n.home = at
		npcs.append(n)
