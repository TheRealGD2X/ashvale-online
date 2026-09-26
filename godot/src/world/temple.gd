extends Node3D
## The Ash Slopes: grey cinders, bronze light, ash drifting down. Temple Gate (the pilgrims' camp at
## the foot of the stair, braziers burning), the great stair climbing north to the Temple of Ash's
## door in the ridge, the four old statues Pell asks after, cultist tents on the Charnel Steps, and
## the Bell Tower on the north-east ridge.

const B := "res://assets/buildings/"
const GATE := Vector2(24, 36)
const DOOR := Vector2(10, -92)
var fires: Array[OmniLight3D] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("landmarks")
	rng.seed = 71
	var stone := StandardMaterial3D.new(); stone.albedo_color = Color(0.55, 0.52, 0.48); stone.roughness = 0.95
	var dark := StandardMaterial3D.new(); dark.albedo_color = Color(0.3, 0.28, 0.26)
	# the pilgrims' camp at Temple Gate
	for t in [Vector2(10, 44), Vector2(36, 46), Vector2(38, 26), Vector2(8, 26)]:
		_model("tent", t, atan2(GATE.x - t.x, GATE.y - t.y), Vector3(1.8, 2.4, 2.4))
	for b in [Vector2(18, 32), Vector2(30, 32), Vector2(18, 40), Vector2(30, 40)]: _brazier(b)
	# the stair: broad steps climbing the road to the temple door
	var road := [Vector2(20, 0), Vector2(14, -40), Vector2(10, -76)]
	for i in road.size() - 1:
		var a: Vector2 = road[i]; var b: Vector2 = road[i + 1]
		var n := int(a.distance_to(b) / 5.0)
		for k in n:
			var p := a.lerp(b, (k + 0.5) / n)
			var yaw := atan2(b.x - a.x, b.y - a.y)
			for s in [-1.0, 1.0]:
				var side: Vector2 = Vector2(cos(yaw), -sin(yaw)) * s * 3.2
				_pillar(p + side, 2.0 if k % 2 == 0 else 3.2, stone)
	# the temple door in the ridge
	for s in [-1.0, 1.0]: _pillar(DOOR + Vector2(s * 3.4, 2.0), 7.0, stone)
	var lintel := MeshInstance3D.new(); var lm := BoxMesh.new(); lm.size = Vector3(8.0, 1.0, 1.2); lm.material = stone; lintel.mesh = lm
	add_child(lintel); lintel.position = Vector3(DOOR.x, WorldData.h(DOOR.x, DOOR.y + 2.0) + 7.0, DOOR.y + 2.0)
	var black := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(5.6, 6.4)
	var bm := StandardMaterial3D.new(); bm.albedo_color = Color.BLACK; bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; q.material = bm
	black.mesh = q; add_child(black); black.position = Vector3(DOOR.x, WorldData.h(DOOR.x, DOOR.y) + 3.2, DOOR.y + 1.0)
	_brazier(DOOR + Vector2(-5, 5)); _brazier(DOOR + Vector2(5, 5))
	# the four old statues
	for st in [Vector2(-60, 12), Vector2(4, -58), Vector2(70, -20), Vector2(-30, -80)]: _statue(st, stone)
	# the Bell Tower on the ridge
	var tower := MeshInstance3D.new(); var tm := BoxMesh.new(); tm.size = Vector3(5, 16, 5); tm.material = dark; tower.mesh = tm
	add_child(tower); tower.position = Vector3(92, WorldData.h(92, -92) + 7.5, -92)
	var roof := MeshInstance3D.new(); var rm := CylinderMesh.new(); rm.top_radius = 0.0; rm.bottom_radius = 4.2; rm.height = 4.0; rm.radial_segments = 4
	var roof_m := StandardMaterial3D.new(); roof_m.albedo_color = Color(0.45, 0.2, 0.15); rm.material = roof_m; roof.mesh = rm
	add_child(roof); roof.position = tower.position + Vector3(0, 10.0, 0); roof.rotation.y = PI / 4
	# cultist tents on the Charnel Steps
	for t in [Vector2(-62, -44), Vector2(-74, -52), Vector2(-60, -60)]: _model("tent", t, rng.randf() * TAU, Vector3(1.8, 2.4, 2.4))
	for b in [Vector2(-66, -52), Vector2(10, -66)]: _brazier(b)

