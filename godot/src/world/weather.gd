class_name Weather extends Node3D
## Ashvale's weather: mostly fair, sometimes clouding over, now and then a soft rain that darkens
## the sky, mists the distance and patters on everything (with its own sound). It changes every
## few minutes, smoothly. --weather=rain|clear pins it (for screenshots).

var state := "clear"             # clear | cloudy | rain
var target_cloud := 0.1
var target_rain := 0.0
var next_t := 240.0
var rain_fx: GPUParticles3D
var rain_snd: AudioStreamPlayer
var rng := RandomNumberGenerator.new()
var pinned := false

func _ready() -> void:
	add_to_group("weather")
	rng.randomize()
	var args: Dictionary = get_parent().args if "args" in get_parent() else {}
	if args.has("weather"): set_state(args["weather"]); pinned = true
	_make_rain()
	# the Ash Slopes: ash drifts down all the time instead of rain, under a hazy sky
	if WorldData.Z.get("ashfall", false):
		pinned = true; target_cloud = 0.55; target_rain = 0.0; DayNight.cloud = 0.55; DayNight.rain = 0.0
		var pm: ParticleProcessMaterial = rain_fx.process_material
		pm.initial_velocity_min = 0.6; pm.initial_velocity_max = 1.2; pm.gravity = Vector3(0.3, -0.8, 0.1); pm.spread = 40.0
		rain_fx.lifetime = 9.0; rain_fx.amount = 2500
		var q := QuadMesh.new(); q.size = Vector2(0.06, 0.06)
		var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.75, 0.72, 0.68, 0.7); m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; q.material = m
		rain_fx.draw_pass_1 = q
		set_meta("ash", true)

func set_state(s: String) -> void:
	state = s
	match s:
		"clear": target_cloud = rng.randf_range(0.0, 0.2); target_rain = 0.0
		"cloudy": target_cloud = rng.randf_range(0.55, 0.8); target_rain = 0.0
		"rain": target_cloud = 1.0; target_rain = rng.randf_range(0.6, 1.0)
	if pinned or DayNight.paused: DayNight.cloud = target_cloud; DayNight.rain = target_rain

func _process(delta: float) -> void:
	if not pinned:
		next_t -= delta
		if next_t <= 0.0:
			var r := rng.randf()
			set_state("clear" if r < 0.55 else ("cloudy" if r < 0.8 else "rain"))
			next_t = rng.randf_range(180.0, 480.0) if state != "rain" else rng.randf_range(90.0, 200.0)
	DayNight.cloud = move_toward(DayNight.cloud, target_cloud, delta * 0.02)
	# rain starts only once it's properly grey, and stops before the clouds go
	var want_rain := target_rain if DayNight.cloud > 0.8 else 0.0
	DayNight.rain = move_toward(DayNight.rain, want_rain, delta * 0.05)
	var cam := get_viewport().get_camera_3d()
	if cam and rain_fx:
		rain_fx.global_position = cam.global_position + Vector3(0, 6, 0) - cam.global_basis.z * 8.0
		rain_fx.amount_ratio = DayNight.rain if not has_meta("ash") else 1.0
		rain_fx.emitting = DayNight.rain > 0.02 or has_meta("ash")

	if rain_snd:
		rain_snd.volume_db = linear_to_db(maxf(DayNight.rain, 0.0001)) - 8.0
		if DayNight.rain > 0.02 and not rain_snd.playing: rain_snd.play()
		elif DayNight.rain <= 0.02 and rain_snd.playing: rain_snd.stop()

func _make_rain() -> void:
	rain_fx = GPUParticles3D.new(); rain_fx.amount = 5000; rain_fx.lifetime = 1.1; rain_fx.emitting = false
	rain_fx.visibility_aabb = AABB(Vector3(-30, -30, -30), Vector3(60, 60, 60))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; pm.emission_box_extents = Vector3(26, 4, 26)
	pm.direction = Vector3(0.12, -1, 0.05); pm.spread = 2.0
	pm.initial_velocity_min = 16.0; pm.initial_velocity_max = 20.0; pm.gravity = Vector3(0, -9, 0)
	pm.collision_mode = ParticleProcessMaterial.COLLISION_DISABLED
	rain_fx.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.018, 0.55)
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.75, 0.8, 0.9, 0.35); m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y; m.billboard_keep_scale = true
	q.material = m; rain_fx.draw_pass_1 = q
	add_child(rain_fx)
	var path := "res://assets/sfx/rain.wav"
	if ResourceLoader.exists(path):
		rain_snd = AudioStreamPlayer.new(); var st: AudioStream = load(path)
		if st is AudioStreamWAV: (st as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD; (st as AudioStreamWAV).loop_end = int(st.get_length() * (st as AudioStreamWAV).mix_rate)
		rain_snd.stream = st; add_child(rain_snd)
