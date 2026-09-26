extends Node3D
## The pond: calm reflective water (shaders/water.gdshader) with a mirrored reflection camera,
## lily pads and blossoms, floating petals, pebbles along the bank, a little wooden jetty, and
## now and then a fish that leaves a ripple ring.

var mat: ShaderMaterial
var refl_vp: SubViewport
var refl_cam: Camera3D
var pond: MeshInstance3D
var rings := []            # [Vector4(x, z, age, strength)]
var ring_timer := 2.0
var rng := RandomNumberGenerator.new()
var pads: Array[Node3D] = []
const LAYER_GROUND := 2    # terrain + grass: left out of the reflection (they sit below the mirror)
const LAYER_WATER := 4

func _ready() -> void:
	rng.seed = 5
	pond = MeshInstance3D.new(); pond.name = "Pond"
	var pm := PlaneMesh.new(); pm.size = Vector2.ONE * WorldData.POND_R * 4.0; pm.subdivide_width = 48; pm.subdivide_depth = 48
	pond.mesh = pm
	mat = ShaderMaterial.new(); mat.shader = load("res://shaders/water.gdshader")
	mat.set_shader_parameter("noise_fine", Terrain.noise_fine); mat.set_shader_parameter("noise_big", Terrain.noise_big)
	mat.set_shader_parameter("world_mask", Terrain.mask_tex); mat.set_shader_parameter("half_size", WorldData.HALF)
	pond.material_override = mat
	# some zones have their own water: the sea, a lava lake, a frozen tarn
	var wz: Dictionary = WorldData.Z.get("water", {})
	for k in ["shallow", "mid", "deep"]:
		if wz.has(k): mat.set_shader_parameter(k, wz[k])
	if wz.has("glow"): mat.set_shader_parameter("glow", wz["glow"]); mat.set_shader_parameter("reflect_amount", 0.0)
	pond.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pond.layers = LAYER_WATER
	pond.position = Vector3(WorldData.POND.x, WorldData.WATER_H, WorldData.POND.y)
	add_child(pond)
	_reflection()
	if WorldData.Z.get("water", {}).get("pads", true): _dress()

# ------------------------------------------------------------------ mirrored reflection camera
func _reflection() -> void:
	refl_vp = SubViewport.new(); refl_vp.name = "Reflection"
	refl_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	refl_vp.msaa_3d = Viewport.MSAA_2X
	add_child(refl_vp)
	refl_cam = Camera3D.new(); refl_cam.cull_mask = 0xFFFFF & ~(LAYER_GROUND | LAYER_WATER)
	refl_vp.add_child(refl_cam)
	mat.set_shader_parameter("reflection_tex", refl_vp.get_texture())

func _sync_reflection() -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam: return
	var vs := get_viewport().get_visible_rect().size
	var want := Vector2i(int(vs.x / 3), int(vs.y / 3))
	if refl_vp.size != want: refl_vp.size = want
	if not refl_cam.environment:
		var we := get_tree().root.find_children("*", "WorldEnvironment", true, false)
		if we.size():
			var env: Environment = (we[0] as WorldEnvironment).environment.duplicate()
			env.sdfgi_enabled = false; env.ssil_enabled = false; env.volumetric_fog_enabled = false; env.ssao_enabled = false; env.ssr_enabled = false
			refl_cam.environment = env
	refl_cam.fov = cam.fov; refl_cam.near = cam.near; refl_cam.far = 400.0
	# mirror the main camera in the water plane (flip its up so the basis stays right-handed)
	var h := WorldData.WATER_H
	var R := Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, 1)), Vector3(0, 2.0 * h, 0))
	var S := Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, 1)), Vector3.ZERO)
	refl_cam.global_transform = R * cam.global_transform * S
	# only render the reflection when the pond could be on screen
	# only render the reflection when the pond is close and actually on screen
	var visible := false
	if cam.global_position.distance_to(pond.global_position) < 75.0:
		var r := WorldData.POND_R * 1.2
		for o in [Vector3.ZERO, Vector3(r, 0, 0), Vector3(-r, 0, 0), Vector3(0, 0, r), Vector3(0, 0, -r)]:
			if cam.is_position_in_frustum(pond.global_position + o): visible = true; break
	refl_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED

# ------------------------------------------------------------------ lily pads, petals, pebbles, jetty
func _pad_mesh(r: float) -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 20; var notch := 0.5
	var col_c := Color(0.42, 0.62, 0.24); var col_e := Color(0.22, 0.42, 0.16)
	for i in n:
		var a0 := notch / 2.0 + (TAU - notch) * i / n; var a1 := notch / 2.0 + (TAU - notch) * (i + 1) / n
		var p0 := Vector3(cos(a0) * r, 0.012, sin(a0) * r); var p1 := Vector3(cos(a1) * r, 0.012, sin(a1) * r)
		for v in [[Vector3(0, 0.02, 0), col_c], [p1, col_e], [p0, col_e]]:
			st.set_color(v[1]); st.set_normal(Vector3.UP); st.add_vertex(v[0])
	return st.commit()

func _blossom(parent: Node3D, col: Color) -> void:
	var m := StandardMaterial3D.new(); m.albedo_color = col; m.roughness = 0.6
	m.subsurf_scatter_enabled = false; m.backlight_enabled = true; m.backlight = col * 0.6
	for ring in 2:
		var k := 6 if ring == 0 else 5
		for i in k:
			var petal := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.05; sm.height = 0.1; sm.radial_segments = 8; sm.rings = 4
			petal.mesh = sm; petal.material_override = m
			var a := TAU * i / k + ring * 0.5
			petal.scale = Vector3(0.9, 0.35, 2.0) * (1.0 - ring * 0.25)
			petal.position = Vector3(cos(a) * 0.07, 0.05 + ring * 0.03, sin(a) * 0.07) * (1.0 - ring * 0.35)
			petal.rotation = Vector3(0, -a + PI / 2, 0)
			petal.rotate_object_local(Vector3.RIGHT, -0.5 - ring * 0.4)
			parent.add_child(petal)
	var heart := MeshInstance3D.new(); var hs := SphereMesh.new(); hs.radius = 0.035; hs.height = 0.05; heart.mesh = hs
	var hm := StandardMaterial3D.new(); hm.albedo_color = Color(1.0, 0.82, 0.3); hm.emission_enabled = true; hm.emission = Color(1.0, 0.7, 0.2); hm.emission_energy_multiplier = 0.2
	heart.material_override = hm; heart.position.y = 0.08; parent.add_child(heart)

func _dress() -> void:
	var c := WorldData.POND
	var pad_mat := StandardMaterial3D.new(); pad_mat.vertex_color_use_as_albedo = true; pad_mat.roughness = 0.35; pad_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# lily pads in a few drifting clusters in the shallows
	for cl in 5:
		var a := rng.randf() * TAU; var d := WorldData.POND_R * rng.randf_range(0.4, 0.65)
		var cc := c + Vector2(cos(a), sin(a)) * d
		for i in rng.randi_range(4, 8):
			var p := cc + Vector2(rng.randf_range(-1.6, 1.6), rng.randf_range(-1.6, 1.6))
			if WorldData.pond_d(p) > 0.8: continue
			var pad := MeshInstance3D.new(); pad.mesh = _pad_mesh(rng.randf_range(0.22, 0.42)); pad.material_override = pad_mat
			pad.position = Vector3(p.x, WorldData.WATER_H + 0.005, p.y); pad.rotation.y = rng.randf() * TAU
			pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(pad); pads.append(pad)
			if rng.randf() < 0.3:
				var b := Node3D.new(); pad.add_child(b); b.position = Vector3(0.05, 0.01, 0.02)
				_blossom(b, [Color(1.0, 0.72, 0.82), Color(1.0, 0.95, 0.97), Color(0.98, 0.6, 0.72)][rng.randi() % 3])
	# pebbles along the bank
	var pebbles := ["Pebble_Round_1", "Pebble_Round_2", "Pebble_Round_3", "Pebble_Round_4", "Pebble_Round_5", "Pebble_Square_1", "Pebble_Square_2", "Pebble_Square_3"]
	var placed := 0
	while placed < 150:
		var a := rng.randf() * TAU
		var p := c + Vector2(cos(a), sin(a)) * WorldData.POND_R * rng.randf_range(0.6, 1.5)
		var pd := WorldData.pond_d(p)
		if pd < 0.86 or pd > 1.06: continue
		placed += 1
		var nm: String = pebbles[rng.randi() % pebbles.size()]
		var sc: Node3D = load("res://assets/nature/%s.gltf" % nm).instantiate()
		sc.position = Vector3(p.x, WorldData.h(p.x, p.y) - 0.03, p.y); sc.rotation.y = rng.randf() * TAU
		sc.scale = Vector3.ONE * rng.randf_range(0.6, 1.4)
		add_child(sc)
	# a little wooden jetty reaching out from the path's end
	# the jetty starts where the pond path meets the water and reaches out toward the middle
	var p := Vector2(-29, 37.5); var dir := (c - p).normalized()
	var guard := 0
	while WorldData.h(p.x, p.y) > WorldData.WATER_H + 0.05 and guard < 200: p += dir * 0.25; guard += 1
	_jetty(p - dir * 1.2, c)

