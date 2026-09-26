class_name OrbitCamera extends Camera3D
## Follows a target from above and behind, Albion-style by default. Hold the right mouse button
## (or middle) and drag to turn and tilt, mouse wheel to zoom from over-the-shoulder to a high
## overview. Q / E turn too. Never dips under the ground.

@export var target: Node3D
var yaw := 0.0                 # radians, 0 = looking north (-z)
var pitch := deg_to_rad(-50.0)
var dist := 12.0
var want_dist := 12.0
var shake_t := 0.0
var shake_amt := 0.0
var focus := Vector3.ZERO
const MIN_D := 2.8
const MAX_D := 34.0
var dragging := false

func _ready() -> void:
	add_to_group("camera")
	fov = 50.0; near = 0.1; far = 1200.0
	if target: focus = target.global_position

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_RIGHT or e.button_index == MOUSE_BUTTON_MIDDLE: dragging = e.pressed
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_UP: want_dist = maxf(MIN_D, want_dist / 1.15)
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_DOWN: want_dist = minf(MAX_D, want_dist * 1.15)
	elif e is InputEventMouseMotion and dragging:
		yaw -= e.relative.x * 0.006
		pitch = clampf(pitch - e.relative.y * 0.005, deg_to_rad(-80), deg_to_rad(-6))

func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_Q): yaw += delta * 1.8
	if Input.is_physical_key_pressed(KEY_E): yaw -= delta * 1.8
	dist = lerpf(dist, want_dist, 1.0 - exp(-delta * 10.0))
	if target:
		var t := target.global_position + Vector3(0, 1.35, 0)
		focus = focus.lerp(t, 1.0 - exp(-delta * 12.0))
	place()

func place() -> void:
	# closer in, the camera levels out to look past the hero's shoulder; far out it looks down
	var closeness := 1.0 - clampf((dist - MIN_D) / 10.0, 0.0, 1.0)
	var p := lerpf(pitch, maxf(pitch, deg_to_rad(-16)), closeness * 0.8)
	var dir := Vector3(sin(yaw) * cos(p), -sin(p), cos(yaw) * cos(p))
	var pos := focus + dir * dist
	var g := WorldData.h(pos.x, pos.z) + 0.6
	if pos.y < g: pos.y = g
	if shake_t > 0.0:
		shake_t -= get_process_delta_time()
		var k := shake_amt * clampf(shake_t / 0.35, 0.0, 1.0)
		pos += Vector3(randf_range(-k, k), randf_range(-k, k), randf_range(-k, k))
	global_position = pos
	look_at(focus + Vector3(0, -0.15 * (1.0 - closeness), 0), Vector3.UP)

## a jolt for heavy hits and big spells
func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt if shake_t > 0.0 else 0.0, amount); shake_t = 0.35

## a flat forward/right on the ground, for camera-relative movement
func ground_basis() -> Array:
	var f := Vector3(-sin(yaw), 0, -cos(yaw))
	return [f, Vector3(-f.z, 0, f.x)]
