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
	if not args.has("shot") and await _import_if_needed(): return
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
	if args.has("leakcheck"): add_child(load("res://tools/leakcheck.gd").new()); DayNight.paused = false
	_check_kits()

## New art (e.g. freshly unpacked kits) must be imported by Godot before the game can use it. However
## the game was started, if any art file has no import record yet, run Godot's importer now and
## restart, so the world never loads half-empty.
func _import_if_needed() -> bool:
	var pending := 0
	for d in ["res://assets/village", "res://assets/nature", "res://assets/props", "res://assets/anims", "res://assets/characters", "res://assets/characters/textures"]:
		if not DirAccess.dir_exists_absolute(d): continue
		for f in DirAccess.get_files_at(d):
			var ext := f.get_extension().to_lower()
			if ext in ["gltf", "glb", "png"] and not FileAccess.file_exists(d + "/" + f + ".import"): pending += 1
	if pending == 0: return false
	# never loop: at most one automatic import every 10 minutes
	var mark := "user://last_auto_import.txt"
	if FileAccess.file_exists(mark) and Time.get_unix_time_from_system() - float(FileAccess.get_file_as_string(mark)) < 600.0:
		push_warning("%d art files still not imported after an automatic import" % pending); return false
	var fm := FileAccess.open(mark, FileAccess.WRITE); fm.store_string(str(Time.get_unix_time_from_system())); fm.close()
	var cl := CanvasLayer.new(); add_child(cl)
	var bg := ColorRect.new(); bg.color = Color(0.06, 0.07, 0.06); bg.set_anchors_preset(Control.PRESET_FULL_RECT); cl.add_child(bg)
	var l := Label.new(); l.text = "Preparing %d pieces of new art for Ashvale...\nThis happens once and takes a minute or two. The game restarts by itself." % pending
	l.add_theme_font_size_override("font_size", 26); l.set_anchors_preset(Control.PRESET_CENTER); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(-420, -40); l.size = Vector2(840, 80); cl.add_child(l)
	for i in 3: await get_tree().process_frame
	var out := []
	OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--import"], out, true)
	OS.set_restart_on_exit(true, OS.get_cmdline_args())
	get_tree().quit()
	return true

## the art kits are unpacked from Downloads by tools/setup_godot.ps1; say so plainly if they're missing
func _check_kits() -> void:
	var missing := []
	for k in ["village", "nature", "props"]:
		if not DirAccess.dir_exists_absolute("res://assets/" + k): missing.append(k)
	if not FileAccess.file_exists("res://assets/anims/UAL1.glb"): missing.append("animations")
	if missing.is_empty(): return
	var cl := CanvasLayer.new(); cl.layer = 50; add_child(cl)
	var p := PanelContainer.new(); cl.add_child(p); p.position = Vector2(40, 120)
	var l := Label.new(); p.add_child(l); l.add_theme_font_size_override("font_size", 22)
	l.text = "Some art is missing (%s).\nClose the game and double-click 'Play Ashvale.bat' again:\nit unpacks the Quaternius zips from your Downloads folder." % ", ".join(missing)
	push_warning(l.text)

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