func _jetty(start: Vector2, c: Vector2) -> void:
	var dir := (c - start).normalized()
	var yaw := atan2(dir.x, dir.y)
	var root := Node3D.new(); root.name = "Jetty"; add_child(root)
	root.position = Vector3(start.x, WorldData.WATER_H + 0.45, start.y); root.rotation.y = yaw
	var wood := StandardMaterial3D.new(); wood.albedo_texture = load("res://assets/village/T_WoodTrim_BaseColor.png"); wood.uv1_triplanar = true; wood.uv1_scale = Vector3.ONE * 0.8
	wood.normal_enabled = true; wood.normal_texture = load("res://assets/village/T_WoodTrim_Normal.png"); wood.roughness = 0.85
	for i in 5:
		var f: Node3D = load("res://assets/village/Floor_WoodDark.gltf").instantiate()
		f.position = Vector3(0, 0, 1.0 + i * 2.0); root.add_child(f)
		for sx in [-0.9, 0.9]:
			var post := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.09; cm.bottom_radius = 0.11; cm.height = 2.2; post.mesh = cm
			post.material_override = wood; post.position = Vector3(sx, -0.7, 2.0 + i * 2.0); root.add_child(post)
	# a stool and a fishing rod leaning on a post, for someone who likes to sit here
	var body := StaticBody3D.new(); root.add_child(body)
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(2.0, 0.1, 10.0); cs.shape = bs; cs.position = Vector3(0, -0.02, 5.0); body.add_child(cs)

func _process(delta: float) -> void:
	_sync_reflection()
	var t := DayNight.time_s
	var sd := DayNight.sun_dir()
	var day := 1.0 - DayNight.night
	if sd.y < 0.0: sd = Vector3(-sd.x, absf(sd.y) * 0.9 + 0.25, -sd.z).normalized()   # the moon
	mat.set_shader_parameter("sun_dir", sd)
	mat.set_shader_parameter("daylight", day)
	mat.set_shader_parameter("sun_col", Color(1.0, 0.8, 0.55).lerp(Color(1.0, 0.96, 0.88), clampf(sd.y * 3.0, 0.0, 1.0)) if day > 0.2 else Color(0.6, 0.7, 0.95))
	# fish: every so often a ring spreads from somewhere in the pond
	ring_timer -= delta
	if ring_timer <= 0.0:
		ring_timer = rng.randf_range(3.0, 9.0)
		var a := rng.randf() * TAU; var d := WorldData.POND_R * sqrt(rng.randf()) * 0.8
		rings.append(Vector4(WorldData.POND.x + cos(a) * d, WorldData.POND.y + sin(a) * d, 0.0, rng.randf_range(0.6, 1.0)))
		if rings.size() > 6: rings.pop_front()
	var arr := PackedVector4Array()
	for i in 6:
		if i < rings.size():
			rings[i].z += delta; arr.append(rings[i])
		else: arr.append(Vector4(0, 0, 0, 0))
	mat.set_shader_parameter("rings", arr)
	# lily pads bob gently
	for i in pads.size():
		var p := pads[i]
		p.position.y = WorldData.WATER_H + 0.005 + sin(t * 0.8 + i) * 0.006
		p.rotation.y += sin(t * 0.1 + i * 1.7) * delta * 0.02
