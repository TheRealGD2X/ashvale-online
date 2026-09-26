class_name Raid extends Node
## The Abyssal Sanctum, the ten-player raid (DESIGN §7.2): what every raid boss does, the loot and
## how it is rolled for, the weekly lockout, Mythic pity and the server-firsts.
##
## Every boss has two mechanics, a turn at half health, and goes berserk at six minutes:
##   the Ashen Colossus — Stomp (get out of the ring), Crush stacks on the tank (swap at four),
##                        at half health two Ash Golems climb out of the floor
##   the Archivist      — silence zones drift across the hall, a Rune of Lore every 25 s that must die
##                        in 10 s or he learns from it, at half health he Opens the Book (heal through)
##   the Twin Wardens   — must die within 10 s of each other or the dead one gets up, swap places every
##                        30 s, at half health two people are chained and must stay close
##   Vaal the Undying   — his spawn every 18 s, Soul Drain (hit him hard to break it), at half health
##                        Void Nova rings (run out)

const ENRAGE := 360.0
const ORDER := ["ashen_colossus", "the_archivist", "warden_ashur", "vaal"]
const FIRSTS_PATH := "user://server_firsts.json"

## the raid week starts on Wednesday at 06:00 local time
static func week_id() -> int:
	var bias: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var t := int(Time.get_unix_time_from_system()) + bias * 60 - 6 * 3600
	var day := floori(t / 86400.0)
	return floori((day - 6) / 7.0)          # day 6 after 1970-01-01 (a Thursday) was a Wednesday

static func _hero(tree: SceneTree) -> Player:
	return tree.get_first_node_in_group("player")

static func locked(p: Player, kind: String) -> bool:
	return p != null and int(p.raid_locks.get(kind, -1)) == week_id()

## a boss you've killed this week isn't there when you come back
static func check_lock(m: Monster) -> void:
	if not is_instance_valid(m): return
	var p := _hero(m.get_tree())
	if locked(p, m.kind):
		m.dead = true; m.visible = false; m.collision_layer = 0; m.respawn_t = 1e9; m.corpse_t = 0.0

# ------------------------------------------------------------------ the fights

static func _yell(m: Monster, t: String) -> void:
	m._yell(t)

static func _foes(m: Monster) -> Array:
	return m.threat.keys().filter(func(u): return is_instance_valid(u) and not u.dead)

static func _spawn(m: Monster, kind: String, at: Vector3, lv := -1) -> Monster:
	var a := Monster.new(); a.setup(kind, m.level - 1 if lv < 0 else lv); a.set_meta("add", true)
	m.get_parent().add_child(a)
	var p := Nav.nearest_open(at); p.y = WorldData.h(p.x, p.z)
	a.global_position = p; a.home = p; a.respawn_t = 1e9
	a.died.connect(func(_u): a.get_tree().create_timer(12.0).timeout.connect(a.queue_free))
	m.adds.append(a)
	var f := _foes(m)
	if not f.is_empty():
		var v: Unit = f[m.rng.randi() % f.size()]
		a.get_tree().create_timer(0.4).timeout.connect(func(): if is_instance_valid(a) and is_instance_valid(v) and not v.dead: a.aggro(v))
	return a

static func boss_tick(m: Monster, delta: float) -> void:
	var ft: float = m.get_meta("fight_t", 0.0)
	if ft == 0.0 and m.kind in ORDER and KINDS_of(m).has("yell_pull"): _yell(m, KINDS_of(m)["yell_pull"])
	ft += delta; m.set_meta("fight_t", ft)
	# six minutes and they stop holding back
	if ft > ENRAGE and not m.has_meta("enraged"):
		m.set_meta("enraged", true)
		m.add_aura("enrage", m, 9999.0, {"dmg_pct": 2.0})
		_yell(m, "ENOUGH!")
		m.get_tree().call_group("hud", "error", "%s is enraged!" % m.uname)
	var half := m.hp < m.max_hp * 0.5 and not m.has_meta("half")
	if half: m.set_meta("half", true)
	match KINDS_of(m)["boss"]:
		"colossus": _colossus(m, delta, half)
		"archivist": _archivist(m, delta, half)
		"twins": _twins(m, delta, half)
		"vaal": _vaal(m, delta, half)