func _process(_d: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in fires.size(): fires[i].light_energy = 1.8 + DayNight.night * 1.4 + sin(t * 7.0 + i) * 0.2

func _model(name: String, c: Vector2, yaw: float, solid: Vector3) -> void:
	var path := B + name + ".glb"
	if not ResourceLoader.exists(path): return
	var n: Node3D = load(path).instantiate()
	n.position = Vector3(c.x, WorldData.h(c.x, c.y) - 0.05, c.y); n.rotation.y = yaw
	add_child(n)
	WorldData.clear_disc(c, maxf(solid.x, solid.z) + 0.8, 0.6)
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = solid * Vector3(2, 1, 2); cs.shape = sh
	body.position = n.position + Vector3(0, solid.y / 2.0, 0); body.rotation.y = yaw; body.add_child(cs)

func _pillar(p: Vector2, h: float, m: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.4; cm.bottom_radius = 0.5; cm.height = h; cm.radial_segments = 8; cm.material = m; mi.mesh = cm
	add_child(mi); mi.position = Vector3(p.x, WorldData.h(p.x, p.y) + h / 2.0 - 0.1, p.y)
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = 0.55; sh.height = h; cs.shape = sh
	body.position = mi.position; body.add_child(cs)
	WorldData.clear_disc(p, 1.0, 0.3)

func _brazier(p: Vector2) -> void:
	var root := Node3D.new(); add_child(root); root.position = Vector3(p.x, WorldData.h(p.x, p.y), p.y)
	var iron := StandardMaterial3D.new(); iron.albedo_color = Color(0.2, 0.2, 0.22); iron.metallic = 0.7
	var bowl := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.5; cm.bottom_radius = 0.25; cm.height = 0.4; cm.material = iron; bowl.mesh = cm
	bowl.position.y = 1.2; root.add_child(bowl)
	var leg := MeshInstance3D.new(); var lm := CylinderMesh.new(); lm.top_radius = 0.06; lm.bottom_radius = 0.12; lm.height = 1.0; lm.material = iron; leg.mesh = lm
	leg.position.y = 0.5; root.add_child(leg)
	var fire := Node3D.new(); root.add_child(fire); fire.position.y = 1.45
	_after_fx(func(fx):
		fx.emitter(fire, Color(1.0, 0.55, 0.15), 40, 0.35, 0.6, 1.0, 1.5, Fx.glow, 0.2)
		fx.emitter(fire, Color(0.3, 0.28, 0.26), 6, 0.8, 2.5, 0.8, 0.4, Fx.smoke, 0.25, false, false))
	var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.6, 0.28); l.omni_range = 10.0; l.position.y = 1.9; root.add_child(l); fires.append(l)

func _after_fx(f: Callable) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var fx := get_tree().get_first_node_in_group("fx")
	if fx: f.call(fx)

func _statue(p: Vector2, m: StandardMaterial3D) -> void:
	var y := WorldData.h(p.x, p.y)
	var base := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(1.8, 1.0, 1.8); bm.material = m; base.mesh = bm
	add_child(base); base.position = Vector3(p.x, y + 0.5, p.y)
	var robe := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.4; cm.bottom_radius = 0.8; cm.height = 3.0; cm.material = m; robe.mesh = cm
	add_child(robe); robe.position = Vector3(p.x, y + 2.5, p.y)
	var head := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.42; sm.height = 0.9; sm.material = m; head.mesh = sm
	add_child(head); head.position = Vector3(p.x, y + 4.3, p.y)
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(2.0, 4.5, 2.0); cs.shape = sh
	body.position = Vector3(p.x, y + 2.25, p.y); body.add_child(cs)
	WorldData.clear_disc(p, 1.6, 0.4)
