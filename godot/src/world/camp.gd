extends Node3D
## The Hollow Cliffs dressed as WORLD-LAYOUT.md describes: the Miners' Camp (tents not houses, a
## cook fire, ore carts, timber stacks, lanterns on posts), Lantern Row (cart rails up to the mine,
## lit at night), the mine mouth (a timber gantry cut into the cliff), the rockfall, and the Cairn
## Field's graves up on the high ground.

const B := "res://assets/buildings/"
const PR := "res://assets/props/"
const N := "res://assets/nature/"
const CAMP := Vector2(8, 26)
const MOUTH := Vector2(24, -91)

var lights: Array[OmniLight3D] = []
var flames: Array[Node3D] = []
var fire_light: OmniLight3D

func _ready() -> void:
	add_to_group("landmarks")
	# tents round the camp, doors toward the fire
	for t in [Vector2(-4, 22), Vector2(-2, 38), Vector2(22, 30), Vector2(17, 42), Vector2(-9, 30), Vector2(24, 18)]:
		var yaw := atan2(CAMP.x - t.x, CAMP.y - t.y)
		_model("tent", t, yaw, Vector3(1.8, 2.4, 2.4))
	_cook_fire(Vector2(1, 28))
	# carts, crates, barrels, a timber stack
	_model("cart", Vector2(15, 12), 0.2, Vector3(1.2, 1.4, 1.9))
	_model("cart", Vector2(21, -12), 0.1, Vector3(1.2, 1.4, 1.9))
	_model("cart", Vector2(26, -80), -0.1, Vector3(1.2, 1.4, 1.9))
	for p in [[Vector2(6, 18), "Crate_Wooden"], [Vector2(7, 17), "Barrel"], [Vector2(-1, 20), "Crate_Wooden"], [Vector2(12, 36), "Barrel_Holder"],
			[Vector2(4, 30.5), "Cauldron"], [Vector2(19, 24), "Workbench"], [Vector2(20, 22.5), "Anvil"], [Vector2(9, 16), "Pickaxe_Bronze"], [Vector2(14, 34), "Chest_Wood"]]:
		_prop(p[1], p[0], randf() * TAU)
	_timber_stack(Vector2(-8, 16))
	# Lantern Row: rails from the camp up to the mine, lanterns on posts along them
	var row := [Vector2(14, 0), Vector2(18, -30), Vector2(22, -60), Vector2(24, -86)]
	_rails(row)
	for i in row.size() - 1:
		var a: Vector2 = row[i]; var b: Vector2 = row[i + 1]
		var n := int(a.distance_to(b) / 11.0)
		for k in n:
			var p: Vector2 = a.lerp(b, (k + 0.5) / n) + (b - a).normalized().orthogonal() * 3.0
			_lantern_post(p)
	for p in [Vector2(2, 14), Vector2(16, 36), Vector2(-6, 26), Vector2(26, 26)]: _lantern_post(p)
	# the mine mouth: a gantry against the cliff, darkness behind it
	_mine_mouth()
	# the rockfall that opened the Scree
	for k in 9:
		var p := Vector2(-30, -8) + Vector2(randf_range(-6, 6), randf_range(-4, 4))
		_rock(p, randf_range(1.0, 2.2))
	# the Cairn Field: a ring of cairns round the graves
	for k in 7:
		var a := TAU * k / 7.0
		var c := Vector2(-84, -80) + Vector2(cos(a), sin(a)) * 17.0
		_cairn(c)
	# grave headstones stand where the pickups are (the blessing is the pickup)
	for pk in load("res://src/world/spawns.gd").PICKUPS["hollow"]:
		if pk.get("look", "") == "grave": _model("gravestone", pk["at"] + Vector2(0, -0.9), 0.0, Vector3.ZERO)

func _process(_d: float) -> void:
	var n := DayNight.night
	for l in lights: l.light_energy = 0.4 + n * 2.0
	for f in flames: f.visible = n > 0.05 or true
	if fire_light: fire_light.light_energy = 2.2 + sin(Time.get_ticks_msec() / 90.0) * 0.3 + sin(Time.get_ticks_msec() / 37.0) * 0.2

