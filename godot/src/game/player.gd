class_name Player extends Unit
## You. Point and click, like Albion Online:
##  - left-click the ground to walk there (hold to keep walking toward the cursor)
##  - left-click a monster to target it; click it again (or right-click it) to attack: you walk
##    into range and start swinging. Left-click a friend to target them (for heals).
##  - 1–5 use the five abilities on your bar at your target (ground spells land at the target)
##  - Tab targets the nearest enemy in front of you, Esc clears the target
## WASD also walks, for anyone who prefers it.

signal leveled(level: int)
signal xp_changed

var cam: OrbitCamera
var look := {}
var xp := 0
var gold := 0                       # in copper: 100 copper = 1 silver, 100 silver = 1 gold
var marker: MeshInstance3D
var holding_move := false
var hold_t := 0.0
var pending: String = ""            # an ability waiting until we are in range
var pending_t := 0.0
var save_name := ""

func setup_from(ch: Dictionary) -> void:
	uname = ch.get("name", "Adventurer"); cls = ch.get("cls", "warrior"); level = int(ch.get("level", 1))
	look = ch.get("look", {}); xp = int(ch.get("xp", 0)); gold = int(ch.get("gold", 0))
	faction = "player"
	known = Abilities.for_class(cls)
	bar = ch.get("bar", Abilities.DEFAULT_BAR[cls]).duplicate()
	save_name = uname

func to_save() -> Dictionary:
	return {"name": uname, "cls": cls, "level": level, "look": look, "xp": xp, "gold": gold, "bar": bar,
		"pos": [global_position.x, global_position.z]}

func set_camera(c: OrbitCamera) -> void: cam = c

func _ready() -> void:
	super._ready()
	add_to_group("hero"); add_to_group("player")
	if DisplayServer.get_name() != "headless": Cursors.install()
	model = Avatar.new(); (model as Avatar).look = look; add_child(model)
	_arm()
	refresh_stats(true)
	marker = MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 0.28; tm.outer_radius = 0.36; tm.rings = 24; marker.mesh = tm
	var mm := StandardMaterial3D.new(); mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mm.albedo_color = Color(1.0, 0.86, 0.5, 0.7)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; marker.material_override = mm; marker.visible = false; marker.top_level = true
	add_child(marker)

## the class's starting weapon in hand
func _arm() -> void:
	match cls:
		"warrior":
			model.wield("res://assets/weapons/sword.glb", 0.55)
			weapon = {"min": 3.0 + level * 0.8, "max": 6.0 + level * 1.3, "speed": 2.4}
		"wizard":
			model.wield("res://assets/weapons/staff.glb", 0.62, "hand_r", 50.0)
			weapon = {"min": 2.0 + level * 0.5, "max": 4.0 + level * 0.8, "speed": 2.9}
		"cleric":
			model.wield("res://assets/weapons/club.glb", 0.62, "hand_r", -40.0)
			weapon = {"min": 2.0 + level * 0.6, "max": 4.0 + level * 0.9, "speed": 2.6}

# ------------------------------------------------------------------ input

func _unhandled_input(e: InputEvent) -> void:
	if dead or cam == null: return
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				var hit = _pick(e.position)
				if hit is Unit:
					_click_unit(hit, e.double_click)
					holding_move = false
				elif hit is Vector3:
					move_to(hit); pending = ""
					_mark(hit)
					holding_move = true; hold_t = 0.0
					if attacking and target and distance_to(target) > swing_range(): attacking = false
			else:
				holding_move = false
		elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
			var hit2 = _pick(e.position)
			if hit2 is Unit: _click_unit(hit2, true)
	elif e is InputEventKey and e.pressed and not e.echo:
		var k: int = e.physical_keycode
		if k >= KEY_1 and k <= KEY_5: press_slot(k - KEY_1)
		elif k == KEY_TAB: tab_target()
		elif k == KEY_ESCAPE and target: target = null; attacking = false; changed.emit(); get_viewport().set_input_as_handled()

func press_slot(i: int) -> void:
	if i < 0 or i >= bar.size() or bar[i] == "": return
	var id: String = bar[i]
	var a: Dictionary = Abilities.LIST[id]
	var t := target
	# helpful spells with no friendly target go on yourself
	if a.get("helpful", false) and (t == null or is_enemy(t) or t.dead): t = self
	var why := check_use(id, t)
	if why == "Out of range" and t and not a.get("helpful", false):
		# walk into range and use it on arrival
		pending = id; pending_t = 6.0
		chase(t, float(a.get("range", Rules.SPELL_RANGE)) * 0.9)
		return
	if why != "":
		get_tree().call_group("hud", "error", why); return
	stop_moving()
	use(id, t)
	if t and is_enemy(t) and not a.get("helpful", false) and (cls == "warrior" or a["kind"] == "strike"): start_attack(t)

func _click_unit(u: Unit, attack: bool) -> void:
	var was := target == u
	target = u; changed.emit()
	if is_enemy(u) and (attack or was):
		start_attack(u)
		if distance_to(u) > swing_range() and cls == "warrior": chase(u, swing_range() * 0.8)
		elif cls != "warrior" and distance_to(u) > swing_range():
			# casters: a click on an enemy starts the first spell (or walks in and swings with a wand later)
			pass

