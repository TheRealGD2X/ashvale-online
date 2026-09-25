extends Node3D
## The town of Ashvale: timber-and-stone houses built from the Medieval Village kit around a
## cobbled market square, with stalls, barrels, lanterns that light at dusk, windows that glow at
## night and chimneys that smoke. Houses register their footprints so no grass grows inside them.

const V := "res://assets/village/"
const P := "res://assets/props/"
const FLOOR_H := 3.0
static var _scenes := {}
var window_mat: StandardMaterial3D        # shared glass: glows warm at night
var lamps: Array[OmniLight3D] = []
var flames: Array[MeshInstance3D] = []
var rng := RandomNumberGenerator.new()
var doors: Array[Vector3] = []          # a spot just outside each front door (world space)

## [x, z, W, D, floors, style, yaw_override] - yaw faces the house front (+Z local) at the square
## when yaw is null. W (frontage) 4|6|8 m, D (depth) 4..12 m.
const HOUSES := [
	[-20.0, -16.0, 8, 8, 2, "brick", null],
	[-8.0, -24.0, 6, 6, 2, "plaster", null],
	[13.0, -21.0, 6, 8, 2, "brick", null],
	[22.5, -10.5, 6, 6, 1, "plaster", null],
	[22.0, 12.0, 8, 8, 2, "plaster", null],
	[10.0, 22.0, 6, 6, 2, "brick", null],
	[-24.0, 11.0, 6, 8, 1, "brick", null],
	[-44.0, -12.0, 8, 8, 2, "plaster", 0.0],
	[-40.0, 14.5, 6, 6, 1, "brick", PI],
	[44.0, -12.0, 6, 8, 2, "brick", 0.0],
	[50.0, 16.0, 8, 8, 1, "plaster", PI],
]

func _ready() -> void:
	rng.seed = 42
	add_to_group("village")
	window_mat = StandardMaterial3D.new()
	window_mat.albedo_color = Color(0.2, 0.25, 0.3); window_mat.roughness = 0.08; window_mat.metallic = 0.4
	window_mat.emission_enabled = true; window_mat.emission = Color(1.0, 0.62, 0.3); window_mat.emission_energy_multiplier = 0.0
	for h in HOUSES:
		var c := Vector2(h[0], h[1])
		var yaw: float = h[6] if h[6] != null else atan2(WorldData.TOWN.x - c.x, WorldData.TOWN.y - c.y)
		house(c, yaw, h[2], h[3], h[4], h[5])
	market()
	garden(Vector2(-37.0, 22.0), 0.45)
	woodpile(Vector3(12.0, 0, -31.0), 0.8)

static func scene(path: String) -> PackedScene:
	if not _scenes.has(path): _scenes[path] = load(path)
	return _scenes[path]

func piece(name: String, parent: Node3D, pos: Vector3, yaw := 0.0, dir := V) -> Node3D:
	var n: Node3D = scene(dir + name + ".gltf").instantiate()
	n.position = pos; n.rotation.y = yaw
	parent.add_child(n)
	if name.begins_with("Window") or name.begins_with("Door"):
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m: MeshInstance3D = mi
			for s in m.mesh.get_surface_count():
				var mat := m.mesh.surface_get_material(s)
				if mat and mat.resource_name.begins_with("MI_WindowGlass"): m.set_surface_override_material(s, window_mat)
	return n

