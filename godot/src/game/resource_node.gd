class_name ResourceNode extends Node3D
## Something to gather: an ore vein (Mining) or a herb (Herbalism). Click it to gather a few; it
## comes back a couple of minutes later. The tier follows the zone: copper and hearthleaf in
## Ashvale, black iron and cliffmoss in the Hollow Cliffs.

var kind := "ore"          # ore | herb
var tier := 1
var gone_t := 0.0
var busy := false
var body: Node3D
var rng := RandomNumberGenerator.new()

func setup(k: String, t: int) -> void:
	kind = k; tier = t

func skill_id() -> String: return "mining" if kind == "ore" else "herbalism"

func item_id() -> String: return "%s_%d" % [kind, tier]

func _ready() -> void:
	add_to_group("gather")
	rng.randomize()
	body = Node3D.new(); add_child(body)
	if kind == "ore":
		var rm := StandardMaterial3D.new(); rm.albedo_color = Color(0.42, 0.4, 0.38); rm.roughness = 0.95
		var ore := StandardMaterial3D.new(); ore.albedo_color = [Color(0.8, 0.45, 0.25), Color(0.15, 0.15, 0.18), Color(0.5, 0.35, 0.25), Color(0.55, 0.5, 0.5), Color(0.7, 0.75, 0.85), Color(0.6, 0.5, 0.9)][tier - 1]
		ore.metallic = 0.85; ore.roughness = 0.3
		for k in 3:
			var r := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.45 - k * 0.1; sm.height = 0.6 - k * 0.1; sm.radial_segments = 7; sm.rings = 4; sm.material = rm
			r.mesh = sm; body.add_child(r); r.position = Vector3(k * 0.35 - 0.3, 0.15, rng.randf_range(-0.2, 0.2)); r.scale = Vector3(1.2, 0.8, 1.0)
		for k in 7:
			var o := MeshInstance3D.new(); var om := SphereMesh.new(); om.radius = 0.09; om.height = 0.14; om.radial_segments = 5; om.rings = 2; om.material = ore
			o.mesh = om; body.add_child(o); o.position = Vector3(rng.randf_range(-0.6, 0.5), rng.randf_range(0.2, 0.45), rng.randf_range(-0.3, 0.3))
	else:
		var leaf := StandardMaterial3D.new(); leaf.albedo_color = [Color(0.4, 0.62, 0.25), Color(0.45, 0.55, 0.35), Color(0.3, 0.45, 0.3), Color(0.55, 0.35, 0.2), Color(0.6, 0.75, 0.8), Color(0.5, 0.45, 0.8)][tier - 1]
		var bloom := StandardMaterial3D.new(); bloom.albedo_color = [Color(1.0, 0.75, 0.3), Color(0.9, 0.9, 0.6), Color(0.5, 0.6, 1.0), Color(1.0, 0.4, 0.2), Color(0.8, 0.9, 1.0), Color(1.0, 0.9, 0.5)][tier - 1]
		bloom.emission_enabled = true; bloom.emission = bloom.albedo_color; bloom.emission_energy_multiplier = 0.4
		for k in 6:
			var l := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.0; cm.bottom_radius = 0.06; cm.height = 0.45; cm.material = leaf
			l.mesh = cm; body.add_child(l); var a := TAU * k / 6.0; l.position = Vector3(cos(a) * 0.1, 0.2, sin(a) * 0.1); l.rotation = Vector3(sin(a) * 0.4, 0, -cos(a) * 0.4)
		for k in 3:
			var b := MeshInstance3D.new(); var sm2 := SphereMesh.new(); sm2.radius = 0.07; sm2.height = 0.12; sm2.material = bloom
			b.mesh = sm2; body.add_child(b); b.position = Vector3(rng.randf_range(-0.15, 0.15), 0.45, rng.randf_range(-0.15, 0.15))

func available() -> bool: return gone_t <= 0.0

func _process(delta: float) -> void:
	if gone_t > 0.0:
		gone_t -= delta
		if gone_t <= 0.0: visible = true

func take(p: Player) -> void:
	if not available() or busy: return
	var need := Crafting.skill_needed(tier)
	if p.skill(skill_id()) < need:
		p._hud("error", "Requires %s %d" % [Crafting.SKILLS[skill_id()], need]); return
	busy = true
	p.act("PickUp_Table" if kind == "herb" else "Sword_Regular_A", 0.8)
	get_tree().call_group("fx", "sound", "pickup" if kind == "herb" else "hit_1", global_position, -6.0)
	await get_tree().create_timer(1.2).timeout
	busy = false
	if not is_instance_valid(p) or p.dead or not available(): return
	if p.add_item({"id": item_id(), "n": rng.randi_range(2, 4)}):
		p.skill_up(skill_id(), tier)
		visible = false; gone_t = rng.randf_range(90.0, 150.0)
