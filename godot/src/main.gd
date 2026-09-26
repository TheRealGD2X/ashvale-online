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
var hud: CanvasLayer
const STAGE := Vector3(3, 0, 16)      # where heroes are created and first step into the world
var save_t := 0.0

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
	# solid things need a physics frame before the walking grid can see them
	await get_tree().physics_frame
	await get_tree().physics_frame
	Nav.build(get_tree())
	add_child(load("res://src/world/spawns.gd").new())
	add_child(Fx.new())
	camera = OrbitCamera.new(); add_child(camera); camera.current = true
	add_child(load("res://src/camera/see_through.gd").new())
	print("world built in %d ms" % (Time.get_ticks_msec() - t0))
	if (args.has("shot") or args.has("play")) and not args.has("creator"):
		var cls: String = args.get("class", "warrior")
		var rng := RandomNumberGenerator.new(); rng.seed = int(args.get("seed", "5"))
		var ch := {"name": "Tester", "cls": cls, "level": int(args.get("level", "1")), "look": Avatar.random_look(rng, cls, args.get("sex", "m"))}
		_start_game(ch)
		if args.has("autoplay"): add_child(load("res://tools/autoplay.gd").new())
		if args.has("dbg"): add_child(load("res://tools/dbg.gd").new())
		if args.has("shot"): _shot()
	else:
		var cr = load("res://src/ui/creator.gd").new()
		cr.setup(STAGE, camera)
		cr.start.connect(_start_game)
		add_child(cr)
		if not args.has("hour"): DayNight.set_hour(17.3)
		if args.has("shot"): _shot()
	if args.has("leakcheck"): add_child(load("res://tools/leakcheck.gd").new()); DayNight.paused = false
	_check_kits()

func _start_game(ch: Dictionary) -> void:
	var p := Player.new(); p.setup_from(ch)
	add_child(p)
	var start: Vector3 = STAGE
	if args.has("hero"):
		var hz: PackedStringArray = args["hero"].split(","); start = Vector3(float(hz[0]), 0, float(hz[1]))
	elif ch.has("pos"): start = Vector3(float(ch["pos"][0]), 0, float(ch["pos"][1]))
	start = Nav.nearest_open(start); start.y = WorldData.h(start.x, start.z)
	p.global_position = start; p.home = start
	hero = p
	camera.target = p; camera.focus = start + Vector3(0, 1.35, 0); p.set_camera(camera)
	hud = load("res://src/ui/game_hud.gd").new(); add_child(hud)
	hud.bind(p, camera)

func _process(delta: float) -> void:
	save_t += delta
	if save_t > 60.0: save_t = 0.0; _save()

func _save() -> void:
	if hero is Player and not args.has("shot") and not args.has("play"):
		var d: Dictionary = hero.to_save(); d["look"] = Save.encode_look(d["look"]); Save.upsert(d)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _save()

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

## test: every Bestiary monster in a row beside the hero, playing a move (--lineup=Idle)
func _lineup() -> void:
	if args["lineup"] == "avatars":
		var rng := RandomNumberGenerator.new(); rng.seed = 7
		var i := 0
		for cls in ["warrior", "wizard", "cleric"]:
			for sex in ["m", "f"]:
				var a := Avatar.new(); a.look = Avatar.random_look(rng, cls, sex); add_child(a)
				var p: Vector3 = hero.global_position + Vector3((i - 2.5) * 1.3, 0, -3)
				p.y = WorldData.h(p.x, p.z); a.global_position = p
				i += 1
		return
	var d := "res://assets/licensed/monsters"
	if not DirAccess.dir_exists_absolute(d): return
	var files := Array(DirAccess.get_files_at(d)).filter(func(f): return f.ends_with(".glb"))
	for i in files.size():
		var m := Humanoid.new(); m.model = d + "/" + files[i]; add_child(m)
		var p: Vector3 = hero.global_position + Vector3((i - (files.size() - 1) * 0.5) * 2.2, 0, -4)
		p.y = WorldData.h(p.x, p.z); m.global_position = p
		var mv: String = args["lineup"]
		m.ready.connect(func(): m.play(mv if mv != "1" else "Idle"); m.anim.seek(0.3 * i, true))

## test scenes for screenshots: stand near a monster and use an ability (or a list: "fireball,frostbolt")
##   --demo=fireball --dist=12 --at=20 (frames after the cast to take the picture)
func _demo(what: String) -> void:
	var p: Player = hero
	await get_tree().process_frame
	var best: Unit = null; var bd := 1e9
	for u in get_tree().get_nodes_in_group("units"):
		if u is Monster and not u.dead:
			var d: float = u.global_position.distance_to(p.global_position)
			if d < bd: bd = d; best = u
	if best == null: return
	best.set_physics_process(false)
	var dist := float(args.get("dist", "10"))
	var dir: Vector3 = (p.global_position - best.global_position); dir.y = 0; dir = dir.normalized()
	var pos: Vector3 = best.global_position + dir * dist; pos.y = WorldData.h(pos.x, pos.z)
	p.global_position = pos
	p.target = best
	p.yaw = atan2(-dir.x, -dir.z); p.model.rotation.y = p.yaw
	best.yaw = atan2(dir.x, dir.z); best.model.rotation.y = best.yaw
	camera.focus = pos + Vector3(0, 1.35, 0)
	if args.has("level"): p.power = p.max_power
	for i in 8: await get_tree().process_frame
	best.set_physics_process(true)
	for id in what.split(","):
		p.power = p.max_power; p.gcd = 0.0; p.cds.clear()
		var why := p.use(id, best if not Abilities.LIST[id].get("helpful", false) else p)
		if why != "": print("demo: ", id, " -> ", why)
		var wait := int(Abilities.LIST[id].get("cast", 0.0) * 30.0) + 4
		for i in wait: await get_tree().process_frame
	for i in int(args.get("at", "6")): await get_tree().process_frame

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
		hero.model.has_anim(pz[0]); hero.model.anim.play(pz[0], 0.0); hero.model.anim.seek(float(pz[1]) if pz.size() > 1 else 0.0, true); hero.model.anim.speed_scale = 0.0
	if args.has("demo"): await _demo(args["demo"])
	var frames := int(args.get("frames", "40"))
	for i in frames: await get_tree().process_frame
	var t := Time.get_ticks_msec()
	await get_tree().process_frame
	print("frame ms: ", Time.get_ticks_msec() - t)
	var img := get_viewport().get_texture().get_image()
	img.save_png(args["shot"]); print("saved ", args["shot"])
	get_tree().quit()