## a house of W x D metres (2 m modules), front (door) facing local +Z
func house(c: Vector2, yaw: float, W: int, D: int, floors: int, style: String) -> void:
	var root := Node3D.new(); root.name = "House"; add_child(root)
	var base := -1e9
	for dx in [-W / 2.0, 0.0, W / 2.0]:
		for dz in [-D / 2.0, 0.0, D / 2.0]:
			var p := c + Vector2(dx, dz).rotated(-yaw)
			base = maxf(base, WorldData.h(p.x, p.y))
	root.position = Vector3(c.x, base + 0.02, c.y); root.rotation.y = yaw
	WorldData.clear_rect(c, Vector2(W / 2.0 + 0.3, D / 2.0 + 0.3), yaw, 0.5)
	var brick := style == "brick"
	var ground_wall := "UnevenBrick" if brick else "Plaster"
	var nx := W / 2; var nz := D / 2
	var door_i := nx / 2    # door module along the front
	for f in floors:
		var y := f * FLOOR_H
		var kind := ground_wall if f == 0 else "Plaster"
		var sides := [
			[Vector3(0, 0, D / 2.0), 0.0, nx, Vector3(1, 0, 0), "front"],
			[Vector3(0, 0, -D / 2.0), PI, nx, Vector3(-1, 0, 0), "back"],
			[Vector3(W / 2.0, 0, 0), PI / 2, nz, Vector3(0, 0, -1), "right"],
			[Vector3(-W / 2.0, 0, 0), -PI / 2, nz, Vector3(0, 0, 1), "left"],
		]
		for s in sides:
			var mid: Vector3 = s[0]; var ry: float = s[1]; var n: int = s[2]; var along: Vector3 = s[3]
			for i in n:
				var p := mid + along * ((i - (n - 1) / 2.0) * 2.0) + Vector3(0, y, 0)
				var nm := "Wall_%s_Straight" % kind
				if f == 0 and s[4] == "front" and i == door_i:
					nm = "Wall_%s_Door_Round" % kind
					piece("DoorFrame_Round_Brick" if brick else "DoorFrame_Round_WoodDark", root, p, ry)
					piece("Door_1_Round", root, p + along * -0.52 + Vector3(0, 0, 0).rotated(Vector3.UP, ry), ry)
					doors.append(root.to_global(p + Vector3(0, 0, 1.3).rotated(Vector3.UP, ry)))
					_lantern(root, p + along * 1.1 + Vector3(0, 2.35, 0) + Vector3(0, 0, 0.32).rotated(Vector3.UP, ry), ry)
				elif (i + f + (1 if s[4] == "left" else 0)) % 2 == 0 or f > 0 and rng.randf() < 0.6:
					var wide := rng.randf() < 0.6
					nm = "Wall_%s_Window_%s_Round" % [kind, "Wide" if wide else "Thin"]
					piece("Window_%s_Round1" % ("Wide" if wide else "Thin"), root, p, ry)
					if wide and rng.randf() < 0.55: piece("WindowShutters_Wide_Round_%s" % ("Open" if rng.randf() < 0.7 else "Closed"), root, p, ry)
				elif f > 0 and kind == "Plaster" and rng.randf() < 0.3:
					nm = "Wall_Plaster_WoodGrid"
				piece(nm, root, p, ry)
		# corner posts
		for cx in [-1, 1]:
			for cz in [-1, 1]:
				piece("Corner_Exterior_%s" % ("Brick" if (f == 0 and brick) else "Wood"), root, Vector3(cx * W / 2.0, y, cz * D / 2.0), atan2(cx, cz) - PI / 4)
	# roof and gables
	var top := floors * FLOOR_H
	var roof := piece("Roof_RoundTiles_%dx%d" % [W, D], root, Vector3(0, top, 0))
	_center_xz(roof, root)
	piece("Roof_Front_Brick%d" % W, root, Vector3(0, top, D / 2.0), 0.0)
	piece("Roof_Front_Brick%d" % W, root, Vector3(0, top, -D / 2.0), PI)
	# chimney through the roof, with smoke
	var chx := (W / 2.0 - 1.2) * (1 if rng.randf() < 0.5 else -1)
	piece("Prop_Chimney", root, Vector3(chx, top + 0.6, -D / 4.0))
	_smoke(root, Vector3(chx, top + 0.6 + 3.1, -D / 4.0))
	# stone foundation band where the ground dips
	var found := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(W + 0.5, 1.2, D + 0.5); found.mesh = bm
	found.position = Vector3(0, -0.58, 0); found.material_override = _stone_mat(); root.add_child(found)
	# vines on some houses
	if rng.randf() < 0.5: piece("Prop_Vine%d" % [1, 2, 4, 5, 6, 9][rng.randi() % 6], root, Vector3(W / 2.0 - 1.0, 2.9, D / 2.0 + 0.12))
	# a lived-in yard: barrels, crates, a bucket or bench by the walls
	var yard := [["Barrel", P], ["Crate_Wooden", P], ["Bucket_Wooden_1", P], ["FarmCrate_Empty", P], ["Prop_Crate", V], ["Bench", P], ["Barrel_Holder", P], ["Stool", P]]
	for k in rng.randi_range(2, 4):
		var it: Array = yard[rng.randi() % yard.size()]
		var side := rng.randi() % 3
		var lp: Vector3
		if side == 0: lp = Vector3(rng.randf_range(-W / 2.0 + 0.8, W / 2.0 - 0.8), 0, D / 2.0 + 0.7)
		elif side == 1: lp = Vector3(W / 2.0 + 0.7, 0, rng.randf_range(-D / 2.0 + 0.8, D / 2.0 - 0.8))
		else: lp = Vector3(-W / 2.0 - 0.7, 0, rng.randf_range(-D / 2.0 + 0.8, D / 2.0 - 0.8))
		if side == 0 and absf(lp.x - (door_i - (nx - 1) / 2.0) * 2.0) < 1.4: continue   # keep the door clear
		var gp := root.to_global(lp)
		var it_node := piece(it[0], root, Vector3(lp.x, WorldData.h(gp.x, gp.z) - root.global_position.y, lp.z), [0.0, PI / 2, -PI / 2][side] + rng.randf_range(-0.3, 0.3), it[1])
		it_node.scale = Vector3.ONE
	# _merge(root)   # parked: unfinished (primitive meshes need skipping); see notes
	# collision
	var body := StaticBody3D.new(); root.add_child(body)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = Vector3(W + 0.3, top + 2.0, D + 0.3); cs.shape = sh
	cs.position = Vector3(0, (top + 2.0) / 2.0, 0); body.add_child(cs)