static func KINDS_of(m: Monster) -> Dictionary:
	return Monster.KINDS[m.kind]

static func _timer(m: Monster, key: String, every: float, delta: float) -> bool:
	var t: float = m.get_meta(key, 0.0) + delta
	if t >= every: m.set_meta(key, 0.0); return true
	m.set_meta(key, t); return false

static func _colossus(m: Monster, delta: float, half: bool) -> void:
	# Stomp: the ground round him goes up in a ring of fire — leave it
	if _timer(m, "stomp_t", 20.0, delta) and m.casting.is_empty():
		_yell(m, "KNEEL."); m.stop_moving(); m.use("colossus_stomp", m, m.global_position)
	# Crush: every blow on the tank weighs heavier; at four, someone else should take him
	if _timer(m, "crush_t", 5.0, delta) and m.target and is_instance_valid(m.target) and m.distance_to(m.target) < m.swing_range() + 1.0:
		var n := _stacks(m.target, "crush") + 1
		m.target.add_aura("crush", m, 20.0, {"dmg_taken": 0.12 * n, "stacks": n, "debuff": true})
	if half:
		_yell(m, "RISE, CHILDREN OF THE FORGE.")
		for i in 2: _spawn(m, "ash_golem", m.global_position + Vector3(-8 + 16 * i, 0, -6))

static func _stacks(u: Unit, id: String) -> int:
	for a in u.auras:
		if a["id"] == id: return int(a["data"].get("stacks", 0))
	return 0

static func _archivist(m: Monster, delta: float, half: bool) -> void:
	# the Open Book: eight seconds of everyone hurting; the healers earn their keep
	if m.has_meta("book_t"):
		var bt: float = m.get_meta("book_t") - delta
		m.set_meta("book_t", bt); m.stop_moving(); m.attacking = false
		if _timer(m, "book_tick", 1.0, delta):
			for u in _foes(m): u.take_damage(m, u.max_hp * 0.045, "arcane", false, "spell", 0.0)
			m.get_tree().call_group("fx", "play", "holy_nova", m, m, m.global_position)
		if bt <= 0.0: m.remove_meta("book_t"); _yell(m, "...and so it ends. For now.")
		return
	if half:
		_yell(m, "Let me read you the ending.")
		m.set_meta("book_t", 8.0); return
	# silence drifting across the floor
	if _timer(m, "silence_t", 12.0, delta):
		var f := _foes(m)
		if not f.is_empty():
			var v: Unit = f[m.rng.randi() % f.size()]
			RaidZone.make(m.get_parent(), v.global_position + Vector3(m.rng.randf_range(-3, 3), 0, m.rng.randf_range(-3, 3)), "silence", 5.0, 30.0,
				Vector3(m.rng.randf_range(-1, 1), 0, m.rng.randf_range(-1, 1)).normalized() * 1.2)
	# runes of lore: ten seconds to break each, or he learns from it
	if _timer(m, "rune_t", 25.0, delta):
		_yell(m, ["Read this.", "Another page.", "Learn, or be learned from."][m.rng.randi() % 3])
		var r0 := _spawn(m, "lore_rune", m.global_position + Vector3(m.rng.randf_range(-10, 10), 0, m.rng.randf_range(-10, 10)))
		var wr: WeakRef = weakref(r0); var wm: WeakRef = weakref(m)
		r0.get_tree().create_timer(10.0).timeout.connect(func():
			var r: Monster = wr.get_ref(); var boss: Monster = wm.get_ref()
			if r == null or r.dead or boss == null or boss.dead: return
			var n := _stacks(boss, "lore") + 1
			boss.add_aura("lore", boss, 9999.0, {"dmg_pct": 0.1 * n, "stacks": n})
			_yell(boss, "Yes. I know this one now.")
			for u in _foes(boss): u.take_damage(r, u.max_hp * 0.05, "arcane", false, "spell", 0.0)
			r.die(null))

