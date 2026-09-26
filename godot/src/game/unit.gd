class_name Unit extends CharacterBody3D
## Anyone who can fight: the player, simulated players, monsters. Holds health and power (Rage or
## Mana), stats, the current target, auto-attack, casting, cooldowns, auras (buffs, debuffs,
## damage and healing over time, shields) and a threat table (for monsters). Walks along Nav paths.
##
## The body is a Humanoid (or Avatar) in `model`; the Unit plays its animations.

signal changed                       # health, power, auras or casting changed
signal died(unit: Unit)
signal struck(unit: Unit, amount: int, crit: bool, school: String, kind: String)   # took damage / healing

@export var uname := "Someone"
@export var level := 1
@export var cls := "warrior"         # a class id, or "monster"
@export var faction := "hostile"     # player | friendly | hostile | neutral
var model: Humanoid
var elite := false
var creature_type := "humanoid"      # humanoid | beast | undead | demon | elemental

# ---- stats
var attrs := {"str": 10, "agi": 10, "sta": 10, "int": 10, "spi": 10}
var gear_stats := {}                 # from equipped items: str, agi, sta, int, spi, armor, sp (spell power), ap, crit, hit
var armor := 0.0
var weapon := {"min": 2.0, "max": 4.0, "speed": 2.4}
var hp := 100.0
var max_hp := 100.0
var power := 0.0
var max_power := 0.0
var power_kind := "mana"             # mana | rage | none
var move_speed := Rules.RUN_SPEED
var radius := 0.45                   # body size, for melee reach

# ---- combat state
var target: Unit
var attacking := false
var swing_t := 0.0
var in_combat := false
var combat_t := 0.0                  # time since last hostile action
var casting := {}                    # {id, t, dur, target, pos, channel, ticks, tick_i}
var gcd := 0.0
var cds := {}                        # ability id -> seconds left
var auras: Array = []                # {id, src, t, dur, tick, next, data}
var threat := {}                     # Unit -> threat (monsters)
var dead := false
var known: Array = []                # ability ids (the spellbook)
var bar: Array = ["", "", "", "", ""]
var last_cast_t := 99.0              # seconds since the last mana spend (for the regen rule)

# ---- movement
var path := PackedVector3Array()
var follow: Unit
var follow_range := 0.0
var yaw := 0.0
var stunned := 0.0
var rooted := 0.0
var home := Vector3.ZERO
var busy_anim := 0.0

func _ready() -> void:
	add_to_group("units")
	collision_layer = 2; collision_mask = 1
	var cs := CollisionShape3D.new(); var cap := CapsuleShape3D.new(); cap.radius = 0.32; cap.height = 1.8; cs.shape = cap; cs.position.y = 0.9
	add_child(cs)
	floor_snap_length = 0.8; floor_max_angle = deg_to_rad(55)
	home = global_position

# ------------------------------------------------------------------ stats

## recompute derived stats (after level-up, gear change or auras)
func refresh_stats(fill := false) -> void:
	if cls in Rules.CLASSES:
		var a := Rules.attrs(cls, level)
		for k in a: attrs[k] = a[k] + int(gear_stats.get(k, 0))
		var old := max_hp
		max_hp = (Rules.base_hp(cls, level) + attrs["sta"] * 10) * (1.0 + tmod("hp_pct")) + _aura_sum("max_hp")
		power_kind = Rules.CLASSES[cls]["power"]
		if power_kind == "mana": max_power = Rules.base_mp(cls, level) + attrs["int"] * 15
		else: max_power = 100.0
		armor = float(gear_stats.get("armor", 0)) * (1.0 + tmod("armor_pct")) + attrs["agi"] * 2.0 + _aura_sum("armor")
		if fill: hp = max_hp; power = max_power if power_kind == "mana" else 0.0
		elif old > 0: hp = minf(hp, max_hp)
	changed.emit()

func attack_power() -> float:
	var ap := float(gear_stats.get("ap", 0)) + _aura_sum("ap")
	if cls == "warrior": ap += attrs["str"] * 2.0 + level * 3.0
	else: ap += attrs["str"]
	return ap

func spell_power() -> float:
	return float(gear_stats.get("sp", 0)) + _aura_sum("sp")

## talent effects (see Talents); only players have talents
func tmod(_key: String) -> float:
	return 0.0

