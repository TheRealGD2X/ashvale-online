extends ZoneBuilder
## The Ashen Highlands: heather, cold Lake Ashen, wind. Highland Watch (a palisaded fort with a
## watchtower), a jetty on the lake, oat fields the wild horses come to, the Khar Outpost on the
## ridge, and the lakeside mausoleum over the Sunken Crypts.

const WATCH := Vector2(-30, 40)

func _ready() -> void:
	add_to_group("landmarks")
	rng.seed = 91
	palisade(WATCH, 17.0, [0.0 + PI, -0.25, PI * 0.5 + 0.3, -PI * 0.5])
	tower(WATCH + Vector2(10, -10)); tower(WATCH + Vector2(-11, 9))
	for t in [WATCH + Vector2(-8, -6), WATCH + Vector2(6, 8), WATCH + Vector2(-2, 11), WATCH + Vector2(9, -2)]: tent(t, WATCH)
	for b in [WATCH + Vector2(-3, 2), WATCH + Vector2(4, -4)]: brazier(b)
	banner(WATCH + Vector2(0, -3), Color(0.25, 0.35, 0.7)); banner(WATCH + Vector2(2, 5), Color(0.25, 0.35, 0.7))
	for p in [["Crate_Wooden", WATCH + Vector2(12, 4)], ["Barrel", WATCH + Vector2(12, 6)], ["WeaponStand", WATCH + Vector2(-12, -2)], ["Anvil", WATCH + Vector2(6, 14)]]: prop(p[0], p[1])
	# the jetty on Lake Ashen
	var wood := mat(Color(0.42, 0.32, 0.2))
	for k in 12:
		var p := Vector2(4, 40).lerp(Vector2(14, 28), k / 11.0)
		box(Vector3(2.2, 0.12, 0.6), p, maxf(0.0, WorldData.WATER_H - ground(p)) + 0.35, wood, atan2(10, -12), false)
	# oat fields for the strays
	field(Vector2(-70, 76), Vector2(9, 6), Color(0.8, 0.72, 0.4))
	field(Vector2(-86, -30), Vector2(8, 6), Color(0.78, 0.7, 0.38))
	# the Khar Outpost: dark tents and red banners on the ridge
	for t in [Vector2(74, -64), Vector2(86, -74), Vector2(78, -80)]: tent(t, Vector2(80, -70))
	for b in [Vector2(80, -62), Vector2(90, -66)]: banner(b, Color(0.6, 0.1, 0.08))
	brazier(Vector2(80, -70), Color(1.0, 0.35, 0.1))
	# the mausoleum by the lake, over the Sunken Crypts
	var stone := mat(Color(0.5, 0.52, 0.55))
	box(Vector3(9, 5, 7), Vector2(66, 50), 2.5, stone)
	var roof := MeshInstance3D.new(); var rm := PrismMesh.new(); rm.size = Vector3(10, 2.5, 8); rm.material = mat(Color(0.35, 0.37, 0.4)); roof.mesh = rm
	add_child(roof); roof.position = Vector3(66, ground(Vector2(66, 50)) + 6.2, 50)
	dark_door(Vector2(66, 46.4), 0.0, stone, 2.6, 3.4)
	brazier(Vector2(62, 43)); brazier(Vector2(70, 43))