## Fold a house's ~60 kit pieces into one mesh per material (a handful of draw calls instead of
## hundreds). Lanterns keep their own nodes (they carry lights).
func _merge(root: Node3D) -> void:
	var groups := {}      # key -> [SurfaceTool, material]
	var inv := root.global_transform.affine_inverse()
	var merged: Array[Node] = []
	for child in root.get_children():
		if not (child is Node3D) or child is GPUParticles3D or child is StaticBody3D: continue
		if child.find_children("*", "Light3D", true, false).size() > 0: continue
		var mis := child.find_children("*", "MeshInstance3D", true, false)
		if child is MeshInstance3D: mis.append(child)
		if mis.any(func(m): return not ((m as MeshInstance3D).mesh is ArrayMesh)): continue   # primitive shapes stay as they are
		for m in mis:
			var mi: MeshInstance3D = m
			if not mi.mesh: continue
			var xf := inv * mi.global_transform
			for si in mi.mesh.get_surface_count():
				var mat: Material = mi.material_override if mi.material_override else (mi.get_surface_override_material(si) if mi.get_surface_override_material(si) else mi.mesh.surface_get_material(si))
				var key := str(mat.get_instance_id() if mat else 0) + ":" + str(mi.mesh.surface_get_format(si) & (Mesh.ARRAY_FORMAT_TEX_UV | Mesh.ARRAY_FORMAT_COLOR | Mesh.ARRAY_FORMAT_TANGENT | Mesh.ARRAY_FORMAT_TEX_UV2))
				if not groups.has(key):
					var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); groups[key] = [st, mat]
				(groups[key][0] as SurfaceTool).append_from(mi.mesh, si, xf)
		merged.append(child)
	var mesh := ArrayMesh.new()
	for key in groups:
		var st: SurfaceTool = groups[key][0]
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, groups[key][1])
	for n in merged: n.free()
	var out := MeshInstance3D.new(); out.name = "HouseMesh"; out.mesh = mesh
	root.add_child(out)