## how much harder this unit hits with a school / ability, from talents and auras
func dmg_mult(school: String, id := "") -> float:
	var m := 1.0 + tmod("dmg_all") + tmod("dmg_" + school) + _aura_sum("dmg_pct")
	if school == "physical": m += tmod("dmg_melee")
	if id != "": m += tmod("dmg_" + id)
	return m

func crit_chance(spell: bool) -> float:
	var c := 0.05 + float(gear_stats.get("crit", 0)) / 100.0 + (tmod("crit_spell") if spell else tmod("crit"))
	# about 1% per 12 points of Agility (Intellect for spells) at level 10, per 29 at level 60
	c += float(attrs["int"] if spell else attrs["agi"]) / (8.0 + level * 0.35) / 100.0

	return clampf(c, 0.0, 0.5)

func base_mana() -> int:
	return Rules.base_mp(cls, level) + int(Rules.attrs(cls, level)["int"]) * 15 if cls in Rules.CLASSES and power_kind == "mana" else int(max_power)

func _aura_sum(key: String) -> float:
	var s := 0.0
	for a in auras: s += float(a["data"].get(key, 0.0))
	return s

func has_aura(id: String) -> bool:
	for a in auras:
		if a["id"] == id: return true
	return false

## hostile monsters fight you on sight; neutral ones (boars, hens) only if you start it
func is_enemy(o: Unit) -> bool:
	if o == null or o == self: return false
	if faction in ["hostile", "neutral"]: return o.faction in ["player", "friendly"]
	if faction in ["player", "friendly"]: return o.faction in ["hostile", "neutral"]
	return false

func distance_to(o: Unit) -> float:
	var d := global_position - o.global_position; d.y = 0
	return maxf(0.0, d.length() - radius - o.radius)

# ------------------------------------------------------------------ movement

func move_to(p: Vector3) -> void:
	follow = null
	path = Nav.path(global_position, p)

func chase(o: Unit, rng: float) -> void:
	if follow == o and abs(follow_range - rng) < 0.01 and not path.is_empty(): return
	follow = o; follow_range = rng
	path = Nav.path(global_position, o.global_position)

func stop_moving() -> void:
	path.clear(); follow = null

func is_moving() -> bool:
	return not path.is_empty()

func speed_mult() -> float:
	var m := 1.0
	for a in auras:
		if a["data"].has("slow"): m = minf(m, 1.0 - float(a["data"]["slow"]))
	return m

func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector3.ZERO
		if not is_on_floor(): velocity.y = -9.0; move_and_slide()
		return
	_tick_timers(delta)
	_tick_auras(delta)
	_tick_cast(delta)
	_tick_swing(delta)
	_tick_regen(delta)
	_think(delta)
	# walking
	var mv := Vector3.ZERO
	if follow and is_instance_valid(follow):
		if distance_to(follow) <= follow_range * 0.9: path.clear()
		elif path.is_empty() or path[path.size() - 1].distance_to(follow.global_position) > 1.5:
			path = Nav.path(global_position, follow.global_position)
	if not path.is_empty() and stunned <= 0.0 and rooted <= 0.0:
		var p := path[0]
		var d := p - global_position; d.y = 0
		if d.length() < 0.35:
			path.remove_at(0)
		else:
			mv = d.normalized()
			if not casting.is_empty(): cancel_cast("Interrupted")
	var sp := move_speed * speed_mult()
	var hv := Vector3(velocity.x, 0, velocity.z).lerp(mv * sp, 1.0 - exp(-delta * 14.0))
	velocity.x = hv.x; velocity.z = hv.z
	velocity.y = velocity.y - 18.0 * delta if not is_on_floor() else -1.0
	move_and_slide()
	var gh := WorldData.h(global_position.x, global_position.z)
	if global_position.y < gh - 0.4: global_position.y = gh; velocity.y = 0
	# facing: where we walk, or the target while fighting or casting
	var face_dir := Vector3.ZERO
	if hv.length() > 0.4: face_dir = hv
	elif target and is_instance_valid(target) and (attacking or not casting.is_empty()) and target != self:
		face_dir = target.global_position - global_position
	elif casting.has("pos"): face_dir = casting["pos"] - global_position
	if face_dir.length() > 0.05 and stunned <= 0.0:
		yaw = lerp_angle(yaw, atan2(face_dir.x, face_dir.z), 1.0 - exp(-delta * 12.0))
		if model: model.rotation.y = yaw
	_animate(hv.length())

