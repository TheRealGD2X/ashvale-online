extends SceneTree
## A quick photo studio for characters and effects, much faster than rendering the whole world:
##   xvfb-run godot --path . -s tools/stage.gd -- --out=/tmp/x.png --what=avatars [--anim=Idle] [--t=0.4]
## what: avatars | monsters | classes (each class in its starting gear) | creator (the character screen)

var args := {}

## a hero and a monster on the town square; the hero uses abilities and we take pictures
##   --what=fx --class=wizard --demo=fireball:4,frost_nova:5 --gap=8 --out=/tmp/x.png
func _fx_demo(root: Node3D, cam: Camera3D) -> void:
	create_timer(float(args.get("timeout", "400"))).timeout.connect(func(): print("TIMEOUT"); quit(1))
	await process_frame
	WorldData.bake()
	var g := WorldData.h(0, 0)
	for c in root.get_children():
		if c is MeshInstance3D: c.position.y = g
	var fx := Fx.new(); root.add_child(fx)
	var hud = load("res://src/ui/game_hud.gd").new(); root.add_child(hud)
	var rng := RandomNumberGenerator.new(); rng.seed = int(args.get("seed", "5"))
	var cls: String = args.get("class", "wizard")
	var p := Player.new()
	p.setup_from({"name": "Tester", "cls": cls, "level": int(args.get("level", "6")), "look": Avatar.random_look(rng, cls, args.get("sex", "m"))})
	root.add_child(p); p.global_position = Vector3(0, g, 0)
	var m := Monster.new(); m.setup(args.get("mon", "puglin"), int(args.get("mlevel", "4")))
	root.add_child(m)
	var gap := float(args.get("gap", "9"))
	m.global_position = Vector3(0, g, -gap); m.home = m.global_position
	await process_frame
	p.yaw = PI; p.model.rotation.y = PI
	m.yaw = 0.0; m.model.rotation.y = 0.0
	m.set_physics_process(false)
	var ang := deg_to_rad(float(args.get("yaw", "70")))
	var focus := Vector3(0, g + 1.0, -gap * 0.4)
	var dist := float(args.get("dist", "10"))
	var pitch := deg_to_rad(float(args.get("pitch", "38")))
	cam.fov = 50
	cam.look_at_from_position(focus + Vector3(sin(ang) * cos(pitch), sin(pitch), cos(ang) * cos(pitch)) * dist, focus)
	hud.bind(p, cam)
	p.target = m
	for i in 6: await process_frame
	var list: PackedStringArray = String(args.get("demo", "fireball:4")).split(",")
	for k in list.size():
		var parts := list[k].split(":")
		var id := parts[0]
		p.power = p.max_power; p.gcd = 0.0; p.cds.clear(); p.hp = p.max_hp
		if m.dead: m.revive(1.0)
		m.hp = m.max_hp
		var ab: Dictionary = Abilities.LIST[id]
		var why := p.use(id, m if not ab.get("helpful", false) else p)
		if why != "": print("demo: ", id, " -> ", why)
		var wait := int(float(ab.get("cast", 0.0)) * 30.0) + (int(parts[1]) if parts.size() > 1 else 6)
		for i in wait: await process_frame
		var img := get_root().get_viewport().get_texture().get_image()
		var out: String = String(args.get("out", "/tmp/fx.png")).get_basename() + "_%d.png" % k
		img.save_png(out); print("saved ", out)
		for i in 20: await process_frame
	quit()

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var root := Node3D.new(); get_root().add_child(root)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	var e := env.environment
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.55, 0.66, 0.72)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.72, 0.76, 0.82); e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	root.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-42, 35, 0); sun.light_energy = 1.3
	sun.light_color = Color(1, 0.95, 0.86); sun.shadow_enabled = true; root.add_child(sun)
	var ground := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(40, 40); ground.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_color = Color(0.42, 0.5, 0.3); ground.material_override = gm; root.add_child(ground)
	var cam := Camera3D.new(); root.add_child(cam); cam.current = true; cam.fov = 40
	var what: String = args.get("what", "avatars")
	var actors: Array = []
	if what == "fx":
		await _fx_demo(root, cam)
		return
	var rng := RandomNumberGenerator.new(); rng.seed = int(args.get("seed", "7"))
	match what:
		"avatars", "classes":
			for cls in ["warrior", "wizard", "cleric"]:
				for sex in (["m"] if args.has("one") else ["m", "f"]):
					var a := Avatar.new(); a.look = Avatar.random_look(rng, cls, sex); actors.append(a)
		"monsters":
			var d := "res://assets/licensed/monsters"
			for f in DirAccess.get_files_at(d):
				if f.ends_with(".glb"):
					var m := Humanoid.new(); m.model = d + "/" + f; actors.append(m)
	var n := actors.size()
	var spacing := float(args.get("spacing", "1.2"))
	for i in n:
		var a: Node3D = actors[i]; root.add_child(a)
		a.position = Vector3((i - (n - 1) * 0.5) * spacing, 0, 0)
	var w := (n - 1) * spacing + 1.5
	var h := float(args.get("h", "1.0"))
	var dist := float(args.get("dist", str(w * 0.9 + 1.2)))
	var cx := float(args.get("cx", "0")); var ang := deg_to_rad(float(args.get("yaw", "0")))
	cam.look_at_from_position(Vector3(cx + sin(ang) * dist, h + 0.3, cos(ang) * dist), Vector3(cx, h, 0))
	for i in 4: await process_frame
	if what == "classes":
		var wp := {"warrior": ["sword", 0.55], "wizard": ["staff", 0.62], "cleric": ["club", 0.62]}
		var rot := Vector3(float(args.get("rx", "0")), float(args.get("ry", "0")), float(args.get("rz", "-90")))
		for i in n:
			var c: String = (["warrior", "wizard", "cleric"] if args.has("one") else ["warrior", "warrior", "wizard", "wizard", "cleric", "cleric"])[i]
			actors[i].wield("res://assets/weapons/%s.glb" % wp[c][0], wp[c][1], "hand_r", float(args.get("tilt", "0")) if c != "warrior" else 0.0)
	for i in n:
		var a = actors[i]
		if a is Humanoid:
			a.has_anim(args.get("anim", "Idle")); a.anim.play(args.get("anim", "Idle")); a.anim.seek(float(args.get("t", "0.3")) + i * 0.13, true)
	for i in int(args.get("frames", "12")): await process_frame
	var img := get_root().get_viewport().get_texture().get_image()
	img.save_png(args.get("out", "/tmp/stage.png")); print("saved ", args.get("out", "/tmp/stage.png"))
	quit()
