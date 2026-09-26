extends Node3D
## The Hollow Mine, inside: timber-propped galleries with lanterns and cart rails, the Diggers'
## Hall, the Grub Pit (slime and eggs), the Deep Rails, the Foreman's Gallery, and at the bottom
## the Hollow Throne, a hall of bones where the king sits. No sky: lanterns and dust in the dark.

const PR := "res://assets/props/"
var lamps: Array[OmniLight3D] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 17
	var cave: Dictionary = WorldData.Z["cave"]
	var wood := _mat(Color(0.36, 0.24, 0.14))
	# timber props across the halls every few metres, and a lantern on every third
	for hl in cave["halls"]:
		var pts: Array = hl["pts"]; var w: float = hl["w"]
		var k := 0
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]; var b: Vector2 = pts[i + 1]
			var n := int(a.distance_to(b) / 7.0)
			for j in n:
				var p := a.lerp(b, (j + 0.5) / n)
				_frame(p, b - a, w, wood, k % 3 == 0)
				k += 1
	# rails down the main gallery
	_rails([Vector2(0, 110), Vector2(0, 80), Vector2(-10, 56)])
	_rails([Vector2(-10, 56), Vector2(20, 40), Vector2(40, 20), Vector2(44, -2)])
	# lanterns hung in each room
	for rm in cave["rooms"]:
		var c: Vector2 = rm["at"]; var r: float = rm["r"]
		for t in 3:
			var a := TAU * t / 3.0 + 0.4
			_lamp(c + Vector2(cos(a), sin(a)) * (r - 1.5), 2.6)
	# the entrance hall: crates, a cart and the way out
	for p in [[Vector2(4, 102), "Crate_Wooden"], [Vector2(5, 104), "Barrel"], [Vector2(-5, 100), "Pickaxe_Bronze"], [Vector2(-4, 106), "Crate_Wooden"]]:
		_prop(p[1], p[0], rng.randf() * TAU)
	_cart(Vector2(-2, 96))
	var exit := OmniLight3D.new(); exit.light_color = Color(0.7, 0.8, 1.0); exit.omni_range = 10.0; exit.light_energy = 2.0
	add_child(exit); exit.position = Vector3(0, 3.0, 114)
	# the Diggers' Hall: sleeping rolls and a table
	for p in [[Vector2(-36, 44), "Table_Large"], [Vector2(-34, 46), "Mug"], [Vector2(-28, 36), "Barrel"], [Vector2(-38, 36), "Crate_Wooden"]]:
		_prop(p[1], p[0], rng.randf() * TAU)
	# the Grub Pit: slime on the floor and clutches of eggs
	_slime(Vector2(-54, -12), 9.0)
	for k in 10:
		var a := rng.randf() * TAU; var d := rng.randf_range(5.0, 10.0)
		_eggs(Vector2(-54, -12) + Vector2(cos(a), sin(a)) * d)
	# the Deep Rails: carts left where they stopped
	_cart(Vector2(40, -2)); _cart(Vector2(48, -14))
	# the Foreman's Gallery: Gault's desk and his lamp
	_prop("Table_Large", Vector2(4, -42), 0.3); _prop("CandleStick_Triple", Vector2(4, -42), 0.0); _prop("Scroll_1", Vector2(5, -41.5), 0.5); _prop("Chest_Wood", Vector2(-6, -40), 1.2)
	# the Hollow Throne: bones everywhere, and a throne of them
	_throne(Vector2(0, -98))
	for k in 30:
		var a2 := rng.randf() * TAU; var d2 := rng.randf_range(3.0, 14.0)
		_bones(Vector2(0, -86) + Vector2(cos(a2), sin(a2)) * d2)
	var eerie := OmniLight3D.new(); eerie.light_color = Color(0.45, 1.0, 0.6); eerie.omni_range = 18.0; eerie.light_energy = 1.4
	add_child(eerie); eerie.position = Vector3(0, 4.0, -96)
	# dust in the lantern light
	_after_fx(func(fx):
		for rm2 in cave["rooms"]:
			var n2 := Node3D.new(); add_child(n2); n2.position = Vector3(rm2["at"].x, 1.5, rm2["at"].y)
			var e: GPUParticles3D = fx.emitter(n2, Color(0.8, 0.7, 0.55), 6, 0.05, 6.0, 0.1, 0.0, Fx.spark, float(rm2["r"]) * 0.8)
			e.process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			e.process_material.emission_box_extents = Vector3(rm2["r"], 1.5, rm2["r"]))