func _animate(v: float) -> void:
	if model == null or model.anim == null: return
	if busy_anim > 0.0 and v < 0.4: return
	if stunned > 0.0: model.play("Hit_Knockback" if model.has_anim("Hit_Knockback") else "Idle", 0.3); return
	if not casting.is_empty():
		model.play("Spell_Simple_Idle", 1.0); return
	if v < 0.3:
		model.play("Sword_Idle" if (attacking or in_combat) and _armed() else "Idle")
	elif v < 3.0: model.play("Walk", clampf(v / 1.7, 0.6, 1.5))
	else: model.play("Jog_Fwd", clampf(v / 4.4, 0.8, 1.4))

func _armed() -> bool:
	return cls != "monster"

## play a one-shot move (attack, cast release, hit reaction)
func act(anim: String, speed := 1.0) -> void:
	if model == null or anim == "" or not model.has_anim(anim): return
	model.play_once(anim, speed)
	var real: String = model._map(anim) if model.has_method("_map") else anim
	if model.anim.has_animation(real): busy_anim = model.anim.get_animation(real).length / speed * 0.85

# ------------------------------------------------------------------ timers

func _tick_timers(delta: float) -> void:
	gcd = maxf(0.0, gcd - delta)
	busy_anim = maxf(0.0, busy_anim - delta)
	stunned = maxf(0.0, stunned - delta)
	rooted = maxf(0.0, rooted - delta)
	last_cast_t += delta
	for k in cds.keys():
		cds[k] -= delta
		if cds[k] <= 0.0: cds.erase(k)
	combat_t += delta
	if in_combat and combat_t > 6.0 and threat.is_empty() and not _anyone_attacking_me():
		leave_combat()

func _anyone_attacking_me() -> bool:
	for u in get_tree().get_nodes_in_group("units"):
		if u != self and not u.dead and u.target == self and u.in_combat and u.is_enemy(self): return true
	return false

func enter_combat() -> void:
	combat_t = 0.0
	if not in_combat:
		in_combat = true; changed.emit()

func leave_combat() -> void:
	in_combat = false; attacking = false; threat.clear(); changed.emit()

func _tick_regen(delta: float) -> void:
	if power_kind == "mana":
		var rate: float = attrs["spi"] * 0.06 + max_power * 0.004
		if last_cast_t < 5.0: rate *= 0.15 + tmod("combat_regen")
		if not in_combat: rate *= 2.0
		power = minf(max_power, power + (rate + _aura_sum("mana_regen")) * delta)
	elif power_kind == "rage" and not in_combat:
		power = maxf(0.0, power - 3.0 * delta)
	if not in_combat and hp < max_hp and hp > 0:
		hp = minf(max_hp, hp + (attrs["spi"] * 0.05 + max_hp * 0.012) * delta)

# ------------------------------------------------------------------ auto-attack

func start_attack(t: Unit) -> void:
	if t == null or not is_enemy(t) or t.dead: return
	target = t; attacking = true
	enter_combat()

func swing_range() -> float:
	return Rules.MELEE_RANGE

func _tick_swing(delta: float) -> void:
	swing_t = maxf(0.0, swing_t - delta)
	if not attacking or target == null or not is_instance_valid(target) or target.dead:
		attacking = false; return
	if not casting.is_empty() or stunned > 0.0: return
	if distance_to(target) > swing_range(): return
	if swing_t > 0.0: return
	var spd: float = weapon["speed"] * (1.0 + _aura_sum("slow_attack")) / (1.0 + tmod("haste"))
	swing_t = spd
	var dmg: float = randf_range(weapon["min"], weapon["max"]) + attack_power() / 14.0 * weapon["speed"]
	melee_hit(target, dmg, "white")
	# Sweeping Strikes: the swing also catches one more enemy nearby
	if tmod("cleave") > 0.0:
		for u in enemies_near(target.global_position, 3.0):
			if u != target: melee_hit(u, dmg * 0.6, "white"); break
	act(["Sword_Regular_A", "Sword_Regular_B"][randi() % 2] if _armed() else "Punch_Jab", 1.0)

