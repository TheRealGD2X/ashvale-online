extends ZoneBuilder
## Saltmere Coast: salt grass and pale sand, a grey-green sea to the east. Gullhaven (a fishing
## town of timber houses round a little square, nets drying on racks, boats pulled up on the sand
## and a long pier out into the bay), the lighthouse on Gull Point with its turning beam, the Wreck of
## the Merrow on the southern shore, Wrecker's Cove with its false lanterns, and the sea cave under
## the point where the Drowned Hold lies.

const TOWN := Vector2(-40, 20)
const LIGHT := Vector2(50, -70)
var beam: Node3D
var lamps: Array[OmniLight3D] = []

func _ready() -> void:
	add_to_group("landmarks")
	rng.seed = 131
	houses([[Vector2(-52, 6), facing(Vector2(-52, 6), TOWN), 6, 6, 2, "plaster"], [Vector2(-26, 6), facing(Vector2(-26, 6), TOWN), 6, 6, 1, "brick"],
		[Vector2(-54, 34), facing(Vector2(-54, 34), TOWN), 8, 8, 2, "plaster"], [Vector2(-40, 38), facing(Vector2(-40, 38), TOWN), 6, 6, 1, "brick"],
		[Vector2(-24, 36), facing(Vector2(-24, 36), TOWN), 6, 6, 2, "plaster"]])
	var wood := mat(Color(0.45, 0.34, 0.22)); var dark := mat(Color(0.28, 0.2, 0.13))
	# a sign for the inn, nets on racks, barrels of salt fish, lanterns round the square
	banner(Vector2(-49, 29), Color(0.2, 0.35, 0.55), 4.0)
	for r in [Vector2(-60, 16), Vector2(-20, 18), Vector2(-30, 44)]: _net_rack(r, rng.randf() * PI, wood)
	for p in [["Barrel", Vector2(-33, 17)], ["Barrel", Vector2(-32, 18)], ["Crate_Wooden", Vector2(-34, 28)], ["Barrel_Apples", Vector2(-46, 22)],
			["Rope_1", Vector2(-31, 26)], ["Bucket_Wooden_1", Vector2(-44, 13)], ["Chest_Wood", Vector2(-38, 29)], ["Stall_Cart_Empty", Vector2(-44, 24)]]:
		prop(p[0], p[1])
	for p in [Vector2(-34, 14), Vector2(-46, 26), Vector2(-33, 26), Vector2(-47, 14)]: _lamp(p, Color(1.0, 0.7, 0.35))
	# the pier out into the bay, boats on the sand
	_pier([Vector2(56, 36), Vector2(66, 36), Vector2(80, 36)], wood, dark)
	_lamp(Vector2(80, 37.5), Color(1.0, 0.75, 0.4), true)
	for b in [[Vector2(58, 30), 0.3], [Vector2(54, 44), -0.4], [Vector2(62, 48), 1.2], [Vector2(46, 22), 2.6]]: _boat(b[0], b[1], wood, dark)
	# the lighthouse on Gull Point
	_lighthouse(LIGHT)
	# the Wreck of the Merrow, and the wreck of the Gull's Pride at the cove
	_wreck(Vector2(78, 76), 0.6, wood, dark)
	_wreck(Vector2(70, 100), -0.4, wood, dark)
	for p in [Vector2(48, 86), Vector2(60, 94), Vector2(40, 98)]: _lamp(p, Color(1.0, 0.45, 0.2))     # the wreckers' false lights
	for t in [Vector2(50, 94), Vector2(58, 84), Vector2(36, 92)]: tent(t, Vector2(52, 90))
	# the sea cave under the point
	var rock := mat(Color(0.42, 0.42, 0.4))
	dark_door(Vector2(70, -88), 0.0, rock, 3.4, 4.0)
	brazier(Vector2(66, -83), Color(0.4, 0.8, 1.0)); brazier(Vector2(74, -83), Color(0.4, 0.8, 1.0))
	# rocks along the shore
	for i in 40:
		var a := rng.randf() * TAU; var d := WorldData.POND_R * rng.randf_range(1.05, 1.5)
		var p := WorldData.POND + Vector2(cos(a), sin(a)) * d
		if absf(p.x) > 118 or absf(p.y) > 118 or p.distance_to(Vector2(64, 36)) < 12.0: continue
		var s := rng.randf_range(0.5, 1.6)
		var r := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = s; sm.height = s * 1.3; sm.radial_segments = 7; sm.rings = 4; sm.material = rock; r.mesh = sm
		add_child(r); r.position = Vector3(p.x, ground(p) + s * 0.2, p.y); r.scale = Vector3(1.3, 0.7, 1.0); r.rotation.y = rng.randf() * TAU

