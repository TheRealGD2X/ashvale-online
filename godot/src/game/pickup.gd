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
		_:
			for i in 3:
				var m2 := MeshInstance3D.new(); var cy := CylinderMesh.new(); cy.top_radius = 0.05; cy.bottom_radius = 0.05; cy.height = 0.012
				var mt2 := StandardMaterial3D.new(); mt2.albedo_color = Color(0.72, 0.58, 0.3); mt2.metallic = 0.9; mt2.roughness = 0.4; cy.material = mt2
				m2.mesh = cy; body.add_child(m2)
				m2.position = Vector3(randf_range(-0.12, 0.12), 0.01 + i * 0.013, randf_range(-0.12, 0.12)); m2.rotation_degrees = Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
	visible = false

func _process(delta: float) -> void:
	if gone_t > 0.0:
		gone_t -= delta
		if gone_t > 0.0: return
	var p: Player = get_tree().get_first_node_in_group("player")
	var want := p != null and p.quests.has(needed_by) and not p.quest_complete(needed_by)
	if want != visible:
		visible = want
		if want and glint == null:
			var fx := get_tree().get_first_node_in_group("fx")
			if fx: glint = fx.twinkle(self, Color(1.0, 0.9, 0.5), 0.3)
	if visible: body.rotation.y += delta * 0.4

func take(p: Player) -> void:
	if not visible or busy: return
	busy = true
	p.act("Interact" if p.model and p.model.has_anim("Interact") else "PickUp", 1.2)
	await get_tree().create_timer(0.7).timeout
	busy = false
	if not is_instance_valid(p) or p.dead: return
	if p.add_item({"id": item, "n": 1}):
		get_tree().call_group("fx", "sound", "pickup", global_position, -6.0)
		visible = false; gone_t = respawn
		if glint: glint.queue_free(); glint = null
