class_name Fx extends Node3D
## Spell and combat effects, built in layers from painted textures (art/vfx_textures.py):
## animated flipbooks of fire, smoke, explosions, frost mist and shadow wisps; flares, spark streaks
## that stretch along their flight, embers, ice shards, light rays and shock rings; weapon swipes
## with a painted edge; and decals left on the ground (scorch marks, frost, holy glyphs, cracks).
## Every effect is several of these together: a core and a glow, trailing particles, a flash of
## light on the world, and something left behind.
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
static var _tex := {}
var energy_shader: Shader
var mats := {}
var casting := {}          # unit -> [nodes]
var lingering := {}        # "unit_id:aura" -> node
var cam: Camera3D
var shake_amt := 0.0

## a painted effect texture from assets/fx
static func T(name: String) -> Texture2D:
	if not _tex.has(name):
		var p := "res://assets/fx/%s.png" % name
		_tex[name] = load(p) if ResourceLoader.exists(p) else null
	return _tex[name]

func _ready() -> void:
	add_to_group("fx")
	energy_shader = load("res://shaders/energy.gdshader")
	if glow == null: _make_textures()

# ------------------------------------------------------------------ textures

func _make_textures() -> void:
	glow = T("glow") if T("glow") else _radial(64, func(d): return pow(clampf(1.0 - d, 0.0, 1.0), 2.2))
	spark = T("ember") if T("ember") else _radial(32, func(d): return pow(clampf(1.0 - d, 0.0, 1.0), 6.0))
	ring_tex = T("shock_ring") if T("shock_ring") else _radial(128, func(d): return pow(clampf(1.0 - absf(d - 0.8) / 0.2, 0.0, 1.0), 1.5))
	smoke = _radial(64, func(d): return clampf((1.0 - d) * 1.4, 0, 1) * 0.6)
	var nt := NoiseTexture2D.new(); nt.seamless = true; nt.width = 256; nt.height = 256
	var n2 := FastNoiseLite.new(); n2.frequency = 0.015; n2.fractal_octaves = 3; nt.noise = n2
	noise = nt
	rune = T("glyph_arcane")

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
	mats[key] = m
	return m

## a flipbook material (4 x 4 frames) for particles; plays once over each particle's life
func _flip_mat(tex: Texture2D, additive := true) -> StandardMaterial3D:
	var key := "flip%s%s" % [tex.get_rid(), additive]
	if mats.has(key): return mats[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES; m.billboard_keep_scale = true
	m.particles_anim_h_frames = 4; m.particles_anim_v_frames = 4; m.particles_anim_loop = false
	m.proximity_fade_enabled = true; m.proximity_fade_distance = 0.4
	mats[key] = m
	return m

func _streak_mat(tex: Texture2D) -> StandardMaterial3D:
	var key := "streak%s" % tex.get_rid()
	if mats.has(key): return mats[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.vertex_color_use_as_albedo = true; m.albedo_texture = tex
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED; m.cull_mode = BaseMaterial3D.CULL_DISABLED
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
				var at := _chest(t)
				if result == "crit":
					streaks(at, Color(1.0, 0.85, 0.5), 22, 7.0, 0.8, 0.35, -6.0)
					flash(at, Color(1.0, 0.8, 0.5), 1.4, 0.18)
				else:
					streaks(at, Color(1.0, 0.8, 0.55), 6, 4.0, 0.5, 0.25, -6.0))

func died(u: Node3D) -> void:
	sound("death", u, -4.0, 0.15)

# ------------------------------------------------------------------ building blocks

func _ramp(col: Color, k := 1.3, fade_in := 0.0) -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, Color(col.r * k, col.g * k, col.b * k, 0.0 if fade_in > 0.0 else col.a))
	g.set_color(1, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.0))
	g.add_point(maxf(fade_in, 0.12), Color(col.r * k * 1.1, col.g * k * 1.1, col.b * k * 1.1, col.a))
	var gt := GradientTexture1D.new(); gt.gradient = g
	return gt

func _curve(pts: Array) -> CurveTexture:
	var c := Curve.new()
	for p in pts: c.add_point(p)
	var t := CurveTexture.new(); t.curve = c
	return t

## a one-shot spray of sprites (the old all-purpose burst; flipbook textures play their frames)
func burst(pos: Vector3, col: Color, amount := 24, speed := 4.0, size := 0.25, life := 0.6, gravity := 0.0,
		tex: Texture2D = null, spread := 180.0, dir := Vector3.UP, additive := true, radius := 0.1, parent: Node3D = null) -> GPUParticles3D:
	if tex == smoke and not additive: return puffs(pos, "smoke_flip", col, amount, size * 1.3, life * 1.2, speed, gravity, spread, dir, false, radius, parent)
	if tex == glow and col.r > col.b * 2.0 and col.g > 0.3: return puffs(pos, "fire_flip", Color(1, 1, 1), amount, size * 1.4, life, speed, gravity, spread, dir, true, radius, parent)
	if tex == spark or tex == null: return streaks(pos, col, amount, speed, size * 6.0, life, gravity, spread, dir, radius, parent)
	var p := GPUParticles3D.new()
	p.amount = amount; p.lifetime = life; p.one_shot = true; p.explosiveness = 0.92
	var pm := ParticleProcessMaterial.new()
	pm.direction = dir; pm.spread = spread
	pm.initial_velocity_min = speed * 0.5; pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, gravity, 0)
	pm.damping_min = speed * 0.6; pm.damping_max = speed * 1.2
	pm.scale_min = size * 0.6; pm.scale_max = size * 1.3
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = radius
	pm.color_ramp = _ramp(col, 1.4)
	pm.scale_curve = _curve([Vector2(0, 0.6), Vector2(0.2, 1.0), Vector2(1, 0.2)])
	pm.angle_min = -180.0; pm.angle_max = 180.0
	p.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(1, 1)
	q.material = _add_mat(tex) if additive else _mix_mat(tex)
	p.draw_pass_1 = q
	return _launch(p, pos, parent, life)

func _launch(p: GPUParticles3D, pos: Vector3, parent: Node3D, life: float) -> GPUParticles3D:
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else self).add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(life + 1.0).timeout.connect(p.queue_free)
	return p

## a one-shot of animated flipbook sprites: fire, smoke, explosions, mist, wisps
func puffs(pos: Vector3, flip: String, col: Color, amount := 12, size := 1.0, life := 0.8, speed := 1.5, gravity := 1.0,
		spread := 180.0, dir := Vector3.UP, additive := true, radius := 0.2, parent: Node3D = null, grow := 1.6) -> GPUParticles3D:
	var t := T(flip)
	if t == null: return null
	var p := GPUParticles3D.new()
	p.amount = amount; p.lifetime = life; p.one_shot = true; p.explosiveness = 0.9; p.randomness = 0.3
	var pm := ParticleProcessMaterial.new()
	pm.direction = dir; pm.spread = spread
	pm.initial_velocity_min = speed * 0.4; pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, gravity, 0); pm.damping_min = speed * 0.5; pm.damping_max = speed
	pm.scale_min = size * 0.7; pm.scale_max = size * 1.2
	pm.scale_curve = _curve([Vector2(0, 0.55), Vector2(1, grow * 0.55)])
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = radius
	pm.angle_min = -180.0; pm.angle_max = 180.0
	pm.angular_velocity_min = -40.0; pm.angular_velocity_max = 40.0
	pm.anim_speed_min = 1.0; pm.anim_speed_max = 1.0
	pm.color_ramp = _ramp(col, 1.0 if not additive else 1.2, 0.05)
	p.process_material = pm
	var q := QuadMesh.new(); q.material = _flip_mat(t, additive); p.draw_pass_1 = q
	return _launch(p, pos, parent, life)

## sparks or shards flying out, each stretched along its path
func streaks(pos: Vector3, col: Color, amount := 20, speed := 6.0, length := 0.6, life := 0.5, gravity := -6.0,
		spread := 180.0, dir := Vector3.UP, radius := 0.1, parent: Node3D = null, tex_name := "spark", width := 0.08) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount; p.lifetime = life; p.one_shot = true; p.explosiveness = 0.95
	p.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY
	var pm := ParticleProcessMaterial.new()
	pm.direction = dir; pm.spread = spread
	pm.initial_velocity_min = speed * 0.45; pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, gravity, 0); pm.damping_min = speed * 0.3; pm.damping_max = speed * 0.8
	pm.scale_min = 0.6; pm.scale_max = 1.2
	pm.scale_curve = _curve([Vector2(0, 1.0), Vector2(0.7, 0.8), Vector2(1, 0.0)])
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = radius
	pm.color_ramp = _ramp(col, 2.2)
	p.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(width, length); q.material = _streak_mat(T(tex_name) if T(tex_name) else spark); p.draw_pass_1 = q
	return _launch(p, pos, parent, life)