func _process(_d: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in lamps.size():
		lamps[i].light_energy = 1.7 + sin(t * 5.3 + i) * 0.08 + sin(t * 11.0 + i * 2.0) * 0.05

func _mat(c: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = rough; return m

func _after_fx(f: Callable) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var fx := get_tree().get_first_node_in_group("fx")
	if fx: f.call(fx)

## two posts and a beam across a gallery
func _frame(p: Vector2, along: Vector2, w: float, wood: StandardMaterial3D, lamp: bool) -> void:
	var side := along.normalized().orthogonal()
	for s in [-1.0, 1.0]:
		var q: Vector2 = p + side * s * (w - 0.3)
		var post := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.28, 3.2, 0.28); bm.material = wood; post.mesh = bm
		add_child(post); post.position = Vector3(q.x, WorldData.h(q.x, q.y) + 1.6, q.y)
	var beam := MeshInstance3D.new(); var bb := BoxMesh.new(); bb.size = Vector3(w * 2.0 + 0.2, 0.3, 0.32); bb.material = wood; beam.mesh = bb
	add_child(beam); beam.position = Vector3(p.x, WorldData.h(p.x, p.y) + 3.25, p.y); beam.rotation.y = atan2(side.x, side.y) + PI / 2.0
	if lamp: _lamp(p + side * (w - 0.6), 2.9)

func _lamp(p: Vector2, h: float) -> void:
	var y := WorldData.h(p.x, p.y) + h
	var lm := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.07; cm.bottom_radius = 0.1; cm.height = 0.22
	var glow := StandardMaterial3D.new(); glow.albedo_color = Color(1.0, 0.8, 0.5); glow.emission_enabled = true; glow.emission = Color(1.0, 0.6, 0.28); glow.emission_energy_multiplier = 3.0
	cm.material = glow; lm.mesh = cm; add_child(lm); lm.position = Vector3(p.x, y, p.y)
	var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.62, 0.3); l.omni_range = 9.5; l.light_energy = 1.7; l.shadow_enabled = lamps.size() % 4 == 0
	lm.add_child(l); lamps.append(l)

func _prop(name: String, c: Vector2, yaw: float) -> void:
	var path := PR + name + ".gltf"
	if not ResourceLoader.exists(path): return
	var n: Node3D = load(path).instantiate()
	n.position = Vector3(c.x, WorldData.h(c.x, c.y), c.y); n.rotation.y = yaw
	add_child(n)

func _cart(c: Vector2) -> void:
	var path := "res://assets/buildings/cart.glb"
	if not ResourceLoader.exists(path): return
	var n: Node3D = load(path).instantiate()
	n.position = Vector3(c.x, WorldData.h(c.x, c.y), c.y); n.rotation.y = rng.randf_range(-0.3, 0.3)
	add_child(n)
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(1.3, 1.4, 1.9); cs.shape = sh
	body.position = n.position + Vector3(0, 0.7, 0); body.add_child(cs)