static func _twins(m: Monster, delta: float, half: bool) -> void:
	var twin: Monster = null
	for u in m.get_tree().get_nodes_in_group("units"):
		if u is Monster and u.kind == KINDS_of(m)["twin"]: twin = u
	if twin == null: return
	# they fight as one: anyone either of them hates, both of them know about
	if not twin.dead and not twin.evading:
		for u in _foes(m):
			if not twin.threat.has(u): twin.add_threat(u, 0.0)
		for u in _foes(twin):
			if not m.threat.has(u): m.add_threat(u, 0.0)
		if not twin.in_combat and not _foes(m).is_empty(): twin.add_threat(_foes(m)[0], 1.0); twin.enter_combat()
	# only one of them runs the shared clock (the one alphabetically first)
	if m.kind > twin.kind and not twin.dead: return
	if twin.dead and twin.has_meta("fell_at"):
		var since: float = Time.get_ticks_msec() / 1000.0 - float(twin.get_meta("fell_at"))
		if since > 10.0 and not m.dead:
			_yell(m, "Brother! Stand up!")
			twin.remove_meta("fell_at")
			twin.revive(0.3); twin.visible = true; twin.loot.clear(); twin.loot_money = 0; twin.respawn_t = 1e9
			for u in _foes(m): twin.add_threat(u, 1.0)
			twin.enter_combat()
	# they trade places every 30 seconds; the tanks have to find them again
	if _timer(m, "swap_t", 30.0, delta) and not twin.dead:
		var a := m.global_position; var b := twin.global_position
		m.global_position = b; twin.global_position = a
		_yell(m, "Change!")
		m.get_tree().call_group("fx", "play", "blink", m, m, m.global_position)
	# chains: two people bound together; apart, it hurts
	if half or (twin.has_meta("half") and not m.has_meta("chains_on")):
		m.set_meta("chains_on", true)
	if m.has_meta("chains_on") and _timer(m, "chain_t", 25.0, delta):
		var f := _foes(m).filter(func(u): return u != m.target and (twin.dead or u != twin.target))
		if f.size() >= 2:
			f.shuffle()
			_yell(m, "Bound together, you die together.")
			RaidTether.make(m.get_parent(), f[0], f[1], 15.0, m)

static func _vaal(m: Monster, delta: float, half: bool) -> void:
	# Soul Drain: he feeds on someone; hit him hard enough and his focus breaks
	if m.has_meta("drain_on"):
		var v = m.get_meta("drain_on")
		var t_left: float = m.get_meta("drain_t") - delta
		m.set_meta("drain_t", t_left); m.stop_moving(); m.attacking = false
		if v == null or not is_instance_valid(v) or v.dead or t_left <= 0.0 or m.hp < float(m.get_meta("drain_hp")) - m.max_hp * 0.04:
			if t_left > 0.0 and m.hp < float(m.get_meta("drain_hp")) - m.max_hp * 0.04: _yell(m, "You DARE?")
			m.remove_meta("drain_on"); return
		if _timer(m, "drain_tick", 1.0, delta):
			var dmg: float = v.max_hp * 0.07
			v.take_damage(m, dmg, "shadow", false, "dot", 0.0); m.heal(m, dmg * 3.0)
			m.get_tree().call_group("fx", "play", "shadow_rot", m, v, v.global_position)
		return
	if _timer(m, "drain_every", 22.0, delta):
		var f := _foes(m).filter(func(u): return u != m.target)
		if not f.is_empty():
			var dv: Unit = f[m.rng.randi() % f.size()]
			m.set_meta("drain_on", dv); m.set_meta("drain_t", 6.0); m.set_meta("drain_hp", m.hp)
			_yell(m, "Your soul, %s. Give it to me." % dv.uname)
			return
	# his spawn, every 18 seconds
	if _timer(m, "spawn_t", 18.0, delta):
		for i in 2: _spawn(m, "void_spawn", m.global_position + Vector3(m.rng.randf_range(-12, 12), 0, m.rng.randf_range(-6, 10)))
	# below half: the Void Nova, every 15 seconds
	if half: _yell(m, "You have seen my face. Now see my HEART.")
	if m.has_meta("half") and _timer(m, "nova_t", 15.0, delta) and m.casting.is_empty():
		m.stop_moving(); m.use("vaal_nova", m, m.global_position)