## a continuous emitter that follows its parent (trails, auras, hand glows, camp fires)
func emitter(parent: Node3D, col: Color, rate := 30, size := 0.18, life := 0.6, speed := 0.4, gravity := 0.0,
		tex: Texture2D = null, radius := 0.08, local := false, additive := true) -> GPUParticles3D:
	var flip := ""
	if tex == smoke and not additive: flip = "smoke_flip"
	elif (tex == glow or tex == null) and additive and gravity > 0.5 and col.r > col.b * 2.0 and col.g > 0.25: flip = "fire_flip"
	var p := GPUParticles3D.new()
	p.amount = maxi(4, int(rate * life)); p.lifetime = life; p.local_coords = local
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP; pm.spread = 180.0 if flip == "" else 25.0
	pm.initial_velocity_min = speed * 0.3; pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, gravity, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = radius
	pm.angle_min = -180.0; pm.angle_max = 180.0
	var q := QuadMesh.new()
	if flip != "":
		# a real flame (or smoke column): animated flipbook sprites, fewer and larger
		p.amount = maxi(6, int(rate * life * 0.45))
		pm.scale_min = size * 1.6; pm.scale_max = size * 2.4
		pm.scale_curve = _curve([Vector2(0, 0.7), Vector2(1, 1.0 if flip == "fire_flip" else 1.8)])
		pm.anim_speed_min = 1.0; pm.anim_speed_max = 1.0
		pm.angular_velocity_min = -30.0; pm.angular_velocity_max = 30.0
		pm.color_ramp = _ramp(Color(1, 1, 1) if flip == "fire_flip" else col, 1.0, 0.05)
		q.material = _flip_mat(T(flip), flip == "fire_flip")
	else:
		pm.scale_min = size * 0.6; pm.scale_max = size * 1.2
		pm.scale_curve = _curve([Vector2(0, 1.0), Vector2(1, 0.1)])
		pm.color_ramp = _ramp(col, 1.4, 0.15)
		q.material = _add_mat(tex if tex else glow) if additive else _mix_mat(tex if tex else smoke)
	p.process_material = pm
	p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.emitting = true
	return p

## a continuous flipbook emitter (flames licking up from a body, mist rolling off, wisps)
func flip_emitter(parent: Node3D, flip: String, col: Color, rate := 10.0, size := 0.8, life := 0.8, speed := 0.8, gravity := 1.0,
		radius := 0.2, additive := true, local := false) -> GPUParticles3D:
	var t := T(flip)
	if t == null: return emitter(parent, col, int(rate), size * 0.4, life, speed, gravity, glow, radius, local, additive)
	var p := GPUParticles3D.new()
	p.amount = maxi(3, int(rate * life)); p.lifetime = life; p.local_coords = local
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP; pm.spread = 30.0
	pm.initial_velocity_min = speed * 0.4; pm.initial_velocity_max = speed
	pm.gravity = Vector3(0, gravity, 0)
	pm.scale_min = size * 0.7; pm.scale_max = size * 1.2
	pm.scale_curve = _curve([Vector2(0, 0.6), Vector2(1, 1.2)])
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = radius
	pm.angle_min = -180.0; pm.angle_max = 180.0; pm.angular_velocity_min = -30.0; pm.angular_velocity_max = 30.0
	pm.anim_speed_min = 1.0; pm.anim_speed_max = 1.0
	pm.color_ramp = _ramp(col, 1.0, 0.08)
	p.process_material = pm
	var q := QuadMesh.new(); q.material = _flip_mat(t, additive); p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p); p.emitting = true
	return p

## slow golden twinkles: something here can be looted or picked up
func twinkle(parent: Node3D, col: Color, radius := 0.5) -> Node3D:
	var n := Node3D.new(); parent.add_child(n)
	var e := emitter(n, col, 10, 0.2, 1.1, 0.35, 0.3, T("flare") if T("flare") else spark, radius, false)
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

## a bright star of light that blooms and fades (impacts, casts going off)
func flash(pos: Vector3, col: Color, size := 1.5, dur := 0.25, parent: Node3D = null, tex_name := "flare") -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(1, 1)
	var m := _add_mat(T(tex_name) if T(tex_name) else glow).duplicate()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; m.vertex_color_use_as_albedo = false
	m.albedo_color = Color(col.r * 2.2, col.g * 2.2, col.b * 2.2, 1.0)
	q.material = m; mi.mesh = q; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else self).add_child(mi)
	if parent == null: mi.global_position = pos
	else: mi.position = pos
	mi.scale = Vector3.ONE * size * 0.35
	mi.rotation.z = randf() * TAU
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * size, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)
	return mi

## a mark left on the ground (scorch, frost, cracks, a glyph), fading away after a while
func decal(pos: Vector3, tex_name: String, col: Color, size: float, dur := 3.0, emit_name := "", emit_col := Color.BLACK, energy := 2.0) -> Decal:
	var t := T(tex_name)
	if t == null: return null
	var d := Decal.new(); d.texture_albedo = t
	d.size = Vector3(size, 4.0, size); d.modulate = col
	d.upper_fade = 0.3; d.lower_fade = 0.3; d.cull_mask = 1
	if emit_name != "" and T(emit_name):
		d.texture_emission = T(emit_name); d.emission_energy = energy
	add_child(d)
	d.global_position = pos + Vector3(0, 0.5, 0)
	d.rotation.y = randf() * TAU
	var tw := d.create_tween()
	tw.tween_interval(dur * 0.6)
	tw.tween_property(d, "modulate:a", 0.0, dur * 0.4)
	tw.parallel().tween_property(d, "emission_energy", 0.0, dur * 0.3)
	tw.tween_callback(d.queue_free)
	return d

## a flat glowing picture on the ground (a magic circle, a shock ring) that grows, turns and fades
func ground_glyph(pos: Vector3, tex_name: String, col: Color, r0: float, r1: float, dur := 0.8, spin := 0.6, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new(); q.size = Vector2(2, 2); q.orientation = PlaneMesh.FACE_Y
	var m := _add_mat(T(tex_name) if T(tex_name) else ring_tex, false).duplicate()
	m.albedo_color = Color(col.r * 2.0, col.g * 2.0, col.b * 2.0, 0.0); m.vertex_color_use_as_albedo = false
	q.material = m; mi.mesh = q; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else self).add_child(mi)
	if parent == null: mi.global_position = pos + Vector3(0, 0.09, 0)
	else: mi.position = Vector3(0, 0.09, 0)
	mi.scale = Vector3.ONE * r0
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * r1, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 1.0, dur * 0.2)
	tw.chain().tween_property(m, "albedo_color:a", 0.0, dur * 0.8).set_ease(Tween.EASE_IN)
	if spin != 0.0: tw.parallel().tween_property(mi, "rotation:y", spin, dur)
	tw.chain().tween_callback(mi.queue_free)
	return mi

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

## an upright fan of light rays behind something (holy strikes, resurrection, level up)
func rays(pos: Vector3, col: Color, height := 4.0, dur := 0.8) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(height, height)
	var m := _add_mat(T("rays") if T("rays") else glow, false).duplicate()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y; m.vertex_color_use_as_albedo = false
	m.albedo_color = Color(col.r * 1.8, col.g * 1.8, col.b * 1.8, 0.0)
	q.material = m; mi.mesh = q; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi); mi.global_position = pos + Vector3(0, height * 0.45, 0)
	mi.scale = Vector3(0.6, 0.3, 1)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE, dur * 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 1.0, dur * 0.2)
	tw.chain().tween_property(m, "albedo_color:a", 0.0, dur * 0.7)
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

## a weapon swipe: a crescent band painted with a keen bright edge and streaky trail, swinging round
func slash(src: Node3D, col: Color, size := 1.3, dur := 0.28, tilt := -25.0, flip := false, at: Vector3 = Vector3.INF, width := 0.45) -> MeshInstance3D:
	if not is_instance_valid(src): return null
	var mi := MeshInstance3D.new()
	var am := ArrayMesh.new(); var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 28
	var verts := []
	for i in seg + 1:
		var t := float(i) / seg
		var ang := lerpf(-1.3, 1.4, t)
		var w := (sin(t * PI) * 0.8 + 0.2) * width
		verts.append([Vector3(sin(ang), 0, cos(ang)) * size, Vector3(sin(ang), 0, cos(ang)) * (size - w), t])
	for i in seg:
		var a = verts[i]; var b = verts[i + 1]
		st.set_uv(Vector2(a[2], 0)); st.add_vertex(a[0])
		st.set_uv(Vector2(b[2], 0)); st.add_vertex(b[0])
		st.set_uv(Vector2(a[2], 1)); st.add_vertex(a[1])
		st.set_uv(Vector2(b[2], 0)); st.add_vertex(b[0])
		st.set_uv(Vector2(b[2], 1)); st.add_vertex(b[1])
		st.set_uv(Vector2(a[2], 1)); st.add_vertex(a[1])
	st.commit(am)
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_texture = T("slash"); m.albedo_color = Color(col.r * 2.6, col.g * 2.6, col.b * 2.6, 1.0)
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	am.surface_set_material(0, m)
	mi.mesh = am; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var yaw: float = src.yaw if "yaw" in src else src.global_rotation.y
	mi.global_position = (src.global_position if at == Vector3.INF else at) + Vector3(0, 1.1, 0)
	mi.rotation = Vector3(deg_to_rad(tilt), yaw, deg_to_rad(180.0 if flip else 0.0))
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "rotation:y", yaw + (-0.9 if flip else 0.9), dur).from(yaw - 0.5 * (-1.0 if flip else 1.0)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, dur).from(1.0).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)
	return mi

func shake(amount: float, near: Vector3) -> void:
	var hero := get_tree().get_first_node_in_group("player")
	if hero and hero.global_position.distance_to(near) < 25.0:
		get_tree().call_group("camera", "shake", amount)

func _chest(u: Node3D) -> Vector3:
	return u.global_position + Vector3(0, 1.15 * (u.model.scale.y if "model" in u and u.model else 1.0), 0)

