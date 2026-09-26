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

# ---- belongings, quests, talents
const BAG_SIZE := 20
var bags: Array = []                 # BAG_SIZE entries: null or {"id", "n", ["rolled"]}
var equipped := {}                   # slot -> item
var quests := {}                     # id -> {"have": [counts per objective]}
var done_quests: Array = []
var talents := {}                    # talent id -> rank
var titles: Array = []
var title := ""
var rep := {}                        # faction -> standing
var hearth := "ashvale"             # the zone whose inn is home

var durability := 1.0                # 1 = like new; dying costs 10%, Grom mends it for money
var interact: Node3D                 # an NPC, corpse or thing on the ground we are walking to


func setup_from(ch: Dictionary) -> void:
	uname = ch.get("name", "Adventurer"); cls = ch.get("cls", "warrior"); level = int(ch.get("level", 1))
	look = ch.get("look", {}); xp = int(ch.get("xp", 0)); gold = int(ch.get("gold", 0))
	faction = "player"
	var fresh := not ch.has("known")
	known = ch.get("known", Npcs.starting_abilities(cls)).duplicate() if not ch.get("all_abilities", false) else Abilities.for_class(cls)
	if fresh and ch.get("all_abilities", false) == false and ch.has("bar"):
		# characters from before training existed keep what they had
		known = Abilities.for_class(cls)
	var start_bar: Array = []
	for id in known:
		if start_bar.size() < 5 and Abilities.LIST[id]["kind"] != "buff": start_bar.append(id)
	for id in known:
		if start_bar.size() < 5 and not (id in start_bar): start_bar.append(id)
	while start_bar.size() < 5: start_bar.append("")
	bar = ch.get("bar", start_bar).duplicate()
	bags = ch.get("bags", []).duplicate(true)
	bags.resize(BAG_SIZE)
	equipped = ch.get("equipped", {}).duplicate(true)
	if fresh and equipped.is_empty():
		for id in Items.START[cls]:
			var d: Dictionary = Items.LIST[id]
			equipped[d["slot"]] = {"id": id, "n": 1}
		add_item({"id": "hearthstone", "n": 1})
		add_item({"id": "warm_meal", "n": 4}); add_item({"id": "spring_water", "n": 4})
	quests = ch.get("quests", {}).duplicate(true)
	done_quests = ch.get("done_quests", []).duplicate()
	talents = ch.get("talents", {}).duplicate()
	titles = ch.get("titles", []).duplicate(); title = ch.get("title", "")
	rep = ch.get("rep", {}).duplicate()
	durability = float(ch.get("durability", 1.0))
	hearth = String(ch.get("hearth", "ashvale")).to_lower()

	# rested: every 8 hours away earns 5% of a level (four times faster at the inn), up to a level and a half
	rested = int(ch.get("rested", 0))
	if ch.has("logout"):
		var hours := (Time.get_unix_time_from_system() - float(ch["logout"])) / 3600.0
		var rate := 0.05 * (1.0 if ch.get("at_inn", false) else 0.25)
		rested = mini(int(rested + hours / 8.0 * rate * Rules.xp_need(level)), int(Rules.xp_need(level) * 1.5))

	save_name = uname

func to_save() -> Dictionary:
	return {"name": uname, "cls": cls, "level": level, "look": look, "xp": xp, "gold": gold, "bar": bar,
		"pos": [global_position.x, global_position.z], "known": known, "bags": bags, "equipped": equipped,
		"quests": quests, "done_quests": done_quests, "talents": talents, "titles": titles, "title": title, "rep": rep, "durability": durability,
		"rested": rested, "hearth": hearth, "logout": Time.get_unix_time_from_system(), "at_inn": global_position.distance_to(Vector3(-19, 0, 9)) < 14.0}

# ------------------------------------------------------------------ bags

func add_item(it: Dictionary) -> bool:
	var d := Items.get_def(it)
	if d.is_empty(): return false
	var n := int(it.get("n", 1))
	var stack := int(d.get("stack", 1))
	if stack > 1 and not it.has("rolled"):
		for i in bags.size():
			var b = bags[i]
			if b and b["id"] == it["id"] and int(b["n"]) < stack:
				var put := mini(n, stack - int(b["n"])); b["n"] = int(b["n"]) + put; n -= put
				if n <= 0: break
	while n > 0:
		var free := bags.find(null)
		if free < 0: _hud("error", "Inventory is full"); inventory_changed.emit(); return false
		var put := mini(n, stack)
		var nit := it.duplicate(true); nit["n"] = put
		bags[free] = nit; n -= put
	inventory_changed.emit()
	_quest_items_changed()
	return true

