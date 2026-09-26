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
var zone := "ashvale"
var loading: CanvasLayer
var exit_warned := {}
static var travel := {}              # set before reloading into another zone: {"ch", "zone", "pos", "party"}

const BUILDERS := {"village": "res://src/world/village.gd", "landmarks": "res://src/world/landmarks.gd", "water": "res://src/world/water.gd",
	"vegetation": "res://src/world/vegetation.gd", "life": "res://src/world/life.gd", "camp": "res://src/world/camp.gd", "mine": "res://src/world/mine.gd", "marsh": "res://src/world/marsh.gd", "temple": "res://src/world/temple.gd", "highland": "res://src/world/highland.gd", "varn": "res://src/world/varn.gd",
	"coast": "res://src/world/coast.gd", "ember": "res://src/world/ember.gd", "frost": "res://src/world/frost.gd", "scar": "res://src/world/scar.gd"}

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if args.has("shot"):   # a watchdog: a broken build must not hang the test machine
		get_tree().create_timer(float(args.get("timeout", "420")), true, false, true).timeout.connect(func(): print("TIMEOUT"); get_tree().quit(1))
	if not args.has("shot") and travel.is_empty() and await _import_if_needed(): return
	zone = travel.get("zone", args.get("zone", "ashvale"))
	WorldData.use_zone(zone)
	var Z: Dictionary = WorldData.Z
	if not travel.is_empty(): await _show_loading(Z)
	if args.has("hour"): DayNight.set_hour(float(args["hour"]))
	var t0 := Time.get_ticks_msec()
	WorldData.lite = args.has("lite")
	if WorldData.lite: RenderingServer.directional_shadow_atlas_set_size(4096, true)
	WorldData.bake()
	print("world baked in %d ms (%s)" % [Time.get_ticks_msec() - t0, zone])
	day_night = DayNight.new(); day_night.hq = not args.has("lite"); day_night.cave = Z.get("sky", "day") == "cave"; add_child(day_night)
	if args.has("gi"): day_night.env.sdfgi_enabled = true; day_night.env.ssil_enabled = true
	if args.has("shot"): DayNight.paused = true
	add_child(Terrain.new())
	for b in Z.get("builders", []):
		var path: String = BUILDERS.get(b, "")
		if path != "" and ResourceLoader.exists(path):
			var n: Node = load(path).new(); add_child(n)
	_signposts(Z)
	for st in Z.get("stations", []):
		var s := Station.new(); s.setup(st[0]); add_child(s)
		s.position = Vector3(st[1].x, WorldData.h(st[1].x, st[1].y), st[1].y); s.rotation.y = st[2]
		WorldData.clear_disc(st[1], 2.0, 0.5)

	# solid things need a physics frame before the walking grid can see them
	await get_tree().physics_frame
	await get_tree().physics_frame
	Nav.build(get_tree())
	add_child(load("res://src/world/spawns.gd").new())
	add_child(Fx.new())
	if not Z.get("dungeon", false): add_child(Market.new())

	if Z.get("sky", "day") != "cave": add_child(Weather.new())
	if not args.has("shot"): add_child(Soundscape.new())
	camera = OrbitCamera.new(); add_child(camera); camera.current = true
	add_child(load("res://src/camera/see_through.gd").new())
	print("world built in %d ms" % (Time.get_ticks_msec() - t0))
	if not travel.is_empty():
		var tr := travel; travel = {}
		_start_game(tr["ch"], tr)
		if loading: loading.queue_free()
		if args.has("questtest"): add_child(load("res://tools/questtest.gd").new())
		if args.has("shot"): _shot()
		return

	if (args.has("shot") or args.has("play")) and not args.has("creator"):
		var cls: String = args.get("class", "warrior")
		var rng := RandomNumberGenerator.new(); rng.seed = int(args.get("seed", "5"))
		var ch := {"name": "Tester", "cls": cls, "level": int(args.get("level", "1")), "look": Avatar.random_look(rng, cls, args.get("sex", "m")), "zone": zone}
		# tests can start further along: --done=ashvale marks the province's quests done
		# (or --done=mirewood: every quest given in that zone and the ones before it on the road)
		var road := ["ashvale", "hollow", "mirewood", "ashslopes", "highlands", "varn", "saltmere", "emberreach", "palereach", "scar"]
		if road.has(args.get("done", "")):
			var upto := road.find(args["done"])
			var dq := []
			for id in Quests.LIST:
				var gz: String = Npcs.LIST.get(Quests.LIST[id]["giver"], {}).get("zone", "ashvale")
				if road.find(gz) < 0 or road.find(gz) > upto: continue
				if gz == "ashvale" and int(Quests.LIST[id]["level"]) > 10: continue
				if Quests.LIST[id].get("kind", "") == "daily": continue
				dq.append(id)
			ch["done_quests"] = dq
			ch["known"] = []
			for t in Npcs.TRAINING[cls]:
				if int(t[1]) <= int(ch["level"]): ch["known"].append(t[0])
			ch["test_gear"] = true


		_start_game(ch)
		if args.has("autoplay"): add_child(load("res://tools/autoplay.gd").new())
		if args.has("questtest"): add_child(load("res://tools/questtest.gd").new())
		if args.has("duel"): add_child(load("res://tools/duel.gd").new())
		if args.has("chattest"): add_child(load("res://tools/chattest.gd").new())
		if args.has("crafttest"): add_child(load("res://tools/crafttest.gd").new())
		if args.has("zonetour"): add_child(load("res://tools/zonetour.gd").new())



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