func _feet(u: Node3D) -> Vector3:
	var p := u.global_position
	p.y = WorldData.h(p.x, p.z)
	return p

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
	var school: String = a.get("school", "arcane")
	var col: Color = SCHOOL.get(school, Color.WHITE)
	var nodes := []
	for bone in ["hand_r", "hand_l"]:
		var ba := _attach_to_bone(u, bone); nodes.append(ba)
		if ba == u: continue
		match school:
			"fire": flip_emitter(ba, "fire_flip", Color(1, 1, 1), 16.0, 0.34, 0.45, 0.6, 1.2, 0.05)
			"frost":
				flip_emitter(ba, "mist_flip", Color(0.6, 0.85, 1.0, 0.8), 10.0, 0.45, 0.8, 0.2, -0.3, 0.06)
				emitter(ba, Color(0.85, 0.95, 1.0), 20, 0.08, 0.6, 0.4, -0.5, T("flare"), 0.12)
			"shadow": flip_emitter(ba, "wisp_flip", Color(0.55, 0.25, 0.95), 12.0, 0.5, 0.7, 0.3, 0.4, 0.06)
			"holy":
				emitter(ba, Color(1.0, 0.85, 0.45), 26, 0.16, 0.6, 0.3, 0.6, T("flare"), 0.1)
				emitter(ba, col, 24, 0.22, 0.5, 0.2, 0.6, glow, 0.06)
			_:
				emitter(ba, col, 30, 0.2, 0.5, 0.3, 0.6, glow, 0.08)
				emitter(ba, col.lightened(0.3), 16, 0.1, 0.6, 0.4, 0.2, T("flare"), 0.12)
		var l := OmniLight3D.new(); l.light_color = col; l.light_energy = 1.3; l.omni_range = 3.5; ba.add_child(l)
		nodes.append(l)
	# the magic circle at the caster's feet, turning slowly
	var mi := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(2.8, 2.8); q.orientation = PlaneMesh.FACE_Y
	var gtex: Texture2D = T("glyph_holy") if school == "holy" else rune
	var m := _add_mat(gtex if gtex else glow, false).duplicate(); m.albedo_color = Color(col.r * 1.8, col.g * 1.8, col.b * 1.8, 0.0); m.vertex_color_use_as_albedo = false
	q.material = m; mi.mesh = q; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	u.add_child(mi); mi.position = Vector3(0, 0.07, 0)
	mi.scale = Vector3.ONE * 0.6
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(m, "albedo_color:a", 0.9, 0.3); tw.tween_property(mi, "scale", Vector3.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	mi.set_meta("spin", 0.8)
	nodes.append(mi)
	var hum := sound("cast_loop", u, -12.0, 0.0)
	if hum: hum.finished.disconnect(hum.queue_free); hum.finished.connect(hum.play); nodes.append(hum)
	casting[u] = nodes

func cast_stop(u: Node3D) -> void:
	if not casting.has(u): return
	for n in casting[u]:
		if is_instance_valid(n) and n != u:
			if n is BoneAttachment3D:
				for c in n.get_children():
					if c is GPUParticles3D: c.emitting = false
				get_tree().create_timer(1.0).timeout.connect(n.queue_free)
			else: n.queue_free()
	casting.erase(u)

func _process(delta: float) -> void:
	for u in casting.keys():
		if not is_instance_valid(u) or u.casting.is_empty(): cast_stop(u); continue
		for n in casting[u]:
			if is_instance_valid(n) and n.has_meta("spin"): n.rotate_y(delta * float(n.get_meta("spin")))

# ------------------------------------------------------------------ projectiles

const BOLT := {"fireball": "fire", "ember_bolt": "fire", "pyroblast": "fire", "frostbolt": "frost", "brine_bolt": "brine", "frost_lance": "frost",
	"arcane_missiles": "arcane", "void_bolt": "shadow", "bog_bolt": "bog", "arrow_shot": "arrow"}

func projectile(src: Node3D, t: Node3D, id: String, on_hit: Callable) -> void:
	var a: Dictionary = Abilities.LIST[id]
	var col: Color = SCHOOL.get(a.get("school", "arcane"), Color.WHITE)
	var p := Node3D.new(); add_child(p)
	p.global_position = _hand(src) + Vector3(0, 0.2, 0)
	var kind: String = BOLT.get(id, a.get("school", "arcane"))
	var big: float = {"pyroblast": 1.5, "ember_bolt": 0.65, "frost_lance": 1.2}.get(id, 1.0)
	match kind:
		"fire":
			# a boiling head of flame, licks trailing behind it, embers and a smoky tail
			_head(p, Color(1.0, 0.5, 0.12), 1.2 * big, Color(1, 0.92, 0.65))
			flip_emitter(p, "fire_flip", Color(1, 1, 1), 34.0, 0.75 * big, 0.28, 0.3, 0.0, 0.08 * big, true, true)
			flip_emitter(p, "fire_flip", Color(1, 1, 1), 40.0, 0.6 * big, 0.45, 0.5, 1.0, 0.12 * big)
			emitter(p, Color(1.0, 0.7, 0.3), 50, 0.07, 0.6, 1.8, -1.0, spark, 0.2 * big)
			flip_emitter(p, "smoke_flip", Color(0.25, 0.2, 0.18, 0.7), 10.0, 0.8 * big, 1.1, 0.4, 0.8, 0.1, false)
			light(Vector3.ZERO, Color(1.0, 0.55, 0.2), 3.5 * big, 8.0, 0.0, p)
		"frost", "brine":
			var c2 := Color(0.55, 0.82, 1.0) if kind == "frost" else Color(0.35, 0.9, 0.85)
			_shard(p, c2, big)
			flip_emitter(p, "mist_flip", Color(c2.r, c2.g, c2.b, 0.7), 26.0, 0.6 * big, 0.6, 0.2, -0.2, 0.08)
			emitter(p, Color(0.9, 0.97, 1.0), 40, 0.07, 0.7, 1.0, -2.0, T("flare"), 0.15)
			light(Vector3.ZERO, c2, 2.8, 6.0, 0.0, p)
		"arcane":
			_head(p, Color(0.8, 0.45, 1.0), 0.5, Color(1, 0.85, 1.0))
			emitter(p, Color(0.75, 0.4, 1.0), 70, 0.22, 0.35, 0.2, 0.0, glow, 0.05)
			emitter(p, Color(0.95, 0.8, 1.0), 30, 0.09, 0.5, 0.6, 0.0, T("flare"), 0.1)
			light(Vector3.ZERO, Color(0.8, 0.5, 1.0), 2.0, 5.0, 0.0, p)
		"shadow":
			_head(p, Color(0.6, 0.3, 1.0), 0.7, Color(0.95, 0.85, 1.0))
			flip_emitter(p, "wisp_flip", Color(0.5, 0.2, 0.9), 24.0, 0.7, 0.6, 0.3, 0.3, 0.1)
			flip_emitter(p, "smoke_flip", Color(0.08, 0.03, 0.12, 0.8), 14.0, 0.6, 0.8, 0.3, 0.2, 0.1, false)
			light(Vector3.ZERO, Color(0.6, 0.3, 1.0), 2.5, 6.0, 0.0, p)
		"bog":
			_head(p, Color(0.55, 0.95, 0.25), 0.8, Color(0.95, 1.0, 0.7))
			flip_emitter(p, "smoke_flip", Color(0.35, 0.6, 0.15, 0.7), 18.0, 0.5, 0.7, 0.3, -0.6, 0.1, false)
			emitter(p, Color(0.6, 1.0, 0.3), 30, 0.1, 0.6, 0.8, -3.0, spark, 0.12)
			light(Vector3.ZERO, Color(0.5, 1.0, 0.3), 2.0, 5.0, 0.0, p)
		"arrow":
			var mi := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.02; cm.bottom_radius = 0.02; cm.height = 0.9
			var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.55, 0.4, 0.25); cm.material = wm; mi.mesh = cm
			mi.rotation_degrees = Vector3(90, 0, 0); p.add_child(mi)
			emitter(p, Color(0.9, 0.9, 1.0), 40, 0.05, 0.25, 0.1, 0.0, glow, 0.02)
		_:
			_head(p, col, 0.6, Color.WHITE)
			emitter(p, col, 60, 0.3, 0.4, 0.3, 0.0, glow, 0.08)
	sound({"fire": "fire_launch", "frost": "frost_launch", "brine": "frost_launch", "arcane": "arcane", "shadow": "shadow", "arrow": "swing_0"}.get(kind, "arcane"), src, -4.0)
	var speed: float = float(a.get("speed", 20.0))
	var wobble := Vector3(randf_range(-1, 1), randf_range(0.2, 1.0), randf_range(-1, 1)) * (1.2 if id == "arcane_missiles" else 0.0)
	var start := p.global_position
	var d0 := start.distance_to(_chest(t)) if is_instance_valid(t) else 10.0
	var fly := func(dt: float) -> bool:
		if not is_instance_valid(p): return false
		var goal := _chest(t) if is_instance_valid(t) else p.global_position
		var to := goal - p.global_position
		var step := speed * dt
		if to.length() <= step + 0.15:
			_impact(id, kind, goal, col, t)
			on_hit.call()
			for c in p.get_children():
				if c is GPUParticles3D:
					c.emitting = false; c.reparent(self); get_tree().create_timer(1.5).timeout.connect(c.queue_free)
			p.queue_free()
			return false
		var k := 1.0 - clampf(to.length() / maxf(d0, 0.1), 0.0, 1.0)
		var bend := wobble * sin(k * PI) * 0.08
		p.global_position += to.normalized() * step + bend
		if to.length() > 0.2: p.look_at(goal, Vector3.UP)
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