func count_item(id: String) -> int:
	var c := 0
	for b in bags:
		if b and b["id"] == id: c += int(b["n"])
	return c

func remove_item(id: String, n := 1) -> void:
	for i in bags.size():
		var b = bags[i]
		if b and b["id"] == id and n > 0:
			var take := mini(n, int(b["n"])); b["n"] = int(b["n"]) - take; n -= take
			if int(b["n"]) <= 0: bags[i] = null
	inventory_changed.emit()
	_quest_items_changed()

signal inventory_changed
signal quests_changed

## use or equip what's in a bag slot
func use_bag(i: int) -> void:
	var it = bags[i]
	if it == null: return
	var d := Items.get_def(it)
	if d.has("slot"):
		equip_from_bag(i); return
	match d.get("use", ""):
		"food", "drink":
			if in_combat: _hud("error", "You can't eat or drink in combat"); return
			stop_moving()
			add_aura("eating" if d.has("heal") else "drinking", self, 18.0, {"hot": float(d.get("heal", 0)) / 6.0, "mana_regen": float(d.get("mana", 0)) / 18.0}, 3.0)
			act("Sitting_Enter", 1.0); set_meta("sitting", true)
			_consume(i)
		"hearth":
			if cds.has("hearthstone"): _hud("error", "Your hearthstone isn't ready (%d min)" % int(ceil(cds["hearthstone"] / 60.0))); return
			stop_moving()
			var why := use("hearthstone", self)
			if why != "": _hud("error", why)
		"potion":
			if cds.has("potion"): _hud("error", "Not ready yet"); return
			heal(self, float(d.get("heal", 0))); cds["potion"] = 60.0
			_consume(i)

func _consume(i: int) -> void:
	bags[i]["n"] = int(bags[i]["n"]) - 1
	if int(bags[i]["n"]) <= 0: bags[i] = null
	inventory_changed.emit()

func equip_from_bag(i: int) -> void:
	var it = bags[i]
	var d := Items.get_def(it)
	if not Items.can_use(cls, d, level):
		_hud("error", "You can't use that" if Items.can_use(cls, d, 99) else "You must reach level %d to use that" % Items.req_level(d)); return
	var slot: String = d["slot"]
	if slot.begins_with("finger") or slot.begins_with("trinket"):
		var base := slot.trim_suffix("1").trim_suffix("2")
		slot = base + "1" if not equipped.has(base + "1") or equipped.has(base + "2") else base + "2"
	var old = equipped.get(slot)
	equipped[slot] = it
	bags[i] = old
	_gear_changed()

func unequip(slot: String) -> void:
	if not equipped.has(slot): return
	var free := bags.find(null)
	if free < 0: _hud("error", "Inventory is full"); return
	bags[free] = equipped[slot]; equipped.erase(slot)
	_gear_changed()

## stats and looks follow from what you wear
func _gear_changed() -> void:
	var g := {}
	for slot in equipped:
		var d := Items.get_def(equipped[slot])
		for k in d.get("stats", {}): g[k] = int(g.get(k, 0)) + int(d["stats"][k])
		g["armor"] = int(g.get("armor", 0)) + int(d.get("armor", 0))
		g["sp"] = int(g.get("sp", 0)) + int(d.get("sp", 0))
	# talents that add stats
	for k in Talents.stat_bonus(self): g[k] = g.get(k, 0) + Talents.stat_bonus(self)[k]
	gear_stats = g
	var mh = equipped.get("main_hand")
	if mh:
		var w: Array = Items.get_def(mh).get("weapon", [1, 2, 2.0])
		weapon = {"min": float(w[0]), "max": float(w[1]), "speed": float(w[2])}
	else:
		weapon = {"min": 1.0, "max": 2.0, "speed": 2.0}
	refresh_stats()
	_dress()
	inventory_changed.emit()

