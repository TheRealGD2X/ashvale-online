class_name Fx extends Node3D
## Spell and combat effects. Every ability has a look: a glow in the caster's hands and a rune
## circle at their feet while casting, projectiles with trails and lights, impacts with sparks,
## smoke and a flash, shockwaves along the ground, columns of fire and light, shields, and small
## lingering effects for as long as a burn, slow, root or blessing lasts.
##
## Units call it through the "fx" group:  play(id, src, target, pos) · projectile(...) ·
## cast_start(unit, id) · aura_added(unit, id) · aura_removed(unit, id) · level_up(unit)

const SCHOOL := {"fire": Color(1.0, 0.42, 0.08), "frost": Color(0.45, 0.78, 1.0), "arcane": Color(0.78, 0.45, 1.0),
	"holy": Color(1.0, 0.86, 0.45), "shadow": Color(0.55, 0.25, 0.95), "nature": Color(0.5, 1.0, 0.4), "physical": Color(1.0, 0.85, 0.6)}

static var glow: Texture2D
static var spark: Texture2D
static var ring_tex: Texture2D
static var smoke: Texture2D
static var noise: Texture2D
static var rune: Texture2D
var energy_shader: Shader
var mats := {}
var casting := {}          # unit -> [nodes]
var lingering := {}        # "unit_id:aura" -> node
var cam: Camera3D
var shake_amt := 0.0

func _ready() -> void:
	add_to_group("fx")
	energy_shader = load("res://shaders/energy.gdshader")
	if glow == null: _make_textures()

# ------------------------------------------------------------------ textures

func _make_textures() -> void:
	glow = _radial(64, func(d): return pow(clampf(1.0 - d, 0.0, 1.0), 2.2))
	spark = _radial(32, func(d): return pow(clampf(1.0 - d, 0.0, 1.0), 6.0) + 0.2 * clampf(1.0 - d * 1.5, 0, 1))
	ring_tex = _radial(128, func(d): return pow(clampf(1.0 - absf(d - 0.8) / 0.2, 0.0, 1.0), 1.5) + 0.25 * clampf(d / 0.8, 0, 1) * float(d < 0.8))
	var fn := FastNoiseLite.new(); fn.frequency = 0.08; fn.fractal_octaves = 4
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length() / 32.0
			var n := fn.get_noise_2d(x, y) * 0.5 + 0.5
			img.set_pixel(x, y, Color(1, 1, 1, clampf((1.0 - d) * 1.6 - 0.2, 0, 1) * (0.45 + n * 0.7)))
	smoke = ImageTexture.create_from_image(img)
	var nt := NoiseTexture2D.new(); nt.seamless = true; nt.width = 256; nt.height = 256
	var n2 := FastNoiseLite.new(); n2.frequency = 0.015; n2.fractal_octaves = 3; nt.noise = n2
	noise = nt
	# a rune circle for the ground under casters
	var r := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in 256:
		for x in 256:
			var v := Vector2(x - 127.5, y - 127.5); var d := v.length() / 128.0; var ang := v.angle()
			var a := 0.0
			a += clampf(1.0 - absf(d - 0.92) / 0.03, 0, 1)
			a += clampf(1.0 - absf(d - 0.78) / 0.02, 0, 1) * 0.8
			if d > 0.8 and d < 0.9: a += clampf(1.0 - absf(sin(ang * 12.0)) * 6.0, 0, 1) * 0.7   # runes between the rings
			a += clampf(1.0 - absf(d - 0.45) / 0.015, 0, 1) * 0.6
			for k in 6:   # a star
				var t := ang + TAU * k / 6.0
				a += clampf(1.0 - absf(sin(t * 0.5) * d * 128.0 - 0.0) / 1.5, 0, 1) * float(d < 0.78) * 0.0
			var tri := 0.0
			for k in 3:
				var th := TAU * k / 3.0 + PI / 2.0
				var n := Vector2(cos(th), sin(th))
				tri = maxf(tri, clampf(1.0 - absf(v.dot(n) / 128.0 - 0.39) / 0.012, 0, 1))
				var th2 := th + PI
				var n3 := Vector2(cos(th2), sin(th2))
				tri = maxf(tri, clampf(1.0 - absf(v.dot(n3) / 128.0 - 0.39) / 0.012, 0, 1))
			a += tri * float(d < 0.78) * 0.7
			r.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0, 1)))
	rune = ImageTexture.create_from_image(r)

