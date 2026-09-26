extends Node3D
## Mirewood dressed as WORLD-LAYOUT.md has it: Mirewood Landing (a dock village of huts on stilts,
## boardwalks out over the black water, lanterns with green glass, nets and barrels, and the tall
## dock light), goblin camps with their totems in the shallows, and the Warrens: a great hollow tree
## you can walk into.

const B := "res://assets/buildings/"
const PR := "res://assets/props/"
const N := "res://assets/nature/"
const HUB := Vector2(-40, 28)
const WARRENS := Vector2(90, -86)

var lamps: Array[OmniLight3D] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("landmarks")
	rng.seed = 51
	# huts on stilts round the landing
	for h in [[Vector2(-50, 20), 0.6], [Vector2(-30, 16), -0.5], [Vector2(-54, 38), 1.9], [Vector2(-26, 40), -2.4], [Vector2(-44, 46), 3.0]]:
		_model("granary", h[0], h[1], Vector3(3.4, 5.0, 2.6))
	# the boardwalk out over the water, and the dock light at its end
	_boardwalk([Vector2(-30, 24), Vector2(-18, 16), Vector2(-6, 6), Vector2(2, -2)])
	_dock_light(Vector2(3, -3))
	for p in [[Vector2(-36, 22), "Barrel"], [Vector2(-35, 23), "Crate_Wooden"], [Vector2(-44, 32), "Barrel_Apples"], [Vector2(-38, 34), "Rope_1"],
			[Vector2(-33, 30), "Bucket_Wooden_1"], [Vector2(-42, 24), "Chest_Wood"]]:
		_prop(p[1], p[0])
	for p in [Vector2(-40, 20), Vector2(-46, 30), Vector2(-34, 34), Vector2(-28, 28)]: _lantern(p)
	# goblin camps: crude huts (tents daubed dark) and a fire each
	for c in [Vector2(28, 62), Vector2(62, 62), Vector2(100, -16)]:
		for k in 3:
			var a := TAU * k / 3.0 + 0.4
			_model("tent", c + Vector2(cos(a), sin(a)) * 6.0, a + PI, Vector3(1.8, 2.4, 2.4))
	# the hollow tree over the Warrens
	var tree_path := N + "TwistedTree_4.gltf"
	if ResourceLoader.exists(tree_path):
		var t: Node3D = load(tree_path).instantiate()
		t.position = Vector3(WARRENS.x, WorldData.h(WARRENS.x, WARRENS.y - 5.0) - 0.5, WARRENS.y - 5.0); t.scale = Vector3.ONE * 3.2; t.rotation.y = 0.8
		add_child(t)
		var body := StaticBody3D.new(); add_child(body)
		var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = 3.0; sh.height = 8.0; cs.shape = sh
		body.position = t.position + Vector3(0, 4, -1.5); body.add_child(cs)
	var dark := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(3.0, 3.6)
	var m := StandardMaterial3D.new(); m.albedo_color = Color.BLACK; m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; q.material = m
	dark.mesh = q; add_child(dark); dark.position = Vector3(WARRENS.x, WorldData.h(WARRENS.x, WARRENS.y) + 1.8, WARRENS.y - 2.2)
	_lantern(WARRENS + Vector2(2.5, 1.5))
	WorldData.clear_disc(WARRENS, 6.0, 1.0)

func _process(_d: float) -> void:
	for l in lamps: l.light_energy = 0.5 + DayNight.night * 1.8

func _model(name: String, c: Vector2, yaw: float, solid: Vector3) -> Node3D:
	var path := B + name + ".glb"
	if not ResourceLoader.exists(path): return null
	var n: Node3D = load(path).instantiate()
	n.position = Vector3(c.x, WorldData.h(c.x, c.y) - 0.05, c.y); n.rotation.y = yaw
	add_child(n)
	WorldData.clear_disc(c, maxf(solid.x, solid.z) + 0.8, 0.6)
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = solid * Vector3(2, 1, 2); cs.shape = sh
	body.position = n.position + Vector3(0, solid.y / 2.0, 0); body.rotation.y = yaw; body.add_child(cs)
	return n

