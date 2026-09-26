class_name Pickup extends Node3D
## Something small on the ground you can pick up for a quest (a lamb's bell, old coins at the
## shrine). It twinkles when you need it, and only then; picked-up things come back after a while.

var item := ""
var needed_by := ""             # only shows while this quest is underway (and not yet done)
var respawn := 45.0
var gone_t := 0.0
var look := "coin"
var body: Node3D
var glint: Node3D
var busy := false

func setup(it: String, quest: String, kind := "coin") -> void:
	item = it; needed_by = quest; look = kind

func _ready() -> void:
	add_to_group("pickups")
	body = Node3D.new(); add_child(body)
	match look:
		"bell":
			var m := MeshInstance3D.new(); var c := CylinderMesh.new(); c.top_radius = 0.04; c.bottom_radius = 0.1; c.height = 0.14
			var mt := StandardMaterial3D.new(); mt.albedo_color = Color(0.85, 0.66, 0.25); mt.metallic = 0.8; mt.roughness = 0.35; c.material = mt
			m.mesh = c; body.add_child(m); m.position.y = 0.08; m.rotation_degrees.z = 70
			var r := MeshInstance3D.new(); var t := TorusMesh.new(); t.inner_radius = 0.05; t.outer_radius = 0.07
			var rm := StandardMaterial3D.new(); rm.albedo_color = Color(0.55, 0.2, 0.15); t.material = rm; r.mesh = t
			body.add_child(r); r.position = Vector3(0.1, 0.05, 0); r.rotation_degrees.x = 90
		"ore":
			var rock := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.55; sm.height = 0.7; sm.radial_segments = 7; sm.rings = 4
			var rm := StandardMaterial3D.new(); rm.albedo_color = Color(0.4, 0.38, 0.36); rm.roughness = 0.9; sm.material = rm; rock.mesh = sm
			body.add_child(rock); rock.position.y = 0.2; rock.scale = Vector3(1.3, 0.8, 1.0)
			for k in 5:
				var o := MeshInstance3D.new(); var om := SphereMesh.new(); om.radius = 0.12; om.height = 0.18; om.radial_segments = 5; om.rings = 2
				var omt := StandardMaterial3D.new(); omt.albedo_color = Color(0.12, 0.12, 0.15); omt.metallic = 0.9; omt.roughness = 0.25; om.material = omt; o.mesh = om
				rock.add_child(o); var a := TAU * k / 5.0; o.position = Vector3(cos(a) * 0.4, 0.15, sin(a) * 0.35)
			# the foreman's chalk mark
			var ch := MeshInstance3D.new(); var cm := BoxMesh.new(); cm.size = Vector3(0.35, 0.05, 0.05)
			var cmt := StandardMaterial3D.new(); cmt.albedo_color = Color(0.95, 0.95, 0.9); cm.material = cmt; ch.mesh = cm
			rock.add_child(ch); ch.position = Vector3(0, 0.33, 0.25); ch.rotation.z = 0.6
		"oats", "bloom":
			var col := Color(0.85, 0.75, 0.4) if look == "oats" else Color(0.65, 0.35, 0.75)
			for k in 7:
				var st := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.02; cm.bottom_radius = 0.03; cm.height = 0.7
				var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.5, 0.6, 0.3); cm.material = sm; st.mesh = cm
				body.add_child(st); st.position = Vector3(randf_range(-0.2, 0.2), 0.35, randf_range(-0.2, 0.2))
				var head := MeshInstance3D.new(); var hm := SphereMesh.new(); hm.radius = 0.06; hm.height = 0.14
				var hmt := StandardMaterial3D.new(); hmt.albedo_color = col; hm.material = hmt; head.mesh = hm
				st.add_child(head); head.position.y = 0.36
		"totem":

			var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.35, 0.25, 0.15)
			var pole := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.1; cm.bottom_radius = 0.14; cm.height = 1.8; cm.material = wood; pole.mesh = cm
			body.add_child(pole); pole.position.y = 0.9
			var bone := StandardMaterial3D.new(); bone.albedo_color = Color(0.88, 0.85, 0.75)
			var skull := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.18; sm.height = 0.3; sm.material = bone; skull.mesh = sm
			body.add_child(skull); skull.position.y = 1.9
			for k in 3:
				var f := MeshInstance3D.new(); var fm := BoxMesh.new(); fm.size = Vector3(0.05, 0.4, 0.02)
				var fc := StandardMaterial3D.new(); fc.albedo_color = [Color(0.8, 0.2, 0.15), Color(0.9, 0.8, 0.2), Color(0.2, 0.5, 0.8)][k]; fm.material = fc; f.mesh = fm
				body.add_child(f); f.position = Vector3(0.12, 1.5 - k * 0.1, 0); f.rotation.z = 0.4 + k * 0.3
		"grave":

			var wreath := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 0.18; tm.outer_radius = 0.3
			var wm := StandardMaterial3D.new(); wm.albedo_color = Color(0.35, 0.5, 0.25); tm.material = wm; wreath.mesh = tm
			body.add_child(wreath); wreath.position.y = 0.05
		_:
			for i in 3:

				var m2 := MeshInstance3D.new(); var cy := CylinderMesh.new(); cy.top_radius = 0.05; cy.bottom_radius = 0.05; cy.height = 0.012
				var mt2 := StandardMaterial3D.new(); mt2.albedo_color = Color(0.72, 0.58, 0.3); mt2.metallic = 0.9; mt2.roughness = 0.4; cy.material = mt2
				m2.mesh = cy; body.add_child(m2)
				m2.position = Vector3(randf_range(-0.12, 0.12), 0.01 + i * 0.013, randf_range(-0.12, 0.12)); m2.rotation_degrees = Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
	visible = false

var available := true

func _process(delta: float) -> void:
	if gone_t > 0.0:
		gone_t -= delta
		available = gone_t <= 0.0
	# only people on the quest see it glint (bots don't need to see it to find it)
	var p: Player = get_tree().get_first_node_in_group("player")
	var want := available and p != null and p.quests.has(needed_by) and not p.quest_complete(needed_by)
	var show := want or (available and look in ["totem"])
	if show != visible: visible = show
	if want and glint == null:
		var fx := get_tree().get_first_node_in_group("fx")
		if fx: glint = fx.twinkle(self, Color(1.0, 0.9, 0.5), 0.3)
	elif not want and glint: glint.queue_free(); glint = null

	if visible: body.rotation.y += delta * 0.4

func take(p: Player) -> void:
	if not available or busy: return
	if not p.quests.has(needed_by) or p.quest_complete(needed_by):
		if not p.is_bot: p._hud("error", "You don't need that right now")
		return

	busy = true
	p.act("PickUp_Table" if p.model and p.model.has_anim("PickUp_Table") else "Interact", 1.0)
	await get_tree().create_timer(0.7).timeout
	busy = false
	if not is_instance_valid(p) or p.dead: return
	if p.add_item({"id": item, "n": 1}):
		get_tree().call_group("fx", "sound", "pickup", global_position, -6.0)
		visible = false; available = false; gone_t = respawn
		if glint: glint.queue_free(); glint = null
