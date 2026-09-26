extends Node3D
## The people and small creatures that make Ashvale feel alive.
##  - villagers with something to do: merchants at their stalls, neighbours chatting, someone
##    resting on a bench, a woodcutter at the forest edge, a gardener, and walkers going from
##    door to door and to the square; most head home when night falls
##  - butterflies over the meadows by day, fireflies by night, birds wheeling overhead

const MODELS := ["villager_m1", "villager_m2", "villager_f1", "villager_f2", "ranger_m2"]
const HAIR := [Color(0.08, 0.06, 0.05), Color(0.32, 0.2, 0.1), Color(0.55, 0.36, 0.18), Color(0.8, 0.62, 0.36), Color(0.6, 0.6, 0.58), Color(0.45, 0.14, 0.06)]
var rng := RandomNumberGenerator.new()
var villagers: Array[Villager] = []

class Villager extends Node3D:
	var body: Humanoid
	var job := "walk"            # walk | stay
	var loop_anim := "Idle"
	var dest := Vector3.INF
	var speed := 1.25
	var wait := 0.0
	var home := Vector3.ZERO
	var night_owl := false
	var hidden_until := 0.0
	var life: Node
	var yaw := 0.0

	func setup(model: String, hair: Color) -> void:
		if Avatar.available():
			# townsfolk dressed from the outfit kit: mostly peasants, a few nobles and rangers
			var r := RandomNumberGenerator.new(); r.randomize()
			var kind: String = ["peasant", "peasant", "peasant", "noble_", "ranger"][r.randi() % 5]
			var a := Avatar.new()
			a.look = Avatar.random_look(r, "cleric" if kind == "noble_" else kind)
			if WorldData.lite: a.look["tint"] = {}      # fewer textures on slow test machines
			if kind == "noble_": a.look["gear"].erase("neck")
			body = a
		else:
			body = Humanoid.new(); body.model = model; body.hair_color = hair
		add_child(body)

	func face(dir: Vector3) -> void:
		if dir.length() > 0.01: yaw = atan2(dir.x, dir.z); body.rotation.y = yaw

	func _process(delta: float) -> void:
		var n := DayNight.night
		# at night most folk are indoors
		var should_hide := n > 0.7 and not night_owl
		if should_hide != (not visible):
			if should_hide: visible = false; set_meta("gone", true)
			else: visible = true; global_position = home; dest = Vector3.INF
		if not visible: return
		if job == "stay":
			body.play(loop_anim); return
		if wait > 0.0:
			wait -= delta; body.play("Idle"); return
		if dest == Vector3.INF:
			dest = life.pick_destination(self); return
		var d := dest - global_position; d.y = 0
		if d.length() < 0.4:
			dest = Vector3.INF; wait = randf_range(2.0, 9.0)
			if randf() < 0.3: body.play_once(["Idle_Talking", "Interact", "Yes", "Idle_No"][randi() % 4])
			return
		var step := d.normalized() * speed * delta
		global_position += step
		global_position.y = WorldData.h(global_position.x, global_position.z)
		yaw = lerp_angle(yaw, atan2(d.x, d.z), 1.0 - exp(-delta * 6.0)); body.rotation.y = yaw
		body.play("Walk", speed / 1.3)

func _ready() -> void:
	rng.seed = 99
	await get_tree().process_frame     # let the village register its doors first
	var village := get_tree().get_first_node_in_group("village")
	var doors: Array = village.doors if village else []
	# people with a place to be
	_stay(Vector3(-7.5, 0, -3.2), PI + 0.9, "Idle_FoldArms")        # stall keeper
	_stay(Vector3(6.4, 0, -4.4), PI - 0.8, "Idle_Talking")          # another
	_stay(Vector3(-1.6, 0, 8.8), 1.2, "Idle_Talking")               # two neighbours chatting
	_stay(Vector3(-0.4, 0, 9.6), 1.2 + PI, "Idle_Talking")
	_stay(Vector3(3.2, 0.0, 5.8), PI, "Sitting_Idle")               # resting on the bench
	var wc := _stay(Vector3(9.2, 0, -32.0), 0.3, "TreeChopping")    # woodcutter at the forest edge
	wc.body.hold("res://assets/props/Axe_Bronze.gltf", "hand_r", Vector3(0.02, 0.08, 0.0), Vector3(0, 0, 90))
	_stay(Vector3(-38.0, 0, 20.5), 2.6, "Farm_Watering")              # gardener behind a cottage
	_stay(Vector3(-36.0, 0, 21.5), 2.0, "Farm_Harvest")
	# walkers
	for i in 9:
		var v := _make()
		v.job = "walk"; v.speed = rng.randf_range(1.05, 1.45)
		v.home = doors[rng.randi() % doors.size()] if doors.size() else Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8))
		v.global_position = _ring_point(); v.night_owl = i == 0
	_critters()

