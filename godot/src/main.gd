extends Node3D
## Ashvale: builds the world and starts play.
##
## Command-line options (after "--"), used by the test tools:
##   --shot=out.png      render, save a screenshot, quit
##   --hour=17.5         time of day
##   --cam=x,y,z,tx,ty,tz  a fixed camera (position, look-at target); default follows the hero
##   --frames=40         frames to settle before a shot
##   --lite              skip the costliest lighting (GI, volumetric fog), for slow test machines
##   --hero=x,z          where the hero starts

var args := {}
var day_night: DayNight
var camera: OrbitCamera
var hero: Node3D

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if args.has("shot"):   # a watchdog: a broken build must not hang the test machine
		get_tree().create_timer(float(args.get("timeout", "420")), true, false, true).timeout.connect(func(): print("TIMEOUT"); get_tree().quit(1))
	if args.has("hour"): DayNight.set_hour(float(args["hour"]))
	var t0 := Time.get_ticks_msec()
	WorldData.lite = args.has("lite")
	if WorldData.lite: RenderingServer.directional_shadow_atlas_set_size(4096, true)
	WorldData.bake()
	print("world baked in %d ms" % (Time.get_ticks_msec() - t0))
	day_night = DayNight.new(); day_night.hq = not args.has("lite"); add_child(day_night)
	if args.has("gi"): day_night.env.sdfgi_enabled = true; day_night.env.ssil_enabled = true
	if args.has("shot"): DayNight.paused = true
	add_child(Terrain.new())
	for s in ["res://src/world/village.gd", "res://src/world/water.gd", "res://src/world/vegetation.gd", "res://src/world/life.gd"]:
		if ResourceLoader.exists(s):
			var n: Node = load(s).new(); add_child(n)
	var start := Vector3(3, 0, 16)
	if args.has("hero"):
		var hz: PackedStringArray = args["hero"].split(","); start = Vector3(float(hz[0]), 0, float(hz[1]))
	start.y = WorldData.h(start.x, start.z)
	if ResourceLoader.exists("res://src/actors/hero.gd"):
		hero = load("res://src/actors/hero.gd").new(); add_child(hero); hero.global_position = start
	else:
		hero = Node3D.new(); add_child(hero); hero.global_position = start
	camera = OrbitCamera.new(); camera.target = hero; add_child(camera); camera.current = true
	if hero.has_method("set_camera"): hero.set_camera(camera)
	if ResourceLoader.exists("res://src/ui/hud.gd") and not args.has("shot"): add_child(load("res://src/ui/hud.gd").new())
	print("world built in %d ms" % (Time.get_ticks_msec() - t0))
	if args.has("shot"): _shot()

func _shot() -> void:
	if args.has("cam"):
		var c: PackedStringArray = args["cam"].split(",")
		camera.set_process(false)
		camera.global_position = Vector3(float(c[0]), float(c[1]), float(c[2]))
		camera.look_at(Vector3(float(c[3]), float(c[4]), float(c[5])), Vector3.UP)
	if args.has("yaw"): camera.yaw = deg_to_rad(float(args["yaw"]))
	if args.has("pitch"): camera.pitch = deg_to_rad(float(args["pitch"]))
	if args.has("dist"): camera.dist = float(args["dist"]); camera.want_dist = camera.dist
	if args.has("pose") and hero is CharacterBody3D:
		await get_tree().process_frame
		var pz: PackedStringArray = args["pose"].split(":")
		hero.set_physics_process(false)
		hero.model.rotation.y = deg_to_rad(float(args.get("face", "0")))
		hero.model.anim.play(pz[0], 0.0); hero.model.anim.seek(float(pz[1]) if pz.size() > 1 else 0.0, true); hero.model.anim.speed_scale = 0.0
	var frames := int(args.get("frames", "40"))
	for i in frames: await get_tree().process_frame
	var t := Time.get_ticks_msec()
	await get_tree().process_frame
	print("frame ms: ", Time.get_ticks_msec() - t)
	var img := get_viewport().get_texture().get_image()
	img.save_png(args["shot"]); print("saved ", args["shot"])
	get_tree().quit()