func _radial(size: int, f: Callable) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x - c, y - c).length() / (size / 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(f.call(d), 0.0, 1.0)))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _add_mat(tex: Texture2D, billboard := true) -> StandardMaterial3D:
	var key := str(tex.get_rid()) + str(billboard)
	if mats.has(key): return mats[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.no_depth_test = false
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.billboard_keep_scale = true
	mats[key] = m
	return m

func _mix_mat(tex: Texture2D) -> StandardMaterial3D:
	var key := "mix" + str(tex.get_rid())
	if mats.has(key): return mats[key]
	var m := _add_mat(tex).duplicate()
	m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mats[key] = m
	return m

# ------------------------------------------------------------------ sound

var _streams := {}

## play one of our synthesised sounds at a place in the world (or attached to a node)
func sound(name: String, at: Variant = null, vol := 0.0, pitch_var := 0.07) -> AudioStreamPlayer3D:
	if not _streams.has(name):
		var path := "res://assets/sfx/%s.wav" % name
		_streams[name] = load(path) if ResourceLoader.exists(path) else null
	if _streams[name] == null: return null
	var a := AudioStreamPlayer3D.new(); a.stream = _streams[name]
	a.volume_db = vol; a.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	a.unit_size = 8.0; a.max_distance = 60.0; a.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	a.bus = "Master"
	if at is Node3D: (at as Node3D).add_child(a)
	else:
		add_child(a)
		if at is Vector3: a.global_position = at
	a.play()
	a.finished.connect(a.queue_free)
	return a

## a melee swing landed (or didn't)
func melee(src: Node3D, t: Node3D, result: String) -> void:
	if not is_instance_valid(src): return
	sound("swing_%d" % (randi() % 3), src, -6.0, 0.12)
	if result == "hit" or result == "crit":
		_delay(0.12, func():
			if is_instance_valid(t):
				sound("crit" if result == "crit" else "hit_%d" % (randi() % 3), t, -2.0 if result == "crit" else -5.0, 0.1)
				if result == "crit": burst(_chest(t), Color(1.0, 0.85, 0.5), 18, 6.0, 0.08, 0.35, -4.0, spark))

func died(u: Node3D) -> void:
	sound("death", u, -4.0, 0.15)

# ------------------------------------------------------------------ building blocks

## a one-shot spray of sprites
func burst(pos: Vector3, col: Color, amount := 24, speed := 4.0, size := 0.25, life := 0.6, gravity := 0.0,
		tex: Texture2D = null, spread := 180.0, dir := Vector3.UP, additive := true, radius := 0.1, parent: Node3D = null) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount; p.lifetime = life; p.one_shot = true; p.explosiveness = 0.92
	var pm := ParticleProcessMaterial.new()
	pm.direction = dir; pm.spread = spread
	pm.initial_velocity_min = speed * 0.5; pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, gravity, 0)
	pm.damping_min = speed * 0.6; pm.damping_max = speed * 1.2
	pm.scale_min = size * 0.6; pm.scale_max = size * 1.3
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = radius
	var g := Gradient.new()
	g.set_color(0, Color(col.r * 1.3, col.g * 1.3, col.b * 1.3, 1.0)); g.set_color(1, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.0))
	g.add_point(0.15, Color(col.r * 1.5, col.g * 1.5, col.b * 1.5, 1.0))
	var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	var sc := Curve.new(); sc.add_point(Vector2(0, 0.6)); sc.add_point(Vector2(0.2, 1.0)); sc.add_point(Vector2(1, 0.2))
	var st := CurveTexture.new(); st.curve = sc; pm.scale_curve = st
	p.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(1, 1)
	q.material = _add_mat(tex if tex else spark) if additive else _mix_mat(tex if tex else smoke)
	p.draw_pass_1 = q
	(parent if parent else self).add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(life + 0.6).timeout.connect(p.queue_free)
	return p

## a continuous emitter that follows its parent (trails, auras, hand glows)
func emitter(parent: Node3D, col: Color, rate := 30, size := 0.18, life := 0.6, speed := 0.4, gravity := 0.0,
		tex: Texture2D = null, radius := 0.08, local := false, additive := true) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = maxi(4, int(rate * life)); p.lifetime = life; p.local_coords = local
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP; pm.spread = 180.0
	pm.initial_velocity_min = speed * 0.3; pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, gravity, 0)
	pm.scale_min = size * 0.6; pm.scale_max = size * 1.2
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = radius
	var g := Gradient.new()
	g.set_color(0, Color(col.r * 1.4, col.g * 1.4, col.b * 1.4, 0.0)); g.set_color(1, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.0))
	g.add_point(0.15, Color(col.r * 1.4, col.g * 1.4, col.b * 1.4, 1.0))
	var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	var sc := Curve.new(); sc.add_point(Vector2(0, 1.0)); sc.add_point(Vector2(1, 0.1))
	var st := CurveTexture.new(); st.curve = sc; pm.scale_curve = st
	p.process_material = pm
	var q := QuadMesh.new(); q.material = _add_mat(tex if tex else glow) if additive else _mix_mat(tex if tex else smoke); p.draw_pass_1 = q
	parent.add_child(p)
	p.emitting = true
	return p

## slow golden twinkles: something here can be looted or picked up
func twinkle(parent: Node3D, col: Color, radius := 0.5) -> Node3D:
	var n := Node3D.new(); parent.add_child(n)
	var e := emitter(n, col, 10, 0.16, 1.1, 0.35, 0.3, spark, radius, false)
	e.process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	e.process_material.emission_box_extents = Vector3(radius, 0.25, radius)
	var l := OmniLight3D.new(); l.light_color = col; l.light_energy = 0.7; l.omni_range = 2.5; l.shadow_enabled = false
	n.add_child(l); l.position.y = 0.3
	return n

func light(pos: Vector3, col: Color, energy := 3.0, rng := 6.0, dur := 0.4, parent: Node3D = null) -> OmniLight3D:
	var l := OmniLight3D.new(); l.light_color = col; l.light_energy = energy; l.omni_range = rng; l.shadow_enabled = false
	(parent if parent else self).add_child(l)
	if parent == null: l.global_position = pos
	if dur > 0.0:
		var tw := l.create_tween(); tw.tween_property(l, "light_energy", 0.0, dur).set_ease(Tween.EASE_OUT)
		tw.tween_callback(l.queue_free)
	return l

## a flat glowing ring on the ground that grows and fades (shockwaves, novas)
func ground_ring(pos: Vector3, col: Color, r0: float, r1: float, dur := 0.5, tex: Texture2D = null, spin := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new(); q.size = Vector2(2, 2); q.orientation = PlaneMesh.FACE_Y
	var m := _add_mat(tex if tex else ring_tex, false).duplicate()
	m.albedo_color = Color(col.r * 2.0, col.g * 2.0, col.b * 2.0, 1.0)
	m.vertex_color_use_as_albedo = false
	q.material = m; mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = pos + Vector3(0, 0.08, 0)
	mi.scale = Vector3.ONE * maxf(r0, 0.01)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * r1, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, dur).set_ease(Tween.EASE_IN)
	if spin != 0.0: tw.tween_property(mi, "rotation:y", spin, dur)
	tw.chain().tween_callback(mi.queue_free)
	return mi