func _start_game(ch: Dictionary, tr := {}) -> void:
	# a saved character who logged out somewhere else goes straight there
	var their_zone: String = ch.get("zone", "ashvale")
	if tr.is_empty() and their_zone != zone and Zones.DEFS.has(their_zone) and not args.has("play"):
		var pos := Vector2(float(ch["pos"][0]), float(ch["pos"][1])) if ch.has("pos") else Zones.v2(Zones.get_def(their_zone), "start")
		travel_to(their_zone, pos, ch); return
	Save._fix(ch)
	var p := Player.new(); p.setup_from(ch)

	add_child(p)
	var Z: Dictionary = WorldData.Z
	var start := Vector3(STAGE) if zone == "ashvale" else Vector3(Z["start"].x, 0, Z["start"].y)
	if args.has("hero"):
		var hz: PackedStringArray = args["hero"].split(","); start = Vector3(float(hz[0]), 0, float(hz[1]))
	elif tr.has("pos"): start = Vector3(tr["pos"].x, 0, tr["pos"].y)
	elif ch.has("pos") and their_zone == zone: start = Vector3(float(ch["pos"][0]), 0, float(ch["pos"][1]))
	start = Nav.nearest_open(start); start.y = WorldData.h(start.x, start.z)
	p.global_position = start; p.home = start
	hero = p
	camera.target = p; camera.focus = start + Vector3(0, 1.35, 0); p.set_camera(camera)
	hud = load("res://src/ui/game_hud.gd").new(); add_child(hud)
	hud.bind(p, camera)
	if not args.has("questtest") or args.has("bots") or not tr.get("party", []).is_empty():
		var soc: Node = load("res://src/world/society.gd").new(); add_child(soc)

		# the group comes along from the last zone
		for pm in tr.get("party", []): soc.bring(pm, p)
	if not tr.is_empty(): hud.notice("Entering %s" % Z["name"])

## walking off the end of a road: into the next zone
func _check_exits() -> void:
	if not (hero is Player) or hero.dead: return
	for ex in WorldData.Z.get("exits", []):
		var d := Vector2(hero.global_position.x, hero.global_position.z).distance_to(ex["at"])
		if d > float(ex["r"]): exit_warned.erase(ex["name"]); continue
		if ex["to"] == "":
			if not exit_warned.has(ex["name"]): exit_warned[ex["name"]] = true; hud.error(ex["sign"])
			continue
		var need := int(Zones.get_def(ex["to"]).get("group", 1))
		if need > 1 and hero.party_members().size() < need:
			if not exit_warned.has(ex["name"]): exit_warned[ex["name"]] = true; hud.error("You need a group of %d or more to go in (invite someone)" % need)
			continue
		travel_to(ex["to"], ex["arrive"])
		return