## one melee hit through the hit table; returns the damage dealt (0 on miss/dodge)
func melee_hit(t: Unit, dmg: float, kind := "white", threat_mult := 1.0) -> int:
	var r := randf()
	var miss := 0.05 + 0.01 * maxi(0, t.level - level)
	if r < miss: t.show_text("Miss", Color(1, 1, 1), self); _swing_sound(t, "miss"); return 0
	if r < miss + 0.05 + t.tmod("dodge"): t.show_text("Dodge", Color(1, 1, 1), self); t._on_dodge(); _swing_sound(t, "miss"); return 0
	var crit := randf() < crit_chance(false)
	if kind == "white": _swing_sound(t, "crit" if crit else "hit")
	if crit: dmg *= 2.0 + tmod("crit_bonus")
	dmg *= dmg_mult("physical", cur_ability)
	dmg *= 1.0 - Rules.armor_dr(t.armor, level)
	var got := t.take_damage(self, dmg, "physical", crit, kind, threat_mult)
	if power_kind == "rage":
		gain_rage(7.5 * got / maxf(1.0, 8.0 + 2.2 * level) * (1.15 if kind == "white" else 0.0) * (1.0 + tmod("rage_gen")))
	return got

func _swing_sound(t: Unit, result: String) -> void:
	get_tree().call_group("fx", "melee", self, t, result)

func _on_dodge() -> void:
	pass

func gain_rage(n: float) -> void:
	if power_kind != "rage": return
	power = clampf(power + n, 0.0, max_power); changed.emit()

# ------------------------------------------------------------------ damage and healing

## deal damage to this unit; returns what actually got through (after shields)
func take_damage(src: Unit, amount: float, school := "physical", crit := false, kind := "", threat_mult := 1.0) -> int:
	if dead: return 0
	var dmg := int(round(maxf(1.0, amount)))
	# shields absorb first
	var absorbed := 0
	for a in auras:
		if a["data"].has("absorb") and dmg > 0:
			var take := mini(dmg, int(a["data"]["absorb"]))
			a["data"]["absorb"] -= take; dmg -= take; absorbed += take
			if a["data"]["absorb"] <= 0: a["t"] = a["dur"]
	hp -= dmg
	enter_combat()
	if src and is_instance_valid(src):
		src.enter_combat()
		add_threat(src, (dmg + absorbed) * threat_mult * (1.0 + src.tmod("threat")))
		if target == null and faction != "player": target = src
	if power_kind == "rage" and dmg > 0: gain_rage(2.5 * dmg / maxf(1.0, max_hp) * 100.0 * 0.5)
	# roots break on damage (after a short grace)
	for a in auras:
		if a["data"].has("root") and not a["data"].has("cage") and a["t"] > 1.5: a["t"] = a["dur"]
	struck.emit(self, dmg, crit, school, kind)
	if absorbed > 0: show_text("Absorb %d" % absorbed, Color(0.9, 0.9, 0.7), src)
	if dmg > 0 and model and busy_anim <= 0.0 and casting.is_empty() and randf() < 0.35: act("Hit_Chest", 1.2)
	if hp <= 0: die(src)
	changed.emit()
	return dmg

func heal(src: Unit, amount: float, crit := false) -> int:
	if dead: return 0
	if src and is_instance_valid(src): amount *= 1.0 + src.tmod("heal") + src.tmod("heal_" + src.cur_ability) - _aura_sum("heal_taken_down")
	var h := int(round(amount))
	var real := mini(h, int(max_hp - hp))
	hp = minf(max_hp, hp + h)
	struck.emit(self, h, crit, "holy", "heal")
	# healing draws the attention of every monster fighting the healed one
	if src and real > 0:
		for u in get_tree().get_nodes_in_group("units"):
			if u.faction == "hostile" and u.threat.has(self): u.add_threat(src, real * 0.5)
	changed.emit()
	return real

func add_threat(src: Unit, amount: float) -> void:
	if not (faction in ["hostile", "neutral"]) or src == null: return
	threat[src] = float(threat.get(src, 0.0)) + amount

func show_text(text: String, col: Color, _src: Unit = null) -> void:
	get_tree().call_group("fct", "float_text", self, text, col, false)

func die(killer: Unit) -> void:
	if dead: return
	dead = true; hp = 0; attacking = false; casting.clear(); path.clear(); auras.clear()
	collision_layer = 0
	if model: model.play_once("Death01", 1.0); busy_anim = 999.0
	died.emit(self)
	changed.emit()
	get_tree().call_group("fx", "died", self)
	_on_death(killer)

