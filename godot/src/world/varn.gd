extends ZoneBuilder
## Varn Plateau: blasted ground under a purple dusk, banners in the wind. Varn's Rest (the war camp,
## palisaded, full of tents and braziers), the ruins of Castle Varn with the Catacomb Arch in its
## foot, the Black Chapel, the Acolytes' Circle of standing stones, and far off in the north-east the
## Sanctum Gate, glowing, where the raid will be.

const REST := Vector2(10, 70)

func _ready() -> void:
	add_to_group("landmarks")
	rng.seed = 113
	palisade(REST, 20.0, [PI * 0.5, -PI * 0.5, 0.35, PI * 0.8])
	tower(REST + Vector2(14, 12)); tower(REST + Vector2(-14, -12)); tower(REST + Vector2(14, -12))
	for k in 8:
		var a := TAU * k / 8.0 + 0.2
		tent(REST + Vector2(cos(a), sin(a)) * 12.0, REST)
	for b in [REST + Vector2(-4, 0), REST + Vector2(4, 0), REST + Vector2(0, 6)]: brazier(b)
	for b in [REST + Vector2(-6, -6), REST + Vector2(6, -6), REST + Vector2(0, -14)]: banner(b, Color(0.5, 0.12, 0.12), 6.0)
	# the ruins of Castle Varn, and the Catacomb Arch at their foot
	var stone := mat(Color(0.38, 0.36, 0.4))
	wall(Vector2(-30, -70), Vector2(-10, -96), 7.0, stone)
	wall(Vector2(30, -70), Vector2(10, -96), 7.0, stone)
	wall(Vector2(-30, -70), Vector2(-12, -64), 5.0, stone)
	wall(Vector2(30, -70), Vector2(12, -64), 5.0, stone)
	dark_door(Vector2(0, -90), 0.0, stone, 3.4, 4.2)
	brazier(Vector2(-4, -84), Color(0.7, 0.4, 1.0)); brazier(Vector2(4, -84), Color(0.7, 0.4, 1.0))
	# the Black Chapel
	box(Vector3(8, 7, 12), Vector2(-86, -36), 3.5, mat(Color(0.18, 0.16, 0.2)), 0.4)
	banner(Vector2(-80, -28), Color(0.2, 0.05, 0.25), 6.0)
	# the Acolytes' Circle
	for k in 9:
		var a := TAU * k / 9.0
		var p := Vector2(60, -30) + Vector2(cos(a), sin(a)) * 9.0
		box(Vector3(1.2, rng.randf_range(2.5, 4.0), 0.8), p, 1.6, stone, a)
	# the Sanctum Gate, far off, glowing
	var glow := StandardMaterial3D.new(); glow.albedo_color = Color(0.7, 0.5, 1.0); glow.emission_enabled = true; glow.emission = Color(0.6, 0.35, 1.0); glow.emission_energy_multiplier = 3.0
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; glow.albedo_color.a = 0.8
	dark_door(Vector2(96, -84), -0.6, stone, 5.0, 7.0)
	var veil := MeshInstance3D.new(); var qm := QuadMesh.new(); qm.size = Vector2(5.0, 7.0); qm.material = glow; veil.mesh = qm
	add_child(veil); veil.position = Vector3(96, ground(Vector2(96, -84)) + 3.5, -84) + Vector3(0, 0, 0.1); veil.rotation.y = -0.6
	var l := OmniLight3D.new(); l.light_color = Color(0.7, 0.5, 1.0); l.omni_range = 18.0; l.light_energy = 2.5; add_child(l); l.position = veil.position + Vector3(0, 0, 2)
