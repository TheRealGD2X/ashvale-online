extends Node3D
## Who lives where in Ashvale Province (docs/QUESTS.md, part A): the townsfolk who give quests,
## the monster camps the quests send you to, and the things on the ground you pick up.
## Level 1 near town, harder further out, like a WoW starting zone. Camps pull together when one
## member is hit.

const CAMPS := [
	# ---- around town (1–4)
	{"kind": "field_rat", "lv": [1, 2], "n": 9, "at": Vector2(-27, 25), "r": 9.0},
	{"kind": "hen", "lv": [1, 1], "n": 7, "at": Vector2(-5, 10), "r": 5.0},
	{"kind": "scarecrow", "lv": [2, 3], "n": 8, "at": Vector2(-64, 14), "r": 11.0},
	{"kind": "grizzled_rat", "lv": [4, 4], "n": 1, "at": Vector2(-11, -35), "r": 0.5},
	# ---- the Mill (4–10)
	{"kind": "wild_boar", "lv": [3, 5], "n": 12, "at": Vector2(73, 40), "r": 13.0},
	{"kind": "wildcat", "lv": [5, 7], "n": 9, "at": Vector2(99, -12), "r": 11.0},
	{"kind": "old_scratch", "lv": [8, 8], "n": 1, "at": Vector2(105, -36), "r": 0.5},
	{"kind": "skeleton_a", "lv": [6, 7], "n": 4, "at": Vector2(72, -84), "r": 6.0},
	{"kind": "skeleton_b", "lv": [7, 8], "n": 4, "at": Vector2(72, -84), "r": 8.0},
	{"kind": "hogtooth", "lv": [9, 9], "n": 1, "at": Vector2(100, 52), "r": 0.5, "elite": true},
	{"kind": "old_tusk", "lv": [10, 10], "n": 1, "at": Vector2(96, 70), "r": 0.5},
	# ---- the north road, where the wolves are (the way to the Miners' Camp)
	{"kind": "wolf", "lv": [8, 10], "n": 5, "at": Vector2(-12, -86), "r": 12.0},
]

## quest things lying on the ground
const PICKUPS := [
	{"item": "lamb_bell", "quest": "lost_lamb", "at": Vector2(104, 31), "look": "bell"},
	{"item": "old_coin", "quest": "rowans_history", "at": Vector2(69, -81)},
	{"item": "old_coin", "quest": "rowans_history", "at": Vector2(75, -87)},
	{"item": "old_coin", "quest": "rowans_history", "at": Vector2(66, -88)},
	{"item": "old_coin", "quest": "rowans_history", "at": Vector2(78, -80)},
	{"item": "old_coin", "quest": "rowans_history", "at": Vector2(71, -91)},
	{"item": "old_coin", "quest": "rowans_history", "at": Vector2(64, -78)},
	{"item": "old_coin", "quest": "rowans_history", "at": Vector2(80, -89)},
]

var monsters: Array = []
var npcs: Array = []

func _ready() -> void:
	add_to_group("spawns")
	var args: Dictionary = get_parent().args if "args" in get_parent() else {}
	_people()
	for pk in PICKUPS:
		var p := Pickup.new(); p.setup(pk["item"], pk["quest"], pk.get("look", "coin"))
		add_child(p)
		var at := Vector3(pk["at"].x, 0, pk["at"].y); at.y = WorldData.h(at.x, at.z) + 0.02
		p.global_position = at
	if args.has("nomonsters"): return
	var rng := RandomNumberGenerator.new(); rng.seed = 1234
	var near := Vector2.INF
	if WorldData.lite and args.has("hero"):
		var hz: PackedStringArray = args["hero"].split(","); near = Vector2(float(hz[0]), float(hz[1]))
	for c in CAMPS:
		var d: Dictionary = Monster.KINDS[c["kind"]]
		if d.has("model") and not ResourceLoader.exists("res://assets/licensed/monsters/%s.glb" % d["model"]): continue
		# slow test machines only get the camps near where the test starts
		if near != Vector2.INF and near.distance_to(c["at"]) > 45.0: continue
		var camp: Array = []
		for i in int(c["n"]):
			var m := Monster.new()
			m.setup(c["kind"], rng.randi_range(c["lv"][0], c["lv"][1]), c.get("elite", false))
			var a := rng.randf() * TAU; var dd := sqrt(rng.randf()) * float(c["r"])
			var p := Vector3(c["at"].x + cos(a) * dd, 0, c["at"].y + sin(a) * dd)
			p = Nav.nearest_open(p); p.y = WorldData.h(p.x, p.z)
			add_child(m)
			m.global_position = p; m.home = p
			m.yaw = rng.randf() * TAU
			camp.append(m); monsters.append(m)
		for m in camp: m.camp = camp

func _people() -> void:
	for id in Npcs.LIST:
		var info: Dictionary = Npcs.LIST[id]
		if info.has("zone") and info["zone"] != "ashvale": continue
		var n := Npc.new(); n.setup(id)
		add_child(n)
		var at := Vector3(info["at"][0], 0, info["at"][1])
		at.y = WorldData.h(at.x, at.z)
		n.global_position = at; n.home = at
		npcs.append(n)
