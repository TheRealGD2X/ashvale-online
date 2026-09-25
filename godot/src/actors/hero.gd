extends CharacterBody3D
## The player's hero. WASD / arrows move relative to the camera (Shift runs faster, Ctrl walks),
## or left-click the ground to walk there, Albion-style. Space jumps.

var cam: OrbitCamera
var model: Humanoid
var target := Vector3.INF          # click-to-move destination
var yaw := 0.0
var marker: MeshInstance3D
const WALK := 1.9
const JOG := 4.6
const RUN := 6.8

func set_camera(c: OrbitCamera) -> void: cam = c

func _ready() -> void:
	add_to_group("hero")
	var cs := CollisionShape3D.new(); var cap := CapsuleShape3D.new(); cap.radius = 0.32; cap.height = 1.8; cs.shape = cap; cs.position.y = 0.9
	add_child(cs)
	floor_snap_length = 0.6; floor_max_angle = deg_to_rad(50)
	model = Humanoid.new(); model.model = "hero_m"; add_child(model)
	marker = MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 0.28; tm.outer_radius = 0.36; tm.rings = 24; marker.mesh = tm
	var mm := StandardMaterial3D.new(); mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mm.albedo_color = Color(1.0, 0.86, 0.5, 0.7)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; marker.material_override = mm; marker.visible = false; marker.top_level = true
	add_child(marker)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and cam:
		var from := cam.project_ray_origin(e.position); var dir := cam.project_ray_normal(e.position)
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 400.0); q.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if hit:
			target = hit.position
			marker.global_position = target + Vector3(0, 0.05, 0); marker.visible = true
	if e is InputEventKey and e.pressed and e.physical_keycode == KEY_SPACE and is_on_floor():
		velocity.y = 5.2; model.play("Jump_Start", 1.0, 0.1)

func _physics_process(delta: float) -> void:
	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)) - float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)))
	var move := Vector3.ZERO
	if input.length() > 0.1 and cam:
		var gb := cam.ground_basis()
		move = (gb[0] * input.y + gb[1] * input.x).normalized()
		target = Vector3.INF; marker.visible = false
	elif target != Vector3.INF:
		var d := target - global_position; d.y = 0
		if d.length() < 0.25: target = Vector3.INF; marker.visible = false
		else: move = d.normalized()
	var speed := JOG
	if Input.is_physical_key_pressed(KEY_SHIFT): speed = RUN
	elif Input.is_physical_key_pressed(KEY_CTRL): speed = WALK
	var hv := Vector3(velocity.x, 0, velocity.z)
	hv = hv.lerp(move * speed, 1.0 - exp(-delta * (10.0 if move != Vector3.ZERO else 14.0)))
	velocity.x = hv.x; velocity.z = hv.z
	if not is_on_floor(): velocity.y -= 14.0 * delta
	move_and_slide()
	# never fall through the world
	var gh := WorldData.h(global_position.x, global_position.z)
	if global_position.y < gh - 0.5: global_position.y = gh; velocity.y = 0
	# face where we're going, smoothly
	if hv.length() > 0.3:
		var want := atan2(hv.x, hv.z)
		yaw = lerp_angle(yaw, want, 1.0 - exp(-delta * 12.0))
		model.rotation.y = yaw
	_animate(hv.length())
	if marker.visible: marker.rotate_y(delta)

func _animate(v: float) -> void:
	if not is_on_floor() and velocity.y < -1.0: model.play("Jump", 1.0); return
	if model.busy(): return
	if v < 0.25: model.play("Idle")
	elif v < 3.0: model.play("Walk", clampf(v / 1.7, 0.6, 1.5))
	elif v < 5.6: model.play("Jog_Fwd", clampf(v / 4.2, 0.7, 1.4))
	else: model.play("Sprint", clampf(v / 6.4, 0.8, 1.3))