## rebuild the body when the visible gear changes
func _dress() -> void:
	var gear := {}
	var tint: Dictionary = look.get("tint", {}).duplicate()
	for slot in equipped:
		var d := Items.get_def(equipped[slot])
		if d.has("look"):
			var l: Array = d["look"]
			gear[slot] = l[0]
			tint[l[1]] = int(l[2])
	var sig := str(gear) + str(tint)
	if model and model.has_meta("dressed") and model.get_meta("dressed") == sig: return
	look["gear"] = gear; look["tint"] = tint
	var old := model
	var a := Avatar.new(); a.look = look
	add_child(a); a.rotation.y = yaw
	model = a
	model.set_meta("dressed", sig)
	if old: old.queue_free()
	_arm()

func set_camera(c: OrbitCamera) -> void: cam = c

func _animate(v: float) -> void:
	if has_meta("sitting") and v < 0.3 and model and model.anim and busy_anim <= 0.0:
		model.play("Sitting_Idle"); return
	super._animate(v)

var is_bot := false                 # a simulated player (Bot) uses all of this without the screen

## tell the interface (only for the real player)
func _hud(method: String, a = null, b = null) -> void:
	if is_bot or not is_inside_tree(): return
	if b != null: get_tree().call_group("hud", method, a, b)
	elif a != null: get_tree().call_group("hud", method, a)
	else: get_tree().call_group("hud", method)

func _ready() -> void:
	super._ready()
	if is_bot: add_to_group("bots")
	else:
		add_to_group("hero"); add_to_group("player")
		if DisplayServer.get_name() != "headless": Cursors.install()
	model = null
	_gear_changed()
	refresh_stats(true)
	marker = MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 0.28; tm.outer_radius = 0.36; tm.rings = 24; marker.mesh = tm
	var mm := StandardMaterial3D.new(); mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mm.albedo_color = Color(1.0, 0.86, 0.5, 0.7)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; marker.material_override = mm; marker.visible = false; marker.top_level = true
	add_child(marker)

## the weapon you carry, in your hand
func _arm() -> void:
	var mh = equipped.get("main_hand")
	if mh == null: return
	var d := Items.get_def(mh)
	var m: String = d.get("model", "sword")
	var staffy := m.contains("staff")
	var wand: bool = d.get("wtype", "") == "wand"
	var tilt := 50.0 if staffy else (-40.0 if d.get("wtype", "") == "mace" else 0.0)
	model.wield("res://assets/weapons/%s.glb" % m, 0.62 if staffy else (0.5 if wand else 0.55), "hand_r", tilt)

# ------------------------------------------------------------------ input

func _unhandled_input(e: InputEvent) -> void:
	if dead or cam == null or is_bot: return
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				var hit = _pick(e.position)
				interact = null
				if hit is Pickup:
					go_interact(hit); holding_move = false
				elif hit is Unit:
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
			elif hit2 is Pickup: go_interact(hit2)
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
		_hud("error", why); return
	stop_moving()
	use(id, t)
	if t and is_enemy(t) and not a.get("helpful", false) and (cls == "warrior" or a["kind"] == "strike"): start_attack(t)

func _click_unit(u: Unit, attack: bool) -> void:
	var was := target == u
	if u.dead:
		# a corpse: walk over and look through it
		if u is Monster and u.has_loot(self): go_interact(u)
		return
	target = u; changed.emit()
	if u is Npc:
		go_interact(u); return
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
	var best: Node3D = null; var bd := 1.2
	for u in get_tree().get_nodes_in_group("units"):
		if u == self or not u.visible: continue
		if u.dead and not (u is Monster and u.has_loot(self)): continue
		var d := Vector2(u.global_position.x - hit.position.x, u.global_position.z - hit.position.z).length()
		if d < bd: bd = d; best = u
	for pk in get_tree().get_nodes_in_group("pickups"):
		if not pk.visible or not pk.available: continue
		var d2 := Vector2(pk.global_position.x - hit.position.x, pk.global_position.z - hit.position.z).length()
		if d2 < 1.3 and d2 < bd + 0.3: bd = d2; best = pk
	if best: return best
	return hit.position

## walk up to something and use it when close enough (talk, loot, pick up)
func go_interact(n: Node3D) -> void:
	interact = n
	pending = ""
	if _near(n): _do_interact(); return
	move_to(n.global_position)

func _near(n: Node3D) -> bool:
	var d := n.global_position - global_position; d.y = 0
	return d.length() < 3.2