func _on_death(_killer: Unit) -> void:
	pass

func revive(frac := 1.0) -> void:
	dead = false; hp = max_hp * frac; collision_layer = 2; busy_anim = 0.0
	if model: model._once = false; model.current = ""; model.play("Idle")
	changed.emit()

# ------------------------------------------------------------------ auras

func add_aura(id: String, src: Unit, dur: float, data := {}, tick := 0.0) -> void:
	for a in auras:
		if a["id"] == id and a["src"] == src:
			a["t"] = 0.0; a["dur"] = dur; a["data"] = data; a["next"] = tick
			_aura_changed(); return
	auras.append({"id": id, "src": src, "t": 0.0, "dur": dur, "tick": tick, "next": tick, "data": data})
	if data.has("root"): rooted = maxf(rooted, dur)
	_aura_changed()
	get_tree().call_group("fx", "aura_added", self, id)

func remove_aura(id: String) -> void:
	for i in range(auras.size() - 1, -1, -1):
		if auras[i]["id"] == id: auras.remove_at(i)
	_aura_changed()

func _aura_changed() -> void:
	if cls in Rules.CLASSES: refresh_stats()
	changed.emit()

func _tick_auras(delta: float) -> void:
	var gone := false
	for i in range(auras.size() - 1, -1, -1):
		var a: Dictionary = auras[i]
		a["t"] += delta
		if a["tick"] > 0.0 and a["t"] >= a["next"] - 0.001 and a["t"] <= a["dur"] + 0.01:
			a["next"] += a["tick"]
			var d: Dictionary = a["data"]
			var src: Unit = a["src"] if is_instance_valid(a["src"]) else null
			if d.has("dot"): take_damage(src, d["dot"], d.get("school", "physical"), false, "dot")
			if d.has("hot"): heal(src, d["hot"])
			if dead: return
		if a["t"] >= a["dur"]:
			auras.remove_at(i); gone = true
			get_tree().call_group("fx", "aura_removed", self, a["id"])
	rooted = 0.0
	for a in auras:
		if a["data"].has("root"): rooted = maxf(rooted, a["dur"] - a["t"])
	if gone: _aura_changed()

# ------------------------------------------------------------------ abilities

## why an ability can't be used right now ("" if it can)
func check_use(id: String, t: Unit) -> String:
	if dead: return "You are dead"
	if not Abilities.LIST.has(id): return "Unknown ability"
	var a: Dictionary = Abilities.LIST[id]
	if stunned > 0.0: return "You are stunned"
	if not casting.is_empty(): return "You are busy"
	if a.get("gcd", true) and gcd > 0.0: return "Not ready yet"
	if cds.has(id): return "Not ready yet"
	var c := cost_of(id)
	if c > power + 0.01: return "Not enough rage" if power_kind == "rage" else "Not enough mana"
	var kind: String = a["kind"]
	if a.get("self", false) or kind == "aoe": return ""
	if t == null or not is_instance_valid(t) or t.dead:
		if a.get("helpful", false): return ""
		return "You have no target"
	if a.get("helpful", false):
		if is_enemy(t): return ""   # falls back to self
	elif not is_enemy(t): return "Invalid target"
	var d := distance_to(t)
	if d > float(a.get("range", Rules.SPELL_RANGE)): return "Out of range"
	if d < float(a.get("min_range", 0.0)): return "Too close"
	if a.get("ooc", false) and in_combat: return "You are in combat"
	if a.has("below") and t.hp > t.max_hp * float(a["below"]): return "Target must be below 20% health"
	return ""

func cost_of(id: String) -> float:
	var c := float(Abilities.LIST[id].get("cost", 0))
	if c <= 0: return 0.0
	if power_kind == "rage": return maxf(0.0, c + tmod("cost_" + id))
	return base_mana() * c / 100.0 * maxf(0.2, 1.0 + tmod("cost_pct"))

func cast_time_of(id: String) -> float:
	var ct := float(Abilities.LIST[id].get("cast", 0.0))
	if ct <= 0.0: return 0.0
	if has_aura("presence_of_mind"): return 0.0
	return maxf(0.5, ct + tmod("cast_" + id))

