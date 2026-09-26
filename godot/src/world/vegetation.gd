extends Node3D
## Everything that grows: woods to the north, lone trees and bushes in the meadows, flower
## patches, ferns and mushrooms on the forest floor, reeds by the pond, boulders on the hills,
## then the meadow grass over it all. Each kind is one MultiMesh (thousands of plants, few draw
## calls), all sharing the foliage wind shader.

const N := "res://assets/nature/"
var rng := RandomNumberGenerator.new()
var lists := {}          # model name -> Array[Transform3D]
var tints := {}          # model name -> Color
var mats: Array[ShaderMaterial] = []
var noise: FastNoiseLite
var bodies: StaticBody3D

const TREE_KINDS := {
	"CommonTree_1": 6.0, "CommonTree_2": 6.0, "CommonTree_3": 7.0, "CommonTree_4": 7.0, "CommonTree_5": 5.5,
	"Pine_1": 7.0, "Pine_2": 7.0, "Pine_3": 7.0, "Pine_4": 7.0, "Pine_5": 7.0,
	"TwistedTree_1": 9.0, "TwistedTree_3": 9.0, "TwistedTree_4": 9.0, "DeadTree_1": 6.0, "DeadTree_3": 6.0,
}

func _ready() -> void:
	rng.seed = 1234
	noise = FastNoiseLite.new(); noise.seed = 77; noise.frequency = 1.0 / 55.0
	bodies = StaticBody3D.new(); bodies.name = "TreeTrunks"; add_child(bodies)
	_scatter()
	for k in lists: _build(k)
	var g := Grass.new(); g.lite = WorldData.lite; g.name = "Grass"; add_child(g)

# ------------------------------------------------------------------ where things grow
func _free_ground(x: float, z: float, road_gap := 2.5) -> bool:
	if absf(x) > WorldData.HALF - 1 or absf(z) > WorldData.HALF - 1: return false
	var m := WorldData.m(x, z)
	if m.r > 0.02 or m.a > 0.3: return false
	if WorldData.road(Vector2(x, z)).x < road_gap: return false
	if WorldData.clear.get_pixel(clampi(int((x + WorldData.HALF) * 4.0), 0, 1023), clampi(int((z + WorldData.HALF) * 4.0), 0, 1023)).r > 0.05: return false
	return true

func _forest(x: float, z: float) -> float:
	if WorldData.zone_id != "ashvale":
		# other zones: scattered stands, thicker at the rim, never on cliffs
		var n0 := noise.get_noise_2d(x, z) * 0.5 + 0.5
		var rim := smoothstep(92.0, 115.0, maxf(absf(x), absf(z)))
		var steep := 1.0 - WorldData.n(x, z).y
		return clampf(maxf(smoothstep(0.62, 0.8, n0) * float(WorldData.Z.get("forest", 0.5)), rim * 0.6) * (1.0 - WorldData.town_w(Vector2(x, z))) * (1.0 - smoothstep(0.25, 0.4, steep)), 0.0, 1.0)
	var n := noise.get_noise_2d(x, z) * 0.5 + 0.5
	var north := smoothstep(-34.0, -58.0, z)
	var edge := smoothstep(92.0, 112.0, maxf(absf(x), absf(z)))
	var woods := smoothstep(0.66, 0.8, n) * (1.0 - WorldData.town_w(Vector2(x, z)))
	return clampf(maxf(maxf(north * (0.55 + n * 0.6), edge * 0.8), woods), 0.0, 1.0) * (1.0 - WorldData.town_w(Vector2(x, z)) * 0.9)

func _add(kind: String, x: float, z: float, s: float, yaw := -1.0, sink := 0.05) -> void:
	if not lists.has(kind): lists[kind] = []
	var y := WorldData.h(x, z) - sink * s
	var b := Basis(Vector3.UP, rng.randf() * TAU if yaw < 0 else yaw).scaled(Vector3.ONE * s)
	# plants lean a touch with the slope
	var nn := WorldData.n(x, z)
	b = Basis(Quaternion(Vector3.UP, nn.lerp(Vector3.UP, 0.6).normalized())) * b
	lists[kind].append(Transform3D(b, Vector3(x, y, z)))

func _trunk(x: float, z: float, r: float, h: float) -> void:
	var cs := CollisionShape3D.new(); var c := CylinderShape3D.new(); c.radius = r; c.height = h; cs.shape = c
	cs.position = Vector3(x, WorldData.h(x, z) + h / 2.0, z); bodies.add_child(cs)