func travel_to(to: String, pos: Vector2, ch := {}) -> void:
	if ch.is_empty():
		ch = hero.to_save(); ch["look"] = Save.encode_look(ch["look"]); ch["zone"] = to; ch["pos"] = [pos.x, pos.y]
		if not args.has("play") and not args.has("shot"): Save.upsert(ch)
	var party := []
	if hero is Player:
		for m in hero.party:
			if is_instance_valid(m): party.append(m.to_bot_save())
	travel = {"ch": ch, "zone": to, "pos": pos, "party": party}
	set_process(false)
	await _show_loading(Zones.get_def(to))
	get_tree().reload_current_scene()

## a plain loading screen with the name of where you're going
func _show_loading(Z: Dictionary) -> void:
	loading = CanvasLayer.new(); loading.layer = 50; add_child(loading)
	var bg := ColorRect.new(); bg.color = Color(0.05, 0.04, 0.03); bg.set_anchors_preset(Control.PRESET_FULL_RECT); loading.add_child(bg)
	var l := Label.new(); l.text = Z["name"]; l.set_anchors_preset(Control.PRESET_CENTER); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.offset_left = -400; l.offset_right = 400; l.offset_top = -40
	l.add_theme_font_size_override("font_size", 54); l.add_theme_color_override("font_color", Color(0.98, 0.84, 0.5))
	var f := SystemFont.new(); f.font_names = PackedStringArray(["Georgia", "serif"]); f.font_weight = 700; l.add_theme_font_override("font", f)
	loading.add_child(l)
	var band: Array = Z.get("band", [1, 1])
	var s := Label.new(); s.text = "Levels %d–%d" % [band[0], band[1]]; s.set_anchors_preset(Control.PRESET_CENTER); s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.offset_left = -400; s.offset_right = 400; s.offset_top = 30; s.add_theme_font_size_override("font_size", 22); s.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	loading.add_child(s)
	await get_tree().process_frame
	await get_tree().process_frame

## a signpost where each road leaves the zone
func _signposts(Z: Dictionary) -> void:
	for ex in Z.get("exits", []):
		if ex.get("no_post", false): continue
		var at: Vector2 = ex["at"]

		var root := Node3D.new(); add_child(root)
		var dir := (Vector2.ZERO - at).normalized() * 6.0
		var p := at + dir + dir.orthogonal().normalized() * 3.0
		root.position = Vector3(p.x, WorldData.h(p.x, p.y), p.y)
		var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.42, 0.28, 0.16)
		var post := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.16, 2.4, 0.16); bm.material = wood; post.mesh = bm; post.position.y = 1.2; root.add_child(post)
		var l := Label3D.new(); l.text = "%s\n%s" % [ex["name"], ex["sign"]]; l.font_size = 44; l.pixel_size = 0.006; l.outline_size = 8
		l.modulate = Color(1.0, 0.93, 0.75); l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y; l.position.y = 2.7; root.add_child(l)

func _process(delta: float) -> void:
	if Engine.get_process_frames() % 10 == 0: _check_exits()
	save_t += delta
	if save_t > 60.0: save_t = 0.0; _save()

