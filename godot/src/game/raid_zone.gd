class_name RaidZone extends Node3D
## A patch of the floor that does something to whoever stands in it, drifting slowly: the
## Archivist's silence (no spells while you're in it). Shown as a glowing disc.

var kind := "silence"
var radius := 5.0
var life := 30.0
var drift := Vector3.ZERO
var disc: MeshInstance3D

static func make(parent: Node, at: Vector3, k: String, r: float, t: float, v: Vector3) -> RaidZone:
	var z := RaidZone.new(); z.kind = k; z.radius = r; z.life = t; z.drift = v
	parent.add_child(z)
	z.global_position = Vector3(at.x, WorldData.h(at.x, at.z) + 0.08, at.z)
	return z

func _ready() -> void:
	add_to_group("raid_zones"); add_to_group("raid_floor")
	disc = MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2.ONE * radius * 2.0; q.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; m.albedo_texture = Fx.ring_tex; m.albedo_color = Color(0.55, 0.35, 1.0, 0.9)
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = m; disc.mesh = q; disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(disc)
	var fill := MeshInstance3D.new(); var q2 := QuadMesh.new(); q2.size = Vector2.ONE * radius * 1.9; q2.orientation = PlaneMesh.FACE_Y
	var m2 := StandardMaterial3D.new(); m2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m2.albedo_texture = Fx.ring_tex; m2.albedo_color = Color(0.3, 0.15, 0.6, 0.25); m2.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q2.material = m2; fill.mesh = q2; fill.position.y = -0.02; add_child(fill)

func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0: queue_free(); return
	var p := global_position + drift * delta
	if Nav.walkable(p): global_position = Vector3(p.x, WorldData.h(p.x, p.z) + 0.08, p.z)
	else: drift = -drift
	disc.rotation.y += delta * 0.6
	if Engine.get_physics_frames() % 10 != 0: return
	for u in get_tree().get_nodes_in_group("units"):
		if u.dead or u.faction != "player": continue
		if Vector2(u.global_position.x - global_position.x, u.global_position.z - global_position.z).length() < radius:
			u.add_aura("silenced", null, 0.6, {"silence": 1.0, "debuff": true})

## is this point inside any zone (bots use it to step out)
static func inside(tree: SceneTree, p: Vector3) -> RaidZone:
	for z in tree.get_nodes_in_group("raid_floor"):
		if Vector2(p.x - z.global_position.x, p.z - z.global_position.z).length() < z.radius + 0.8: return z
	return null
