extends Node3D
## Monster camps around Ashvale, level 1 near town and harder further out, like a WoW starting zone.
## Each camp: a kind, a level range, how many, where. Camps pull together when one member is hit.

const CAMPS := [
	{"kind": "puglin", "lv": [1, 2], "n": 5, "at": Vector2(58, -20), "r": 12.0},
	{"kind": "puglin", "lv": [2, 3], "n": 5, "at": Vector2(86, -32), "r": 12.0},
	{"kind": "puglin", "lv": [3, 4], "n": 6, "at": Vector2(95, 25), "r": 12.0},
	{"kind": "skeleton_a", "lv": [4, 5], "n": 3, "at": Vector2(-66, -48), "r": 12.0},
	{"kind": "skeleton_b", "lv": [4, 6], "n": 3, "at": Vector2(-74, -58), "r": 12.0},
	{"kind": "imp", "lv": [5, 7], "n": 5, "at": Vector2(66, 60), "r": 12.0},
	{"kind": "lycan", "lv": [8, 8], "n": 1, "at": Vector2(-86, 78), "r": 2.0, "elite": true},
	{"kind": "tidebreaker", "lv": [10, 10], "n": 1, "at": Vector2(-60, 62), "r": 1.0, "elite": true},
	{"kind": "hellwarden", "lv": [12, 12], "n": 1, "at": Vector2(20, -96), "r": 1.0, "elite": true},
]

var monsters: Array = []

func _ready() -> void:
	add_to_group("spawns")
	if not ResourceLoader.exists("res://assets/licensed/monsters/Puglin.glb"):
		push_warning("Bestiary monsters not unpacked; no monsters this time"); return
	var rng := RandomNumberGenerator.new(); rng.seed = 1234
	var near := Vector2.INF
	var args: Dictionary = get_parent().args if "args" in get_parent() else {}
	if WorldData.lite and args.has("hero"):
		var hz: PackedStringArray = args["hero"].split(","); near = Vector2(float(hz[0]), float(hz[1]))
	for c in CAMPS:
		# slow test machines only get the camps near where the test starts
		if near != Vector2.INF and near.distance_to(c["at"]) > 70.0: continue
		var camp: Array = []
		for i in int(c["n"]):
			var m := Monster.new()
			m.setup(c["kind"], rng.randi_range(c["lv"][0], c["lv"][1]), c.get("elite", false))
			var a := rng.randf() * TAU; var d := sqrt(rng.randf()) * float(c["r"])
			var p := Vector3(c["at"].x + cos(a) * d, 0, c["at"].y + sin(a) * d)
			p = Nav.nearest_open(p); p.y = WorldData.h(p.x, p.z)
			add_child(m)
			m.global_position = p; m.home = p
			m.yaw = rng.randf() * TAU
			camp.append(m); monsters.append(m)
		for m in camp: m.camp = camp