func energy_mat(col: Color, core := Color(1, 1, 1), intensity := 2.0, rim := 0.0, flow := 1.2, v_fade := 0.0, ns := 3.0) -> ShaderMaterial:
	var m := ShaderMaterial.new(); m.shader = energy_shader
	m.set_shader_parameter("color", col); m.set_shader_parameter("core", core)
	m.set_shader_parameter("intensity", intensity); m.set_shader_parameter("rim", rim)
	m.set_shader_parameter("flow", flow); m.set_shader_parameter("v_fade", v_fade)
	m.set_shader_parameter("noise_scale", ns); m.set_shader_parameter("noise_tex", noise)
	return m

## a glowing column (fire pillar, beam of light)
func column(pos: Vector3, col: Color, core: Color, radius: float, height: float, dur: float, grow := 0.12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new(); cm.top_radius = radius * 0.7; cm.bottom_radius = radius; cm.height = height; cm.cap_top = false; cm.cap_bottom = false
	cm.radial_segments = 24; cm.rings = 1
	var m := energy_mat(col, core, 1.3, 0.6, 2.4, 1.0, 2.5)
	cm.material = m; mi.mesh = cm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = pos + Vector3(0, height / 2.0, 0)
	mi.scale = Vector3(0.2, 1, 0.2)
	m.set_shader_parameter("alpha", 0.0)
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE, grow).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v): m.set_shader_parameter("alpha", v), 0.0, 1.0, grow)
	tw.chain().tween_interval(maxf(0.0, dur - grow - 0.35))
	tw.chain().tween_method(func(v): m.set_shader_parameter("alpha", v), 1.0, 0.0, 0.35)
	tw.parallel().tween_property(mi, "scale", Vector3(1.4, 1.0, 1.4), 0.35)
	tw.chain().tween_callback(mi.queue_free)
	return mi

## a crescent swoosh in front of the attacker (weapon trails)
func slash(src: Node3D, col: Color, size := 1.3, dur := 0.28, tilt := -25.0, flip := false) -> void:
	var mi := MeshInstance3D.new()
	var am := ArrayMesh.new(); var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 20
	var verts := []
	for i in seg + 1:
		var t := float(i) / seg
		var ang := lerpf(-1.2, 1.3, t)
		var w := sin(t * PI) * 0.35 + 0.05
		var o := Vector3(sin(ang), 0, cos(ang)) * size
		var inn := Vector3(sin(ang), 0, cos(ang)) * (size - w)
		verts.append([o, inn, t])
	for i in seg:
		var a = verts[i]; var b = verts[i + 1]
		var ca := Color(col.r * 2.5, col.g * 2.5, col.b * 2.5, pow(a[2], 1.6))
		var cb := Color(col.r * 2.5, col.g * 2.5, col.b * 2.5, pow(b[2], 1.6))
		st.set_color(ca); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(a[0])
		st.set_color(cb); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(b[0])
		st.set_color(Color(ca, 0.0)); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(a[1])
		st.set_color(cb); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(b[0])
		st.set_color(Color(cb, 0.0)); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(b[1])
		st.set_color(Color(ca, 0.0)); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(a[1])
	st.commit(am)
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.vertex_color_use_as_albedo = true; m.cull_mode = BaseMaterial3D.CULL_DISABLED
	am.surface_set_material(0, m)
	mi.mesh = am; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var yaw: float = src.yaw if "yaw" in src else src.global_rotation.y
	mi.global_position = src.global_position + Vector3(0, 1.1, 0)
	mi.rotation = Vector3(deg_to_rad(tilt), yaw, deg_to_rad(180.0 if flip else 0.0))
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "rotation:y", yaw + (-0.9 if flip else 0.9), dur).from(yaw - 0.4 * (-1.0 if flip else 1.0))
	tw.tween_property(m, "albedo_color:a", 0.0, dur).from(1.0).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)

func shake(amount: float, near: Vector3) -> void:
	var hero := get_tree().get_first_node_in_group("player")
	if hero and hero.global_position.distance_to(near) < 25.0:
		get_tree().call_group("camera", "shake", amount)

func _chest(u: Node3D) -> Vector3:
	return u.global_position + Vector3(0, 1.15 * (u.model.scale.y if "model" in u and u.model else 1.0), 0)

func _hand(u: Node3D) -> Vector3:
	if "model" in u and u.model and u.model.skeleton:
		var sk: Skeleton3D = u.model.skeleton
		var b := sk.find_bone("hand_r")
		if b >= 0: return sk.global_transform * sk.get_bone_global_pose(b).origin
	return _chest(u) + Vector3(0, 0.1, 0)

func _attach_to_bone(u: Node3D, bone: String) -> Node3D:
	if not ("model" in u) or u.model == null or u.model.skeleton == null: return u
	var ba := BoneAttachment3D.new(); ba.bone_name = bone; u.model.skeleton.add_child(ba)
	return ba

# ------------------------------------------------------------------ casting visuals

func cast_start(u: Node3D, id: String) -> void:
	cast_stop(u)
	var a: Dictionary = Abilities.LIST[id]
	var col: Color = SCHOOL.get(a.get("school", "arcane"), Color.WHITE)
	var nodes := []
	for bone in ["hand_r", "hand_l"]:
		var ba := _attach_to_bone(u, bone); nodes.append(ba)
		if ba != u:
			emitter(ba, col, 40, 0.16, 0.5, 0.3, 0.8, glow, 0.08)
			var l := OmniLight3D.new(); l.light_color = col; l.light_energy = 1.2; l.omni_range = 3.5; ba.add_child(l)
	# the rune circle at the caster's feet
	var mi := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(2.6, 2.6); q.orientation = PlaneMesh.FACE_Y
	var m := _add_mat(rune, false).duplicate(); m.albedo_color = Color(col.r * 1.8, col.g * 1.8, col.b * 1.8, 0.0); m.vertex_color_use_as_albedo = false
	q.material = m; mi.mesh = q; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	u.add_child(mi); mi.position = Vector3(0, 0.07, 0)
	mi.create_tween().tween_property(m, "albedo_color:a", 0.9, 0.25)
	mi.set_meta("spin", 1.2)
	nodes.append(mi)
	var hum := sound("cast_loop", u, -12.0, 0.0)
	if hum: hum.finished.disconnect(hum.queue_free); hum.finished.connect(hum.play); nodes.append(hum)
	casting[u] = nodes