## start using an ability; returns "" or the reason it failed
func use(id: String, t: Unit = null, at := Vector3.INF) -> String:
	if t == null: t = target
	var why := check_use(id, t)
	if why != "": return why
	var a: Dictionary = Abilities.LIST[id]
	if a.get("helpful", false) and (t == null or is_enemy(t) or t.dead): t = self
	if a.get("self", false) or a["kind"] == "aoe": t = self if a.get("self", false) else t
	if a.get("gcd", true): gcd = Rules.GCD
	var cast_time := cast_time_of(id)
	if cast_time == 0.0 and float(a.get("cast", 0.0)) > 0.0 and has_aura("presence_of_mind"): remove_aura("presence_of_mind")
	var chan := float(a.get("channel", 0.0))
	if a["kind"] in ["ground", "telegraph"] and at == Vector3.INF:
		at = global_position if a.get("self_center", false) else (t.global_position if t else global_position)
	if cast_time > 0.0 or chan > 0.0:
		stop_moving()
		casting = {"id": id, "t": 0.0, "dur": cast_time if cast_time > 0 else chan, "target": t, "pos": at, "channel": chan > 0.0,
			"ticks": int(a.get("ticks", 0)), "tick_i": 0}
		if chan > 0.0: _pay(id)
		if a["kind"] != "heal" and t and is_enemy(t): enter_combat()
		act("Spell_Simple_Enter", 1.2)
		get_tree().call_group("fx", "cast_start", self, id)
		if a["kind"] == "telegraph": get_tree().call_group("fx", "telegraph", at, float(a["radius"]), cast_time, a.get("school", "fire"))
		changed.emit()
		return ""
	_pay(id)
	_fire(id, t, at)
	return ""

func _pay(id: String) -> void:
	var a: Dictionary = Abilities.LIST[id]
	var c := cost_of(id)
	if a.get("all_rage", false) and power_kind == "rage": extra_rage = power - c
	power -= c
	if int(a.get("cost", 0)) < 0 and power_kind == "rage": gain_rage(-float(a["cost"]))
	if c > 0 and power_kind == "mana": last_cast_t = 0.0
	if a.has("cd"): cds[id] = maxf(0.5, float(a["cd"]) + tmod("cd_" + id))
	changed.emit()

func _tick_cast(delta: float) -> void:
	if casting.is_empty(): return
	var t: Unit = casting["target"] if is_instance_valid(casting["target"]) else null
	casting["t"] += delta
	var id: String = casting["id"]
	var a: Dictionary = Abilities.LIST[id]
	if casting["channel"]:
		var n: int = casting["ticks"]
		var due := int(floor(casting["t"] / casting["dur"] * n + 0.001))
		while casting["tick_i"] < mini(due, n):
			casting["tick_i"] += 1
			if t and not t.dead: _effect(id, t, casting["pos"])
		if casting["t"] >= casting["dur"]: casting.clear(); act("Spell_Simple_Exit", 1.0); changed.emit()
		return
	if casting["t"] >= casting["dur"]:
		var pos: Vector3 = casting["pos"]
		casting.clear()
		# the target must still be valid and in range at the end
		if not a.get("helpful", false) and not (a["kind"] in ["ground", "telegraph"]) and (t == null or t.dead):
			changed.emit(); return
		_pay(id)
		_fire(id, t, pos)
		changed.emit()

func cancel_cast(why := "") -> void:
	if casting.is_empty(): return
	casting.clear()
	if why != "" and faction == "player": get_tree().call_group("hud", "error", why)
	get_tree().call_group("fx", "cast_stop", self)
	changed.emit()

## the ability goes off: animation, effect (projectiles land later)
func _fire(id: String, t: Unit, at: Vector3) -> void:
	var a: Dictionary = Abilities.LIST[id]
	var anim: String = a.get("anim", "")
	if anim == "cast": anim = "Spell_Simple_Shoot"
	act(anim, 1.25)
	if t and is_enemy(t): enter_combat()
	var kind: String = a["kind"]
	if kind == "spell" and a.has("speed") and t and t != self:
		# a projectile: the effect happens when it arrives
		get_tree().call_group("fx", "projectile", self, t, id, func(): if is_instance_valid(t) and not t.dead: _effect(id, t, at))
		return
	if kind == "charge" and t:
		_charge(t, id); return
	if kind == "blink":
		_blink(float(a["dist"])); get_tree().call_group("fx", "play", id, self, self, global_position); return
	get_tree().call_group("fx", "play", id, self, t, at)
	_effect(id, t, at)