## what is under the mouse: a Unit, a ground point, or null
func _pick(sp: Vector2):
	var from := cam.project_ray_origin(sp); var dir := cam.project_ray_normal(sp)
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 500.0, 2); q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit and hit.collider is Unit and not hit.collider.dead: return hit.collider
	q = PhysicsRayQueryParameters3D.create(from, from + dir * 500.0, 1)
	hit = space.intersect_ray(q)
	if not hit: return null
	# forgiving clicks: something standing right where you clicked counts
	var best: Unit = null; var bd := 1.2
	for u in get_tree().get_nodes_in_group("units"):
		if u == self or u.dead or not u.visible: continue
		var d := Vector2(u.global_position.x - hit.position.x, u.global_position.z - hit.position.z).length()
		if d < bd: bd = d; best = u
	if best: return best
	return hit.position

func _mark(p: Vector3) -> void:
	marker.global_position = p + Vector3(0, 0.06, 0); marker.visible = true; marker.scale = Vector3.ONE

func tab_target() -> void:
	var best: Unit = null; var bs := 1e9
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	if cam: fwd = -cam.global_basis.z; fwd.y = 0; fwd = fwd.normalized()
	for u in get_tree().get_nodes_in_group("units"):
		if u.dead or not is_enemy(u) or not u.visible or u == target: continue
		var d: Vector3 = u.global_position - global_position; d.y = 0
		if d.length() > 40.0: continue
		var score := d.length() * (1.0 + (1.0 - fwd.dot(d.normalized())))
		if score < bs: bs = score; best = u
	if best: target = best; changed.emit()

# ------------------------------------------------------------------ every frame

var hover_t := 0.0

## the pointer tells you what a click would do
func _hover() -> void:
	if cam == null: return
	var hit = _pick(get_viewport().get_mouse_position())
	var shape := Input.CURSOR_ARROW
	if hit is Unit:
		shape = Input.CURSOR_CROSS if is_enemy(hit) else Input.CURSOR_POINTING_HAND
	if Input.get_current_cursor_shape() != shape: Input.set_default_cursor_shape(shape)

func _think(delta: float) -> void:
	hover_t += delta
	if hover_t > 0.08: hover_t = 0.0; _hover()
	# keep walking toward the cursor while the button is held
	if holding_move and cam:
		hold_t += delta
		if hold_t > 0.25 and Engine.get_physics_frames() % 6 == 0:
			var hit = _pick(get_viewport().get_mouse_position())
			if hit is Vector3: move_to(hit); _mark(hit)
	# WASD
	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_S)))
	if input.length() > 0.1 and cam:
		var gb := cam.ground_basis()
		var dir: Vector3 = (gb[0] * input.y + gb[1] * input.x).normalized()
		path = PackedVector3Array([global_position + dir * 1.5]); follow = null; pending = ""
	# an ability waiting for range
	if pending != "":
		pending_t -= delta
		if pending_t <= 0.0 or target == null or target.dead: pending = ""
		elif check_use(pending, target) != "Out of range":
			var id := pending; pending = ""
			stop_moving()
			var why := use(id, target)
			if why != "": get_tree().call_group("hud", "error", why)
			elif cls == "warrior": start_attack(target)
	# warriors close in on what they are attacking
	if attacking and target and is_instance_valid(target) and not target.dead and cls == "warrior" and path.is_empty() and pending == "":
		if distance_to(target) > swing_range(): chase(target, swing_range() * 0.8)
	if target and is_instance_valid(target) and target.dead and target.faction == "hostile" and attacking: attacking = false
	if marker.visible:
		marker.rotate_y(delta * 2.0)
		if path.is_empty(): marker.scale = marker.scale.lerp(Vector3.ZERO, 1.0 - exp(-delta * 8.0))
		if marker.scale.x < 0.05: marker.visible = false

# ------------------------------------------------------------------ growing

func gain_xp(n: int, from: Unit = null) -> void:
	if n <= 0 or level >= Rules.MAX_LEVEL: return
	xp += n
	get_tree().call_group("fct", "float_text", self, "+%d XP" % n, Color(0.75, 0.55, 1.0), true)
	while level < Rules.MAX_LEVEL and xp >= Rules.xp_need(level):
		xp -= Rules.xp_need(level); level += 1
		refresh_stats(true)
		_arm_stats()
		get_tree().call_group("fx", "level_up", self)
		leveled.emit(level)
	xp_changed.emit(); changed.emit()

func _arm_stats() -> void:
	match cls:
		"warrior": weapon = {"min": 3.0 + level * 0.8, "max": 6.0 + level * 1.3, "speed": 2.4}
		"wizard": weapon = {"min": 2.0 + level * 0.5, "max": 4.0 + level * 0.8, "speed": 2.9}
		"cleric": weapon = {"min": 2.0 + level * 0.6, "max": 4.0 + level * 0.9, "speed": 2.6}

func gain_gold(c: int) -> void:
	if c <= 0: return
	gold += c; changed.emit()

func _on_death(_k: Unit) -> void:
	get_tree().call_group("hud", "player_died")

## release: back at the graveyard (town edge) with half health; your gear takes a knock later
func release() -> void:
	var g := Nav.nearest_open(Vector3(-18, 0, -14))
	g.y = WorldData.h(g.x, g.z)
	global_position = g
	revive(0.5)
	power = max_power * 0.5 if power_kind == "mana" else 0.0
	in_combat = false; target = null; attacking = false