func _save() -> void:
	if hero is Player and not args.has("shot") and not args.has("play"):
		var d: Dictionary = hero.to_save(); d["look"] = Save.encode_look(d["look"]); d["zone"] = zone; Save.upsert(d)

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
	var dist := float(args.get("gap", "10"))
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
	# each entry: ability[:frames to wait before the picture]; a picture is taken after every entry
	var list := what.split(",")
	for k in list.size():
		var parts := list[k].split(":")
		var id := parts[0]
		p.power = p.max_power; p.gcd = 0.0; p.cds.clear(); p.hp = p.max_hp
		if is_instance_valid(best) and best.dead: best.revive(1.0)
		if not is_instance_valid(best) or best.dead: break
		var ab: Dictionary = Abilities.LIST[id]
		var why := p.use(id, best if not ab.get("helpful", false) else p)
		if why != "": print("demo: ", id, " -> ", why)
		var wait := int(float(ab.get("cast", 0.0)) * 30.0) + (int(parts[1]) if parts.size() > 1 else 6)
		for i in wait: await get_tree().process_frame
		if list.size() > 1:
			var img := get_viewport().get_texture().get_image()
			var out: String = String(args["shot"]).get_basename() + "_%d.png" % k
			img.save_png(out); print("saved ", out)
			for i in 30: await get_tree().process_frame

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
	if args.has("ui"): await _ui_demo(args["ui"]); get_tree().quit(); return
	var frames := int(args.get("frames", "40"))
	for i in frames: await get_tree().process_frame
	var t := Time.get_ticks_msec()
	await get_tree().process_frame
	print("frame ms: ", Time.get_ticks_msec() - t)
	var img := get_viewport().get_texture().get_image()
	img.save_png(args["shot"]); print("saved ", args["shot"])
	get_tree().quit()

## screenshots of the windows, one after another:  --ui=npc:rowan,quest:pests_in_fields,bags,char,talents,log,map,vendor:bess,trainer
func _ui_demo(spec: String) -> void:
	var p: Player = hero
	var per := int(args.get("uiframes", "6"))
	for i in per * 2: await get_tree().process_frame
	# something to look at: a few quests, some loot, a couple of talents
	for id in ["word_with_elder"]: p.done_quests.append(id)
	for id in ["pests_in_fields", "hen_feathers", "blacksmiths_wager"]: p.accept_quest(id)
	p.quests["pests_in_fields"]["have"][0] = 5
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	for k in 3: p.add_item(Items.roll(p.level, rng))
	p.add_item({"id": "hen_feather", "n": 3}); p.add_item({"id": "rat_tail", "n": 4}); p.add_item({"id": "cracked_tusk", "n": 1}); p.add_item({"id": "minor_healing_potion", "n": 2})
	p.gold = 2345
	if p.level >= 10:
		var t: Array = Talents.TREES[p.cls][0]["talents"]
		for k in 3: p.learn_talent(t[0]["id"]); p.learn_talent(t[1]["id"])
	var k := 0
	for step in spec.split(","):
		var parts := step.split(":")
		var w: GameWindows = hud.win
		for c in [w.npc_win, w.bag_win, w.char_win, w.log_win, w.tal_win]:
			if c: c.visible = false
		if hud.minimap.big_open: hud.minimap.toggle_big(hud.root)
		match parts[0]:
			"npc", "vendor", "trainer", "quest":
				var who := parts[1] if parts.size() > 1 and parts[0] != "quest" else ("trainer_" + p.cls if parts[0] == "trainer" else "rowan")
				if parts[0] == "quest": who = Quests.LIST[parts[1]]["giver"]
				var n: Npc = null
				for x in get_tree().get_nodes_in_group("npcs"):
					if x.npc_id == who: n = x
				if n == null: continue
				p.global_position = n.global_position + Vector3(2.2, 0, 1.5); p.global_position.y = WorldData.h(p.global_position.x, p.global_position.z)
				camera.focus = p.global_position + Vector3(0, 1.35, 0)
				w.open_npc(n)
				if parts[0] == "vendor": w.npc_page = "vendor"; w._vendor(); w.open_bags(true)
				elif parts[0] == "trainer": w.npc_page = "trainer"; w._trainer()
				elif parts[0] == "quest": w._show_quest(parts[1])
			"bags": w.open_bags(true)
			"char": w.toggle_char()
			"talents": w.toggle_talents()
			"log": w.toggle_log()
			"map": hud.minimap.toggle_big(hud.root)
		for i in per: await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()

		var out: String = args["shot"].get_basename() + "_%d.png" % k
		img.save_png(out); print("saved ", out)
		k += 1