var extra_rage := 0.0                # Execute: the Rage beyond its cost, spent for extra damage
var cur_ability := ""
                # the ability whose effect is being applied (talent mods by ability)

func _effect(id: String, t: Unit, at: Vector3) -> void:
	cur_ability = id
	_effect2(id, t, at)
	cur_ability = ""

func _effect2(id: String, t: Unit, at: Vector3) -> void:
	var a: Dictionary = Abilities.LIST[id]
	var kind: String = a["kind"]
	var school: String = a.get("school", "physical")
	var spell := school != "physical"
	var pw := spell_power() if spell else attack_power()
	match kind:
		"strike":
			if t == null or t.dead: return
			var dmg: float = randf_range(weapon["min"], weapon["max"]) + attack_power() / 14.0 * weapon["speed"] + Abilities.value(id, "bonus", level)
			if a.has("per_rage"): dmg += Abilities.value(id, "per_rage", level) * extra_rage; extra_rage = 0.0
			if a.get("all_rage", false): power = 0.0
			melee_hit(t, dmg, "special", float(a.get("threat", 1.0)))
		"spell":
			if t == null or t.dead: return
			var dmg := Abilities.value(id, "dmg", level, pw)
			if a.has("undead") and t.creature_type == "undead": dmg *= float(a["undead"])
			spell_hit(t, dmg, school)
			if a.has("burn"): t.add_aura(id + "_burn", self, float(a["burn_dur"]), {"dot": Abilities.value(id, "burn", level) / (float(a["burn_dur"]) / 2.0), "school": school}, 2.0)
			if a.has("slow"): t.add_aura(id + "_slow", self, float(a["slow_dur"]), {"slow": a["slow"]})
		"dot":
			if t == null or t.dead: return
			var total := Abilities.value(id, "total", level, pw) * dmg_mult(school, id)
			var ticks := float(a["dur"]) / float(a["tick"])
			t.add_aura(id, self, float(a["dur"]), {"dot": total / ticks, "school": school, "debuff": true}, float(a["tick"]))
			t.add_threat(self, 10.0 + level); t.enter_combat()
			if not spell: gain_rage(0)
		"heal":
			var h := Abilities.value(id, "heal", level, spell_power())
			var crit := randf() < crit_chance(true)
			t.heal(self, h * (1.5 if crit else 1.0), crit)
		"hot":
			var total := Abilities.value(id, "total", level, spell_power() * 1.0)
			t.add_aura(id, self, float(a["dur"]), {"hot": total / (float(a["dur"]) / float(a["tick"]))}, float(a["tick"]))
		"shield":
			if t.has_aura("weakened_soul"): return
			t.add_aura(id, self, float(a["dur"]), {"absorb": Abilities.value(id, "absorb", level, spell_power())})
			t.add_aura("weakened_soul", self, float(a["weakened"]), {"debuff": true})
		"aoe":
			for u in enemies_near(global_position, float(a["radius"])):
				if a.has("dmg"):
					if spell: spell_hit(u, Abilities.value(id, "dmg", level, pw), school)
					else: u.take_damage(self, Abilities.value(id, "dmg", level) * (1.0 - Rules.armor_dr(u.armor, level)), school, false, "special", 1.75)
				if a.has("root"): u.add_aura(id, self, float(a["root"]), {"root": true, "debuff": true})
				if a.has("slow_attack"): u.add_aura(id, self, float(a["dur"]), {"slow_attack": a["slow_attack"], "debuff": true})
			if a.has("heal"):
				for u in friends_near(global_position, float(a["radius"])): u.heal(self, Abilities.value(id, "heal", level, spell_power() * 0.5))
		"ground":
			for u in enemies_near(at, float(a["radius"])):
				spell_hit(u, Abilities.value(id, "dmg", level, pw), school)
				if a.has("burn"): u.add_aura(id + "_burn", self, float(a["burn_dur"]), {"dot": Abilities.value(id, "burn", level) / (float(a["burn_dur"]) / 2.0), "school": school}, 2.0)
		"buff":
			var data := {}
			for key in ["ap", "armor", "sp"]:
				if a.has(key): data[key] = Abilities.value(id, key, level)
			t.add_aura(String(a.get("aura", id)), self, float(a["dur"]), data)
		"debuff":
			if t == null: return
			if a.has("dmg"): melee_hit(t, Abilities.value(id, "dmg", level), "special")
			t.add_aura(id, self, float(a["dur"]), {"slow": a.get("slow", 0.0), "debuff": true})
		"telegraph":
			# a marked area that goes off after a warning (the cast time was the warning)
			var c: Vector3 = global_position if a.get("self_center", false) else (at if at != Vector3.INF else (t.global_position if t else global_position))
			var victims := enemies_near(c, float(a["radius"]))
			for u in victims: spell_hit(u, Abilities.value(id, "dmg", level), school)
		"hearth":
			if has_method("go_home"): call("go_home")
		"taunt":
			if t == null: return
			var top := 0.0
			for k in t.threat: top = maxf(top, t.threat[k])
			t.threat[self] = top * 1.1 + 10.0; t.target = self; t.enter_combat()
			t.set_meta("taunted", 3.0)