func _scatter() -> void:
	var H := WorldData.HALF
	var ash := WorldData.zone_id == "ashvale"
	# the landmark trees the quests name: the split oak (a great dead tree, riven down the middle)
	# and the hollow oak where Old Scratch dens
	if ash:
		_add("DeadTree_3", 94, 24, 2.3, 0.4, 0.15); _trunk(94, 24, 1.0, 6.0)
		_add("TwistedTree_4", 108, -40, 1.7, 2.0, 0.15); _trunk(108, -40, 1.3, 6.0)
	# trees on a jittered 4.5 m grid
	var step := 4.5
	var z := -H
	while z < H:
		var x := -H
		while x < H:
			var px := x + rng.randf() * step; var pz := z + rng.randf() * step
			var f := _forest(px, pz)
			var meadow_tree := 0.035 * (1.0 - WorldData.town_w(Vector2(px, pz)))
			if rng.randf() < maxf(f * 0.85, meadow_tree) and _free_ground(px, pz, 3.5):
				var pine: bool = pz < -50.0 or maxf(absf(px), absf(pz)) > 100.0 or WorldData.Z.get("pines", false)
				var kind: String
				if WorldData.Z.get("dead_trees", false) and rng.randf() < 0.6: kind = ["DeadTree_1", "DeadTree_3", "TwistedTree_1", "TwistedTree_4"][rng.randi() % 4]
				elif pine and rng.randf() < 0.72: kind = "Pine_%d" % (1 + rng.randi() % 5)

				elif rng.randf() < 0.03: kind = ["DeadTree_1", "DeadTree_3"][rng.randi() % 2]
				else: kind = "CommonTree_%d" % (1 + rng.randi() % 5)
				var s := rng.randf_range(0.85, 1.35) * (1.15 if f < 0.2 else 1.0)
				_add(kind, px, pz, s, -1.0, 0.1)
				_trunk(px, pz, 0.35 * s, 4.0)
			x += step
		z += step
	# the great red ash at the heart of the square: the tree Ashvale is named for
	if ash:
		_add("TwistedTree_3", -0.6, 0.35, 0.5, 0.3, 0.05)
		# the tree the woodcutter is working on
		_add("CommonTree_2", 9.45, -31.1, 1.0, 0.0, 0.1); _trunk(9.45, -31.1, 0.35, 4.0)
	# a few great twisted trees as landmarks
	for p in ([Vector2(-58, 36), Vector2(-26, 58), Vector2(38, -42), Vector2(70, 34), Vector2(-74, -24), Vector2(24, 60)] if ash else []):
		if _free_ground(p.x, p.y, 4.0):
			var kind: String = ["TwistedTree_1", "TwistedTree_3", "TwistedTree_4"][rng.randi() % 3]
			_add(kind, p.x, p.y, rng.randf_range(1.0, 1.25), -1.0, 0.1); _trunk(p.x, p.y, 0.9, 5.0)
			WorldData.clear_disc(p, 2.0)
	# undergrowth, flowers, rocks on a finer grid
	step = 1.6
	z = -H
	while z < H:
		var x := -H
		while x < H:
			var px := x + rng.randf() * step; var pz := z + rng.randf() * step
			x += step
			if not _free_ground(px, pz, 0.8): continue
			var f := _forest(px, pz)
			var n2 := noise.get_noise_2d(px * 3.1 + 100.0, pz * 3.1) * 0.5 + 0.5
			var r := rng.randf()
			if f > 0.4:
				if r < 0.10: _add("Fern_1", px, pz, rng.randf_range(0.8, 1.4))
				elif r < 0.13: _add("Bush_Common", px, pz, rng.randf_range(0.8, 1.3))
				elif r < 0.14: _add(["Mushroom_Common", "Mushroom_Laetiporus"][rng.randi() % 2], px, pz, rng.randf_range(0.8, 1.5))
				elif r < 0.17: _add("Plant_1", px, pz, rng.randf_range(0.8, 1.2))
			else:
				var town := WorldData.town_w(Vector2(px, pz))
				if n2 > 0.62 and r < 0.35 * (1.0 - town * 0.7):
					_add(["Flower_3_Group", "Flower_4_Group", "Flower_3_Single", "Flower_4_Single"][rng.randi() % 4], px, pz, rng.randf_range(0.32, 0.5))
				elif n2 < 0.3 and r < 0.12: _add("Clover_%d" % (1 + rng.randi() % 2), px, pz, rng.randf_range(0.9, 1.4))
				elif r < 0.018: _add(["Bush_Common", "Bush_Common_Flowers"][rng.randi() % 2], px, pz, rng.randf_range(0.7, 1.1))
				elif r < 0.05: _add(["Grass_Wispy_Tall", "Grass_Common_Tall", "Grass_Wispy_Short"][rng.randi() % 3], px, pz, rng.randf_range(0.3, 0.5))
				elif r < 0.054: _add(["Plant_7", "Plant_1"][rng.randi() % 2], px, pz, rng.randf_range(0.4, 0.7))
			# rocks: hills and forest edges
			var rocky := 0.0 if ash else 0.008 + 0.05 * (1.0 - WorldData.n(px, pz).y)
			if rng.randf() < 0.004 + rocky + 0.02 * smoothstep(85.0, 115.0, maxf(absf(px), absf(pz))):
				var s := rng.randf_range(0.5, 1.4)
				_add("Rock_Medium_%d" % (1 + rng.randi() % 3), px, pz, s, -1.0, 0.25)
				WorldData.clear_disc(Vector2(px, pz), 1.4 * s)
				_trunk(px, pz, 1.3 * s, 1.5 * s)
		z += step
	# reeds and flowers around the pond
	var placed := 0 if WorldData.POND_R > 0.0 else 999
	while placed < 170:
		var a := rng.randf() * TAU; var d := WorldData.POND_R * rng.randf_range(0.7, 1.6)
		var p := WorldData.POND + Vector2(cos(a), sin(a)) * d
		var pd := WorldData.pond_d(p)
		if pd < 0.93 or pd > 1.25 or WorldData.road(p).x < 1.0: continue
		placed += 1
		_add(["Grass_Common_Tall", "Grass_Wispy_Tall", "Plant_1"][rng.randi() % 3], p.x, p.y, rng.randf_range(0.45, 0.8), -1.0, 0.0)
	tints["Bush_Common"] = Color(0.36, 0.62, 0.22, 1.0)     # the kit's bush is autumn red: repaint it summer green

