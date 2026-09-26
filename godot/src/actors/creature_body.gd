class_name CreatureBody extends Humanoid
## An animal's body (our own models in godot/assets/creatures: boar, wolf, wildcat, rat, hen,
## deer, bear, spider, bat...). They carry their own animations (Idle, Walk, Attack, Hit, Die,
## Dead); the people-animation names the game asks for are translated to those.

const MAP := {"Walk": "Walk", "Jog_Fwd": "Walk", "Sprint": "Walk", "Zombie_Walk_Fwd": "Walk", "Idle": "Idle", "Sword_Idle": "Idle",
	"Zombie_Idle": "Idle", "Hit_Chest": "Hit", "Hit_Head": "Hit", "Hit_Knockback": "Hit", "Death01": "Die"}

var speed_mul := 1.0     # small animals scurry

func _ready() -> void:
	body = load("res://assets/creatures/%s.glb" % model).instantiate()
	add_child(body)
	var sks := body.find_children("*", "Skeleton3D", true, false)
	skeleton = sks[0] if sks.size() else null
	var aps := body.find_children("*", "AnimationPlayer", true, false)
	anim = aps[0] if aps.size() else null
	if anim:
		anim.playback_default_blend_time = 0.18
		anim.animation_finished.connect(func(_n): _once = false)
		for n in ["Idle", "Walk"]:
			if anim.has_animation(n): anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		lib_ref = anim.get_animation_library("")
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	play("Idle")

func _map(n: String) -> String:
	if MAP.has(n): return MAP[n]
	if n.begins_with("Sword") or n.begins_with("Punch") or n.begins_with("Melee") or n.begins_with("Zombie_Scratch") or n.begins_with("Spell"): return "Attack"
	return n

func has_anim(n: String) -> bool:
	return anim != null and anim.has_animation(_map(n))

func play(n: String, speed := 1.0, blend := -1.0) -> void:
	if _once or anim == null: return
	var m := _map(n)
	if not anim.has_animation(m): return
	anim.speed_scale = speed * speed_mul
	if current == m: return
	current = m
	anim.play(m, blend)

func play_once(n: String, speed := 1.0) -> void:
	if anim == null: return
	var m := _map(n)
	if not anim.has_animation(m): return
	_once = true; current = m; anim.speed_scale = speed
	anim.play(m, 0.1)
	anim.seek(0.0, true)