func spell_hit(t: Unit, dmg: float, school: String) -> int:
	if randf() < 0.04 + 0.01 * maxi(0, t.level - level):
		t.show_text("Resist", Color(0.8, 0.8, 1.0), self); t.add_threat(self, 1.0); t.enter_combat(); return 0
	var crit := randf() < crit_chance(true) + tmod("crit_" + school)
	if crit: dmg *= 1.5 + tmod("crit_bonus_" + school)
	dmg *= dmg_mult(school, cur_ability)
	dmg *= 1.0 - clampf(float(t.level) * 0.004, 0.0, 0.25)
	var got := t.take_damage(self, dmg, school, crit, "spell", 1.0)
	if tmod("vampiric") > 0.0 and school == "shadow": heal(self, got * tmod("vampiric"))
	return got

func _charge(t: Unit, id: String) -> void:
	var a: Dictionary = Abilities.LIST[id]
	get_tree().call_group("fx", "play", id, self, t, t.global_position)
	var dir := (t.global_position - global_position); dir.y = 0
	var dest := t.global_position - dir.normalized() * (radius + t.radius + 0.6)
	stop_moving()
	var tw := create_tween()
	var dur := clampf(dir.length() / 28.0, 0.15, 0.8)
	var start := global_position
	tw.tween_method(func(k: float):
		var p := start.lerp(dest, k); p.y = WorldData.h(p.x, p.z); global_position = p, 0.0, 1.0, dur)
	tw.tween_callback(func():
		if is_instance_valid(t) and not t.dead:
			t.stunned = maxf(t.stunned, float(a["stun"])); t.enter_combat(); t.add_threat(self, 20.0)
			get_tree().call_group("fx", "play", "charge_hit", self, t, t.global_position)
			start_attack(t))
	yaw = atan2(dir.x, dir.z); if model: model.rotation.y = yaw
	act("Sword_Dash", 1.6)
	enter_combat()

func _blink(dist: float) -> void:
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	var best := global_position
	for i in range(1, 25):
		var p := global_position + fwd * dist * i / 24.0
		if not Nav.walkable(p): break
		best = p
	best.y = WorldData.h(best.x, best.z)
	global_position = best; stop_moving(); rooted = 0.0; stunned = 0.0
	for a in auras.duplicate():
		if a["data"].has("root") or a["data"].has("slow"): remove_aura(a["id"])

func enemies_near(p: Vector3, r: float) -> Array:
	var out := []
	for u in get_tree().get_nodes_in_group("units"):
		if not u.dead and is_enemy(u):
			var d: Vector3 = u.global_position - p; d.y = 0
			if d.length() <= r + u.radius: out.append(u)
	return out

func friends_near(p: Vector3, r: float) -> Array:
	var out := []
	for u in get_tree().get_nodes_in_group("units"):
		if u.dead: continue
		var ally: bool = u == self or u.faction == faction or (faction in ["player", "friendly"] and u.faction in ["player", "friendly"])
		if ally:
			var d: Vector3 = u.global_position - p; d.y = 0
			if d.length() <= r: out.append(u)
	return out

## overridden by Monster (AI) and Player (input); called every physics frame before moving
func _think(_delta: float) -> void:
	pass