func _ground(p: Vector2) -> float:
	var y := INF
	for d in [Vector2.ZERO, Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]: y = minf(y, WorldData.h(p.x + d.x, p.y + d.y))
	return y

func _model(name: String, c: Vector2, yaw: float, solid: Vector3) -> Node3D:
	var path := B + name + ".glb"
	if not ResourceLoader.exists(path): return null
	var n: Node3D = load(path).instantiate()
	n.position = Vector3(c.x, _ground(c) - 0.04, c.y); n.rotation.y = yaw
	add_child(n)
	WorldData.clear_disc(c, maxf(solid.x, solid.z) + 0.8, 0.6)
	if solid != Vector3.ZERO:
		var body := StaticBody3D.new(); add_child(body)
		var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = solid * Vector3(2, 1, 2); cs.shape = sh
		body.position = n.position + Vector3(0, solid.y / 2.0, 0); body.rotation.y = yaw; body.add_child(cs)
	return n

func _prop(name: String, c: Vector2, yaw: float) -> void:
	var path := PR + name + ".gltf"
	if not ResourceLoader.exists(path): return
	var n: Node3D = load(path).instantiate()
	n.position = Vector3(c.x, WorldData.h(c.x, c.y), c.y); n.rotation.y = yaw
	add_child(n)

func _rock(c: Vector2, s: float) -> void:
	var path := N + "Rock_Medium_%d.gltf" % (1 + randi() % 3)
	if not ResourceLoader.exists(path): return
	var n: Node3D = load(path).instantiate()
	n.position = Vector3(c.x, WorldData.h(c.x, c.y) - 0.3 * s, c.y); n.rotation.y = randf() * TAU; n.scale = Vector3.ONE * s
	add_child(n)
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = 1.1 * s; sh.height = 2.0 * s; cs.shape = sh
	body.position = n.position + Vector3(0, s, 0); body.add_child(cs)
	WorldData.clear_disc(c, 1.4 * s, 0.4)

func _cook_fire(c: Vector2) -> void:
	var root := Node3D.new(); add_child(root)
	root.position = Vector3(c.x, WorldData.h(c.x, c.y), c.y)
	var stone := StandardMaterial3D.new(); stone.albedo_color = Color(0.45, 0.43, 0.4)
	for k in 9:
		var a := TAU * k / 9.0
		var s := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.22; sm.height = 0.3; sm.material = stone; s.mesh = sm
		root.add_child(s); s.position = Vector3(cos(a) * 0.8, 0.08, sin(a) * 0.8)
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.3, 0.2, 0.12)
	for k in 4:
		var l := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.07; cm.bottom_radius = 0.09; cm.height = 1.1; cm.material = wood; l.mesh = cm
		root.add_child(l); l.rotation = Vector3(0.5, TAU * k / 4.0, 0); l.position.y = 0.25
	var fx := get_tree().get_first_node_in_group("fx")
	var fire := Node3D.new(); root.add_child(fire); fire.position.y = 0.35
	flames.append(fire)
	# flames and smoke are made once Fx exists (it is added after the builders)
	_after_fx(func(f):
		f.emitter(fire, Color(1.0, 0.55, 0.15), 50, 0.45, 0.7, 1.2, 1.5, Fx.glow, 0.25)
		f.emitter(fire, Color(1.0, 0.85, 0.4), 30, 0.25, 0.5, 1.0, 1.0, Fx.spark, 0.2)
		f.emitter(fire, Color(0.35, 0.33, 0.32), 8, 1.1, 3.0, 1.1, 0.4, Fx.smoke, 0.3, false, false))
	fire_light = OmniLight3D.new(); fire_light.light_color = Color(1.0, 0.6, 0.28); fire_light.omni_range = 12.0; fire_light.shadow_enabled = true
	root.add_child(fire_light); fire_light.position.y = 1.0
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = 1.0; sh.height = 1.0; cs.shape = sh
	body.position = root.position + Vector3(0, 0.5, 0); body.add_child(cs)
	WorldData.clear_disc(c, 1.6, 0.5)

func _after_fx(f: Callable) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var fx := get_tree().get_first_node_in_group("fx")
	if fx: f.call(fx)