func cast_stop(u: Node3D) -> void:
	if not casting.has(u): return
	for n in casting[u]:
		if is_instance_valid(n) and n != u: n.queue_free()
	casting.erase(u)

func _process(delta: float) -> void:
	for u in casting.keys():
		if not is_instance_valid(u) or u.casting.is_empty(): cast_stop(u); continue
		for n in casting[u]:
			if is_instance_valid(n) and n.has_meta("spin"): n.rotate_y(delta * float(n.get_meta("spin")))

# ------------------------------------------------------------------ projectiles

func projectile(src: Node3D, t: Node3D, id: String, on_hit: Callable) -> void:
	var a: Dictionary = Abilities.LIST[id]
	var col: Color = SCHOOL.get(a.get("school", "arcane"), Color.WHITE)
	var p := Node3D.new(); add_child(p)
	p.global_position = _hand(src) + Vector3(0, 0.2, 0)
	var size := 0.55
	match id:
		"fireball", "ember_bolt":
			var big := 1.0 if id == "fireball" else 0.6
			_head(p, Color(1.0, 0.5, 0.12), 1.5 * big, Color(1, 0.92, 0.65))
			emitter(p, Color(1.0, 0.42, 0.08), 140, 0.75 * big, 0.5, 0.8, 1.6, glow, 0.2 * big)
			emitter(p, Color(1.0, 0.75, 0.3), 60, 0.1, 0.5, 2.0, 0.5, spark, 0.25 * big)
			emitter(p, Color(0.2, 0.16, 0.14), 14, 0.6 * big, 0.9, 0.4, 1.0, smoke, 0.1, false, false)
			light(Vector3.ZERO, Color(1.0, 0.55, 0.2), 3.0, 7.0, 0.0, p)
		"frostbolt":
			_shard(p, Color(0.55, 0.8, 1.0))
			emitter(p, Color(0.4, 0.7, 1.0), 70, 0.35, 0.5, 0.3, -0.5, glow, 0.1)
			emitter(p, Color(0.8, 0.95, 1.0), 40, 0.08, 0.6, 1.0, -2.0, spark, 0.12)
			light(Vector3.ZERO, Color(0.5, 0.8, 1.0), 2.5, 6.0, 0.0, p)
		"arcane_missile":
			_head(p, Color(0.8, 0.45, 1.0), 0.45, Color(1, 0.85, 1.0))
			emitter(p, Color(0.75, 0.4, 1.0), 80, 0.25, 0.35, 0.2, 0.0, glow, 0.05)
			light(Vector3.ZERO, Color(0.8, 0.5, 1.0), 2.0, 5.0, 0.0, p)
			size = 0.3
		_:
			_head(p, col, 0.6, Color.WHITE)
			emitter(p, col, 60, 0.3, 0.4, 0.3, 0.0, glow, 0.08)
	sound({"fireball": "fire_launch", "ember_bolt": "fire_launch", "frostbolt": "frost_launch", "arcane_missile": "arcane"}.get(id, "arcane"), src, -4.0)
	var speed: float = float(a.get("speed", 20.0))
	var wobble := Vector3(randf_range(-1, 1), randf_range(0.2, 1.0), randf_range(-1, 1)) * (1.2 if id == "arcane_missile" else 0.0)
	var start := p.global_position
	var d0 := start.distance_to(_chest(t)) if is_instance_valid(t) else 10.0
	var fly := func(dt: float) -> bool:
		if not is_instance_valid(p): return false
		var goal := _chest(t) if is_instance_valid(t) else p.global_position
		var to := goal - p.global_position
		var step := speed * dt
		if to.length() <= step + 0.15:
			_impact(id, goal, col, t)
			on_hit.call()
			for c in p.get_children():
				if c is GPUParticles3D:
					c.emitting = false; c.reparent(self); get_tree().create_timer(1.2).timeout.connect(c.queue_free)
			p.queue_free()
			return false
		var k := 1.0 - clampf(to.length() / maxf(d0, 0.1), 0.0, 1.0)
		var bend := wobble * sin(k * PI) * 0.08
		p.global_position += to.normalized() * step + bend
		if to.length() > 0.2: p.look_at(goal, Vector3.UP)
		p.rotate_object_local(Vector3.FORWARD, dt * 8.0)
		return true
	_flights.append(fly)

var _flights: Array = []

func _physics_process(delta: float) -> void:
	for i in range(_flights.size() - 1, -1, -1):
		if not _flights[i].call(delta): _flights.remove_at(i)

func _head(p: Node3D, col: Color, size: float, core: Color) -> void:
	var s := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(size, size)
	var m := _add_mat(glow).duplicate(); m.vertex_color_use_as_albedo = false; m.albedo_color = Color(col.r * 1.8, col.g * 1.8, col.b * 1.8, 1.0)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = m; s.mesh = q; p.add_child(s)
	var s2 := MeshInstance3D.new(); var q2 := QuadMesh.new(); q2.size = Vector2(size * 0.45, size * 0.45)
	var m2 := m.duplicate(); m2.albedo_color = Color(core.r * 2.0, core.g * 2.0, core.b * 2.0, 1.0); q2.material = m2; s2.mesh = q2; p.add_child(s2)

func _shard(p: Node3D, col: Color) -> void:
	var mi := MeshInstance3D.new(); var pm := PrismMesh.new(); pm.size = Vector3(0.18, 0.7, 0.18)
	var m := StandardMaterial3D.new(); m.albedo_color = Color(col, 0.75); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true; m.emission = col; m.emission_energy_multiplier = 2.5; m.roughness = 0.1; m.metallic = 0.3
	pm.material = m; mi.mesh = pm; mi.rotation_degrees = Vector3(-90, 0, 0); p.add_child(mi)
	_head(p, col, 0.5, Color.WHITE)

