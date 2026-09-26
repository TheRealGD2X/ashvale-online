extends Node
## Frame-time benchmark: --play --bench[=seconds] [--zone=...]. Walks the hero around, then prints
## average/worst frame time, CPU script time, GPU time, draw calls and what's in the scene, and quits.

var t := 0.0
var warm := 4.0
var dur := 12.0
var frames: PackedFloat32Array = []
var gpu: PackedFloat32Array = []
var cpu: PackedFloat32Array = []
var proc: PackedFloat32Array = []
var phys: PackedFloat32Array = []
var draws: PackedFloat32Array = []
var prims: PackedFloat32Array = []

func _ready() -> void:
	var a: String = get_parent().args.get("bench", "1")
	if a != "1": dur = float(a)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	# --off=grass,veg,shadow,ssao,glow,gi,fog,units : switch one thing off to measure what it costs
	var off: PackedStringArray = String(get_parent().args.get("off", "")).split(",", false)
	var root := get_tree().current_scene
	for n in root.find_children("*", "", true, false):
		if "grass" in off and n is Grass: n.visible = false
		if "veg" in off and n is MultiMeshInstance3D and not (n.get_parent() is Grass): n.visible = false
		if "meshes" in off and n is MeshInstance3D and not n.get_parent() is Skeleton3D: n.visible = false
		if "shadow" in off and n is Light3D: n.shadow_enabled = false
		if "lights" in off and (n is OmniLight3D or n is SpotLight3D): n.visible = false
		if "particles" in off and (n is GPUParticles3D or n is CPUParticles3D): n.visible = false
	var we: WorldEnvironment = null
	for n in root.find_children("*", "WorldEnvironment", true, false): we = n
	if we:
		var env := we.environment
		if "ssao" in off: env.ssao_enabled = false
		if "glow" in off: env.glow_enabled = false
		if "gi" in off: env.sdfgi_enabled = false
		if "fog" in off: env.volumetric_fog_enabled = false
		if "ssr" in off: env.ssr_enabled = false
	if "scale" in get_parent().args: get_viewport().scaling_3d_scale = float(get_parent().args["scale"])

func _process(delta: float) -> void:
	t += delta
	var hero: Node3D = get_parent().hero
	# keep the hero walking in a slow circle, so streaming, grass and the camera all work
	if hero is Player and not hero.dead and int(t * 2.0) % 6 == 0:
		var ang := t * 0.25
		var goal: Vector3 = hero.home + Vector3(cos(ang), 0, sin(ang)) * 14.0
		hero.move_to(goal)
	if t < warm: return
	var vp := get_viewport().get_viewport_rid()
	frames.append(delta * 1000.0)
	gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vp))
	cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(vp))
	proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	phys.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	prims.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	if t >= warm + dur: _report(); get_tree().quit()

func _avg(a: PackedFloat32Array) -> float:
	var s := 0.0
	for v in a: s += v
	return s / max(1, a.size())

func _p(a: PackedFloat32Array, q: float) -> float:
	var b := a.duplicate(); b.sort()
	return b[int(clamp(q * (b.size() - 1), 0, b.size() - 1))]

func _report() -> void:
	var sz := get_viewport().get_visible_rect().size
	print("BENCH zone=%s window=%dx%d render_scale=%.2f frames=%d" % [get_parent().zone, sz.x, sz.y, get_viewport().scaling_3d_scale, frames.size()])
	print("BENCH frame ms avg %.2f  p95 %.2f  worst %.2f  (%.0f fps)" % [_avg(frames), _p(frames, 0.95), _p(frames, 1.0), 1000.0 / _avg(frames)])
	print("BENCH gpu ms %.2f  render-cpu ms %.2f  process ms %.2f  physics ms %.2f" % [_avg(gpu), _avg(cpu), _avg(proc), _avg(phys)])
	print("BENCH draw calls %.0f  primitives %.0f  objects %d  nodes %d" % [_avg(draws), _avg(prims), Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	var groups := {}
	for n in get_tree().root.find_children("*", "", true, false):
		var k := n.get_class()
		if n.get_script(): k = n.get_script().resource_path.get_file()
		groups[k] = groups.get(k, 0) + 1
	var keys := groups.keys(); keys.sort_custom(func(x, y): return groups[x] > groups[y])
	var line := "BENCH top nodes:"
	for i in min(14, keys.size()): line += " %s=%d" % [keys[i], groups[keys[i]]]
	print(line)