func _do_interact() -> void:
	var n := interact
	interact = null
	if n == null or not is_instance_valid(n): return
	stop_moving()
	var d := n.global_position - global_position
	yaw = atan2(d.x, d.z); if model: model.rotation.y = yaw
	if n is Npc:
		on_talk(n.npc_id)
		n.face(self)
		_hud("open_npc", n)
	elif n is Monster:
		_hud("open_loot", n)
	elif n is Pickup:
		n.take(self)

func _check_pickup() -> void:
	if interact and is_instance_valid(interact) and _near(interact): _do_interact()

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
	if cam == null or is_bot: return
	var hit = _pick(get_viewport().get_mouse_position())
	var shape := Input.CURSOR_ARROW
	if hit is Unit:
		shape = Input.CURSOR_CROSS if is_enemy(hit) and not hit.dead else Input.CURSOR_POINTING_HAND
		if hit.dead: shape = Input.CURSOR_DRAG
	elif hit is Pickup: shape = Input.CURSOR_DRAG
	if Input.get_current_cursor_shape() != shape: Input.set_default_cursor_shape(shape)

func _think(delta: float) -> void:
	_explore_t += delta
	if _explore_t > 0.5: _explore_t = 0.0; _check_explore(); _check_pickup()
	if has_meta("sitting") and (is_moving() or in_combat):
		remove_meta("sitting"); remove_aura("eating"); remove_aura("drinking")
	elif has_meta("sitting") and not has_aura("eating") and not has_aura("drinking"):
		remove_meta("sitting")
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
	if is_bot or get_viewport().gui_get_focus_owner() is LineEdit: input = Vector2.ZERO
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
			if why != "": _hud("error", why)
			elif cls == "warrior": start_attack(target)
	# warriors close in on what they are attacking
	if attacking and target and is_instance_valid(target) and not target.dead and cls == "warrior" and path.is_empty() and pending == "":
		if distance_to(target) > swing_range(): chase(target, swing_range() * 0.8)
	if target and is_instance_valid(target) and target.dead and target.faction == "hostile" and attacking: attacking = false
	if marker.visible:
		marker.rotate_y(delta * 2.0)
		if path.is_empty(): marker.scale = marker.scale.lerp(Vector3.ZERO, 1.0 - exp(-delta * 8.0))
		if marker.scale.x < 0.05: marker.visible = false

# ------------------------------------------------------------------ loot and the group

var party: Array = []                # other members of our group (simulated players)

func party_members() -> Array:
	var out: Array = [self]
	for m in party:
		if is_instance_valid(m): out.append(m)
	return out

## take one thing from a corpse (-1 = the coins)
func loot_take(m: Monster, i: int) -> void:
	if not m.has_loot(self): return
	if i < 0:
		if m.loot_money > 0:
			var share := m.loot_money / party_members().size()
			gold += share
			_hud("notice", "You loot %s" % Items.money(share))
			get_tree().call_group("fx", "sound", "coins", global_position, -8.0)
			m.loot_money = 0
	elif i < m.loot.size():
		if add_item(m.loot[i]):
			var d := Items.get_def(m.loot[i])
			_hud("loot_line", d, int(m.loot[i].get("n", 1)))
			m.loot.remove_at(i)
	m.loot_taken(); changed.emit()

func loot_all(m: Monster) -> void:
	loot_take(m, -1)
	for i in range(m.loot.size() - 1, -1, -1): loot_take(m, i)

## sell a bag slot to a vendor
func sell(i: int) -> void:
	var it = bags[i]
	if it == null: return
	var d := Items.get_def(it)
	if d.get("quest", false) and int(d.get("sell", 0)) == 0: _hud("error", "The merchant doesn't want that"); return
	var v := int(d.get("sell", 0)) * int(it.get("n", 1))
	if v <= 0: _hud("error", "The merchant doesn't want that"); return
	gold += v; bags[i] = null
	buyback.append(it)
	if buyback.size() > 6: buyback.pop_front()
	get_tree().call_group("fx", "sound", "coins", global_position, -8.0)
	inventory_changed.emit(); _quest_items_changed(); changed.emit()

var buyback: Array = []

func buy(id: String) -> void:
	var d: Dictionary = Items.LIST[id]
	var price := Items.buy_price(d)
	if gold < price: _hud("error", "You don't have enough money"); return
	if add_item({"id": id, "n": 1 if int(d.get("stack", 1)) == 1 else mini(5, int(d["stack"]))}):
		gold -= price
		get_tree().call_group("fx", "sound", "coins", global_position, -8.0)
		changed.emit()