func _impact(id: String, pos: Vector3, col: Color, t: Node3D) -> void:
	sound({"fireball": "fire_impact", "ember_bolt": "fire_impact", "frostbolt": "ice_shatter"}.get(id, "hit_1"), pos, -3.0 if id == "fireball" else -6.0)
	match id:
		"fireball", "ember_bolt":
			burst(pos, Color(1.0, 0.5, 0.12), 46, 6.0, 0.55, 0.55, 1.5, glow, 180.0, Vector3.UP, true, 0.2)
			burst(pos, Color(1.0, 0.8, 0.3), 30, 9.0, 0.08, 0.5, -6.0, spark, 180.0)
			burst(pos, Color(0.22, 0.18, 0.16), 14, 1.5, 0.9, 1.3, 0.8, smoke, 180.0, Vector3.UP, false, 0.3)
			light(pos, Color(1.0, 0.55, 0.2), 6.0, 9.0, 0.45)
			shake(0.12, pos)
		"frostbolt":
			burst(pos, Color(0.6, 0.88, 1.0), 30, 5.0, 0.35, 0.5, 0.0, glow)
			burst(pos, Color(0.9, 0.97, 1.0), 26, 7.0, 0.1, 0.8, -9.0, spark, 180.0)
			light(pos, Color(0.5, 0.8, 1.0), 4.0, 7.0, 0.4)
		_:
			burst(pos, col, 30, 5.0, 0.3, 0.45, 0.0, glow)
			burst(pos, col.lightened(0.4), 16, 7.0, 0.08, 0.4, 0.0, spark)
			light(pos, col, 3.0, 5.0, 0.3)

# ------------------------------------------------------------------ ability effects

const ABILITY_SOUND := {"heroic_strike": "swing_2", "rend": "swing_1", "execute": "crit", "hamstring": "swing_0", "thunder_clap": "thunder_clap",
	"charge": "charge", "charge_hit": "hit_2", "battle_shout": "shout", "fire_blast": "fire_impact", "frost_nova": "frost_nova",
	"flamestrike": "flamestrike", "smite": "holy_smite", "mend": "heal", "renewal": "heal", "ward_of_light": "shield", "shadow_rot": "shadow",
	"holy_nova": "holy_nova", "inner_fire": "shield", "frost_armor": "frost_launch", "blink": "blink", "taunt": "shout"}

