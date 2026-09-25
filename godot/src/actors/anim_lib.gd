class_name AnimLib
## The Universal Animation Library (UAL1 + UAL2: walking, running, sword play, spells, farming,
## sitting, dancing...) made to fit any of our people.
##
## The animations were made on the UAL mannequin. Our people share its bone names but not exactly
## its rest pose (a slightly different spine, longer legs...), so each animation is re-expressed as
## "how far each bone turns from its rest pose" and applied to the person's own rest pose. Results are
## cached per skeleton shape, so a crowd of villagers shares one converted library.

const SOURCES := ["res://assets/anims/UAL1.glb", "res://assets/anims/UAL2.glb"]
const SKEL_PATH := "Armature/Skeleton3D"

static var _src: AnimationLibrary          # every UAL animation, as imported
static var _src_rest := {}                   # bone name -> rest Transform3D on the mannequin
static var _cache := {}                      # skeleton signature -> AnimationLibrary

static func _load_sources() -> void:
	if _src: return
	_src = AnimationLibrary.new()
	for path in SOURCES:
		var scene: Node = load(path).instantiate()
		var ap: AnimationPlayer = scene.get_node("AnimationPlayer")
		if _src_rest.is_empty():
			var sk: Skeleton3D = scene.get_node(SKEL_PATH)
			for b in sk.get_bone_count(): _src_rest[sk.get_bone_name(b)] = sk.get_bone_rest(b)
		for n in ap.get_animation_list():
			if n == "A_TPose" or _src.has_animation(n): continue
			_src.add_animation(n, ap.get_animation(n))
		scene.free()

## an AnimationLibrary whose animations fit this skeleton (tracks target "Armature/Skeleton3D:<bone>")
static func for_skeleton(sk: Skeleton3D) -> AnimationLibrary:
	_load_sources()
	var sig := _signature(sk)
	if _cache.has(sig): return _cache[sig]
	var lib := AnimationLibrary.new()
	var hip_ratio := 1.0
	var pb := sk.find_bone("pelvis")
	if pb >= 0 and _src_rest.has("pelvis"): hip_ratio = sk.get_bone_rest(pb).origin.y / (_src_rest["pelvis"] as Transform3D).origin.y
	for n in _src.get_animation_list():
		lib.add_animation(n, _retarget(_src.get_animation(n), sk, hip_ratio))
	_cache[sig] = lib
	return lib

static func _signature(sk: Skeleton3D) -> String:
	var s := ""
	for b in [sk.find_bone("pelvis"), sk.find_bone("spine_03"), sk.find_bone("Head"), sk.find_bone("upperarm_l"), sk.find_bone("thigh_l")]:
		if b >= 0:
			var q := sk.get_bone_rest(b).basis.get_rotation_quaternion()
			s += "%.3f,%.3f,%.3f,%.3f|%s;" % [q.x, q.y, q.z, q.w, str(sk.get_bone_rest(b).origin.snapped(Vector3.ONE * 0.001))]
	return s

static func _retarget(src: Animation, sk: Skeleton3D, hip_ratio: float) -> Animation:
	var a: Animation = src.duplicate(true)
	for t in range(a.get_track_count() - 1, -1, -1):
		var path := a.track_get_path(t)
		var bone := path.get_concatenated_subnames()
		var bi := sk.find_bone(bone)
		if bi < 0 or not _src_rest.has(bone):
			a.remove_track(t); continue
		var rs: Transform3D = _src_rest[bone]
		var rt: Transform3D = sk.get_bone_rest(bi)
		match a.track_get_type(t):
			Animation.TYPE_ROTATION_3D:
				# q_target = rest_target * (rest_source^-1 * q_source)
				var qs_inv := rs.basis.get_rotation_quaternion().inverse()
				var qt := rt.basis.get_rotation_quaternion()
				for k in a.track_get_key_count(t):
					var q: Quaternion = a.track_get_key_value(t, k)
					a.track_set_key_value(t, k, (qt * (qs_inv * q)).normalized())
			Animation.TYPE_POSITION_3D:
				if bone == "pelvis" or bone == "root":
					for k in a.track_get_key_count(t):
						var p: Vector3 = a.track_get_key_value(t, k)
						a.track_set_key_value(t, k, rt.origin + (p - rs.origin) * hip_ratio)
				else:
					a.remove_track(t)
			Animation.TYPE_SCALE_3D:
				a.remove_track(t)
	return a

## names of every animation available (for tools and debugging)
static func names() -> PackedStringArray:
	_load_sources()
	return _src.get_animation_list()