func sell_junk() -> void:
	for i in bags.size():
		if bags[i] and int(Items.get_def(bags[i]).get("q", 1)) == 0 and int(Items.get_def(bags[i]).get("sell", 0)) > 0: sell(i)

func repair_cost() -> int:
	var worth := 0
	for s in equipped: worth += int(Items.get_def(equipped[s]).get("sell", 0))
	return int(ceil((1.0 - durability) * (worth * 0.6 + level * 12)))

func repair() -> void:
	var c := repair_cost()
	if c <= 0: return
	if gold < c: _hud("error", "You don't have enough money"); return
	gold -= c; durability = 1.0
	get_tree().call_group("fx", "sound", "anvil", global_position, -6.0)
	changed.emit()

## learn an ability from a trainer
func train(id: String, cost: int) -> void:
	if id in known: return
	if gold < cost: _hud("error", "You don't have enough money"); return
	gold -= cost; known.append(id)
	var free := bar.find("")
	if free >= 0: bar[free] = id
	_hud("notice", "You have learned %s." % Abilities.LIST[id]["name"])
	get_tree().call_group("fx", "sound", "learn", global_position, -6.0)
	get_tree().call_group("fx", "level_up", self)
	changed.emit()

# ------------------------------------------------------------------ talents

var _tm := {}                        # talent effect cache

func tmod(key: String) -> float:
	if not _tm.has(key): _tm[key] = Talents.mod(self, key)
	return _tm[key]

func learn_talent(id: String) -> bool:
	if not Talents.can_learn(self, id): return false
	talents[id] = int(talents.get(id, 0)) + 1
	_tm.clear()
	var t := Talents.find(cls, id)
	var ab = t.get("fx", {}).get("learn", "")
	if ab is String and ab != "" and Abilities.LIST.has(ab) and not (ab in known):
		known.append(ab)
		_hud("notice", "You have learned a new ability: %s." % Abilities.LIST[ab]["name"])
	_gear_changed()
	talents_changed.emit()
	return true

func reset_talents() -> void:
	for id in talents:
		var ab = Talents.find(cls, id).get("fx", {}).get("learn", "")
		if ab is String and ab in known:
			known.erase(ab)
			var i := bar.find(ab)
			if i >= 0: bar[i] = ""
	talents.clear(); _tm.clear()
	_gear_changed(); talents_changed.emit()

signal talents_changed

# ------------------------------------------------------------------ quests

## where a quest stands for this player: "done", "active", "complete" (ready to hand in),
## "available", "low" (not yet: level), "locked" (earlier quests first)
func quest_state(id: String) -> String:
	if id in done_quests: return "done"
	if quests.has(id): return "complete" if quest_complete(id) else "active"
	var q: Dictionary = Quests.LIST[id]
	for a in q.get("after", []):
		if not (a in done_quests): return "locked"
	if q.has("needs_item") and count_item(q["needs_item"]) <= 0: return "locked"
	if level < int(q.get("min", 1)): return "low"
	return "available"

func quest_complete(id: String) -> bool:
	if not quests.has(id): return false
	var q: Dictionary = Quests.LIST[id]
	var have: Array = quests[id]["have"]
	for i in q["obj"].size():
		var o: Dictionary = q["obj"][i]
		if o["kind"] == "talk":
			if o.has("take") and count_item(o["take"]) <= 0: return false
			# the last step of a delivery or "speak to" quest happens when you hand it in
			if o["npc"] == ender_of(id): continue
		if int(have[i]) < int(o.get("n", 1)): return false
	return true

static func ender_of(id: String) -> String:
	var q: Dictionary = Quests.LIST[id]
	return q.get("ender", q["giver"])

func accept_quest(id: String) -> void:
	if quest_state(id) != "available": return
	if quests.size() >= 20: _hud("error", "Your quest log is full"); return
	var q: Dictionary = Quests.LIST[id]
	quests[id] = {"have": []}
	for o in q["obj"]: quests[id]["have"].append(0)
	for it in q.get("provide", []): add_item({"id": it, "n": 1})
	_recount(id)
	_hud("notice", "Quest accepted: %s" % q["title"])
	get_tree().call_group("fx", "sound", "quest_accept", global_position, -6.0)
	quests_changed.emit()