func play(id: String, src: Node3D, t: Node3D, pos: Vector3) -> void:
	var tp := _chest(t) if t and is_instance_valid(t) else pos
	if ABILITY_SOUND.has(id):
		var where = t if (t and is_instance_valid(t) and id in ["smite", "mend", "renewal", "shadow_rot", "fire_blast", "charge_hit", "ward_of_light"]) else src
		if id == "flamestrike": where = pos
		sound(ABILITY_SOUND[id], where, -8.0 if id == "renewal" else -3.0)
		if id in ["heroic_strike", "hamstring", "rend"]: _delay(0.15, func(): if is_instance_valid(t): sound("hit_%d" % (randi() % 3), t, -3.0))
	match id:
		"heroic_strike":
			slash(src, Color(1.0, 0.75, 0.3), 1.4, 0.3)
			_delay(0.18, func(): burst(tp, Color(1.0, 0.8, 0.4), 22, 6.0, 0.1, 0.4, -4.0, spark); light(tp, Color(1, 0.8, 0.4), 2.5, 4.0, 0.25))
		"rend":
			slash(src, Color(1.0, 0.25, 0.2), 1.3, 0.28, 15.0, true)
			_delay(0.15, func(): burst(tp, Color(0.8, 0.08, 0.05), 20, 3.0, 0.09, 0.8, -9.0, spark, 70.0, Vector3.UP, false))
		"execute":
			slash(src, Color(1.0, 0.3, 0.1), 1.8, 0.35, -60.0)
			_delay(0.2, func():
				burst(tp, Color(1.0, 0.35, 0.1), 40, 9.0, 0.14, 0.6, -6.0, spark)
				burst(tp, Color(1.0, 0.4, 0.15), 16, 3.0, 0.7, 0.35, 0.0, glow)
				light(tp, Color(1.0, 0.4, 0.2), 5.0, 6.0, 0.35); shake(0.25, tp))
		"hamstring":
			slash(src, Color(0.9, 0.6, 0.4), 1.1, 0.25, 40.0)
		"thunderclap":
			pass
		"thunder_clap":
			var g := src.global_position
			_delay(0.25, func():
				ground_ring(g, Color(0.6, 0.75, 1.0), 0.5, 9.0, 0.55)
				ground_ring(g, Color(1.0, 0.95, 0.8), 0.2, 5.0, 0.35)
				burst(g + Vector3(0, 0.2, 0), Color(0.55, 0.5, 0.45), 40, 7.0, 0.8, 0.9, 1.0, smoke, 90.0, Vector3(0, 0.2, 0), false, 1.0)
				burst(g + Vector3(0, 0.4, 0), Color(0.7, 0.85, 1.0), 40, 10.0, 0.1, 0.5, -4.0, spark, 100.0, Vector3.UP, true, 0.5)
				light(g + Vector3(0, 1, 0), Color(0.7, 0.8, 1.0), 6.0, 12.0, 0.4); shake(0.35, g))
		"charge":
			var e := emitter(src, Color(0.55, 0.48, 0.4), 60, 0.7, 0.8, 0.6, 0.6, smoke, 0.4, false, false)
			e.position = Vector3(0, 0.2, 0)
			_delay(0.8, func():
				if is_instance_valid(e):
					e.emitting = false; get_tree().create_timer(1.0).timeout.connect(e.queue_free))
		"charge_hit":
			burst(tp, Color(1.0, 0.85, 0.5), 30, 7.0, 0.1, 0.5, -3.0, spark)
			burst(t.global_position + Vector3(0, 0.2, 0), Color(0.55, 0.5, 0.45), 20, 3.0, 0.7, 0.8, 0.5, smoke, 90.0, Vector3.UP, false, 0.5)
			shake(0.2, tp)
			_stars(t)
		"battle_shout":
			ground_ring(src.global_position, Color(1.0, 0.75, 0.3), 0.5, 7.0, 0.6)
			burst(_chest(src), Color(1.0, 0.8, 0.35), 30, 4.0, 0.12, 1.0, 1.5, spark, 60.0)
		"taunt":
			if t: burst(_chest(t) + Vector3(0, 1.0, 0), Color(1.0, 0.25, 0.2), 16, 2.0, 0.4, 0.6, 0.0, glow)
		"fire_blast":
			burst(tp, Color(1.0, 0.5, 0.1), 50, 7.0, 0.5, 0.5, 1.0, glow, 180.0, Vector3.UP, true, 0.3)
			burst(tp, Color(1.0, 0.85, 0.4), 30, 10.0, 0.08, 0.5, -5.0, spark)
			burst(tp, Color(0.25, 0.2, 0.18), 10, 1.5, 0.8, 1.2, 0.8, smoke, 180.0, Vector3.UP, false, 0.3)
			light(tp, Color(1.0, 0.5, 0.2), 6.0, 8.0, 0.4); shake(0.12, tp)
		"frost_nova":
			var g2 := src.global_position
			ground_ring(g2, Color(0.55, 0.85, 1.0), 0.5, 9.0, 0.7)
			ground_ring(g2, Color(0.85, 0.95, 1.0), 0.3, 6.0, 0.45)
			_ice_spikes(g2, 8.0)
			burst(g2 + Vector3(0, 0.3, 0), Color(0.75, 0.92, 1.0), 70, 13.0, 0.1, 0.8, -3.0, spark, 88.0, Vector3.UP, true, 0.6)
			burst(g2 + Vector3(0, 0.2, 0), Color(0.55, 0.8, 1.0), 40, 10.0, 1.0, 0.9, 0.3, smoke, 88.0, Vector3.UP, true, 0.8)
			light(g2 + Vector3(0, 1, 0), Color(0.5, 0.8, 1.0), 6.0, 12.0, 0.6)
		"flamestrike":
			var at := pos if pos != Vector3.INF else tp
			at.y = WorldData.h(at.x, at.z)
			column(at, Color(1.0, 0.3, 0.04), Color(1.0, 0.8, 0.35), 1.7, 6.5, 0.9)
			column(at, Color(1.0, 0.55, 0.1), Color(1.0, 0.95, 0.7), 0.7, 8.0, 0.7)
			_delay(0.08, func():
				ground_ring(at, Color(1.0, 0.4, 0.08), 0.5, 5.5, 0.8)
				burst(at + Vector3(0, 0.3, 0), Color(1.0, 0.42, 0.08), 90, 8.0, 0.9, 1.1, 5.0, glow, 25.0, Vector3.UP, true, 2.2)
				burst(at + Vector3(0, 0.3, 0), Color(1.0, 0.7, 0.25), 50, 11.0, 0.1, 1.4, -2.0, spark, 40.0, Vector3.UP, true, 1.8)
				burst(at + Vector3(0, 1.5, 0), Color(0.18, 0.14, 0.12), 22, 2.5, 1.6, 2.2, 1.5, smoke, 50.0, Vector3.UP, false, 1.5)
				light(at + Vector3(0, 2, 0), Color(1.0, 0.45, 0.15), 8.0, 16.0, 0.9); shake(0.35, at))
			_ground_fire(at, 4.5, 3.0)
		"smite":
			if t:
				var base := t.global_position
				column(base, Color(1.0, 0.85, 0.4), Color(1, 1, 0.9), 0.55, 14.0, 0.55, 0.06)
				_delay(0.06, func():
					burst(_chest(t), Color(1.0, 0.9, 0.5), 40, 6.0, 0.35, 0.5, 0.0, glow)
					burst(_chest(t), Color(1.0, 1.0, 0.8), 26, 9.0, 0.08, 0.5, -3.0, spark)
					ground_ring(base, Color(1.0, 0.85, 0.4), 0.3, 2.5, 0.4)
					light(_chest(t), Color(1.0, 0.9, 0.6), 6.0, 8.0, 0.4))
		"mend":
			if t:
				_spiral(t, Color(1.0, 0.85, 0.4), 1.0)
				ground_ring(t.global_position, Color(1.0, 0.85, 0.4), 0.3, 2.0, 0.6)
				light(_chest(t), Color(1.0, 0.85, 0.5), 3.5, 6.0, 0.8)
		"renewal":
			if t: burst(_chest(t), Color(0.6, 1.0, 0.5), 24, 2.0, 0.25, 0.9, 1.0, glow)
		"ward_of_light":
			pass
		"shadow_rot":
			if t:
				burst(_chest(t), Color(0.5, 0.2, 0.9), 26, 2.5, 0.7, 0.8, 0.5, smoke, 180.0, Vector3.UP, true, 0.3)
				burst(_chest(t), Color(0.7, 0.4, 1.0), 20, 5.0, 0.08, 0.6, 0.0, spark)
		"holy_nova":
			var g3 := src.global_position
			ground_ring(g3, Color(1.0, 0.9, 0.5), 0.5, 11.0, 0.6)
			burst(_chest(src), Color(1.0, 0.9, 0.55), 70, 12.0, 0.25, 0.6, 0.0, glow, 180.0)
			burst(_chest(src), Color(1.0, 1.0, 0.85), 40, 14.0, 0.08, 0.6, 0.0, spark, 180.0)
			light(_chest(src), Color(1.0, 0.9, 0.6), 8.0, 14.0, 0.5)
		"inner_fire", "frost_armor":
			var c: Color = Color(1.0, 0.6, 0.2) if id == "inner_fire" else Color(0.6, 0.88, 1.0)
			_spiral(src, c, 0.8)
		"blink":
			burst(_chest(src), Color(0.8, 0.5, 1.0), 40, 4.0, 0.3, 0.5, 0.0, glow)
			burst(_chest(src), Color(0.9, 0.8, 1.0), 30, 8.0, 0.08, 0.5, 0.0, spark)
			light(_chest(src), Color(0.8, 0.5, 1.0), 4.0, 6.0, 0.3)
		"slash_red":
			slash(src, Color(1.0, 0.3, 0.2), 1.2, 0.25)