func _rails(pts: Array) -> void:
	var iron := _mat(Color(0.3, 0.3, 0.33), 0.4); iron.metallic = 0.7
	var wood := _mat(Color(0.34, 0.23, 0.14))
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]; var b: Vector2 = pts[i + 1]
		var d := b - a; var yaw := atan2(d.x, d.y)
		var steps := int(d.length())
		for k in steps:
			var p := a.lerp(b, (k + 0.5) / steps)
			var y := WorldData.h(p.x, p.y)
			var tie := MeshInstance3D.new(); var tm := BoxMesh.new(); tm.size = Vector3(1.4, 0.08, 0.2); tm.material = wood; tie.mesh = tm
			add_child(tie); tie.position = Vector3(p.x, y + 0.04, p.y); tie.rotation.y = yaw
			for s in [-0.5, 0.5]:
				var r := MeshInstance3D.new(); var rm := BoxMesh.new(); rm.size = Vector3(0.07, 0.08, d.length() / steps + 0.02); rm.material = iron; r.mesh = rm
				add_child(r); r.position = Vector3(p.x, y + 0.11, p.y) + Vector3(cos(yaw), 0, -sin(yaw)) * s; r.rotation.y = yaw

func _slime(c: Vector2, r: float) -> void:
	var mi := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = r; cm.bottom_radius = r; cm.height = 0.04; cm.radial_segments = 24
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.35, 0.45, 0.15, 0.8); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true; m.emission = Color(0.3, 0.5, 0.1); m.emission_energy_multiplier = 0.4; m.roughness = 0.15
	cm.material = m; mi.mesh = cm; add_child(mi); mi.position = Vector3(c.x, WorldData.h(c.x, c.y) + 0.05, c.y)

func _eggs(c: Vector2) -> void:
	var m := _mat(Color(0.85, 0.82, 0.62), 0.4)
	m.emission_enabled = true; m.emission = Color(0.4, 0.5, 0.15); m.emission_energy_multiplier = 0.25
	for k in 4:
		var e := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.22; sm.height = 0.5; sm.material = m; e.mesh = sm
		add_child(e); e.position = Vector3(c.x + rng.randf_range(-0.4, 0.4), WorldData.h(c.x, c.y) + 0.2, c.y + rng.randf_range(-0.4, 0.4))

func _bones(c: Vector2) -> void:
	var m := _mat(Color(0.86, 0.83, 0.74), 0.6)
	var y := WorldData.h(c.x, c.y)
	for k in 3:
		var b := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.04; cm.bottom_radius = 0.05; cm.height = rng.randf_range(0.4, 0.8); cm.material = m; b.mesh = cm
		add_child(b); b.position = Vector3(c.x + rng.randf_range(-0.4, 0.4), y + 0.05, c.y + rng.randf_range(-0.4, 0.4)); b.rotation = Vector3(PI / 2, rng.randf() * TAU, 0)
	if rng.randf() < 0.4:
		var s := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.14; sm.height = 0.26; sm.material = m; s.mesh = sm
		add_child(s); s.position = Vector3(c.x, y + 0.12, c.y)

func _throne(c: Vector2) -> void:
	var m := _mat(Color(0.8, 0.77, 0.68), 0.7)
	var y := WorldData.h(c.x, c.y)
	var seat := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(2.2, 1.0, 1.6); bm.material = m; seat.mesh = bm
	add_child(seat); seat.position = Vector3(c.x, y + 0.5, c.y)
	var back := MeshInstance3D.new(); var bk := BoxMesh.new(); bk.size = Vector3(2.4, 3.4, 0.4); bk.material = m; back.mesh = bk
	add_child(back); back.position = Vector3(c.x, y + 1.7, c.y - 0.9)
	for k in 7:
		var sp := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.0; cm.bottom_radius = 0.12; cm.height = 1.0; cm.material = m; sp.mesh = cm
		add_child(sp); sp.position = Vector3(c.x - 1.1 + k * 0.37, y + 3.7, c.y - 0.9)
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(2.6, 3.0, 2.2); cs.shape = sh
	body.position = Vector3(c.x, y + 1.5, c.y - 0.3); body.add_child(cs)