func abandon_quest(id: String) -> void:
	if not quests.has(id): return
	var q: Dictionary = Quests.LIST[id]
	quests.erase(id)
	for it in q.get("provide", []): remove_item(it, count_item(it))
	_hud("notice", "Abandoned: %s" % q["title"])
	quests_changed.emit()

## hand a quest in; choice is the index of the reward picked (if there is a choice)
func turn_in(id: String, choice := -1) -> bool:
	if not quest_complete(id): return false
	var q: Dictionary = Quests.LIST[id]
	var free := bags.count(null)
	var gets: int = q.get("items", []).size() + (1 if q.has("choice") else 0)
	if free < gets: _hud("error", "Inventory is full"); return false
	if q.has("choice") and (choice < 0 or choice >= q["choice"].size()): _hud("error", "Choose a reward first"); return false
	# take what the quest asked for
	for o in q["obj"]:
		if o["kind"] in ["collect", "gather"]: remove_item(o["item"], int(o["n"]))
		if o.has("take"): remove_item(o["take"], 1)
	for it in q.get("provide", []): remove_item(it, count_item(it))
	quests.erase(id); done_quests.append(id)
	# and give what it promised
	for it in q.get("items", []): add_item({"id": it, "n": 1})
	if q.has("choice"): add_item({"id": q["choice"][choice], "n": 1})
	if q.has("money"): gold += int(q["money"])
	if q.has("rep"): rep["Ashvale"] = int(rep.get("Ashvale", 0)) + int(q["rep"])
	if q.has("title_reward"):
		titles.append(q["title_reward"])
		_hud("notice", "You have earned a title: %s" % q["title_reward"])
	_hud("notice", "%s completed." % q["title"])
	get_tree().call_group("fx", "sound", "quest_done", global_position, -4.0)
	gain_xp(Quests.xp_for(id, level))
	quests_changed.emit(); changed.emit()
	return true

## progress from items in the bags (collect / gather objectives)
func _quest_items_changed() -> void:
	var any := false
	for id in quests: any = _recount(id) or any
	if any: quests_changed.emit()

func _recount(id: String) -> bool:
	var q: Dictionary = Quests.LIST[id]
	var have: Array = quests[id]["have"]
	var moved := false
	for i in q["obj"].size():
		var o: Dictionary = q["obj"][i]
		if o["kind"] in ["collect", "gather"]:
			var c := mini(count_item(o["item"]), int(o["n"]))
			if c != int(have[i]):
				if c > int(have[i]): _progress_text(o, c)
				have[i] = c; moved = true
	if moved: _check_done(id)
	return moved

func _progress_text(o: Dictionary, c: int) -> void:
	if not is_inside_tree(): return
	_hud("quest_progress", Quests.objective_text(o, c))

func _check_done(id: String) -> void:
	if quest_complete(id) and is_inside_tree():
		_hud("quest_progress", "%s (Complete)" % Quests.LIST[id]["title"])

## a monster died and we get the credit
func on_kill(m: Unit) -> void:
	if not (m is Monster): return
	var key: String = Monster.KINDS[m.kind].get("as", m.kind)
	var moved := false
	for id in quests:
		var q: Dictionary = Quests.LIST[id]
		for i in q["obj"].size():
			var o: Dictionary = q["obj"][i]
			if o["kind"] == "kill" and o["mon"] == key and int(quests[id]["have"][i]) < int(o["n"]):
				quests[id]["have"][i] = int(quests[id]["have"][i]) + 1
				_progress_text(o, quests[id]["have"][i]); moved = true
				_check_done(id)
	if moved: quests_changed.emit()

## what a monster's corpse should hold for us: quest items we still need
func quest_drops(m: Monster) -> Array:
	var out := []
	var key: String = Monster.KINDS[m.kind].get("as", m.kind)
	for id in quests:
		var q: Dictionary = Quests.LIST[id]
		for i in q["obj"].size():
			var o: Dictionary = q["obj"][i]
			if o["kind"] == "collect" and key in o.get("from", []) and count_item(o["item"]) < int(o["n"]):
				var chance := float(o.get("chance", 0.5))
				# "drops for sure once the kills are done" (the kill objective at index sure_after)
				if o.has("sure_after") and int(quests[id]["have"][int(o["sure_after"])]) >= int(q["obj"][int(o["sure_after"])]["n"]): chance = 1.0
				if randf() < chance: out.append({"id": o["item"], "n": 1})

	return out