## an ice lance: a faceted crystal pointing along the flight, with a cold glow
func _shard(p: Node3D, col: Color, big := 1.0) -> void:
	var mi := MeshInstance3D.new(); var pm := PrismMesh.new(); pm.size = Vector3(0.2, 0.8, 0.2) * big
	var m := StandardMaterial3D.new(); m.albedo_color = Color(col.lightened(0.3), 0.8); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true; m.emission = col; m.emission_energy_multiplier = 2.2; m.roughness = 0.05; m.metallic = 0.3
	m.rim_enabled = true; m.rim = 1.0; m.rim_tint = 0.2
	pm.material = m; mi.mesh = pm; mi.rotation_degrees = Vector3(-90, 0, 0); p.add_child(mi)
	for k in 3:
		var sm := MeshInstance3D.new(); var sp := PrismMesh.new(); sp.size = Vector3(0.08, 0.35, 0.08) * big; sp.material = m; sm.mesh = sp
		sm.rotation_degrees = Vector3(-90 + randf_range(-25, 25), randf_range(-25, 25), 0); sm.position = Vector3(randf_range(-0.08, 0.08), randf_range(-0.08, 0.08), 0.12)
		p.add_child(sm)
	_head(p, col, 0.6 * big, Color.WHITE)

func _impact(id: String, kind: String, pos: Vector3, col: Color, t: Node3D) -> void:
	sound({"fire": "fire_impact", "frost": "ice_shatter", "brine": "ice_shatter", "shadow": "shadow"}.get(kind, "hit_1"), pos, -3.0 if id in ["fireball", "pyroblast"] else -6.0)
	var big: float = {"pyroblast": 1.6, "ember_bolt": 0.6}.get(id, 1.0)
	match kind:
		"fire": fire_hit(pos, big)
		"frost", "brine": frost_hit(pos, Color(0.6, 0.88, 1.0) if kind == "frost" else Color(0.4, 0.95, 0.9), big)
		"shadow": shadow_hit(pos, 1.0)
		"arcane":
			flash(pos, Color(0.85, 0.6, 1.0), 1.4, 0.22)
			streaks(pos, Color(0.9, 0.7, 1.0), 14, 5.0, 0.5, 0.35, 0.0)
			ground_glyph(pos - Vector3(0, 1.0, 0), "shock_ring", Color(0.8, 0.5, 1.0), 0.2, 1.6, 0.35, 0.0)
			light(pos, Color(0.8, 0.5, 1.0), 3.0, 5.0, 0.3)
		"bog":
			puffs(pos, "smoke_flip", Color(0.35, 0.6, 0.15, 0.9), 8, 1.1, 0.9, 2.0, -0.5, 180.0, Vector3.UP, false, 0.2)
			streaks(pos, Color(0.6, 1.0, 0.3), 16, 4.0, 0.4, 0.6, -9.0)
			light(pos, Color(0.5, 1.0, 0.3), 3.0, 5.0, 0.3)
		"arrow":
			streaks(pos, Color(0.9, 0.85, 0.7), 8, 3.0, 0.4, 0.3, -6.0)
		_:
			flash(pos, col, 1.2, 0.25)
			streaks(pos, col.lightened(0.4), 16, 7.0, 0.5, 0.4, 0.0)
			light(pos, col, 3.0, 5.0, 0.3)

## a fireball going off: flash, a boiling explosion, licks of fire, sparks, smoke and a scorch
func fire_hit(pos: Vector3, big := 1.0) -> void:
	flash(pos, Color(1.0, 0.75, 0.4), 2.4 * big, 0.2)
	puffs(pos, "explosion_flip", Color(1, 1, 1), 3, 2.6 * big, 0.55, 0.6, 0.5, 180.0, Vector3.UP, true, 0.1, null, 1.3)
	puffs(pos, "fire_flip", Color(1, 1, 1), int(10 * big), 1.3 * big, 0.6, 4.0 * big, 2.0, 180.0, Vector3.UP, true, 0.25)
	streaks(pos, Color(1.0, 0.72, 0.3), int(26 * big), 10.0 * big, 0.7, 0.6, -8.0)
	puffs(pos + Vector3(0, 0.3, 0), "smoke_flip", Color(0.18, 0.15, 0.14, 0.85), 6, 1.6 * big, 1.6, 1.2, 1.0, 180.0, Vector3.UP, false, 0.3)
	light(pos, Color(1.0, 0.55, 0.2), 7.0 * big, 10.0 * big, 0.5)
	var g := pos; g.y = WorldData.h(g.x, g.z)
	if pos.y - g.y < 2.5: decal(g, "scorch", Color(1, 1, 1, 0.9), 2.2 * big, 6.0, "scorch_emit", Color(1, 1, 1), 2.5)
	shake(0.12 * big, pos)

## ice shattering: a cold flash, shards flying, mist rolling out, frost on the ground
func frost_hit(pos: Vector3, col: Color, big := 1.0) -> void:
	flash(pos, col.lightened(0.3), 1.8 * big, 0.2)
	streaks(pos, Color(0.85, 0.95, 1.0), int(18 * big), 7.0, 0.45, 0.7, -9.0, 180.0, Vector3.UP, 0.1, null, "shard", 0.16)
	streaks(pos, col, 14, 5.0, 0.4, 0.5, -3.0)
	puffs(pos, "mist_flip", Color(col.r, col.g, col.b, 0.8), 7, 1.4 * big, 1.1, 1.4, -0.3, 180.0, Vector3.UP, true, 0.3)
	light(pos, col, 4.0, 7.0, 0.4)
	var g := pos; g.y = WorldData.h(g.x, g.z)
	if pos.y - g.y < 2.5: decal(g, "frost_decal", Color(0.85, 0.95, 1.0, 0.85), 2.4 * big, 5.0)

func shadow_hit(pos: Vector3, big := 1.0) -> void:
	flash(pos, Color(0.7, 0.4, 1.0), 1.6 * big, 0.25)
	puffs(pos, "wisp_flip", Color(0.55, 0.25, 0.95), 6, 1.6 * big, 0.9, 1.5, 0.4, 180.0, Vector3.UP, true, 0.2)
	puffs(pos, "smoke_flip", Color(0.06, 0.02, 0.1, 0.9), 6, 1.3 * big, 1.1, 1.2, 0.3, 180.0, Vector3.UP, false, 0.2)
	streaks(pos, Color(0.8, 0.55, 1.0), 12, 5.0, 0.4, 0.4, 0.0)
	light(pos, Color(0.6, 0.3, 1.0), 3.5, 6.0, 0.4)

## a pillar of holy light striking down
func holy_hit(u: Node3D, big := 1.0) -> void:
	var base := _feet(u)
	column(base, Color(1.0, 0.85, 0.4), Color(1, 1, 0.9), 0.5 * big, 14.0, 0.5, 0.05)
	rays(base, Color(1.0, 0.88, 0.5), 4.5 * big, 0.7)
	_delay(0.06, func():
		if not is_instance_valid(u): return
		flash(_chest(u), Color(1.0, 0.92, 0.6), 2.2 * big, 0.3)
		streaks(_chest(u), Color(1.0, 0.95, 0.7), 16, 6.0, 0.5, 0.5, -2.0)
		ground_glyph(base, "glyph_holy", Color(1.0, 0.85, 0.4), 0.6, 1.8 * big, 0.8, 0.8)
		light(_chest(u), Color(1.0, 0.9, 0.6), 6.0, 8.0, 0.4))

# ------------------------------------------------------------------ ability effects

const ABILITY_SOUND := {"heroic_strike": "swing_2", "rend": "swing_1", "execute": "crit", "hamstring": "swing_0", "thunder_clap": "thunder_clap",
	"charge": "charge", "charge_hit": "hit_2", "battle_shout": "shout", "fire_blast": "fire_impact", "frost_nova": "frost_nova",
	"flamestrike": "flamestrike", "smite": "holy_smite", "mend": "heal", "renewal": "heal", "ward_of_light": "shield", "shadow_rot": "shadow",
	"holy_nova": "holy_nova", "inner_fire": "shield", "frost_armor": "frost_launch", "blink": "blink", "taunt": "shout",
	"mortal_strike": "crit", "whirlwind": "swing_2", "cleaving_slam": "thunder_clap", "recklessness": "shout", "shield_wall": "shield",
	"rallying_cry": "shout", "defensive_stance": "shield", "shield_block": "shield", "cone_of_cold": "frost_nova", "meteor": "flamestrike",
	"ice_barrier": "shield", "arcane_power": "arcane", "evocation": "arcane", "time_warp": "blink", "greater_mend": "heal", "salvation": "heal",
	"mind_blast": "shadow", "prayer_of_healing": "holy_nova", "divine_protection": "shield", "radiance": "heal", "holy_fire": "holy_smite",
	"resurrection": "level_up", "myth_quake": "thunder_clap", "myth_dawn": "holy_nova", "myth_hours": "blink"}