## a wipe: the boss goes home and forgets everything
static func reset(m: Monster) -> void:
	for k in ["fight_t", "enraged", "half", "stomp_t", "crush_t", "silence_t", "rune_t", "book_t", "book_tick", "swap_t", "chains_on", "chain_t",
			"drain_on", "drain_t", "drain_hp", "drain_tick", "drain_every", "spawn_t", "nova_t", "fell_at"]:
		if m.has_meta(k): m.remove_meta(k)
	m.remove_aura("enrage"); m.remove_aura("lore")
	for a in m.adds:
		if is_instance_valid(a): a.queue_free()
	m.adds.clear()
	for z in m.get_tree().get_nodes_in_group("raid_zones"): z.queue_free()
	# a twin that lay dead gets up again for the next try
	if KINDS_of(m).has("twin"):
		for u in m.get_tree().get_nodes_in_group("units"):
			if u is Monster and u.kind == KINDS_of(m)["twin"] and u.dead:
				u._respawn()

# ------------------------------------------------------------------ the loot

static func boss_died(m: Monster) -> void:
	var tree := m.get_tree()
	var p := _hero(tree)
	var d := KINDS_of(m)
	for a in m.adds:
		if is_instance_valid(a) and not a.dead: a.die(null)
	for z in tree.get_nodes_in_group("raid_zones"): z.queue_free()
	m.loot.clear(); m.loot_money = 0
	# a twin: nothing until the other one falls too
	if d.has("twin"):
		var twin: Monster = null
		for u in tree.get_nodes_in_group("units"):
			if u is Monster and u.kind == d["twin"]: twin = u
		if twin and not twin.dead:
			m.set_meta("fell_at", Time.get_ticks_msec() / 1000.0)
			m.respawn_t = 1e9
			return
		if twin: _drop(twin, p)
	if d.has("yell_die"): _yell(m, d["yell_die"])
	_drop(m, p)
	if p == null: return
	var boss_kind := "warden_ashur" if d.has("twin") else m.kind
	p.raid_locks[boss_kind] = week_id()
	p.gold += 300000 + m.rng.randi_range(0, 200000); p.changed.emit()
	tree.call_group("hud", "banner", "%s defeated" % (m.uname if not d.has("twin") else "The Twin Wardens"), "The Abyssal Sanctum")
	_server_first(tree, boss_kind, "The Twin Wardens" if d.has("twin") else m.uname, p)

static func _drop(m: Monster, p: Player) -> void:
	var d := KINDS_of(m)
	var items := []
	var pool: Array = d.get("raid_loot", []).duplicate()
	pool.shuffle()
	for i in mini(2 if not d.has("twin") else 1, pool.size()): items.append(pool[i])
	if d.has("token"): items.append(d["token"])
	# Mythics: one kill in twenty, and after twenty kills without one of your own, it's yours
	if d.has("mythic") and p:
		var pity := int(p.pity.get(m.kind, 0))
		if pity >= 19:
			p.pity[m.kind] = 0
			p.add_item({"id": d["mythic"], "n": 1})
			m.get_tree().call_group("chat", "post", "raid_warning", "", "%s has received a Mythic: %s! (after %d kills — about time)" % [p.uname, Items.def(d["mythic"])["name"], pity + 1])
			m.get_tree().call_group("fx", "sound", "quest_done", null, -2.0)
		elif m.rng.randf() < 0.05: items.append(d["mythic"])
		else: p.pity[m.kind] = pity + 1
	RaidLoot.get_or_make(m.get_tree()).queue(items, m.uname)

static func _server_first(tree: SceneTree, key: String, name: String, p: Player) -> void:
	var firsts := {}
	if FileAccess.file_exists(FIRSTS_PATH):
		var j = JSON.parse_string(FileAccess.get_file_as_string(FIRSTS_PATH))
		if j is Dictionary: firsts = j
	if firsts.has(key): return
	var names := []
	for u in p.party_members(): names.append(u.uname)
	firsts[key] = {"when": Time.get_datetime_string_from_system(), "who": names}
	var f := FileAccess.open(FIRSTS_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(firsts)); f.close()
	tree.call_group("chat", "post", "raid_warning", "", "SERVER FIRST! %s has been defeated by %s." % [name, ", ".join(names)])