## a ring of ice crystals bursting out of the ground and shattering (Frost Nova)
func _ice_spikes(at: Vector3, radius: float) -> void:
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.72, 0.9, 1.0, 0.8); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05; m.metallic = 0.1; m.emission_enabled = true; m.emission = Color(0.35, 0.65, 1.0); m.emission_energy_multiplier = 0.9
	m.rim_enabled = true; m.rim = 1.0
	var holder := Node3D.new(); add_child(holder); holder.global_position = at
	var n := 26
	for k in n:
		var ang := TAU * k / n + randf() * 0.2
		var r := randf_range(1.2, radius)
		var mi := MeshInstance3D.new(); var pm := PrismMesh.new()
		var h := randf_range(0.6, 1.5) * (1.3 - r / radius * 0.6)
		pm.size = Vector3(0.35, h, 0.35); pm.material = m; mi.mesh = pm
		holder.add_child(mi)
		var p := Vector3(cos(ang) * r, 0, sin(ang) * r)
		mi.position = p + Vector3(0, WorldData.h(at.x + p.x, at.z + p.z) - at.y - h, 0)
		mi.rotation = Vector3(randf_range(-0.5, 0.5), randf() * TAU, randf_range(-0.5, 0.5))
		var delay := r / radius * 0.18
		var tw := mi.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(mi, "position:y", mi.position.y + h * 0.95, 0.08).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.9 + randf() * 0.3)
		tw.tween_property(mi, "scale", Vector3(1.3, 0.05, 1.3), 0.15)
	_delay(1.3, func():
		burst(at + Vector3(0, 0.4, 0), Color(0.85, 0.96, 1.0), 60, 5.0, 0.09, 0.8, -9.0, spark, 90.0, Vector3.UP, true, radius * 0.7)
		sound("ice_shatter", at, -8.0))
	get_tree().create_timer(1.8).timeout.connect(holder.queue_free)

func _delay(t: float, f: Callable) -> void:
	get_tree().create_timer(t).timeout.connect(f)

## rising sparkles spiralling around someone (heals, blessings)
func _spiral(u: Node3D, col: Color, dur: float) -> void:
	var holder := Node3D.new(); u.add_child(holder)
	for k in 3:
		var arm := Node3D.new(); holder.add_child(arm)
		var e := emitter(arm, col, 60, 0.22, 0.7, 0.1, 0.6, glow, 0.02)
		arm.set_meta("k", k)
	var tw := holder.create_tween()
	tw.tween_method(func(v: float):
		for arm in holder.get_children():
			var k: int = arm.get_meta("k")
			var ang := v * TAU * 2.0 + TAU * k / 3.0
			arm.position = Vector3(cos(ang) * 0.7, 0.1 + v * 2.2, sin(ang) * 0.7), 0.0, 1.0, dur)
	tw.tween_callback(func():
		for c in holder.find_children("*", "GPUParticles3D", true, false):
			c.emitting = false)
	tw.tween_interval(0.8)
	tw.tween_callback(holder.queue_free)

## little stars circling a stunned head
func _stars(u: Node3D) -> void:
	var holder := Node3D.new(); u.add_child(holder); holder.position = Vector3(0, 2.0, 0)
	for k in 3:
		var s := Node3D.new(); holder.add_child(s); s.position = Vector3(cos(TAU * k / 3.0) * 0.35, 0, sin(TAU * k / 3.0) * 0.35)
		_head(s, Color(1.0, 0.9, 0.4), 0.22, Color.WHITE)
	var tw := holder.create_tween(); tw.tween_property(holder, "rotation:y", TAU * 2.0, 1.3); tw.tween_callback(holder.queue_free)

func _ground_fire(at: Vector3, radius: float, dur: float) -> void:
	var holder := Node3D.new(); add_child(holder); holder.global_position = at
	var e := emitter(holder, Color(1.0, 0.45, 0.1), 60, 0.6, 0.8, 0.8, 1.6, glow, radius * 0.8)
	var pm: ParticleProcessMaterial = e.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING; pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = radius * 0.8; pm.emission_ring_inner_radius = 0.0; pm.emission_ring_height = 0.1
	var l := light(Vector3.ZERO, Color(1.0, 0.5, 0.2), 3.0, radius * 2.5, 0.0, holder); l.position.y = 1.0
	_delay(dur, func():
		e.emitting = false
		var tw := l.create_tween(); tw.tween_property(l, "light_energy", 0.0, 0.8)
		get_tree().create_timer(1.5).timeout.connect(holder.queue_free))