func play(id: String, src: Node3D, t: Node3D, pos: Vector3) -> void:
	if not is_instance_valid(src): return
	var tv := t != null and is_instance_valid(t)
	var tp := _chest(t) if tv else pos
	if ABILITY_SOUND.has(id):
		var where = t if (tv and id in ["smite", "mend", "renewal", "shadow_rot", "fire_blast", "charge_hit", "ward_of_light", "greater_mend", "salvation", "holy_fire", "mind_blast", "radiance", "resurrection"]) else src
		if id in ["flamestrike", "meteor"]: where = pos
		sound(ABILITY_SOUND[id], where, -8.0 if id == "renewal" else -3.0)
		if id in ["heroic_strike", "hamstring", "rend", "mortal_strike"]: _delay(0.15, func(): if is_instance_valid(t): sound("hit_%d" % (randi() % 3), t, -3.0))
	match id:
		# ---------------------------------------------------------- warrior
		"heroic_strike":
			slash(src, Color(1.0, 0.72, 0.3), 1.5, 0.3)
			_delay(0.16, func():
				if not is_instance_valid(t): return
				streaks(_chest(t), Color(1.0, 0.8, 0.45), 18, 7.0, 0.7, 0.4, -6.0); flash(_chest(t), Color(1, 0.8, 0.45), 1.3, 0.2)
				light(_chest(t), Color(1, 0.8, 0.4), 2.5, 4.0, 0.25))
		"rend":
			slash(src, Color(1.0, 0.2, 0.15), 1.35, 0.28, 15.0, true)
			_delay(0.15, func(): if is_instance_valid(t): streaks(_chest(t), Color(0.75, 0.05, 0.03), 22, 4.0, 0.35, 0.8, -9.0, 70.0))
		"execute", "mortal_strike":
			var red := Color(1.0, 0.25, 0.08) if id == "execute" else Color(1.0, 0.5, 0.15)
			slash(src, red, 1.9, 0.35, -60.0, false, Vector3.INF, 0.6)
			_delay(0.2, func():
				if not is_instance_valid(t): return
				flash(_chest(t), red.lightened(0.3), 2.2, 0.25)
				streaks(_chest(t), red.lightened(0.2), 36, 10.0, 0.9, 0.6, -7.0)
				if id == "execute": puffs(_chest(t), "fire_flip", Color(1, 0.6, 0.5), 4, 0.9, 0.4, 2.0, 0.5)
				decal(_feet(t), "cracks", Color(1, 1, 1, 0.9), 2.4, 3.5, "cracks_emit", red, 2.0)
				light(_chest(t), red, 5.0, 6.0, 0.35); shake(0.25, tp))
		"hamstring":
			slash(src, Color(0.9, 0.55, 0.35), 1.15, 0.25, 40.0)
			_delay(0.14, func(): if is_instance_valid(t): streaks(_feet(t) + Vector3(0, 0.5, 0), Color(0.9, 0.3, 0.2), 12, 4.0, 0.4, 0.4, -8.0, 60.0))
		"thunder_clap", "cleaving_slam", "myth_quake":
			var g := _feet(src)
			var big: float = {"cleaving_slam": 1.2, "myth_quake": 1.6}.get(id, 1.0)
			if id == "cleaving_slam": slash(src, Color(1.0, 0.7, 0.3), 2.2, 0.3, -70.0, false, Vector3.INF, 0.7)
			_delay(0.25, func():
				ground_ring(g, Color(0.6, 0.75, 1.0) if id == "thunder_clap" else Color(1.0, 0.7, 0.35), 0.5, 9.0 * big, 0.55)
				ground_ring(g, Color(1.0, 0.95, 0.8), 0.2, 5.0 * big, 0.35)
				puffs(g + Vector3(0, 0.3, 0), "smoke_flip", Color(0.55, 0.5, 0.44, 0.8), 14, 1.8 * big, 1.4, 6.0 * big, 0.3, 80.0, Vector3(0, 0.25, 0), false, 1.0)
				streaks(g + Vector3(0, 0.4, 0), Color(0.75, 0.85, 1.0) if id == "thunder_clap" else Color(1.0, 0.8, 0.5), 30, 12.0, 0.8, 0.5, -6.0, 100.0, Vector3.UP, 0.6)
				decal(g, "cracks", Color(1, 1, 1, 0.95), 5.0 * big, 4.0, "cracks_emit", Color(0.6, 0.75, 1.0) if id == "thunder_clap" else Color(1.0, 0.6, 0.2), 1.5)
				flash(g + Vector3(0, 0.6, 0), Color(0.8, 0.85, 1.0), 3.0 * big, 0.25)
				light(g + Vector3(0, 1, 0), Color(0.7, 0.8, 1.0), 6.0, 12.0, 0.4); shake(0.35 * big, g))
		"whirlwind":
			for k in 3:
				_delay(k * 0.12, func():
					if not is_instance_valid(src): return
					var sm := slash(src, Color(1.0, 0.75, 0.4), 2.2, 0.28, -8.0 + k * 6.0, k % 2 == 1, Vector3.INF, 0.5)
					if sm: sm.create_tween().tween_property(sm, "rotation:y", sm.rotation.y + TAU * 0.8 * (1 if k % 2 == 0 else -1), 0.28))
			_delay(0.2, func(): if is_instance_valid(src): puffs(_feet(src) + Vector3(0, 0.3, 0), "smoke_flip", Color(0.55, 0.5, 0.44, 0.7), 8, 1.3, 1.0, 4.0, 0.2, 70.0, Vector3(0, 0.2, 0), false, 0.8))
		"charge":
			var e := flip_emitter(src, "smoke_flip", Color(0.55, 0.48, 0.4, 0.8), 30.0, 1.2, 0.9, 0.6, 0.4, 0.4, false)
			e.position = Vector3(0, 0.2, 0)
			_delay(0.8, func():
				if is_instance_valid(e):
					e.emitting = false; get_tree().create_timer(1.2).timeout.connect(e.queue_free))
		"charge_hit":
			if not tv: return
			flash(tp, Color(1.0, 0.85, 0.5), 2.0, 0.22)
			streaks(tp, Color(1.0, 0.85, 0.5), 26, 8.0, 0.7, 0.5, -5.0)
			puffs(_feet(t) + Vector3(0, 0.3, 0), "smoke_flip", Color(0.55, 0.5, 0.45, 0.8), 8, 1.2, 1.0, 3.0, 0.4, 90.0, Vector3.UP, false, 0.5)
			decal(_feet(t), "cracks", Color(1, 1, 1, 0.8), 2.0, 3.0)
			shake(0.2, tp)
			_stars(t)
		"battle_shout", "rallying_cry", "recklessness", "defensive_stance", "shield_block", "shield_wall":
			_warcry(id, src)
		"taunt":
			if tv:
				flash(_chest(t) + Vector3(0, 1.1, 0), Color(1.0, 0.25, 0.15), 1.6, 0.4)
				puffs(_chest(t) + Vector3(0, 1.0, 0), "fire_flip", Color(1.0, 0.4, 0.4), 4, 0.6, 0.5, 0.8, 1.0)
			ground_ring(_feet(src), Color(1.0, 0.3, 0.2), 0.3, 3.0, 0.4)
		# ---------------------------------------------------------- wizard
		"fire_blast":
			if tv: fire_hit(tp, 0.9)
		"frost_nova":
			var g2 := _feet(src)
			ground_ring(g2, Color(0.55, 0.85, 1.0), 0.5, 9.0, 0.7)
			ground_glyph(g2, "frost_decal", Color(0.7, 0.9, 1.0), 1.0, 8.0, 0.5, 0.0)
			_ice_spikes(g2, 8.0)
			decal(g2, "frost_decal", Color(0.9, 0.97, 1.0, 0.9), 16.0, 5.0)
			puffs(g2 + Vector3(0, 0.3, 0), "mist_flip", Color(0.6, 0.85, 1.0, 0.9), 22, 2.6, 1.3, 9.0, -0.2, 88.0, Vector3.UP, true, 0.8)
			streaks(g2 + Vector3(0, 0.3, 0), Color(0.85, 0.95, 1.0), 40, 13.0, 0.5, 0.8, -3.0, 88.0, Vector3.UP, 0.6, null, "shard", 0.14)
			flash(g2 + Vector3(0, 1.0, 0), Color(0.7, 0.9, 1.0), 4.0, 0.3)
			light(g2 + Vector3(0, 1, 0), Color(0.5, 0.8, 1.0), 6.0, 12.0, 0.6)
		"cone_of_cold":
			var fwd := -src.global_transform.basis.z
			if "yaw" in src: fwd = Vector3(sin(src.yaw), 0, cos(src.yaw))
			var o := _chest(src) + fwd * 0.6
			puffs(o, "mist_flip", Color(0.6, 0.88, 1.0, 0.9), 26, 1.8, 0.9, 13.0, -0.5, 22.0, fwd, true, 0.3, null, 2.2)
			streaks(o, Color(0.85, 0.95, 1.0), 40, 16.0, 0.6, 0.6, -4.0, 20.0, fwd, 0.2, null, "shard", 0.14)
			streaks(o, Color(0.6, 0.85, 1.0), 30, 12.0, 0.5, 0.5, -1.0, 25.0, fwd, 0.2)
			light(o + fwd * 3.0, Color(0.5, 0.8, 1.0), 5.0, 10.0, 0.5)
			var g5 := _feet(src) + fwd * 4.5
			decal(g5, "frost_decal", Color(0.9, 0.97, 1.0, 0.85), 7.0, 4.0)
		"flamestrike", "meteor":
			var at := pos if pos != Vector3.INF else tp
			at.y = WorldData.h(at.x, at.z)
			if id == "meteor": _meteor(at)
			else: _flamestrike(at, 1.0)
		"blink", "hearthstone":
			var c := Color(0.8, 0.5, 1.0)
			flash(_chest(src), c, 2.2, 0.3)
			puffs(_chest(src), "wisp_flip", c, 6, 1.4, 0.7, 2.0, 0.2, 180.0, Vector3.UP, true, 0.3)
			streaks(_chest(src), Color(0.9, 0.8, 1.0), 24, 7.0, 0.5, 0.5, 0.0)
			ground_glyph(_feet(src), "glyph_arcane", c, 0.5, 1.8, 0.6, 1.5)
			light(_chest(src), c, 4.0, 6.0, 0.3)
		"frost_armor", "ice_barrier":
			var c2 := Color(0.6, 0.88, 1.0)
			puffs(_chest(src), "mist_flip", Color(c2.r, c2.g, c2.b, 0.8), 10, 1.4, 1.0, 1.5, 0.3, 180.0, Vector3.UP, true, 0.5)
			streaks(_chest(src), Color(0.9, 0.97, 1.0), 20, 5.0, 0.4, 0.5, 0.0, 180.0, Vector3.UP, 0.8, null, "shard", 0.12)
			ground_glyph(_feet(src), "frost_decal", c2, 0.5, 2.2, 0.8, 0.0)
			_spiral(src, c2, 0.8)
		"arcane_power", "evocation", "time_warp", "myth_hours":
			var c3 := Color(0.8, 0.5, 1.0) if id != "time_warp" else Color(0.5, 0.8, 1.0)
			ground_glyph(_feet(src), "glyph_arcane", c3, 0.6, 2.6 if id != "time_warp" else 9.0, 1.2, 2.5)
			flash(_chest(src), c3, 2.4, 0.4)
			puffs(_chest(src), "wisp_flip", c3, 8, 1.4, 1.0, 1.6, 0.8, 180.0, Vector3.UP, true, 0.4)
			_spiral(src, c3, 1.0)
			light(_chest(src), c3, 4.0, 7.0, 0.6)
		# ---------------------------------------------------------- cleric
		"smite", "holy_fire":
			if tv:
				holy_hit(t, 1.0 if id == "smite" else 1.2)
				if id == "holy_fire": _delay(0.1, func(): if is_instance_valid(t): puffs(_chest(t), "fire_flip", Color(1.0, 0.9, 0.6), 8, 1.1, 0.7, 2.0, 1.5))
		"mind_blast":
			if tv:
				shadow_hit(tp, 1.4)
				ground_glyph(_feet(t), "shock_ring", Color(0.6, 0.3, 1.0), 0.3, 3.0, 0.45, 0.0)
		"mend", "greater_mend", "salvation":
			if tv:
				var big: float = {"greater_mend": 1.3, "salvation": 1.8}.get(id, 1.0)
				_spiral(t, Color(1.0, 0.85, 0.4), 1.0)
				ground_glyph(_feet(t), "glyph_holy", Color(1.0, 0.85, 0.4), 0.4, 1.6 * big, 1.0, 0.8)
				rays(_feet(t), Color(1.0, 0.9, 0.55), 3.5 * big, 0.9)
				emitter_once(t, Color(1.0, 0.9, 0.6), 1.0, 16, "flare")
				light(_chest(t), Color(1.0, 0.85, 0.5), 3.5, 6.0, 0.8)
		"renewal", "radiance":
			if tv:
				streaks(_feet(t) + Vector3(0, 0.3, 0), Color(0.6, 1.0, 0.5), 14, 2.5, 0.35, 1.2, 1.5, 30.0, Vector3.UP, 0.5)
				emitter_once(t, Color(0.7, 1.0, 0.55), 1.2, 10, "leaf", false)
				ground_glyph(_feet(t), "glyph_holy", Color(0.6, 1.0, 0.5), 0.4, 1.4, 0.9, 0.5)
		"ward_of_light", "divine_protection":
			var who := t if tv else src
			flash(_chest(who), Color(1.0, 0.9, 0.55), 2.0, 0.3)
			ground_glyph(_feet(who), "glyph_holy", Color(1.0, 0.85, 0.4), 0.5, 1.8, 0.7, 1.0)
		"shadow_rot":
			if tv: shadow_hit(tp, 0.8)
		"holy_nova", "prayer_of_healing", "myth_dawn":
			var g3 := _feet(src)
			var big: float = {"prayer_of_healing": 1.3, "myth_dawn": 1.6}.get(id, 1.0)
			ground_glyph(g3, "glyph_holy", Color(1.0, 0.88, 0.5), 1.0, 5.0 * big, 1.1, 1.2)
			ground_ring(g3, Color(1.0, 0.9, 0.5), 0.5, 11.0 * big, 0.6)
			rays(g3, Color(1.0, 0.9, 0.55), 6.0 * big, 1.0)
			flash(_chest(src), Color(1.0, 0.93, 0.65), 3.5 * big, 0.35)
			streaks(_chest(src), Color(1.0, 0.95, 0.7), 50, 14.0, 0.7, 0.6, 0.0, 180.0)
			light(_chest(src), Color(1.0, 0.9, 0.6), 8.0, 14.0, 0.5)
		"inner_fire":
			puffs(_chest(src), "fire_flip", Color(1.0, 0.8, 0.5), 8, 0.9, 0.6, 1.4, 1.0, 180.0, Vector3.UP, true, 0.5)
			_spiral(src, Color(1.0, 0.6, 0.2), 0.8)
		"resurrection":
			if tv:
				var b := _feet(t)
				column(b, Color(1.0, 0.85, 0.45), Color(1, 1, 0.9), 1.0, 12.0, 1.4, 0.2)
				rays(b, Color(1.0, 0.92, 0.6), 7.0, 1.6)
				ground_glyph(b, "glyph_holy", Color(1.0, 0.88, 0.5), 0.8, 3.0, 1.6, 1.2)
				streaks(b + Vector3(0, 0.3, 0), Color(1.0, 0.95, 0.7), 40, 6.0, 0.6, 1.4, 2.0, 25.0, Vector3.UP, 0.8)
				light(b + Vector3(0, 2, 0), Color(1.0, 0.9, 0.6), 7.0, 10.0, 1.5)
		"slash_red":
			slash(src, Color(1.0, 0.3, 0.2), 1.2, 0.25)
		"summon_stag":
			flash(_chest(src), Color(0.6, 1.0, 0.5), 2.4, 0.4)
			emitter_once(src, Color(0.7, 1.0, 0.55), 1.0, 16, "leaf", false)
			ground_glyph(_feet(src), "glyph_holy", Color(0.6, 1.0, 0.5), 0.5, 2.4, 0.9, 1.0)
		_:
			_generic(id, src, t, pos)

