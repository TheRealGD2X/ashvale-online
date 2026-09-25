class_name DayNight extends Node3D
## Sun, moon, sky, ambient light and air through a whole day. A full day lasts DAY_MINUTES real
## minutes; the hour can be set directly (DayNight.set_hour) and T speeds time up while held.
## Other things read DayNight.night (0 by day, 1 at night) to light lamps, bring out fireflies, etc.

const DAY_MINUTES := 36.0
static var hour := 9.5
static var night := 0.0            # 0 day .. 1 night (smooth)
static var dusk := 0.0             # 1 at sunrise / sunset
static var time_s := 0.0           # game seconds since start (clouds, wind)
static var paused := false

var sun: DirectionalLight3D
var moon: DirectionalLight3D
var env: Environment
var sky_mat: ShaderMaterial
var fast := false
var hq := true

static func set_hour(h: float) -> void: hour = fposmod(h, 24.0)

func _ready() -> void:
	sun = DirectionalLight3D.new(); sun.name = "Sun"; add_child(sun)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 90.0
	sun.directional_shadow_split_1 = 0.06; sun.directional_shadow_split_2 = 0.16; sun.directional_shadow_split_3 = 0.4
	sun.directional_shadow_blend_splits = true
	sun.shadow_blur = 1.2
	sun.light_angular_distance = 0.8
	sun.shadow_bias = 0.03; sun.shadow_normal_bias = 1.2
	sun.light_volumetric_fog_energy = 1.4
	moon = DirectionalLight3D.new(); moon.name = "Moon"; add_child(moon)
	moon.shadow_enabled = true; moon.directional_shadow_max_distance = 80.0; moon.shadow_blur = 2.0
	moon.light_color = Color(0.62, 0.72, 1.0); moon.light_volumetric_fog_energy = 0.6
	sky_mat = ShaderMaterial.new(); sky_mat.shader = load("res://shaders/sky.gdshader")
	var cn := FastNoiseLite.new(); cn.noise_type = FastNoiseLite.TYPE_PERLIN; cn.frequency = 1.0 / 70.0; cn.fractal_octaves = 4; cn.seed = 9
	var cimg := cn.get_seamless_image(512, 512); cimg.generate_mipmaps()
	sky_mat.set_shader_parameter("cloud_noise", ImageTexture.create_from_image(cimg))
	var sky := Sky.new(); sky.sky_material = sky_mat; sky.radiance_size = Sky.RADIANCE_SIZE_256
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	env = Environment.new()
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX; env.tonemap_exposure = 1.0
	env.ssao_enabled = true; env.ssao_radius = 1.4; env.ssao_intensity = 1.8; env.ssao_power = 1.4; env.ssao_detail = 0.6
	env.ssil_enabled = false; env.ssil_radius = 4.0; env.ssil_intensity = 0.8
	env.sdfgi_enabled = hq; env.sdfgi_use_occlusion = true; env.sdfgi_cascades = 3; env.sdfgi_min_cell_size = 0.3; env.sdfgi_energy = 0.9
	env.glow_enabled = true; env.glow_intensity = 0.55; env.glow_bloom = 0.04; env.glow_hdr_threshold = 1.1; env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true; env.fog_mode = Environment.FOG_MODE_DEPTH; env.fog_depth_begin = 30.0; env.fog_depth_end = 260.0; env.fog_depth_curve = 1.6
	env.fog_aerial_perspective = 0.55; env.fog_sky_affect = 0.0
	env.volumetric_fog_enabled = hq; env.volumetric_fog_density = 0.004; env.volumetric_fog_anisotropy = 0.55; env.volumetric_fog_length = 90.0
	env.volumetric_fog_detail_spread = 2.0; env.volumetric_fog_gi_inject = 0.6; env.volumetric_fog_ambient_inject = 0.3
	env.adjustment_enabled = true; env.adjustment_saturation = 1.0; env.adjustment_contrast = 1.04
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	_apply()

func set_quality(high: bool) -> void:
	hq = high
	if env:
		env.sdfgi_enabled = high; env.volumetric_fog_enabled = high

