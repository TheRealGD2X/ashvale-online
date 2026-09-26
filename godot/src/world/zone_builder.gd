class_name ZoneBuilder extends Node3D
## Shared pieces for dressing a zone: models from the buildings folder, tents, braziers, palisades,
## watchtowers, banners, stone walls and arches, crop fields. Zone scripts extend this.

const B := "res://assets/buildings/"
const PR := "res://assets/props/"
var fires: Array[OmniLight3D] = []
var rng := RandomNumberGenerator.new()

func _process(_d: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in fires.size(): fires[i].light_energy = 1.6 + DayNight.night * 1.4 + sin(t * 7.0 + i) * 0.2

func mat(c: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = rough; return m

func ground(p: Vector2) -> float:
	return WorldData.h(p.x, p.y)

func box(size: Vector3, p: Vector2, y: float, m: Material, yaw := 0.0, solid := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; bm.material = m; mi.mesh = bm
	add_child(mi); mi.position = Vector3(p.x, ground(p) + y, p.y); mi.rotation.y = yaw
	if solid:
		var body := StaticBody3D.new(); add_child(body)
		var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh
		body.position = mi.position; body.rotation.y = yaw; body.add_child(cs)
		WorldData.clear_rect(p, Vector2(size.x, size.z) * 0.5 + Vector2(0.3, 0.3), yaw, 0.4)
	return mi

func model(name: String, c: Vector2, yaw: float, solid := Vector3.ZERO, scale := 1.0) -> Node3D:
	var path := B + name + ".glb"
	if not ResourceLoader.exists(path): return null
	var n: Node3D = load(path).instantiate()
	n.position = Vector3(c.x, ground(c) - 0.05, c.y); n.rotation.y = yaw; n.scale = Vector3.ONE * scale
	add_child(n)
	if solid != Vector3.ZERO:
		var body := StaticBody3D.new(); add_child(body)
		var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = solid * Vector3(2, 1, 2) * scale; cs.shape = sh
		body.position = n.position + Vector3(0, solid.y * scale / 2.0, 0); body.rotation.y = yaw; body.add_child(cs)
		WorldData.clear_disc(c, maxf(solid.x, solid.z) * scale + 0.8, 0.6)
	return n

func tent(c: Vector2, facing: Vector2) -> void:
	model("tent", c, atan2(facing.x - c.x, facing.y - c.y), Vector3(1.8, 2.4, 2.4))

func prop(name: String, c: Vector2, yaw := -1.0) -> void:
	var path := PR + name + ".gltf"
	if not ResourceLoader.exists(path): return
	var n: Node3D = load(path).instantiate()
	n.position = Vector3(c.x, ground(c), c.y); n.rotation.y = rng.randf() * TAU if yaw < 0 else yaw
	add_child(n)

func brazier(p: Vector2, col := Color(1.0, 0.55, 0.15)) -> void:
	var root := Node3D.new(); add_child(root); root.position = Vector3(p.x, ground(p), p.y)
	var iron := mat(Color(0.2, 0.2, 0.22), 0.4); iron.metallic = 0.7
	var bowl := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.5; cm.bottom_radius = 0.25; cm.height = 0.4; cm.material = iron; bowl.mesh = cm
	bowl.position.y = 1.2; root.add_child(bowl)
	var leg := MeshInstance3D.new(); var lm := CylinderMesh.new(); lm.top_radius = 0.06; lm.bottom_radius = 0.12; lm.height = 1.0; lm.material = iron; leg.mesh = lm
	leg.position.y = 0.5; root.add_child(leg)
	var fire := Node3D.new(); root.add_child(fire); fire.position.y = 1.45
	after_fx(func(fx):
		fx.emitter(fire, col, 40, 0.35, 0.6, 1.0, 1.5, Fx.glow, 0.2)
		fx.emitter(fire, Color(0.3, 0.28, 0.26), 6, 0.8, 2.5, 0.8, 0.4, Fx.smoke, 0.25, false, false))
	var l := OmniLight3D.new(); l.light_color = col.lightened(0.2); l.omni_range = 10.0; l.position.y = 1.9; root.add_child(l); fires.append(l)

func after_fx(f: Callable) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var fx := get_tree().get_first_node_in_group("fx")
	if fx: f.call(fx)

## a ring of sharpened logs round a camp, with gaps where roads come in
func palisade(c: Vector2, r: float, gaps: Array) -> void:
	var wood := mat(Color(0.4, 0.28, 0.17))
	var n := int(TAU * r / 0.7)
	for k in n:
		var a := TAU * k / n
		var skip := false
		for g in gaps:
			if absf(wrapf(a - float(g), -PI, PI)) < 0.22: skip = true
		if skip: continue
		var p := c + Vector2(cos(a), sin(a)) * r
		var log := MeshInstance3D.new(); var lm := CylinderMesh.new(); lm.top_radius = 0.0 if k % 2 == 0 else 0.05; lm.bottom_radius = 0.3; lm.height = 3.2 + rng.randf_range(-0.3, 0.3)
		lm.radial_segments = 6; lm.material = wood; log.mesh = lm
		add_child(log); log.position = Vector3(p.x, ground(p) + 1.4, p.y)
		var body := StaticBody3D.new(); add_child(body)
		var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = 0.4; sh.height = 3.0; cs.shape = sh
		body.position = log.position; body.add_child(cs)
	WorldData.clear_disc(c, 0.0, 0.1)

func tower(p: Vector2, h := 9.0) -> void:
	var wood := mat(Color(0.42, 0.3, 0.19))
	for dx in [-1.2, 1.2]:
		for dz in [-1.2, 1.2]:
			box(Vector3(0.3, h, 0.3), p + Vector2(dx, dz), h / 2.0, wood, 0.0, false)
	box(Vector3(3.4, 0.3, 3.4), p, h - 1.0, wood, 0.0, false)
	var roof := MeshInstance3D.new(); var rm := CylinderMesh.new(); rm.top_radius = 0.0; rm.bottom_radius = 2.8; rm.height = 2.0; rm.radial_segments = 4
	rm.material = mat(Color(0.45, 0.24, 0.16)); roof.mesh = rm
	add_child(roof); roof.position = Vector3(p.x, ground(p) + h + 1.0, p.y); roof.rotation.y = PI / 4
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(3.0, 4.0, 3.0); cs.shape = sh
	body.position = Vector3(p.x, ground(p) + 2.0, p.y); body.add_child(cs)
	WorldData.clear_disc(p, 2.2, 0.4)

func banner(p: Vector2, col: Color, h := 5.0) -> void:
	box(Vector3(0.14, h, 0.14), p, h / 2.0, mat(Color(0.3, 0.22, 0.14)), 0.0, false)
	var cloth := mat(col); cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	var q := MeshInstance3D.new(); var qm := QuadMesh.new(); qm.size = Vector2(1.0, 2.0); qm.material = cloth; q.mesh = qm
	add_child(q); q.position = Vector3(p.x + 0.55, ground(p) + h - 1.2, p.y)

## a broken wall: a line of stone blocks, some missing, some tumbled
func wall(a: Vector2, b: Vector2, h: float, m: StandardMaterial3D) -> void:
	var d := b - a; var yaw := atan2(d.x, d.y)
	var n := int(d.length() / 2.0)
	for k in n:
		if rng.randf() < 0.18: continue
		var p := a.lerp(b, (k + 0.5) / n)
		var hh := h * rng.randf_range(0.5, 1.0)
		box(Vector3(0.9, hh, 2.0), p, hh / 2.0, m, yaw)

func field(c: Vector2, half: Vector2, col: Color) -> void:
	var root := Node3D.new(); add_child(root); root.position = Vector3(c.x, ground(c), c.y)
	WorldData.clear_rect(c, half, 0.0, 0.5)
	var soil := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = half * 2.0; soil.mesh = pm; soil.material_override = mat(Color(0.4, 0.33, 0.22)); soil.position.y = 0.04
	root.add_child(soil)
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
	var cy := CylinderMesh.new(); cy.top_radius = 0.02; cy.bottom_radius = 0.15; cy.height = 0.8; cy.radial_segments = 5; cy.material = mat(col); mm.mesh = cy
	var xs := []
	for i in int(half.x * 2.0 / 0.45):
		for j in int(half.y * 2.0 / 0.8):
			var lp := Vector3(-half.x + 0.3 + i * 0.45, 0, -half.y + 0.4 + j * 0.8)
			var gy := ground(Vector2(c.x + lp.x, c.y + lp.z)) - root.position.y
			xs.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.8, 1.2)), lp + Vector3(0, gy + 0.35, 0)))
	mm.instance_count = xs.size()
	for i in xs.size(): mm.set_instance_transform(i, xs[i])
	var mi := MultiMeshInstance3D.new(); mi.multimesh = mm; root.add_child(mi)

## a doorway into the dark: two posts, a lintel and blackness (dungeon entrances)
func dark_door(p: Vector2, facing: float, m: StandardMaterial3D, w := 3.0, h := 4.0) -> void:
	var side := Vector2(cos(facing), -sin(facing))
	for s in [-1.0, 1.0]: box(Vector3(0.8, h, 0.8), p + side * s * (w / 2.0 + 0.4), h / 2.0, m, facing)
	box(Vector3(w + 1.6, 0.8, 1.0), p, h + 0.4, m, facing, false)
	var q := MeshInstance3D.new(); var qm := QuadMesh.new(); qm.size = Vector2(w, h)
	var bm := StandardMaterial3D.new(); bm.albedo_color = Color.BLACK; bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; qm.material = bm; q.mesh = qm
	add_child(q); q.position = Vector3(p.x, ground(p) + h / 2.0, p.y); q.rotation.y = facing