## effects for abilities without their own design, by their kind and school
func _generic(id: String, src: Node3D, t: Node3D, pos: Vector3) -> void:
	var a: Dictionary = Abilities.LIST.get(id, {})
	var school: String = a.get("school", "physical")
	var col: Color = SCHOOL.get(school, Color.WHITE)
	var tv := t != null and is_instance_valid(t)
	match a.get("kind", ""):
		"strike", "debuff", "dot":
			if school == "physical": slash(src, col, 1.3, 0.28)
			elif tv:
				match school:
					"fire": fire_hit(_chest(t), 0.6)
					"frost": frost_hit(_chest(t), col, 0.7)
					"shadow": shadow_hit(_chest(t), 0.8)
					_: flash(_chest(t), col, 1.4, 0.25); streaks(_chest(t), col, 14, 5.0, 0.5, 0.4, 0.0)
		"buff", "shield":
			flash(_chest(src), col, 1.8, 0.3); _spiral(src, col, 0.8)
			ground_glyph(_feet(src), "glyph_holy" if school == "holy" else "glyph_arcane", col, 0.5, 2.0, 0.8, 1.0)
		"heal", "hot":
			if tv: _spiral(t, col, 1.0); ground_glyph(_feet(t), "glyph_holy", col, 0.4, 1.5, 0.9, 0.8)
		"aoe":
			var g := _feet(src)
			ground_ring(g, col, 0.5, float(a.get("radius", 8.0)), 0.6)
			flash(g + Vector3(0, 0.8, 0), col, 3.0, 0.3)
			streaks(g + Vector3(0, 0.5, 0), col.lightened(0.3), 30, 10.0, 0.6, 0.5, 0.0, 90.0)