# ------------------------------------------------------------------ building the multimeshes
func _build(kind: String) -> void:
	var sc: Node = load(N + kind + ".gltf").instantiate()
	var mis := sc.find_children("*", "MeshInstance3D", true, false)
	if mis.is_empty(): sc.free(); return
	var src: MeshInstance3D = mis[0]
	var mesh: Mesh = src.mesh.duplicate()
	var aabb := mesh.get_aabb()
	var tall := kind.contains("Tree") or kind.begins_with("Pine")
	for s in mesh.get_surface_count():
		var om := mesh.surface_get_material(s)
		var sm := ShaderMaterial.new(); sm.shader = load("res://shaders/foliage.gdshader")
		var leaf := false
		if om is BaseMaterial3D:
			var bm: BaseMaterial3D = om
			sm.set_shader_parameter("albedo_tex", bm.albedo_texture if bm.albedo_texture else _white())
			if bm.normal_enabled and bm.normal_texture:
				sm.set_shader_parameter("normal_tex", bm.normal_texture); sm.set_shader_parameter("has_normal", true)
			var mn := om.resource_name.to_lower()
			leaf = mn.contains("lea") or mn.contains("flower") or mn.contains("grass")
			sm.set_shader_parameter("tint", bm.albedo_color)
			if tints.has(kind) and leaf: sm.set_shader_parameter("recolor", tints[kind])
		sm.set_shader_parameter("is_leaf", leaf)
		sm.set_shader_parameter("noise_big", Terrain.noise_big)
		sm.set_shader_parameter("height_ref", maxf(aabb.size.y, 0.3))
		sm.set_shader_parameter("sway", 0.35 if tall else 0.12)
		sm.set_shader_parameter("fade_near_hero", tall)
		sm.set_shader_parameter("flutter", 0.04 if tall else 0.02)
		mesh.surface_set_material(s, sm); mats.append(sm)
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = mesh
	var arr: Array = lists[kind]
	mm.instance_count = arr.size()
	var local := src.transform
	for i in arr.size(): mm.set_instance_transform(i, arr[i] * local)
	var mi := MultiMeshInstance3D.new(); mi.multimesh = mm; mi.name = kind
	if not tall:
		mi.visibility_range_end = 45.0 if kind.begins_with("Flower") or kind.begins_with("Clover") or kind.begins_with("Mushroom") else 80.0
		mi.visibility_range_end_margin = 6.0
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if kind.begins_with("Flower") or kind.begins_with("Clover") or kind.begins_with("Grass") else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	sc.free()

static var _w: Texture2D
static func _white() -> Texture2D:
	if not _w:
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8); img.fill(Color.WHITE); _w = ImageTexture.create_from_image(img)
	return _w