func _prop(name: String, c: Vector2) -> void:
	var path := PR + name + ".gltf"
	if not ResourceLoader.exists(path): return
	var n: Node3D = load(path).instantiate()
	n.position = Vector3(c.x, WorldData.h(c.x, c.y), c.y); n.rotation.y = rng.randf() * TAU
	add_child(n)

func _lantern(p: Vector2) -> void:
	var root := Node3D.new(); add_child(root); root.position = Vector3(p.x, WorldData.h(p.x, p.y), p.y)
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.3, 0.22, 0.14)
	var post := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.14, 2.4, 0.14); bm.material = wood; post.mesh = bm; post.position.y = 1.2; root.add_child(post)
	var lamp := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.1; cm.bottom_radius = 0.13; cm.height = 0.28
	var glow := StandardMaterial3D.new(); glow.albedo_color = Color(0.5, 0.9, 0.5); glow.emission_enabled = true; glow.emission = Color(0.35, 0.9, 0.4); glow.emission_energy_multiplier = 2.5
	cm.material = glow; lamp.mesh = cm; lamp.position.y = 2.5; root.add_child(lamp)
	var l := OmniLight3D.new(); l.light_color = Color(0.5, 1.0, 0.55); l.omni_range = 8.0; lamp.add_child(l); lamps.append(l)

func _dock_light(p: Vector2) -> void:
	var root := Node3D.new(); add_child(root); root.position = Vector3(p.x, WorldData.WATER_H, p.y)
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.32, 0.23, 0.15)
	var pole := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.12; cm.bottom_radius = 0.18; cm.height = 7.0; cm.material = wood; pole.mesh = cm
	pole.position.y = 3.0; root.add_child(pole)
	var lamp := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.35; sm.height = 0.6
	var glow := StandardMaterial3D.new(); glow.albedo_color = Color(0.6, 1.0, 0.6); glow.emission_enabled = true; glow.emission = Color(0.4, 1.0, 0.5); glow.emission_energy_multiplier = 4.0
	sm.material = glow; lamp.mesh = sm; lamp.position.y = 6.7; root.add_child(lamp)
	var l := OmniLight3D.new(); l.light_color = Color(0.55, 1.0, 0.6); l.omni_range = 18.0; l.shadow_enabled = true; lamp.add_child(l); lamps.append(l)

func _boardwalk(pts: Array) -> void:
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.42, 0.32, 0.2); wood.roughness = 0.9
	var post_m := StandardMaterial3D.new(); post_m.albedo_color = Color(0.25, 0.18, 0.11)
	var body := StaticBody3D.new(); body.name = "Boardwalk"; add_child(body)
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]; var b: Vector2 = pts[i + 1]
		var d := b - a; var yaw := atan2(d.x, d.y)
		var steps := int(d.length() / 0.6)
		for k in steps:
			var p := a.lerp(b, (k + 0.5) / steps)
			var y := maxf(WorldData.h(p.x, p.y), WorldData.WATER_H) + 0.35
			var plank := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(2.4, 0.08, 0.5); bm.material = wood; plank.mesh = bm
			add_child(plank); plank.position = Vector3(p.x, y, p.y); plank.rotation.y = yaw + rng.randf_range(-0.03, 0.03)
			if k % 4 == 0:
				for s in [-1.1, 1.1]:
					var post := MeshInstance3D.new(); var pm := CylinderMesh.new(); pm.top_radius = 0.08; pm.bottom_radius = 0.1; pm.height = 2.0; pm.material = post_m; post.mesh = pm
					add_child(post); post.position = Vector3(p.x, y - 0.8, p.y) + Vector3(cos(yaw), 0, -sin(yaw)) * s
