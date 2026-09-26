extends Node3D
## The places the Ashvale Province quests name, so you can find them by looking (WORLD-LAYOUT.md):
##   the well and the fields behind it (rats), the granary north of the square (the Grizzled Rat's
##   cellar), the scarecrow fields on the west road, the Mill east along the King's Road (windmill
##   on its rise, farmhouse, barn, beet fields where the boars root), and the Old Shrine up the path
##   north-east of the Mill. The split oak and the hollow oak are planted by vegetation.gd.
## Built before the vegetation so no trees grow through them.

const B := "res://assets/buildings/"
const MILL := Vector2(68, 12)
const WINDMILL := Vector2(73, 23)
const GRANARY := Vector2(-17, -37)
const SHRINE := Vector2(72, -84)
const WELL := Vector2(-16, 14)
const SPLIT_OAK := Vector2(94, 24)
const HOLLOW_OAK := Vector2(108, -40)

var sails: Node3D
var village: Node

func _ready() -> void:
	add_to_group("landmarks")
	village = get_tree().get_first_node_in_group("village")
	_place("well", WELL, 0.4, 1.2)
	_place("granary", GRANARY, 0.35, 3.6, Vector2(3.4, 2.6))
	var wm := _place("windmill", WINDMILL, PI + 0.5, 0.0)
	_solid(WINDMILL, 3.3, 10.0)
	sails = wm.find_child("Sails", true, false)
	_place("shrine", SHRINE, 0.0, 0.0)
	_solid_ring(SHRINE)
	# the Mill: Hale's farmhouse and the barn, facing the road
	if village:
		village.house(Vector2(73, -7), 0.0, 8, 8, 2, "plaster")
		village.house(Vector2(87, -7), 0.0, 8, 10, 1, "brick")
	# fields: beet rows south of the Mill, wheat and hay on the west road
	_field(Vector2(64, 34), Vector2(9, 6), 0.1, "beets")
	_field(Vector2(82, 40), Vector2(8, 6), -0.15, "beets")
	_field(Vector2(-60, 20), Vector2(10, 6), 0.05, "wheat")
	_field(Vector2(-78, -6), Vector2(8, 6), -0.1, "wheat")
	for p in [Vector2(-52, 12), Vector2(-66, 12.5), Vector2(-71, 24), Vector2(58, 26), Vector2(77, 30), Vector2(-26, 24)]:
		_place("haybale", p, randf() * TAU, 1.0)
	# the rats' field behind the well: a scatter of sacks and crates
	for p in [Vector2(-24, 21), Vector2(-30, 27), Vector2(-20, 28)]:
		_prop("FarmCrate_Empty", p, randf() * TAU)
	# a signpost at the Mill fork
	_signpost(Vector2(60, 8), ["Ashvale", "The Mill", "Old Shrine"])
	for p in [SPLIT_OAK, HOLLOW_OAK]: WorldData.clear_disc(p, 5.0, 1.0)

func _process(delta: float) -> void:
	if sails: sails.rotate_object_local(Vector3(0, 0, 1), delta * 0.45)