var _stone: StandardMaterial3D
func _stone_mat() -> StandardMaterial3D:
	if not _stone:
		_stone = StandardMaterial3D.new()
		_stone.albedo_texture = load(V + "T_RockTrim_BaseColor.png"); _stone.normal_enabled = true; _stone.normal_texture = load(V + "T_RockTrim_Normal.png")
		_stone.uv1_triplanar = true; _stone.uv1_scale = Vector3(0.5, 0.5, 0.5); _stone.roughness = 0.9
	return _stone

func _aabb(n: Node3D) -> AABB:
	var bb := AABB(); var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		bb = b if first else bb.merge(b); first = false
	return bb

func _center_xz(n: Node3D, root: Node3D) -> void:
	# the kit's roofs aren't all centred on their origin: shift so the roof sits over the walls
	var bb := AABB(); var first := true
	var inv := root.global_transform.affine_inverse()
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = m
		var b: AABB = (inv * mi.global_transform) * mi.get_aabb()
		bb = b if first else bb.merge(b); first = false
	var cc := bb.get_center()
	n.position -= Vector3(cc.x, 0, cc.z)

func _lantern(root: Node3D, pos: Vector3, yaw: float) -> void:
	var l := piece("Lantern_Wall", root, pos, yaw, P)
	var light := OmniLight3D.new(); light.light_color = Color(1.0, 0.68, 0.36); light.omni_range = 9.0; light.omni_attenuation = 1.4
	light.light_energy = 0.0; light.shadow_enabled = false; light.position = Vector3(0, -0.25, 0.35)
	l.add_child(light); lamps.append(light)
	var fl := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.07; sm.height = 0.16; fl.mesh = sm
	var fm := StandardMaterial3D.new(); fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; fm.albedo_color = Color(1.0, 0.75, 0.4)
	fm.emission_enabled = true; fm.emission = Color(1.0, 0.6, 0.25); fm.emission_energy_multiplier = 3.0
	fl.material_override = fm; fl.position = Vector3(0, -0.25, 0.3); l.add_child(fl); flames.append(fl)

func _smoke(root: Node3D, pos: Vector3) -> void:
	var p := GPUParticles3D.new(); p.position = pos; root.add_child(p)
	p.amount = 24; p.lifetime = 7.0; p.preprocess = 7.0
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.3, 1, 0.1); pm.spread = 12.0; pm.initial_velocity_min = 0.5; pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0.35, 0.12, 0.1); pm.scale_min = 0.6; pm.scale_max = 1.0
	var sc := Curve.new(); sc.add_point(Vector2(0, 0.35)); sc.add_point(Vector2(1, 2.6)); var sct := CurveTexture.new(); sct.curve = sc; pm.scale_curve = sct
	var g := Gradient.new(); g.set_color(0, Color(0.85, 0.85, 0.85, 0.0)); g.set_color(1, Color(0.8, 0.8, 0.82, 0.0)); g.add_point(0.15, Color(0.85, 0.84, 0.82, 0.32))
	var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(1, 1)
	var m := StandardMaterial3D.new(); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES; m.vertex_color_use_as_albedo = true
	m.albedo_texture = _puff(); q.material = m
	p.draw_pass_1 = q
	p.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(14, 16, 10))

static var _puff_tex: Texture2D
static func _puff() -> Texture2D:
	if _puff_tex: return _puff_tex
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new(); t.gradient = g; t.fill = GradientTexture2D.FILL_RADIAL; t.fill_from = Vector2(0.5, 0.5); t.fill_to = Vector2(1.0, 0.5)
	t.width = 64; t.height = 64; _puff_tex = t
	return t