func _process(d: float) -> void:
	super._process(d)
	if beam: beam.rotation.y += d * 0.6
	for l in lamps: l.light_energy = 0.4 + DayNight.night * 2.0

func _lamp(p: Vector2, col: Color, water := false) -> void:
	var root := Node3D.new(); add_child(root)
	root.position = Vector3(p.x, maxf(ground(p), WorldData.WATER_H + 0.35) if water else ground(p), p.y)
	var post := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.14, 2.6, 0.14); bm.material = mat(Color(0.3, 0.22, 0.14)); post.mesh = bm; post.position.y = 1.3; root.add_child(post)
	var lamp := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.1; cm.bottom_radius = 0.14; cm.height = 0.3
	var glow := StandardMaterial3D.new(); glow.albedo_color = col; glow.emission_enabled = true; glow.emission = col; glow.emission_energy_multiplier = 2.5
	cm.material = glow; lamp.mesh = cm; lamp.position.y = 2.7; root.add_child(lamp)
	var l := OmniLight3D.new(); l.light_color = col; l.omni_range = 9.0; lamp.add_child(l); lamps.append(l)

func _net_rack(c: Vector2, yaw: float, wood: StandardMaterial3D) -> void:
	var side := Vector2(cos(yaw), -sin(yaw))
	for s in [-1.0, 1.0]: box(Vector3(0.15, 2.2, 0.15), c + side * s * 1.6, 1.1, wood, yaw, false)
	box(Vector3(3.4, 0.1, 0.1), c, 2.1, wood, yaw, false)
	var net := mat(Color(0.55, 0.5, 0.4)); net.cull_mode = BaseMaterial3D.CULL_DISABLED; net.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; net.albedo_color.a = 0.75
	var q := MeshInstance3D.new(); var qm := QuadMesh.new(); qm.size = Vector2(3.1, 1.6); qm.material = net; q.mesh = qm
	add_child(q); q.position = Vector3(c.x, ground(c) + 1.3, c.y); q.rotation.y = yaw
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(3.4, 2.0, 0.4); cs.shape = sh
	body.position = Vector3(c.x, ground(c) + 1.0, c.y); body.rotation.y = yaw; body.add_child(cs)

func _pier(pts: Array, wood: StandardMaterial3D, dark: StandardMaterial3D) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]; var b: Vector2 = pts[i + 1]
		var yaw := atan2(b.x - a.x, b.y - a.y)
		var steps := int(a.distance_to(b) / 0.6)
		for k in steps:
			var p := a.lerp(b, (k + 0.5) / steps)
			var y := maxf(ground(p), WorldData.WATER_H) + 0.45
			var plank := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(2.6, 0.08, 0.52); bm.material = wood; plank.mesh = bm
			add_child(plank); plank.position = Vector3(p.x, y, p.y); plank.rotation.y = yaw + rng.randf_range(-0.03, 0.03)
			if k % 5 == 0:
				for s in [-1.2, 1.2]:
					var post := MeshInstance3D.new(); var pm := CylinderMesh.new(); pm.top_radius = 0.1; pm.bottom_radius = 0.12; pm.height = 3.0; pm.material = dark; post.mesh = pm
					add_child(post); post.position = Vector3(p.x, y - 1.0, p.y) + Vector3(cos(yaw), 0, -sin(yaw)) * s

func _boat(c: Vector2, yaw: float, wood: StandardMaterial3D, dark: StandardMaterial3D) -> void:
	var root := Node3D.new(); add_child(root); root.position = Vector3(c.x, maxf(ground(c), WorldData.WATER_H) + 0.25, c.y); root.rotation = Vector3(0, yaw, 0.12)
	var hull := MeshInstance3D.new(); var pm := PrismMesh.new(); pm.size = Vector3(1.6, 0.8, 4.2); pm.material = dark; hull.mesh = pm
	root.add_child(hull); hull.rotation.x = PI; hull.position.y = 0.3
	var seat := MeshInstance3D.new(); var sb := BoxMesh.new(); sb.size = Vector3(1.4, 0.08, 0.35); sb.material = wood; seat.mesh = sb
	root.add_child(seat); seat.position.y = 0.55
	WorldData.clear_disc(c, 2.4, 0.4)
	var body := StaticBody3D.new(); root.add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(1.6, 0.8, 4.2); cs.shape = sh; body.add_child(cs)