## we spoke to someone: "speak to" objectives
func on_talk(npc: String) -> void:
	var moved := false
	for id in quests:
		var q: Dictionary = Quests.LIST[id]
		for i in q["obj"].size():
			var o: Dictionary = q["obj"][i]
			if o["kind"] == "talk" and o["npc"] == npc and int(quests[id]["have"][i]) < 1 and (not o.has("take") or count_item(o["take"]) > 0):
				quests[id]["have"][i] = 1; moved = true
				if npc != ender_of(id): _progress_text(o, 1)
				_check_done(id)
	if moved: quests_changed.emit()

var _explore_t := 0.0
func _check_explore() -> void:
	for id in quests:
		var q: Dictionary = Quests.LIST[id]
		for i in q["obj"].size():
			var o: Dictionary = q["obj"][i]
			if o["kind"] == "explore" and int(quests[id]["have"][i]) < 1:
				var at := Vector2(o["at"][0], o["at"][1])
				if Vector2(global_position.x, global_position.z).distance_to(at) < float(o.get("r", 10.0)):
					quests[id]["have"][i] = 1
					_hud("quest_progress", "%s explored" % o.get("name", "Place"))
					# some places answer back: the dead climb out of the ground
					if o.has("spawn"): get_tree().call_group("spawns", "rise", o["spawn"][0], int(o["spawn"][1]), int(o["spawn"][2]), global_position, self)

					_check_done(id); quests_changed.emit()

## the quests an NPC has for us, in WoW's order: hand-ins first, then new ones, then ones underway
func quests_at(npc: String) -> Dictionary:
	var out := {"complete": [], "available": [], "active": []}
	for id in Quests.LIST:
		var q: Dictionary = Quests.LIST[id]
		var st := quest_state(id)
		if st == "complete" and ender_of(id) == npc: out["complete"].append(id)
		elif st == "available" and q["giver"] == npc: out["available"].append(id)
		elif st == "active" and ender_of(id) == npc: out["active"].append(id)
	return out

# ------------------------------------------------------------------ growing

var rested := 0                    # bonus experience from resting (logged out) at an inn: doubles kill XP until used

## back to the inn (the hearthstone)
func go_home() -> void:
	var hz := hearth if Zones.DEFS.has(hearth) else "ashvale"
	var inn: Vector2 = Zones.get_def(hz)["inn"]
	if hz != WorldData.zone_id:
		if is_bot: return
		get_tree().current_scene.travel_to(hz, inn); return
	var at := Nav.nearest_open(Vector3(inn.x, 0, inn.y)); at.y = WorldData.h(at.x, at.z)
	global_position = at; stop_moving(); target = null; attacking = false
	get_tree().call_group("fx", "play", "blink", self, self, global_position)

func gain_xp(n: int, from: Unit = null) -> void:
	if n <= 0 or level >= Rules.MAX_LEVEL: return
	if from and rested > 0:
		var bonus := mini(n, rested); rested -= bonus; n += bonus
	xp += n
	if not is_bot: get_tree().call_group("fct", "float_text", self, "+%d XP" % n, Color(0.75, 0.55, 1.0), true)
	while level < Rules.MAX_LEVEL and xp >= Rules.xp_need(level):
		xp -= Rules.xp_need(level); level += 1
		refresh_stats(true)
		_arm_stats()
		get_tree().call_group("fx", "level_up", self)
		leveled.emit(level)
	xp_changed.emit(); changed.emit()

func _arm_stats() -> void:
	pass

func gain_gold(c: int) -> void:
	if c <= 0: return
	gold += c; changed.emit()

func _on_death(_k: Unit) -> void:
	_hud("player_died")
	# your gear takes a knock (Grom repairs it)
	durability = maxf(0.0, durability - 0.1)

## release: back at the graveyard (town edge) with half health; your gear takes a knock later
func release() -> void:
	var gy: Vector2 = WorldData.Z.get("graveyard", Vector2(-18, -14))
	var g := Nav.nearest_open(Vector3(gy.x, 0, gy.y))
	g.y = WorldData.h(g.x, g.z)
	global_position = g
	revive(0.5)
	power = max_power * 0.5 if power_kind == "mana" else 0.0
	in_combat = false; target = null; attacking = false