func _process(delta: float) -> void:
	fast = Input.is_physical_key_pressed(KEY_T)
	if not paused:
		var rate := 24.0 / (DAY_MINUTES * 60.0) * (90.0 if fast else 1.0)   # game hours per real second
		hour = fposmod(hour + delta * rate, 24.0)
		time_s += delta * (30.0 if fast else 1.0)
	_apply()
	RenderingServer.global_shader_parameter_set("wind_time", time_s)
	var hero := get_tree().get_first_node_in_group("hero") as Node3D
	if hero: RenderingServer.global_shader_parameter_set("hero_pos", hero.global_position)

static func _curve(x: float, pts: Array) -> Variant:
	# pts: [[x, value], ...] sorted; linear between points
	if x <= pts[0][0]: return pts[0][1]
	for i in pts.size() - 1:
		if x <= pts[i + 1][0]:
			var t: float = (x - pts[i][0]) / (pts[i + 1][0] - pts[i][0])
			return lerp(pts[i][1], pts[i + 1][1], smoothstep(0.0, 1.0, t))
	return pts[-1][1]

func _apply() -> void:
	# the sun: rises in the east (+x) at 6, highest at 13, sets in the west at 20, arcing across the south
	var a := (hour - 6.0) / 14.0 * PI
	var to_sun := Vector3(cos(a), sin(a) * 0.86, sin(a) * 0.5 + 0.12).normalized()
	var elev := to_sun.y
	day_values(elev)
	sun.global_transform = Transform3D(Basis.looking_at(-to_sun, Vector3.FORWARD if absf(to_sun.y) > 0.99 else Vector3.UP), Vector3.ZERO)
	var mo := -to_sun; mo.y = absf(mo.y) * 0.9 + 0.25; mo = mo.normalized()   # the moon rides high opposite the sun
	moon.global_transform = Transform3D(Basis.looking_at(-mo, Vector3.UP), Vector3.ZERO)
	var sun_col: Color = _curve(elev, [[-0.05, Color(1.0, 0.45, 0.25)], [0.08, Color(1.0, 0.62, 0.36)], [0.25, Color(1.0, 0.86, 0.68)], [0.5, Color(1.0, 0.96, 0.9)]])
	sun.light_color = sun_col
	sun.light_energy = _curve(elev, [[-0.06, 0.0], [0.02, 0.35], [0.15, 1.3], [0.4, 1.9]])
	sun.visible = elev > -0.07
	sun.shadow_enabled = elev > -0.02
	moon.light_energy = 0.32 * night
	moon.visible = night > 0.02
	env.ambient_light_energy = _curve(elev, [[-0.3, 0.35], [0.0, 0.55], [0.2, 0.95], [0.5, 1.0]])
	env.ambient_light_sky_contribution = 1.0
	env.tonemap_exposure = _curve(elev, [[-0.3, 1.5], [0.0, 1.15], [0.3, 0.95]])
	var fog: Color = _curve(elev, [[-0.3, Color(0.05, 0.07, 0.13)], [-0.02, Color(0.3, 0.26, 0.34)], [0.08, Color(0.95, 0.66, 0.46)], [0.3, Color(0.72, 0.82, 0.93)]])
	env.fog_light_color = fog
	env.fog_density = 0.0015
	env.volumetric_fog_albedo = fog.lerp(Color.WHITE, 0.5)
	# mist gathers at dawn and in the evening
	env.volumetric_fog_density = 0.003 + 0.012 * dusk + 0.004 * night
	sky_mat.set_shader_parameter("day", 1.0 - night)
	sky_mat.set_shader_parameter("dusk", dusk)
	sky_mat.set_shader_parameter("time_s", time_s)

static func day_values(elev: float) -> void:
	night = 1.0 - smoothstep(-0.12, 0.1, elev)
	dusk = exp(-pow((elev - 0.02) / 0.14, 2.0))

## the direction toward the sun right now (for tools)
static func sun_dir() -> Vector3:
	var a := (hour - 6.0) / 14.0 * PI
	return Vector3(cos(a), sin(a) * 0.86, sin(a) * 0.5 + 0.12).normalized()