func _wreck(c: Vector2, yaw: float, wood: StandardMaterial3D, dark: StandardMaterial3D) -> void:
	# a broken hull lying on its side, ribs showing, and the stump of a mast
	var root := Node3D.new(); add_child(root); root.position = Vector3(c.x, ground(c) - 0.6, c.y); root.rotation = Vector3(0, yaw, 0.35)
	for k in 9:
		var rib := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 2.6; tm.outer_radius = 2.9; tm.rings = 12; tm.ring_segments = 5; tm.material = dark; rib.mesh = tm
		root.add_child(rib); rib.position = Vector3(0, 2.0, -5.0 + k * 1.25); rib.rotation = Vector3(0, 0, PI / 2); rib.scale = Vector3(1, 1, 0.3)
	for k in 5:
		var plank := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.12, 0.5, 10.5 - k * 1.2); bm.material = wood; plank.mesh = bm
		root.add_child(plank); plank.position = Vector3(-2.7 + k * 0.1, 0.4 + k * 0.55, 0.0)
	var mast := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.18; cm.bottom_radius = 0.25; cm.height = 6.0; cm.material = dark; mast.mesh = cm
	root.add_child(mast); mast.position = Vector3(0.5, 3.4, 1.0); mast.rotation.z = -0.7
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(5.0, 3.0, 11.0); cs.shape = sh
	body.position = Vector3(c.x, ground(c) + 1.2, c.y); body.rotation.y = yaw; body.add_child(cs)
	WorldData.clear_disc(c, 6.0, 0.5)

func _lighthouse(c: Vector2) -> void:
	var y := ground(c)
	var white := mat(Color(0.92, 0.9, 0.86)); var red := mat(Color(0.7, 0.18, 0.14))
	for k in 6:
		var seg := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 2.2 - (k + 1) * 0.15; cm.bottom_radius = 2.2 - k * 0.15; cm.height = 2.4
		cm.material = white if k % 2 == 0 else red; seg.mesh = cm
		add_child(seg); seg.position = Vector3(c.x, y + 1.2 + k * 2.4, c.y)
	var top := y + 14.4
	var gallery := MeshInstance3D.new(); var gm := CylinderMesh.new(); gm.top_radius = 1.9; gm.bottom_radius = 1.9; gm.height = 0.25; gm.material = mat(Color(0.2, 0.2, 0.22)); gallery.mesh = gm
	add_child(gallery); gallery.position = Vector3(c.x, top + 0.1, c.y)
	var glass := StandardMaterial3D.new(); glass.albedo_color = Color(1.0, 0.9, 0.6); glass.emission_enabled = true; glass.emission = Color(1.0, 0.85, 0.5); glass.emission_energy_multiplier = 3.0
	var lamp := MeshInstance3D.new(); var lm := CylinderMesh.new(); lm.top_radius = 1.0; lm.bottom_radius = 1.0; lm.height = 1.6; lm.material = glass; lamp.mesh = lm
	add_child(lamp); lamp.position = Vector3(c.x, top + 1.0, c.y)
	var cap := MeshInstance3D.new(); var cp := CylinderMesh.new(); cp.top_radius = 0.0; cp.bottom_radius = 1.4; cp.height = 1.4; cp.material = red; cap.mesh = cp
	add_child(cap); cap.position = Vector3(c.x, top + 2.5, c.y)
	var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.85, 0.55); l.omni_range = 26.0; l.light_energy = 1.5; lamp.add_child(l); lamps.append(l)
	# the turning beam
	beam = Node3D.new(); add_child(beam); beam.position = lamp.position
	var bmat := StandardMaterial3D.new(); bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color = Color(1.0, 0.92, 0.7, 0.12); bmat.cull_mode = BaseMaterial3D.CULL_DISABLED; bmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	for s in [-1.0, 1.0]:
		var ray := MeshInstance3D.new(); var rm := CylinderMesh.new(); rm.top_radius = 0.3; rm.bottom_radius = 2.5; rm.height = 40.0; rm.material = bmat; ray.mesh = rm
		beam.add_child(ray); ray.rotation.x = PI / 2 * s; ray.position = Vector3(0, 0, 20.0 * s)
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = 2.3; sh.height = 16.0; cs.shape = sh
	body.position = Vector3(c.x, y + 8.0, c.y); body.add_child(cs)
	WorldData.clear_disc(c, 3.2, 0.5)
	# the keeper's cottage
	houses([[c + Vector2(9, 8), facing(c + Vector2(9, 8), c + Vector2(0, 12)), 4, 6, 1, "brick"]])