## a danger zone on the ground: a red circle that fills in until it goes off (step out!)
func telegraph(at: Vector3, radius: float, dur: float, school: String) -> void:
	at.y = WorldData.h(at.x, at.z)
	var col: Color = Color(1.0, 0.2, 0.1) if school == "fire" else Color(0.3, 0.6, 1.0)
	var holder := Node3D.new(); add_child(holder); holder.global_position = at + Vector3(0, 0.1, 0)
	var edge := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(2, 2); q.orientation = PlaneMesh.FACE_Y
	var m := _add_mat(ring_tex, false).duplicate(); m.vertex_color_use_as_albedo = false; m.albedo_color = Color(col.r * 1.5, col.g * 1.5, col.b * 1.5, 0.9)
	q.material = m; edge.mesh = q; edge.scale = Vector3.ONE * radius; holder.add_child(edge)
	var fill := MeshInstance3D.new(); var q2 := QuadMesh.new(); q2.size = Vector2(2, 2); q2.orientation = PlaneMesh.FACE_Y
	var m2 := _add_mat(glow, false).duplicate(); m2.vertex_color_use_as_albedo = false; m2.albedo_color = Color(col.r, col.g, col.b, 0.55)
	q2.material = m2; fill.mesh = q2; fill.scale = Vector3.ONE * 0.05; holder.add_child(fill)
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tw := holder.create_tween()
	tw.tween_property(fill, "scale", Vector3.ONE * radius * 1.25, dur)
	tw.tween_callback(func():
		if school == "fire":
			burst(at + Vector3(0, 0.3, 0), Color(1.0, 0.4, 0.08), 80, 9.0, 0.7, 0.9, 2.0, glow, 70.0, Vector3.UP, true, radius * 0.7)
			sound("fire_impact", at, 0.0)
		else:
			burst(at + Vector3(0, 0.3, 0), Color(0.5, 0.8, 1.0), 80, 9.0, 0.6, 0.9, -3.0, glow, 70.0, Vector3.UP, true, radius * 0.7)
			sound("ice_shatter", at, 0.0)
		ground_ring(at, col, radius * 0.4, radius * 1.3, 0.5)
		light(at + Vector3(0, 1.5, 0), col, 8.0, radius * 3.0, 0.5); shake(0.4, at))
	tw.tween_callback(holder.queue_free)

# ------------------------------------------------------------------ lingering effects (auras)

func aura_added(u: Node3D, id: String) -> void:
	var key := "%d:%s" % [u.get_instance_id(), id]
	if lingering.has(key) and is_instance_valid(lingering[key]): return
	var n: Node3D = null
	match id:
		"fireball_burn", "flamestrike_burn":
			n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 0.9, 0)
			emitter(n, Color(1.0, 0.45, 0.1), 30, 0.35, 0.6, 0.5, 1.5, glow, 0.35)
		"frostbolt_slow":
			n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 0.3, 0)
			emitter(n, Color(0.6, 0.88, 1.0), 20, 0.3, 1.0, 0.2, 0.2, glow, 0.35)
		"frost_nova":
			n = _ice_block(u)
		"renewal":
			n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 1.0, 0)
			emitter(n, Color(0.55, 1.0, 0.45), 12, 0.2, 1.4, 0.3, 0.6, glow, 0.5)
		"ward_of_light":
			n = MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 1.05; sm.height = 2.3
			sm.material = energy_mat(Color(1.0, 0.85, 0.45), Color(1, 1, 0.9), 1.6, 2.5, 0.4, 0.0, 4.0)
			(n as MeshInstance3D).mesh = sm; (n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			u.add_child(n); n.position = Vector3(0, 1.0, 0)
			n.scale = Vector3.ONE * 0.2; n.create_tween().tween_property(n, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"shadow_rot":
			n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 1.0, 0)
			emitter(n, Color(0.45, 0.18, 0.8), 18, 0.5, 1.0, 0.3, 0.4, smoke, 0.35)
		"rend":
			n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 1.0, 0)
			emitter(n, Color(0.65, 0.05, 0.04), 8, 0.08, 0.7, 0.3, -6.0, spark, 0.25, false, false)
		"inner_fire":
			n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 0.8, 0)
			emitter(n, Color(1.0, 0.6, 0.2), 8, 0.14, 1.2, 0.2, 0.8, glow, 0.45)
		"frost_armor":
			n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 0.8, 0)
			emitter(n, Color(0.65, 0.9, 1.0), 8, 0.12, 1.2, 0.2, -0.3, glow, 0.45)
	if n: lingering[key] = n

func aura_removed(u: Node3D, id: String) -> void:
	var key := "%d:%s" % [u.get_instance_id(), id]
	if not lingering.has(key): return
	var n: Node3D = lingering[key]; lingering.erase(key)
	if not is_instance_valid(n): return
	if id == "frost_nova":
		burst(n.global_position + Vector3(0, 0.6, 0), Color(0.8, 0.95, 1.0), 24, 4.0, 0.12, 0.7, -8.0, spark)
	for c in n.find_children("*", "GPUParticles3D", true, false): c.emitting = false
	var tw := n.create_tween(); tw.tween_property(n, "scale", Vector3.ONE * 0.01, 0.3); tw.tween_interval(0.8); tw.tween_callback(n.queue_free)

func _ice_block(u: Node3D) -> Node3D:
	var n := Node3D.new(); u.add_child(n)
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.7, 0.9, 1.0, 0.55); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05; m.metallic = 0.2; m.emission_enabled = true; m.emission = Color(0.4, 0.7, 1.0); m.emission_energy_multiplier = 0.6
	m.rim_enabled = true; m.rim = 1.0
	for k in 7:
		var mi := MeshInstance3D.new(); var pm := PrismMesh.new(); pm.size = Vector3(0.28, randf_range(0.5, 0.95), 0.28); pm.material = m
		mi.mesh = pm; n.add_child(mi)
		var ang := TAU * k / 7.0 + randf() * 0.4
		mi.position = Vector3(cos(ang) * 0.42, pm.size.y * 0.4, sin(ang) * 0.42)
		mi.rotation = Vector3(randf_range(-0.35, 0.35), randf() * TAU, randf_range(-0.35, 0.35))
	n.scale = Vector3(1, 0.05, 1)
	n.create_tween().tween_property(n, "scale", Vector3.ONE, 0.18).set_ease(Tween.EASE_OUT)
	return n

# ------------------------------------------------------------------ level up

func level_up(u: Node3D) -> void:
	sound("level_up", u, 0.0, 0.0)
	column(u.global_position, Color(1.0, 0.8, 0.35), Color(1, 1, 0.85), 1.3, 7.0, 1.6, 0.25)
	ground_ring(u.global_position, Color(1.0, 0.85, 0.4), 0.5, 5.0, 1.0)
	burst(u.global_position + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.45), 80, 5.0, 0.1, 1.8, 2.0, spark, 30.0, Vector3.UP, true, 0.8)
	light(u.global_position + Vector3(0, 2, 0), Color(1.0, 0.85, 0.5), 6.0, 10.0, 1.5)
