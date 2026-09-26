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
var lib_ref: AnimationLibrary

## can this body play n? (converts it on first ask)
func has_anim(n: String) -> bool:
	return anim != null and AnimLib.ensure(anim.get_animation_library(""), n)

func _ready() -> void:
	body = _make_body()
	add_child(body)
	# the kit characters face +Z; whoever owns this node turns it (rotation.y = atan2(dir.x, dir.z))
	skeleton = body.get_node("Armature/Skeleton3D")
	anim = AnimationPlayer.new(); anim.name = "Anim"; body.add_child(anim)
	anim.root_node = NodePath("..")
	anim.add_animation_library("", AnimLib.for_skeleton(skeleton))
	anim.playback_default_blend_time = 0.22
	anim.animation_finished.connect(func(_n): _once = false)
	lib_ref = anim.get_animation_library("")
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for s in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(s)
			if mat and mat.resource_name.begins_with("MI_Hair") and mat is BaseMaterial3D:
				var hm: BaseMaterial3D = mat.duplicate(); hm.albedo_color = hair_color; m.set_surface_override_material(s, hm)
	play("Idle")

## the body scene (root holding Armature/Skeleton3D). Subclasses (Avatar) assemble their own.
func _make_body() -> Node3D:
	# a name from assets/characters, or a full path (e.g. a Bestiary monster)
	return load(model if model.begins_with("res://") else "res://assets/characters/%s.gltf" % model).instantiate()

## loop an animation (no restart if it is already playing)
func play(n: String, speed := 1.0, blend := -1.0) -> void:
	if _once: return
	if not AnimLib.ensure(anim.get_animation_library(""), n): return
	anim.speed_scale = speed
	if current == n: return
	current = n
	anim.play(n, blend)

## play an animation once, then return to whatever loop is asked for next
func play_once(n: String, speed := 1.0) -> void:
	if not AnimLib.ensure(anim.get_animation_library(""), n): return
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

## hold a weapon properly in the fist: our weapon models have the grip at the origin, the blade (or
## staff head) along +Y and the edge along +X. In the kit skeleton's hand bone the fingers run
## along +Y and the knuckles from the little finger to the index along +Z, so the blade leaves the
## fist on the thumb side, edge forward.
## tilt (degrees) swings the blade from straight out of the fist toward the forearm, so a staff
## stands upright in a hanging hand.
func wield(path: String, scale_by := 0.6, bone := "hand_r", tilt := 0.0) -> Node3D:
	var ba := BoneAttachment3D.new(); ba.bone_name = bone; skeleton.add_child(ba)
	var item: Node3D = load(path).instantiate()
	var side := 1.0 if bone == "hand_r" else -1.0
	var b := Basis(Vector3(0, 1, 0), Vector3(0, 0, side), Vector3(side, 0, 0))
	b = Basis(Vector3(side, 0, 0), deg_to_rad(tilt)) * b
	item.transform = Transform3D(b.scaled(Vector3.ONE * scale_by), Vector3(-0.03 * side, 0.085, -0.005))
	ba.add_child(item)
	return item