## the market square: stalls, crates of produce, barrels, benches and a great old tree
func market() -> void:
	var root := Node3D.new(); root.name = "Market"; add_child(root)
	var y := WorldData.h(0, 0)
	WorldData.clear_disc(Vector2.ZERO, 1.2)
	var stuff := [
		["Stall_Empty", Vector3(-7.5, 0, -4.5), 0.9], ["Stall_Cart_Empty", Vector3(-8.5, 0, 3.5), 2.2],
		["Stall_Empty", Vector3(7.0, 0, -5.5), -0.8], ["FarmCrate_Apple", Vector3(-6.2, 0, -2.6), 0.3], ["FarmCrate_Carrot", Vector3(-5.4, 0, -3.4), 1.2],
		["Barrel_Apples", Vector3(8.6, 0, -3.4), 0.0], ["Barrel", Vector3(9.3, 0, -2.4), 0.5], ["Crate_Wooden", Vector3(5.6, 0, -7.2), 0.2],
		["FarmCrate_Empty", Vector3(-9.7, 0, 5.6), 0.7], ["Bench", Vector3(3.2, 0, 5.8), PI], ["Bench", Vector3(-3.4, 0, 6.2), PI + 0.3],
		["Barrel", Vector3(-10.4, 0, 1.6), 0.0], ["Bucket_Wooden_1", Vector3(-9.8, 0, 2.4), 0.0], ["Sack", Vector3(6.2, 0, -3.8), 0.0],
		["WeaponStand", Vector3(10.4, 0, 3.0), -1.6], ["Crate_Wooden", Vector3(10.8, 0, 4.4), 0.4], ["Pouch_Large", Vector3(7.8, 0, -3.1), 0.0],
	]
	for s in stuff:
		var p: Vector3 = s[1]; p.y = WorldData.h(p.x, p.z)
		var nm: String = s[0]
		if not ResourceLoader.exists(P + nm + ".gltf"): continue
		piece(nm, root, p, s[2], P)
	# the old tree at the heart of the square, with a ring of stone around it
	# (the great red ash itself is planted by vegetation.gd so it sways with the others)
	var body := StaticBody3D.new(); root.add_child(body)
	var cs := CollisionShape3D.new(); var cyl := CylinderShape3D.new(); cyl.radius = 0.9; cyl.height = 4.0; cs.shape = cyl
	cs.position = Vector3(0.0, y + 2.0, 0.0); body.add_child(cs)
	# banners and torches around the square
	for a in [0.4, 2.0, 3.5, 5.2]:
		var p := Vector3(cos(a) * 11.5, 0, sin(a) * 11.5); p.y = WorldData.h(p.x, p.z)
		var t := piece("Torch_Metal", root, p, -a, P)
		var light := OmniLight3D.new(); light.light_color = Color(1.0, 0.62, 0.3); light.omni_range = 11.0; light.light_energy = 0.0
		light.position = Vector3(0, 2.2, 0); light.shadow_enabled = true; t.add_child(light); lamps.append(light)