## a warrior's shout or stance: a burst of force around them, coloured by what it does
func _warcry(id: String, src: Node3D) -> void:
	var col: Color = {"battle_shout": Color(1.0, 0.72, 0.3), "rallying_cry": Color(1.0, 0.85, 0.45), "recklessness": Color(1.0, 0.25, 0.1),
		"defensive_stance": Color(0.6, 0.75, 1.0), "shield_block": Color(0.75, 0.85, 1.0), "shield_wall": Color(0.7, 0.85, 1.0)}[id]
	var g := _feet(src)
	ground_ring(g, col, 0.5, 7.0 if id in ["battle_shout", "rallying_cry"] else 3.5, 0.6)
	flash(_chest(src), col, 2.4, 0.3)
	match id:
		"battle_shout", "rallying_cry":
			ground_glyph(g, "glyph_holy", col, 0.8, 4.0, 0.9, 1.0)
			streaks(_chest(src), col.lightened(0.3), 30, 5.0, 0.6, 1.0, 1.5, 60.0)
			puffs(g + Vector3(0, 0.3, 0), "smoke_flip", Color(0.55, 0.5, 0.44, 0.6), 8, 1.4, 1.0, 3.5, 0.3, 80.0, Vector3(0, 0.2, 0), false, 0.6)
		"recklessness":
			puffs(_chest(src), "fire_flip", Color(1.0, 0.5, 0.4), 10, 1.1, 0.7, 2.0, 1.5, 180.0, Vector3.UP, true, 0.5)
			streaks(_chest(src), col, 24, 6.0, 0.6, 0.6, -2.0)
		"shield_wall", "shield_block", "defensive_stance":
			var b := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 1.2; sm.height = 2.5
			sm.material = energy_mat(col, Color(1, 1, 1), 1.4, 2.5, 0.5, 0.0, 4.0); b.mesh = sm
			b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; src.add_child(b); b.position = Vector3(0, 1.0, 0)
			b.scale = Vector3.ONE * 0.3
			var tw := b.create_tween(); tw.tween_property(b, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_interval(0.35); tw.tween_property(b, "scale", Vector3.ONE * 1.3, 0.3); tw.parallel().tween_method(func(v): sm.material.set_shader_parameter("alpha", v), 1.0, 0.0, 0.3)
			tw.tween_callback(b.queue_free)
			streaks(_chest(src), Color(0.9, 0.95, 1.0), 16, 5.0, 0.5, 0.4, 0.0)

## a shower of motes or leaves rising around someone for a moment
func emitter_once(u: Node3D, col: Color, dur: float, rate := 14, tex_name := "flare", additive := true) -> void:
	var n := Node3D.new(); u.add_child(n); n.position = Vector3(0, 0.3, 0)
	var e := emitter(n, col, rate, 0.18, 1.2, 0.8, 1.2, T(tex_name) if T(tex_name) else glow, 0.6, false, additive)
	e.process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	e.process_material.emission_ring_axis = Vector3.UP; e.process_material.emission_ring_radius = 0.7
	e.process_material.emission_ring_inner_radius = 0.4; e.process_material.emission_ring_height = 0.2
	_delay(dur, func():
		if is_instance_valid(e): e.emitting = false
		get_tree().create_timer(1.5).timeout.connect(func(): if is_instance_valid(n): n.queue_free()))

func _flamestrike(at: Vector3, big: float) -> void:
	column(at, Color(1.0, 0.3, 0.04), Color(1.0, 0.8, 0.35), 1.7 * big, 6.5, 0.9)
	var holder := Node3D.new(); add_child(holder); holder.global_position = at
	var e := flip_emitter(holder, "fire_flip", Color(1, 1, 1), 60.0, 2.0 * big, 0.8, 5.0, 3.0, 1.4 * big)
	_delay(0.7, func(): if is_instance_valid(e): e.emitting = false)
	get_tree().create_timer(2.5).timeout.connect(holder.queue_free)
	_delay(0.08, func():
		ground_ring(at, Color(1.0, 0.4, 0.08), 0.5, 5.5 * big, 0.8)
		puffs(at + Vector3(0, 0.5, 0), "explosion_flip", Color(1, 1, 1), 4, 3.5 * big, 0.6, 1.0, 1.0, 60.0, Vector3.UP, true, 1.2)
		streaks(at + Vector3(0, 0.3, 0), Color(1.0, 0.7, 0.25), 50, 11.0, 0.9, 1.2, -4.0, 40.0, Vector3.UP, 1.8)
		puffs(at + Vector3(0, 2.0, 0), "smoke_flip", Color(0.16, 0.13, 0.12, 0.85), 14, 2.6 * big, 2.2, 1.6, 1.2, 50.0, Vector3.UP, false, 1.5)
		decal(at, "scorch", Color(1, 1, 1, 0.95), 7.0 * big, 7.0, "scorch_emit", Color(1, 1, 1), 3.0)
		light(at + Vector3(0, 2, 0), Color(1.0, 0.45, 0.15), 8.0, 16.0, 0.9); shake(0.35, at))
	_ground_fire(at, 4.5 * big, 3.0)

## a burning rock falling out of the sky and bursting
func _meteor(at: Vector3) -> void:
	var p := Node3D.new(); add_child(p)
	var from := at + Vector3(-6.0, 22.0, -4.0)
	p.global_position = from
	var rock := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.7; sm.height = 1.3
	var rm := StandardMaterial3D.new(); rm.albedo_color = Color(0.15, 0.1, 0.08); rm.emission_enabled = true; rm.emission = Color(1.0, 0.35, 0.05); rm.emission_energy_multiplier = 1.5
	sm.material = rm; rock.mesh = sm; p.add_child(rock)
	flip_emitter(p, "fire_flip", Color(1, 1, 1), 60.0, 2.2, 0.5, 1.0, 0.0, 0.5)
	flip_emitter(p, "smoke_flip", Color(0.18, 0.14, 0.12, 0.85), 20.0, 2.0, 1.4, 0.5, 0.5, 0.4, false)
	emitter(p, Color(1.0, 0.7, 0.3), 60, 0.1, 0.8, 3.0, -2.0, spark, 0.5)
	light(Vector3.ZERO, Color(1.0, 0.5, 0.15), 6.0, 14.0, 0.0, p)
	var tw := p.create_tween()
	tw.tween_property(p, "global_position", at + Vector3(0, 0.5, 0), 0.55).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		for c in p.get_children():
			if c is GPUParticles3D: c.emitting = false; c.reparent(self); get_tree().create_timer(2.0).timeout.connect(c.queue_free)
		p.queue_free()
		sound("fire_impact", at, 2.0)
		fire_hit(at + Vector3(0, 0.6, 0), 2.2)
		_flamestrike(at, 1.2)
		shake(0.6, at))

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
		streaks(at + Vector3(0, 0.4, 0), Color(0.85, 0.96, 1.0), 60, 5.0, 0.4, 0.8, -9.0, 90.0, Vector3.UP, radius * 0.7, null, "shard", 0.12)
		sound("ice_shatter", at, -8.0))
	get_tree().create_timer(1.8).timeout.connect(holder.queue_free)

func _delay(t: float, f: Callable) -> void:
	get_tree().create_timer(t).timeout.connect(f)

## rising motes of light spiralling around someone (heals, blessings)
func _spiral(u: Node3D, col: Color, dur: float) -> void:
	var holder := Node3D.new(); u.add_child(holder)
	for k in 3:
		var arm := Node3D.new(); holder.add_child(arm)
		emitter(arm, col, 50, 0.22, 0.7, 0.1, 0.6, glow, 0.02)
		emitter(arm, col.lightened(0.4), 24, 0.14, 0.8, 0.15, 0.4, T("flare") if T("flare") else spark, 0.03)
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
	tw.tween_interval(0.9)
	tw.tween_callback(holder.queue_free)

## little stars circling a stunned head
func _stars(u: Node3D) -> void:
	var holder := Node3D.new(); u.add_child(holder); holder.position = Vector3(0, 2.0, 0)
	for k in 3:
		var s := Node3D.new(); holder.add_child(s); s.position = Vector3(cos(TAU * k / 3.0) * 0.35, 0, sin(TAU * k / 3.0) * 0.35)
		flash(Vector3.ZERO, Color(1.0, 0.9, 0.4), 0.45, 1.3, s)
	var tw := holder.create_tween(); tw.tween_property(holder, "rotation:y", TAU * 2.0, 1.3); tw.tween_callback(holder.queue_free)

func _ground_fire(at: Vector3, radius: float, dur: float) -> void:
	var holder := Node3D.new(); add_child(holder); holder.global_position = at
	var e := flip_emitter(holder, "fire_flip", Color(1, 1, 1), radius * 10.0, 1.1, 0.9, 1.0, 1.5, radius * 0.8)
	var pm: ParticleProcessMaterial = e.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING; pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = radius * 0.8; pm.emission_ring_inner_radius = 0.0; pm.emission_ring_height = 0.1
	var s := flip_emitter(holder, "smoke_flip", Color(0.18, 0.15, 0.13, 0.6), radius * 2.0, 2.0, 2.0, 1.0, 0.8, radius * 0.6, false)
	s.position.y = 1.2
	var l := light(Vector3.ZERO, Color(1.0, 0.5, 0.2), 3.0, radius * 2.5, 0.0, holder); l.position.y = 1.0
	_delay(dur, func():
		e.emitting = false; s.emitting = false
		var tw := l.create_tween(); tw.tween_property(l, "light_energy", 0.0, 0.8)
		get_tree().create_timer(2.5).timeout.connect(holder.queue_free))

