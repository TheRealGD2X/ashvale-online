extends ZoneBuilder
## Emberreach: black rock, red light, embers on the wind. Forgehold (a walled stone forge-town on a
## shelf above the Lava Lake, its great forge hall breathing smoke), obsidian spires on the Black
## Glass Fields, the burnt-out Ashworks with its furnace door, the drakes' Roost, and the door to the
## Molten Deep below the fields.

const HOLD := Vector2(20, 60)
var glows: Array[OmniLight3D] = []

func _ready() -> void:
	add_to_group("landmarks")
	rng.seed = 151
	var stone := mat(Color(0.32, 0.29, 0.28)); var dark := mat(Color(0.16, 0.14, 0.14), 0.4)
	# the wall of Forgehold, with gates where the roads come in
	var gaps := [atan2(36.0, -20.0), atan2(-30.0, 40.0), atan2(-40.0, -20.0)]
	var n := 48
	for k in n:
		var a := TAU * k / n
		var skip := false
		for g in gaps:
			if absf(wrapf(a - g, -PI, PI)) < 0.2: skip = true
		if skip: continue
		var p := HOLD + Vector2(cos(a), sin(a)) * 28.0
		box(Vector3(3.8, 4.5 + (1.2 if k % 2 == 0 else 0.0), 1.4), p, 2.2, stone, -a + PI / 2)
	for g in gaps:
		for s in [-0.26, 0.26]:
			var p2 := HOLD + Vector2(cos(g + s * 0.82), sin(g + s * 0.82)) * 28.0
			box(Vector3(2.2, 7.5, 2.2), p2, 3.7, stone)
			brazier(HOLD + Vector2(cos(g + s * 0.7), sin(g + s * 0.7)) * 25.5)
	# the great forge hall
	var hall := Vector2(38, 56)
	box(Vector3(9, 6, 11), hall, 3.0, stone, 0.3)
	var roof := MeshInstance3D.new(); var rm := PrismMesh.new(); rm.size = Vector3(10, 2.6, 12); rm.material = dark; roof.mesh = rm
	add_child(roof); roof.position = Vector3(hall.x, ground(hall) + 7.3, hall.y); roof.rotation.y = 0.3
	var chimney := box(Vector3(1.8, 6.0, 1.8), hall + Vector2(2, -3), 9.0, stone, 0.3, false)
	after_fx(func(fx): fx.emitter(chimney, Color(0.25, 0.22, 0.2), 10, 1.2, 4.0, 3.0, 0.5, Fx.smoke, 0.5, false, false))
	var mouth := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(3.4, 3.0)
	var hot := StandardMaterial3D.new(); hot.albedo_color = Color(1.0, 0.45, 0.1); hot.emission_enabled = true; hot.emission = Color(1.0, 0.4, 0.08); hot.emission_energy_multiplier = 3.0
	q.material = hot; mouth.mesh = q; add_child(mouth)
	var fwd := Vector2(sin(0.3 - PI / 2), cos(0.3 - PI / 2))
	mouth.position = Vector3(hall.x + fwd.x * 4.55, ground(hall) + 1.5, hall.y + fwd.y * 4.55); mouth.rotation.y = 0.3 - PI / 2
	var fl := OmniLight3D.new(); fl.light_color = Color(1.0, 0.5, 0.2); fl.omni_range = 12.0; add_child(fl); fl.position = mouth.position + Vector3(fwd.x, 0.5, fwd.y) * 1.5; glows.append(fl)
	for p in [["Anvil", Vector2(28, 46)], ["Anvil", Vector2(32, 45)], ["Workbench", Vector2(26, 42)], ["WeaponStand", Vector2(36, 46)], ["Barrel", Vector2(12, 70)],
			["Crate_Metal", Vector2(10, 72)], ["Crate_Wooden", Vector2(8, 52)], ["Chest_Wood", Vector2(16, 51)], ["Whetstone", Vector2(22, 44)]]:
		prop(p[0], p[1])
	houses([[Vector2(6, 74), facing(Vector2(6, 74), HOLD), 6, 6, 2, "brick"], [Vector2(36, 76), facing(Vector2(36, 76), HOLD), 6, 6, 1, "brick"]])
	for b in [HOLD + Vector2(-5, -2), HOLD + Vector2(4, 4)]: brazier(b)
	banner(HOLD + Vector2(0, -6), Color(0.75, 0.3, 0.08), 6.0); banner(HOLD + Vector2(-6, 6), Color(0.75, 0.3, 0.08), 6.0)
	# obsidian spires on the Black Glass Fields
	var glass := mat(Color(0.06, 0.05, 0.07), 0.08); glass.metallic = 0.3
	for i in 26:
		var p := Vector2(rng.randf_range(-10, 50), rng.randf_range(-70, -20))
		if WorldData.road(p).x < 3.0: continue
		var h := rng.randf_range(2.0, 7.0)
		var sp := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.0; cm.bottom_radius = rng.randf_range(0.5, 1.2); cm.height = h; cm.radial_segments = 5; cm.material = glass; sp.mesh = cm
		add_child(sp); sp.position = Vector3(p.x, ground(p) + h / 2.0 - 0.2, p.y); sp.rotation = Vector3(rng.randf_range(-0.25, 0.25), rng.randf() * TAU, rng.randf_range(-0.25, 0.25))
		var body := StaticBody3D.new(); add_child(body)
		var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = cm.bottom_radius * 0.8; sh.height = h; cs.shape = sh
		body.position = sp.position; body.add_child(cs)
	# the Ashworks: a burnt forge, its furnace door glowing
	var ash := Vector2(-86, -70)
	wall(ash + Vector2(-8, 8), ash + Vector2(8, 8), 4.0, stone)
	wall(ash + Vector2(-8, -8), ash + Vector2(-8, 8), 4.0, stone)
	box(Vector3(6, 7, 3), ash + Vector2(0, -12), 3.5, stone)
	dark_door(ash + Vector2(0, -10.2), 0.0, stone, 2.4, 3.0)
	brazier(ash + Vector2(-3, -7), Color(1.0, 0.35, 0.1)); brazier(ash + Vector2(3, -7), Color(1.0, 0.35, 0.1))
	# the Roost: bones and scorched rock
	var bone := mat(Color(0.85, 0.8, 0.7))
	for i in 10:
		var p := Vector2(90, 0) + Vector2(rng.randf_range(-14, 14), rng.randf_range(-14, 14))
		var rib := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 1.1; tm.outer_radius = 1.25; tm.rings = 10; tm.ring_segments = 4; tm.material = bone; rib.mesh = tm
		add_child(rib); rib.position = Vector3(p.x, ground(p) + 0.4, p.y); rib.rotation = Vector3(PI / 2 + rng.randf_range(-0.4, 0.4), rng.randf() * TAU, 0); rib.scale = Vector3(1, 1, 0.5)
	# the door to the Molten Deep
	dark_door(Vector2(30, -90), 0.0, stone, 3.6, 4.4)
	brazier(Vector2(26, -84), Color(1.0, 0.4, 0.1)); brazier(Vector2(34, -84), Color(1.0, 0.4, 0.1))
	# the lava lake lights the rocks round it
	for i in 6:
		var a := TAU * i / 6.0
		var l := OmniLight3D.new(); l.light_color = Color(1.0, 0.42, 0.12); l.omni_range = 26.0; l.light_energy = 1.4; add_child(l)
		l.position = Vector3(WorldData.POND.x + cos(a) * WorldData.POND_R * 0.5, WorldData.WATER_H + 3.0, WorldData.POND.y + sin(a) * WorldData.POND_R * 0.5)
		glows.append(l)

func _process(d: float) -> void:
	super._process(d)
	var t := Time.get_ticks_msec() / 1000.0
	for i in glows.size(): glows[i].light_energy = 1.3 + sin(t * 1.3 + i * 1.7) * 0.25
