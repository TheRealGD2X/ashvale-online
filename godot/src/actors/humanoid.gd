class_name Humanoid extends Node3D
## A person's body: one of our built characters (godot/assets/characters) with the whole
## animation library fitted to its skeleton, smooth blending between moves, and hair colour.
##
##   var h := Humanoid.new(); h.model = "hero_m"; add_child(h)
##   h.play("Walk"); h.play_once("Sword_Attack")

@export var model := "hero_m"
@export var hair_color := Color(0.25, 0.16, 0.09)
var body: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer
var current := ""
var _once := false

func _ready() -> void:
	body = load("res://assets/characters/%s.gltf" % model).instantiate()
	add_child(body)
	# the kit characters face +Z; whoever owns this node turns it (rotation.y = atan2(dir.x, dir.z))
	skeleton = body.get_node("Armature/Skeleton3D")
	anim = AnimationPlayer.new(); anim.name = "Anim"; body.add_child(anim)
	anim.root_node = NodePath("..")
	anim.add_animation_library("", AnimLib.for_skeleton(skeleton))
	anim.playback_default_blend_time = 0.22
	anim.animation_finished.connect(func(_n): _once = false)
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for s in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(s)
			if mat and mat.resource_name.begins_with("MI_Hair") and mat is BaseMaterial3D:
				var hm: BaseMaterial3D = mat.duplicate(); hm.albedo_color = hair_color; m.set_surface_override_material(s, hm)
	play("Idle")

## loop an animation (no restart if it is already playing)
func play(n: String, speed := 1.0, blend := -1.0) -> void:
	if _once: return
	anim.speed_scale = speed
	if current == n: return
	current = n
	anim.play(n, blend)

## play an animation once, then return to whatever loop is asked for next
func play_once(n: String, speed := 1.0) -> void:
	if not anim.has_animation(n): return
	_once = true; current = n; anim.speed_scale = speed
	anim.play(n, 0.12)
	anim.seek(0.0, true)

func busy() -> bool: return _once

## put a prop (tool, weapon) in a hand: bone "hand_r" or "hand_l"; offset/rotation in the bone's space
func hold(path: String, bone := "hand_r", offset := Vector3.ZERO, rot_deg := Vector3.ZERO, scale_by := 1.0) -> Node3D:
	var ba := BoneAttachment3D.new(); ba.bone_name = bone; skeleton.add_child(ba)
	var item: Node3D = load(path).instantiate()
	item.position = offset; item.rotation_degrees = rot_deg; item.scale = Vector3.ONE * scale_by
	ba.add_child(item)
	return item