## a fenced vegetable garden: rows of carrots and cabbages in dark soil
func garden(c: Vector2, yaw: float) -> void:
	var root := Node3D.new(); root.name = "Garden"; add_child(root)
	root.position = Vector3(c.x, WorldData.h(c.x, c.y), c.y); root.rotation.y = yaw
	var w := 6.0; var d := 4.0
	WorldData.clear_rect(c, Vector2(w / 2.0 + 0.2, d / 2.0 + 0.2), yaw, 0.4)
	var soil := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(w, 0.3, d); soil.mesh = bm; soil.position.y = -0.08
	var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.3, 0.21, 0.14); sm.roughness = 1.0
	sm.albedo_texture = load("res://assets/nature/Rocks_Diffuse.png"); sm.uv1_triplanar = true; sm.uv1_scale = Vector3.ONE * 0.7
	soil.material_override = sm; root.add_child(soil)
	for row in 4:
		for i in 9:
			var lp := Vector3(-w / 2.0 + 0.5 + i * 0.62, 0.05, -d / 2.0 + 0.6 + row * 0.95)
			var nm := "Carrot" if row % 2 == 0 else "Carrot"
			var cr := piece(nm, root, lp + Vector3(rng.randf_range(-0.06, 0.06), 0, rng.randf_range(-0.06, 0.06)), rng.randf() * TAU, P)
			cr.scale = Vector3.ONE * rng.randf_range(0.9, 1.2)
	# fence around it, with a gap for the gate
	for i in 3:
		piece("Prop_WoodenFence_Single", root, Vector3(-w / 2.0 + 1.0 + i * 2.0, 0, -d / 2.0 - 0.3), 0.0, V)
		if i != 1: piece("Prop_WoodenFence_Single", root, Vector3(-w / 2.0 + 1.0 + i * 2.0, 0, d / 2.0 + 0.3), 0.0, V)
	for i in 2:
		piece("Prop_WoodenFence_Single", root, Vector3(-w / 2.0 - 0.3, 0, -d / 2.0 + 1.0 + i * 2.0), PI / 2, V)
		piece("Prop_WoodenFence_Single", root, Vector3(w / 2.0 + 0.3, 0, -d / 2.0 + 1.0 + i * 2.0), PI / 2, V)
	piece("Bucket_Wooden_1", root, Vector3(0.6, 0, d / 2.0 + 0.8), 0.0, P)
	piece("FarmCrate_Carrot", root, Vector3(-1.4, 0, d / 2.0 + 0.9), 0.3, P)

## the woodcutter's corner: a stack of logs and a chopping block
func woodpile(p: Vector3, yaw: float) -> void:
	var root := Node3D.new(); root.name = "Woodpile"; add_child(root)
	p.y = WorldData.h(p.x, p.z); root.position = p; root.rotation.y = yaw
	var bark := StandardMaterial3D.new(); bark.albedo_texture = load("res://assets/nature/Bark_NormalTree.png"); bark.uv1_triplanar = true; bark.uv1_scale = Vector3.ONE * 0.8; bark.roughness = 0.9
	var cut := StandardMaterial3D.new(); cut.albedo_color = Color(0.78, 0.62, 0.42); cut.roughness = 0.9
	var rows := [[4, 0.0], [3, 0.3], [2, 0.6]]
	for r in rows.size():
		var n: int = rows[r][0]
		for i in n:
			var lg := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.16; cm.bottom_radius = 0.16; cm.height = 1.8; cm.radial_segments = 12
			cm.material = bark; lg.mesh = cm
			lg.rotation = Vector3(0, 0, PI / 2); lg.position = Vector3(0, 0.16 + r * 0.29, (i - (n - 1) / 2.0) * 0.33)
			root.add_child(lg)
			for e in [-0.905, 0.905]:
				var cap := MeshInstance3D.new(); var cc := CylinderMesh.new(); cc.top_radius = 0.15; cc.bottom_radius = 0.15; cc.height = 0.01; cc.material = cut; cap.mesh = cc
				cap.rotation = Vector3(0, 0, PI / 2); cap.position = lg.position + Vector3(e, 0, 0); root.add_child(cap)
	# chopping block: a stout round of trunk with a pale cut top
	var bl := MeshInstance3D.new(); var bc := CylinderMesh.new(); bc.top_radius = 0.34; bc.bottom_radius = 0.38; bc.height = 0.55; bc.material = bark; bl.mesh = bc
	bl.position = Vector3(-1.8, 0.27, 0.9); root.add_child(bl)
	var top := MeshInstance3D.new(); var tc := CylinderMesh.new(); tc.top_radius = 0.33; tc.bottom_radius = 0.33; tc.height = 0.012; tc.material = cut; top.mesh = tc
	top.position = Vector3(-1.8, 0.555, 0.9); root.add_child(top)

func _process(_d: float) -> void:
	var n := DayNight.night
	window_mat.emission_energy_multiplier = n * 2.4
	for l in lamps: l.light_energy = n * 2.2
	for f in flames: f.visible = n > 0.05
