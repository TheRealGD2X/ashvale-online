class_name RaidTether extends Node3D
## The Twin Wardens' chains: two people bound for a while. More than six metres apart, and it hurts
## both of them every second. A glowing line joins them so you can see who you're chained to.

var a: Unit
var b: Unit
var life := 15.0
var src: Unit
var line: MeshInstance3D
var tick := 0.0
const MAX_D := 6.0

static func make(parent: Node, u1: Unit, u2: Unit, t: float, from: Unit) -> RaidTether:
	var c := RaidTether.new(); c.a = u1; c.b = u2; c.life = t; c.src = from
	parent.add_child(c)
	u1.set_meta("chained_to", u2); u2.set_meta("chained_to", u1)
	parent.get_tree().call_group("hud", "notice", "%s and %s are chained together! Stay close." % [u1.uname, u2.uname])
	return c

func _ready() -> void:
	add_to_group("raid_zones")
	top_level = true
	line = MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.05; cm.bottom_radius = 0.05; cm.height = 1.0; cm.radial_segments = 6
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.albedo_color = Color(0.7, 0.4, 1.0)
	m.emission_enabled = true; m.emission = Color(0.6, 0.3, 1.0); cm.material = m; line.mesh = cm; add_child(line)

func _exit_tree() -> void:
	for u in [a, b]:
		if is_instance_valid(u) and u.has_meta("chained_to"): u.remove_meta("chained_to")

func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0 or not is_instance_valid(a) or not is_instance_valid(b) or a.dead or b.dead: queue_free(); return
	var pa := a.global_position + Vector3(0, 1.2, 0); var pb := b.global_position + Vector3(0, 1.2, 0)
	var d := pa.distance_to(pb)
	line.global_position = (pa + pb) / 2.0
	line.scale = Vector3(1, maxf(0.1, d), 1)
	if d > 0.01: line.look_at(pb, Vector3.UP if absf((pb - pa).normalized().y) < 0.99 else Vector3.FORWARD); line.rotate_object_local(Vector3.RIGHT, PI / 2)
	(line.mesh.material as StandardMaterial3D).albedo_color = Color(1.0, 0.3, 0.3) if d > MAX_D else Color(0.7, 0.4, 1.0)
	tick += delta
	if tick >= 1.0:
		tick = 0.0
		if d > MAX_D:
			for u in [a, b]: u.take_damage(src if is_instance_valid(src) else null, u.max_hp * 0.08, "shadow", false, "dot", 0.0)