## a danger zone on the ground: a circle that fills in until it goes off (step out!)
func telegraph(at: Vector3, radius: float, dur: float, school: String) -> void:
	at.y = WorldData.h(at.x, at.z)
	var col: Color = {"fire": Color(1.0, 0.2, 0.1), "frost": Color(0.3, 0.6, 1.0), "shadow": Color(0.6, 0.2, 1.0), "nature": Color(0.5, 0.9, 0.2)}.get(school, Color(1.0, 0.3, 0.1))
	var holder := Node3D.new(); add_child(holder); holder.global_position = at + Vector3(0, 0.1, 0)
	var edge := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(2, 2); q.orientation = PlaneMesh.FACE_Y
	var m := _add_mat(ring_tex, false).duplicate(); m.vertex_color_use_as_albedo = false; m.albedo_color = Color(col.r * 1.5, col.g * 1.5, col.b * 1.5, 0.9)
	q.material = m; edge.mesh = q; edge.scale = Vector3.ONE * radius; holder.add_child(edge)
	var fill := MeshInstance3D.new(); var q2 := QuadMesh.new(); q2.size = Vector2(2, 2); q2.orientation = PlaneMesh.FACE_Y
	var m2 := _add_mat(glow, false).duplicate(); m2.vertex_color_use_as_albedo = false; m2.albedo_color = Color(col.r, col.g, col.b, 0.55)
	q2.material = m2; fill.mesh = q2; fill.scale = Vector3.ONE * 0.05; holder.add_child(fill)
	var rn := MeshInstance3D.new(); var q3 := QuadMesh.new(); q3.size = Vector2(2, 2); q3.orientation = PlaneMesh.FACE_Y
	var m3 := _add_mat(rune if rune else ring_tex, false).duplicate(); m3.vertex_color_use_as_albedo = false; m3.albedo_color = Color(col.r * 1.2, col.g * 1.2, col.b * 1.2, 0.5)
	q3.material = m3; rn.mesh = q3; rn.scale = Vector3.ONE * radius * 0.98; holder.add_child(rn)
	for mi in [edge, fill, rn]: mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tw := holder.create_tween()
	tw.parallel().tween_property(fill, "scale", Vector3.ONE * radius * 1.25, dur)
	tw.parallel().tween_property(rn, "rotation:y", 1.5, dur)
	tw.tween_callback(func():
		match school:
			"fire":
				fire_hit(at + Vector3(0, 0.5, 0), radius * 0.35)
				puffs(at + Vector3(0, 0.3, 0), "fire_flip", Color(1, 1, 1), int(radius * 5), 1.6, 0.8, 6.0, 2.5, 60.0, Vector3.UP, true, radius * 0.7)
				decal(at, "scorch", Color(1, 1, 1, 0.9), radius * 2.0, 6.0, "scorch_emit", Color(1, 1, 1), 2.5)
				sound("fire_impact", at, 0.0)
			"shadow":
				shadow_hit(at + Vector3(0, 0.8, 0), radius * 0.4)
				puffs(at + Vector3(0, 0.3, 0), "wisp_flip", col, int(radius * 4), 2.0, 1.0, 5.0, 0.5, 60.0, Vector3.UP, true, radius * 0.7)
				sound("shadow", at, 0.0)
			"nature":
				puffs(at + Vector3(0, 0.3, 0), "smoke_flip", Color(0.35, 0.6, 0.15, 0.9), int(radius * 4), 2.0, 1.2, 5.0, 0.5, 60.0, Vector3.UP, false, radius * 0.7)
				streaks(at + Vector3(0, 0.3, 0), Color(0.6, 1.0, 0.3), 40, 9.0, 0.5, 0.8, -9.0, 60.0, Vector3.UP, radius * 0.6)
				sound("hit_2", at, 0.0)
			_:
				frost_hit(at + Vector3(0, 0.5, 0), Color(0.6, 0.88, 1.0), radius * 0.35)
				puffs(at + Vector3(0, 0.3, 0), "mist_flip", Color(0.6, 0.88, 1.0, 0.9), int(radius * 4), 2.0, 1.2, 6.0, 0.0, 60.0, Vector3.UP, true, radius * 0.7)
				decal(at, "frost_decal", Color(0.9, 0.97, 1.0, 0.9), radius * 2.2, 6.0)
				sound("ice_shatter", at, 0.0)
		ground_ring(at, col, radius * 0.4, radius * 1.3, 0.5)
		light(at + Vector3(0, 1.5, 0), col, 8.0, radius * 3.0, 0.5); shake(0.4, at))
	tw.tween_callback(holder.queue_free)

# ------------------------------------------------------------------ lingering effects (auras)

func aura_added(u: Node3D, id: String) -> void:
	var key := "%d:%s" % [u.get_instance_id(), id]
	if lingering.has(key) and is_instance_valid(lingering[key]): return
	var n: Node3D = null
	var base := id.trim_suffix("_burn").trim_suffix("_slow")
	if id.ends_with("_burn"):
		n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 0.7, 0)
		flip_emitter(n, "fire_flip", Color(1, 1, 1), 10.0, 0.7, 0.7, 0.6, 1.5, 0.35)
		emitter(n, Color(1.0, 0.6, 0.2), 10, 0.06, 0.8, 1.2, 1.0, spark, 0.35)
	elif id.ends_with("_slow") or id in ["frostbolt_slow", "cone_of_cold", "brine_bolt", "frost_lance"]:
		n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 0.3, 0)
		flip_emitter(n, "mist_flip", Color(0.6, 0.88, 1.0, 0.7), 6.0, 0.9, 1.2, 0.2, 0.1, 0.35)
		emitter(n, Color(0.85, 0.95, 1.0), 8, 0.07, 1.0, 0.3, -0.4, T("flare"), 0.4)
	else:
		match id:
			"frost_nova":
				n = _ice_block(u)
			"renewal", "radiance":
				n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 0.4, 0)
				emitter(n, Color(0.7, 1.0, 0.55), 6, 0.2, 1.6, 0.4, 0.5, T("leaf") if T("leaf") else glow, 0.5, false, false)
				emitter(n, Color(0.6, 1.0, 0.5), 8, 0.12, 1.4, 0.3, 0.6, T("flare"), 0.5)
			"ward_of_light", "ice_barrier", "divine_protection", "shield_wall":
				var c: Color = Color(0.6, 0.85, 1.0) if id in ["ice_barrier", "shield_wall"] else Color(1.0, 0.85, 0.45)
				n = MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 1.05; sm.height = 2.3
				sm.material = energy_mat(c, Color(1, 1, 0.9), 1.6, 2.5, 0.4, 0.0, 4.0)
				(n as MeshInstance3D).mesh = sm; (n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				u.add_child(n); n.position = Vector3(0, 1.0, 0)
				emitter(n, c.lightened(0.3), 6, 0.1, 1.2, 0.2, 0.2, T("flare"), 0.9)
				n.scale = Vector3.ONE * 0.2; n.create_tween().tween_property(n, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			"shadow_rot", "void_bolt":
				n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 1.0, 0)
				flip_emitter(n, "wisp_flip", Color(0.5, 0.2, 0.9), 5.0, 0.9, 1.0, 0.3, 0.4, 0.35)
				flip_emitter(n, "smoke_flip", Color(0.08, 0.03, 0.12, 0.6), 4.0, 0.8, 1.3, 0.3, 0.4, 0.35, false)
			"rend", "ravage":
				n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 1.0, 0)
				emitter(n, Color(0.6, 0.04, 0.03), 8, 0.08, 0.7, 0.3, -6.0, spark, 0.25, false, false)
			"inner_fire":
				n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 0.8, 0)
				emitter(n, Color(1.0, 0.65, 0.25), 8, 0.14, 1.2, 0.2, 0.8, T("flare"), 0.45)
			"frost_armor":
				n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 0.8, 0)
				flip_emitter(n, "mist_flip", Color(0.65, 0.9, 1.0, 0.45), 3.0, 0.9, 1.4, 0.1, -0.1, 0.45)
				emitter(n, Color(0.8, 0.95, 1.0), 6, 0.1, 1.2, 0.2, -0.3, T("flare"), 0.45)
			"recklessness", "enrage", "rootmaw_rage", "foremans_fury":
				n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 1.0, 0)
				flip_emitter(n, "fire_flip", Color(1.0, 0.35, 0.3), 6.0, 0.6, 0.6, 0.5, 1.2, 0.4)
			"arcane_power", "time_warp", "evocation":
				n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 1.0, 0)
				emitter(n, Color(0.8, 0.55, 1.0), 10, 0.12, 1.0, 0.3, 0.4, T("flare"), 0.5)
				flip_emitter(n, "wisp_flip", Color(0.7, 0.45, 1.0, 0.6), 3.0, 0.8, 1.2, 0.2, 0.2, 0.4)
			"entangle", "bone_prison":
				n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 0.2, 0)
				emitter(n, Color(0.5, 0.8, 0.3) if id == "entangle" else Color(0.9, 0.85, 0.75), 8, 0.2, 1.2, 0.2, 0.3, T("leaf") if id == "entangle" else glow, 0.4, false, id != "entangle")
			"silenced":
				n = Node3D.new(); u.add_child(n); n.position = Vector3(0, 2.1, 0)
				flip_emitter(n, "wisp_flip", Color(0.6, 0.3, 1.0), 4.0, 0.5, 0.9, 0.2, 0.2, 0.1)
	if n: lingering[key] = n

func aura_removed(u: Node3D, id: String) -> void:
	var key := "%d:%s" % [u.get_instance_id(), id]
	if not lingering.has(key): return
	var n: Node3D = lingering[key]; lingering.erase(key)
	if not is_instance_valid(n): return
	if id == "frost_nova":
		streaks(n.global_position + Vector3(0, 0.6, 0), Color(0.8, 0.95, 1.0), 24, 4.0, 0.4, 0.7, -8.0, 180.0, Vector3.UP, 0.3, null, "shard", 0.12)
	for c in n.find_children("*", "GPUParticles3D", true, false): c.emitting = false
	if n is GPUParticles3D: (n as GPUParticles3D).emitting = false
	var tw := n.create_tween(); tw.tween_property(n, "scale", Vector3.ONE * 0.01, 0.3); tw.tween_interval(1.0); tw.tween_callback(n.queue_free)

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
	flip_emitter(n, "mist_flip", Color(0.65, 0.9, 1.0, 0.5), 3.0, 0.9, 1.4, 0.1, -0.1, 0.4)
	n.scale = Vector3(1, 0.05, 1)
	n.create_tween().tween_property(n, "scale", Vector3.ONE, 0.18).set_ease(Tween.EASE_OUT)
	return n

# ------------------------------------------------------------------ level up

func level_up(u: Node3D) -> void:
	sound("level_up", u, 0.0, 0.0)
	var g := _feet(u)
	column(g, Color(1.0, 0.8, 0.35), Color(1, 1, 0.85), 1.3, 7.0, 1.6, 0.25)
	rays(g, Color(1.0, 0.88, 0.5), 7.0, 1.8)
	ground_glyph(g, "glyph_holy", Color(1.0, 0.85, 0.4), 0.8, 3.5, 1.8, 1.5)
	ground_ring(g, Color(1.0, 0.85, 0.4), 0.5, 5.0, 1.0)
	streaks(g + Vector3(0, 0.5, 0), Color(1.0, 0.88, 0.5), 60, 7.0, 0.7, 1.8, 2.0, 30.0, Vector3.UP, 0.8)
	light(g + Vector3(0, 2, 0), Color(1.0, 0.85, 0.5), 6.0, 10.0, 1.5)
