extends ZoneBuilder
## Vaal's Scar: a torn land under a bruised sky, purple motes drifting up instead of down. The Last
## Watch (the last camp before the end of everything: palisade, towers, tents and fires, siege
## engines facing north), void crystals breaking out of the ground, the Cult Ring, the Broken Crown,
## the Void Pool, and at the head of the Broken Road the Sanctum Gate, open and breathing.

const WATCH := Vector2(0, 80)
const GATE := Vector2(0, -90)
var veil: MeshInstance3D
var gate_l: OmniLight3D
var crystals: Array[OmniLight3D] = []

func _ready() -> void:
	add_to_group("landmarks")
	rng.seed = 191
	palisade(WATCH, 21.0, [PI * 0.5, atan2(-50.0, -10.0)])
	tower(WATCH + Vector2(12, -12)); tower(WATCH + Vector2(-12, -12))
	for t in [Vector2(14, 80), Vector2(-14, 80), Vector2(-10, 96), Vector2(10, 96)]: tent(t, WATCH)
	for b in [WATCH + Vector2(-4, 2), WATCH + Vector2(5, -3), WATCH + Vector2(-6, -12), WATCH + Vector2(6, -12)]: brazier(b)
	for b in [WATCH + Vector2(-3, -8), WATCH + Vector2(3, -8)]: banner(b, Color(0.85, 0.75, 0.3), 7.0)
	for p in [["Crate_Metal", Vector2(17, 86)], ["Barrel", WATCH + Vector2(-16, 6)], ["WeaponStand", WATCH + Vector2(-8, -4)], ["Anvil", Vector2(12, 70)],
			["Crate_Wooden", Vector2(-15, 70)], ["Chest_Wood", Vector2(-2, 90)]]:
		prop(p[0], p[1])
	var wood := mat(Color(0.35, 0.26, 0.17))
	for s in [-1.0, 1.0]: _ballista(WATCH + Vector2(s * 8, -17), wood)
	# void crystals breaking out of the ground
	var vc := StandardMaterial3D.new(); vc.albedo_color = Color(0.55, 0.3, 0.9); vc.emission_enabled = true; vc.emission = Color(0.5, 0.2, 0.95); vc.emission_energy_multiplier = 1.6
	vc.roughness = 0.15
	for i in 22:
		var p := Vector2(rng.randf_range(-100, 100), rng.randf_range(-100, 50))
		if WorldData.road(p).x < 4.0 or p.distance_to(WATCH) < 30.0: continue
		for k in rng.randi_range(2, 4):
			var h := rng.randf_range(1.2, 4.5)
			var cr := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.0; cm.bottom_radius = rng.randf_range(0.3, 0.7); cm.height = h; cm.radial_segments = 5; cm.material = vc; cr.mesh = cm
			var o := p + Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5))
			add_child(cr); cr.position = Vector3(o.x, ground(o) + h / 2.0 - 0.3, o.y); cr.rotation = Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5))
		if i % 3 == 0:
			var l := OmniLight3D.new(); l.light_color = Color(0.6, 0.3, 1.0); l.omni_range = 9.0; l.light_energy = 1.2; add_child(l)
			l.position = Vector3(p.x, ground(p) + 2.0, p.y); crystals.append(l)
	# the Cult Ring
	var stone := mat(Color(0.25, 0.22, 0.27))
	for k in 7:
		var a := TAU * k / 7.0
		box(Vector3(1.0, 3.2, 0.7), Vector2(-44, -72) + Vector2(cos(a), sin(a)) * 8.0, 1.6, stone, a)
	brazier(Vector2(-44, -72), Color(0.6, 0.3, 1.0))
	# the Broken Crown: a ring of shattered pillars
	for k in 8:
		var a := TAU * k / 8.0
		var h := rng.randf_range(3.0, 8.0)
		box(Vector3(1.4, h, 1.4), Vector2(84, -80) + Vector2(cos(a), sin(a)) * 10.0, h / 2.0, stone, a)
	# the Sanctum Gate
	var arch := mat(Color(0.2, 0.18, 0.22))
	for s in [-1.0, 1.0]: box(Vector3(2.4, 14.0, 2.4), GATE + Vector2(s * 5.2, 0), 7.0, arch)
	box(Vector3(13.0, 2.2, 2.6), GATE, 14.5, arch, 0.0, false)
	var glow := StandardMaterial3D.new(); glow.albedo_color = Color(0.7, 0.45, 1.0, 0.8); glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.emission_enabled = true; glow.emission = Color(0.6, 0.3, 1.0); glow.emission_energy_multiplier = 3.0; glow.cull_mode = BaseMaterial3D.CULL_DISABLED
	veil = MeshInstance3D.new(); var qm := QuadMesh.new(); qm.size = Vector2(8.0, 13.0); qm.material = glow; veil.mesh = qm
	add_child(veil); veil.position = Vector3(GATE.x, ground(GATE) + 6.5, GATE.y)
	gate_l = OmniLight3D.new(); gate_l.light_color = Color(0.6, 0.35, 1.0); gate_l.omni_range = 28.0; add_child(gate_l); gate_l.position = veil.position + Vector3(0, 0, 3)
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(8.0, 13.0, 0.6); cs.shape = sh
	body.position = veil.position; body.add_child(cs)
	for b in [GATE + Vector2(-7, 6), GATE + Vector2(7, 6)]: brazier(b, Color(0.6, 0.3, 1.0))

func _process(d: float) -> void:
	super._process(d)
	var t := Time.get_ticks_msec() / 1000.0
	if veil: veil.scale = Vector3.ONE * (1.0 + sin(t * 0.8) * 0.03)       # it breathes
	if gate_l: gate_l.light_energy = 2.4 + sin(t * 0.8) * 0.8
	for i in crystals.size(): crystals[i].light_energy = 1.0 + sin(t * 1.1 + i) * 0.35

func _ballista(c: Vector2, wood: StandardMaterial3D) -> void:
	box(Vector3(1.6, 0.8, 2.6), c, 0.5, wood)
	box(Vector3(3.6, 0.2, 0.25), c + Vector2(0, -0.8), 1.1, wood, 0.0, false)
	box(Vector3(0.15, 0.15, 3.2), c + Vector2(0, -0.4), 1.2, wood, 0.0, false)
