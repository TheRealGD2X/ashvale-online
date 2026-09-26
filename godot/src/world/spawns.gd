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
		{"kind": "cave_maggot", "lv": [11, 12], "n": 10, "at": Vector2(-36, -40), "r": 13.0},
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
