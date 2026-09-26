extends SceneTree
## A quick photo studio for characters and effects, much faster than rendering the whole world:
##   xvfb-run godot --path . -s tools/stage.gd -- --out=/tmp/x.png --what=avatars [--anim=Idle] [--t=0.4]
## what: avatars | monsters | classes (each class in its starting gear) | creator (the character screen)

var args := {}

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