## a building model standing on the ground, with a box you can't walk through
func _place(name: String, c: Vector2, yaw: float, clear_r: float, box := Vector2.ZERO) -> Node3D:
	var path := B + name + ".glb"
	if not ResourceLoader.exists(path): push_warning("missing " + path); return Node3D.new()
	var n: Node3D = load(path).instantiate()
	var y := INF
	for d in [Vector2.ZERO, Vector2(1.5, 0), Vector2(-1.5, 0), Vector2(0, 1.5), Vector2(0, -1.5)]:
		y = minf(y, WorldData.h(c.x + d.x, c.y + d.y))
	n.position = Vector3(c.x, y - 0.05, c.y); n.rotation.y = yaw
	add_child(n)
	for mi in n.find_children("*", "MeshInstance3D", true, false): (mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if clear_r > 0.0: WorldData.clear_disc(c, clear_r, 0.6)
	if box != Vector2.ZERO:
		WorldData.clear_rect(c, box + Vector2(0.6, 0.6), yaw, 0.6)
		var body := StaticBody3D.new(); add_child(body)
		var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(box.x * 2.0, 5.0, box.y * 2.0); cs.shape = sh
		body.position = Vector3(c.x, y + 2.5, c.y); body.rotation.y = yaw; body.add_child(cs)
	return n

func _solid(c: Vector2, r: float, h: float) -> void:
	WorldData.clear_disc(c, r + 1.0, 0.8)
	var body := StaticBody3D.new(); add_child(body)
	var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = r; sh.height = h; cs.shape = sh
	body.position = Vector3(c.x, WorldData.h(c.x, c.y) + h / 2.0, c.y); body.add_child(cs)

## the shrine's pillars and altar block the way, its floor doesn't
func _solid_ring(c: Vector2) -> void:
	WorldData.clear_disc(c, 7.8, 0.8)
	var body := StaticBody3D.new(); add_child(body)
	var y := WorldData.h(c.x, c.y)
	for k in 8:
		var a := k * TAU / 8.0 + 0.2
		# Blender's +Y is Godot's -Z
		var cs := CollisionShape3D.new(); var sh := CylinderShape3D.new(); sh.radius = 0.55; sh.height = 3.0; cs.shape = sh
		cs.position = Vector3(c.x + cos(a) * 5.2, y + 1.5, c.y - sin(a) * 5.2); body.add_child(cs)
	var alt := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(2.6, 3.0, 3.6); alt.shape = bs
	alt.position = Vector3(c.x, y + 1.5, c.y - 2.4); body.add_child(alt)

func _prop(name: String, c: Vector2, yaw: float) -> void:
	if village == null or not ResourceLoader.exists("res://assets/props/%s.gltf" % name): return
	village.piece(name, self, Vector3(c.x, WorldData.h(c.x, c.y), c.y), yaw, "res://assets/props/")

## a ploughed field with rows of crops and a fence along two sides
func _field(c: Vector2, half: Vector2, yaw: float, crop: String) -> void:
	var root := Node3D.new(); add_child(root)
	root.position = Vector3(c.x, WorldData.h(c.x, c.y), c.y); root.rotation.y = yaw
	WorldData.clear_rect(c, half, yaw, 0.5)
	var soil := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = half * 2.0; pm.subdivide_width = 16; pm.subdivide_depth = 16; soil.mesh = pm
	var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.36, 0.25, 0.16) if crop == "beets" else Color(0.52, 0.42, 0.24); sm.roughness = 1.0
	sm.albedo_texture = load("res://assets/nature/Rocks_Diffuse.png"); sm.uv1_triplanar = true; sm.uv1_scale = Vector3.ONE * 0.6
	soil.material_override = sm; root.add_child(soil)
	# follow the ground: a plane can't bend, so sink it a little and let the crops sit on the real height
	soil.position.y = 0.04
	var rng := RandomNumberGenerator.new(); rng.seed = int(c.x * 13 + c.y * 7)
	var leaf := StandardMaterial3D.new(); leaf.albedo_color = Color(0.3, 0.55, 0.2) if crop == "beets" else Color(0.85, 0.72, 0.35); leaf.roughness = 0.9
	var root_mat := StandardMaterial3D.new(); root_mat.albedo_color = Color(0.55, 0.12, 0.2)
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
	var mesh: Mesh
	if crop == "beets":
		var sp := SphereMesh.new(); sp.radius = 0.22; sp.height = 0.34; sp.radial_segments = 6; sp.rings = 3; sp.material = leaf; mesh = sp
	else:
		var cy := CylinderMesh.new(); cy.top_radius = 0.02; cy.bottom_radius = 0.18; cy.height = 0.9; cy.radial_segments = 5; cy.rings = 1; cy.material = leaf; mesh = cy
	mm.mesh = mesh
	var xs := []
	var rows := int(half.y * 2.0 / 0.9)
	var cols := int(half.x * 2.0 / (0.55 if crop == "beets" else 0.4))
	for r in rows:
		for i in cols:
			var lp := Vector3(-half.x + 0.4 + i * (half.x * 2.0 - 0.8) / cols, 0, -half.y + 0.5 + r * 0.9)
			var wp := root.to_global(lp) if root.is_inside_tree() else root.transform * lp
			var gy := WorldData.h(wp.x, wp.z) - root.position.y
			var s := rng.randf_range(0.8, 1.2)
			xs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), lp + Vector3(rng.randf_range(-0.08, 0.08), gy + (0.12 if crop == "beets" else 0.4), rng.randf_range(-0.08, 0.08))))
	mm.instance_count = xs.size()
	for i in xs.size(): mm.set_instance_transform(i, xs[i])
	var mi := MultiMeshInstance3D.new(); mi.multimesh = mm; root.add_child(mi)
	mi.visibility_range_end = 90.0
	# fence posts along the two long sides
	if village:
		var n := int(half.x)
		for i in n:
			var x := -half.x + 1.0 + i * 2.0
			for z in [-half.y - 0.5, half.y + 0.5]:
				var fp := root.transform * Vector3(x, 0, z)
				village.piece("Prop_WoodenFence_Single", root, Vector3(x, WorldData.h(fp.x, fp.z) - root.position.y, z), 0.0, "res://assets/village/")

func _signpost(c: Vector2, words: Array) -> void:
	var root := Node3D.new(); add_child(root)
	root.position = Vector3(c.x, WorldData.h(c.x, c.y), c.y)
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.45, 0.3, 0.18); wood.roughness = 0.9
	var post := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.16, 2.6, 0.16); bm.material = wood; post.mesh = bm; post.position.y = 1.3; root.add_child(post)
	for i in words.size():
		var arm := MeshInstance3D.new(); var am := BoxMesh.new(); am.size = Vector3(1.4, 0.3, 0.06); am.material = wood; arm.mesh = am
		arm.position = Vector3(0.55 if i % 2 == 0 else -0.55, 2.2 - i * 0.42, 0); arm.rotation.y = [0.0, PI, -1.2][i % 3] * 0.3
		root.add_child(arm)
		var l := Label3D.new(); l.text = words[i]; l.font_size = 40; l.pixel_size = 0.006; l.modulate = Color(0.95, 0.9, 0.75); l.outline_size = 6
		l.position = Vector3(0, 0, 0.04); arm.add_child(l)
