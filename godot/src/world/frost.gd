extends ZoneBuilder
## The Pale Reach: snow, pines, a frozen lake and a white sky. Wintermere (a lodge town of steep
## roofs round a bonfire, fenced with stakes against the wolves), the Barrows with their standing
## stones, the frozen lake, the Snowmane camp in the northern pass, and the Frostspire: a spire of
## blue ice in the west with the door to its Halls at its foot.

const TOWN := Vector2(60, -20)
var fire_l: OmniLight3D

func _ready() -> void:
	add_to_group("landmarks")
	rng.seed = 171
	houses([[Vector2(72, -8), facing(Vector2(72, -8), TOWN), 6, 6, 2, "plaster"], [Vector2(46, -10), facing(Vector2(46, -10), TOWN), 8, 8, 2, "plaster"],
		[Vector2(48, -32), facing(Vector2(48, -32), TOWN), 6, 6, 1, "brick"], [Vector2(66, -37), facing(Vector2(66, -37), TOWN), 6, 8, 2, "plaster"]])
	palisade(TOWN, 24.0, [atan2(-16.0, 32.0), atan2(-40.0, -36.0), atan2(50.0, -16.0)])
	_bonfire(TOWN + Vector2(0, 1))
	for p in [["Barrel", TOWN + Vector2(-9, 5)], ["Crate_Wooden", TOWN + Vector2(-10, 6)], ["Bench", TOWN + Vector2(4, 5)], ["Bench", TOWN + Vector2(-3, -4)],
			["Anvil", Vector2(74, -22)], ["WeaponStand", Vector2(76, -26)], ["Chest_Wood", TOWN + Vector2(-8, -7)]]:
		prop(p[0], p[1])
	banner(TOWN + Vector2(6, -6), Color(0.3, 0.45, 0.75), 5.0)
	# the Barrows: mounds and standing stones
	var stone := mat(Color(0.5, 0.52, 0.56)); var snowm := mat(Color(0.9, 0.92, 0.95))
	for i in 9:
		var a := TAU * i / 9.0
		var p := Vector2(-44, -48) + Vector2(cos(a), sin(a)) * 14.0
		box(Vector3(1.1, rng.randf_range(2.6, 4.2), 0.8), p, 1.8, stone, a)
	for m in [Vector2(-30, -60), Vector2(-56, -38), Vector2(-50, -62)]:
		var mound := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 4.0; sm.height = 3.0; sm.material = snowm; mound.mesh = sm
		add_child(mound); mound.position = Vector3(m.x, ground(m) - 0.6, m.y); mound.scale = Vector3(1.4, 1.0, 1.0)
		var body := StaticBody3D.new(); add_child(body)
		var cs := CollisionShape3D.new(); var sh := SphereShape3D.new(); sh.radius = 3.2; cs.shape = sh
		body.position = mound.position; body.add_child(cs)
	# the Frostspire
	var ice := StandardMaterial3D.new(); ice.albedo_color = Color(0.65, 0.85, 1.0, 0.85); ice.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ice.roughness = 0.1; ice.metallic = 0.2; ice.emission_enabled = true; ice.emission = Color(0.35, 0.6, 0.9); ice.emission_energy_multiplier = 0.5
	var spire := Vector2(-100, -26)
	for k in 7:
		var h: float = [26.0, 16.0, 12.0, 18.0, 9.0, 14.0, 10.0][k]
		var off := Vector2.ZERO if k == 0 else Vector2(cos(k * 1.3), sin(k * 1.3)) * rng.randf_range(3.0, 6.0)
		var sp := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.0; cm.bottom_radius = 3.4 if k == 0 else rng.randf_range(1.2, 2.2); cm.height = h; cm.radial_segments = 6; cm.material = ice; sp.mesh = cm
		add_child(sp); sp.position = Vector3(spire.x + off.x, ground(spire + off) + h / 2.0 - 0.5, spire.y + off.y); sp.rotation = Vector3(off.y * 0.02, rng.randf() * TAU, -off.x * 0.02)
		var body := StaticBody3D.new(); add_child(body)
		var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = cm.bottom_radius * 0.7; sh.height = h; cs.shape = sh
		body.position = sp.position; body.add_child(cs)
	dark_door(Vector2(-96, -18), 0.5, stone, 3.0, 4.0)
	brazier(Vector2(-93, -13), Color(0.5, 0.8, 1.0)); brazier(Vector2(-99, -12), Color(0.5, 0.8, 1.0))
	var l := OmniLight3D.new(); l.light_color = Color(0.55, 0.8, 1.0); l.omni_range = 30.0; l.light_energy = 1.2; add_child(l)
	l.position = Vector3(spire.x, ground(spire) + 14.0, spire.y)
	# the Snowmane camp in the northern pass
	for t in [Vector2(-2, -84), Vector2(18, -92), Vector2(10, -78)]: tent(t, Vector2(8, -88))
	brazier(Vector2(8, -88), Color(1.0, 0.5, 0.2))
	# snowy boulders
	for i in 30:
		var p := Vector2(rng.randf_range(-110, 110), rng.randf_range(-110, 110))
		if WorldData.road(p).x < 4.0 or p.distance_to(TOWN) < 30.0 or WorldData.in_water(p.x, p.y): continue
		var s := rng.randf_range(0.8, 2.2)
		var r := MeshInstance3D.new(); var bm := SphereMesh.new(); bm.radius = s; bm.height = s * 1.4; bm.radial_segments = 7; bm.rings = 4; bm.material = snowm; r.mesh = bm
		add_child(r); r.position = Vector3(p.x, ground(p) + s * 0.15, p.y); r.scale = Vector3(1.2, 0.75, 1.0)

func _process(d: float) -> void:
	super._process(d)
	if fire_l: fire_l.light_energy = 2.2 + DayNight.night * 1.8 + sin(Time.get_ticks_msec() / 130.0) * 0.25

func _bonfire(c: Vector2) -> void:
	var root := Node3D.new(); add_child(root); root.position = Vector3(c.x, ground(c), c.y)
	var wood := mat(Color(0.3, 0.2, 0.12))
	for k in 6:
		var lg := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.12; cm.bottom_radius = 0.16; cm.height = 1.8; cm.material = wood; lg.mesh = cm
		root.add_child(lg); var a := TAU * k / 6.0; lg.position = Vector3(cos(a) * 0.35, 0.55, sin(a) * 0.35); lg.rotation = Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5)
	var fire := Node3D.new(); root.add_child(fire); fire.position.y = 0.7
	after_fx(func(fx):
		fx.emitter(fire, Color(1.0, 0.55, 0.15), 80, 0.6, 0.9, 1.6, 2.2, Fx.glow, 0.35)
		fx.emitter(fire, Color(0.3, 0.28, 0.26), 10, 1.0, 3.5, 1.2, 0.6, Fx.smoke, 0.35, false, false))
	fire_l = OmniLight3D.new(); fire_l.light_color = Color(1.0, 0.6, 0.3); fire_l.omni_range = 16.0; fire_l.shadow_enabled = true; fire_l.position.y = 1.6; root.add_child(fire_l)
	WorldData.clear_disc(c, 1.6, 0.3)
	var body := StaticBody3D.new(); root.add_child(body)
	var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = 0.9; sh.height = 1.2; cs.shape = sh; cs.position.y = 0.6; body.add_child(cs)