func _make() -> Villager:
	var v := Villager.new(); v.life = self
	add_child(v)
	v.setup(MODELS[rng.randi() % MODELS.size()], HAIR[rng.randi() % HAIR.size()])
	villagers.append(v)
	return v

func _stay(p: Vector3, yaw: float, anim: String) -> Villager:
	var v := _make()
	p.y = WorldData.h(p.x, p.z) + p.y
	v.global_position = p; v.job = "stay"; v.loop_anim = anim; v.body.rotation.y = yaw; v.home = p
	return v

func _ring_point() -> Vector3:
	var a := rng.randf() * TAU; var r := rng.randf_range(5.5, 11.0)
	var p := Vector3(cos(a) * r, 0, sin(a) * r); p.y = WorldData.h(p.x, p.z)
	return p

func pick_destination(v: Villager) -> Vector3:
	var village := get_tree().get_first_node_in_group("village")
	var r := rng.randf()
	if DayNight.night > 0.45 and not v.night_owl: return v.home
	if r < 0.55 or not village: return _ring_point()
	var doors: Array = village.doors
	var d: Vector3 = doors[rng.randi() % doors.size()]
	# stop on the doorstep, not inside the wall
	return d

# ------------------------------------------------------------------ small creatures
var butterflies: GPUParticles3D
var fireflies: GPUParticles3D

func _critters() -> void:
	butterflies = _swarm(60, 16.0, 0.9, Color(1, 1, 1), false)
	fireflies = _swarm(160, 22.0, 0.9, Color(1.0, 0.9, 0.45), true)

func _swarm(n: int, radius: float, height: float, col: Color, glow: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new(); add_child(p)
	p.amount = n; p.lifetime = 14.0; p.preprocess = 14.0; p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-40, -10, -40), Vector3(80, 30, 80))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; pm.emission_box_extents = Vector3(radius, height, radius)
	pm.direction = Vector3(0, 0.2, 0); pm.spread = 180.0; pm.initial_velocity_min = 0.2; pm.initial_velocity_max = 0.6
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true; pm.turbulence_noise_strength = 1.6; pm.turbulence_noise_scale = 3.0; pm.turbulence_influence_min = 0.1; pm.turbulence_influence_max = 0.25
	var g := Gradient.new(); g.set_color(0, Color(col, 0.0)); g.add_point(0.15, Color(col, 1.0)); g.add_point(0.85, Color(col, 1.0)); g.set_color(g.get_point_count() - 1, Color(col, 0.0))
	var gt := GradientTexture1D.new(); gt.gradient = g; pm.color_ramp = gt
	if not glow:
		pm.hue_variation_min = -0.5; pm.hue_variation_max = 0.5
		pm.color = Color(1.0, 0.75, 0.3)
	p.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.14, 0.1) if not glow else Vector2(0.09, 0.09)
	var m := ShaderMaterial.new(); m.shader = load("res://shaders/critter.gdshader")
	m.set_shader_parameter("glow", glow)
	q.material = m; p.draw_pass_1 = q
	return p

func _process(_d: float) -> void:
	var hero := get_tree().get_first_node_in_group("hero") as Node3D
	var c := hero.global_position if hero else Vector3.ZERO
	var n := DayNight.night
	if butterflies:
		butterflies.global_position = c + Vector3(0, 1.0, 0); butterflies.emitting = n < 0.4; butterflies.visible = n < 0.6
		fireflies.global_position = c + Vector3(0, 1.2, 0); fireflies.emitting = n > 0.5; fireflies.visible = n > 0.3