func _lantern_post(p: Vector2) -> void:
	var root := Node3D.new(); add_child(root)
	root.position = Vector3(p.x, WorldData.h(p.x, p.y), p.y)
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.36, 0.24, 0.14)
	var post := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.14, 2.6, 0.14); bm.material = wood; post.mesh = bm; post.position.y = 1.3; root.add_child(post)
	var arm := MeshInstance3D.new(); var am := BoxMesh.new(); am.size = Vector3(0.6, 0.1, 0.1); am.material = wood; arm.mesh = am; arm.position = Vector3(0.25, 2.5, 0); root.add_child(arm)
	var lamp := MeshInstance3D.new(); var lm := CylinderMesh.new(); lm.top_radius = 0.08; lm.bottom_radius = 0.12; lm.height = 0.26
	var glow := StandardMaterial3D.new(); glow.albedo_color = Color(1.0, 0.8, 0.5); glow.emission_enabled = true; glow.emission = Color(1.0, 0.62, 0.3); glow.emission_energy_multiplier = 2.5
	lm.material = glow; lamp.mesh = lm; lamp.position = Vector3(0.5, 2.3, 0); root.add_child(lamp)
	var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.65, 0.32); l.omni_range = 9.0; l.shadow_enabled = false
	lamp.add_child(l); lights.append(l)

func _rails(pts: Array) -> void:
	var iron := StandardMaterial3D.new(); iron.albedo_color = Color(0.3, 0.3, 0.33); iron.metallic = 0.7; iron.roughness = 0.4
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.38, 0.26, 0.16)
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]; var b: Vector2 = pts[i + 1]
		var d := b - a; var len := d.length(); var yaw := atan2(d.x, d.y)
		var steps := int(len / 1.0)
		for k in steps:
			var t := (k + 0.5) / steps
			var p := a.lerp(b, t)
			var y := WorldData.h(p.x, p.y)
			var tie := MeshInstance3D.new(); var tm := BoxMesh.new(); tm.size = Vector3(1.5, 0.08, 0.2); tm.material = wood; tie.mesh = tm
			add_child(tie); tie.position = Vector3(p.x, y + 0.04, p.y); tie.rotation.y = yaw
			for side in [-0.55, 0.55]:
				var r := MeshInstance3D.new(); var rm := BoxMesh.new(); rm.size = Vector3(0.07, 0.08, len / steps + 0.02); rm.material = iron; r.mesh = rm
				add_child(r); r.position = Vector3(p.x, y + 0.11, p.y) + Vector3(cos(yaw), 0, -sin(yaw)) * side; r.rotation.y = yaw

func _mine_mouth() -> void:
	var g := _model("gantry", MOUTH, 0.0, Vector3.ZERO)
	# darkness in the rock behind the gantry
	var dark := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(4.8, 4.4)
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.0, 0.0, 0.0); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; q.material = m
	dark.mesh = q; add_child(dark)
	dark.position = Vector3(MOUTH.x, _ground(MOUTH) + 2.2, MOUTH.y - 1.2)
	var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.65, 0.32); l.omni_range = 7.0; l.light_energy = 1.6
	add_child(l); l.position = Vector3(MOUTH.x + 1.6, _ground(MOUTH) + 3.4, MOUTH.y + 0.4); lights.append(l)

func _timber_stack(c: Vector2) -> void:
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.52, 0.38, 0.24)
	for r in 3:
		for i in 4 - r:
			var b := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(3.2, 0.3, 0.3); bm.material = wood; b.mesh = bm
			add_child(b); b.position = Vector3(c.x, WorldData.h(c.x, c.y) + 0.15 + r * 0.3, c.y + (i - (3 - r) / 2.0) * 0.32)
	WorldData.clear_disc(c, 2.0, 0.4)

func _cairn(c: Vector2) -> void:
	var stone := StandardMaterial3D.new(); stone.albedo_color = Color(0.55, 0.53, 0.5)
	var y := WorldData.h(c.x, c.y)
	for k in 5:
		var s := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.5 - k * 0.08; sm.height = (0.5 - k * 0.08) * 1.2; sm.material = stone; s.mesh = sm
		add_child(s); s.position = Vector3(c.x + randf_range(-0.08, 0.08), y + 0.2 + k * 0.42, c.y + randf_range(-0.08, 0.08))
