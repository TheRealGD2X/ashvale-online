class_name Brain extends Node
## Plays a character the way a person would: picks up quests, goes where they send it, fights with
## a sensible rotation for its class, loots, eats and drinks between fights, hands quests in, trains
## new abilities, sells junk and wears the better gear it finds. Simulated players (Bot) use it,
## and the quest test drives the real Player with it (--questtest).
##
## It only uses the same things the real player can: walking, targeting, abilities, talking to
## people, looting, bags.

var p: Player
var task := ""                 # what we are doing, in words (bots mention it in chat)
var goal := Vector3.INF
var think_t := 0.0
var dead_t := 0.0
var stuck_t := 0.0
var last_pos := Vector3.ZERO
var fight_t := 0.0
var rng := RandomNumberGenerator.new()
var leader: Unit                # when grouped with the player: follow and help them
var solo_only := false
var log_lines := false          # print what we decide (for the tests)
var no_quest_until := 0.0
var skip := {}                  # quests we gave up on (too hard for now)
var focus: Unit                 # fight only this (tests)

func _init(owner_player: Player = null) -> void:
	p = owner_player
	rng.randomize()

func _physics_process(delta: float) -> void:
	if p == null or not is_instance_valid(p): return
	think_t -= delta
	if p.dead:
		dead_t += delta
		if dead_t > 4.0: dead_t = 0.0; p.release(); task = "back from the graveyard"
		return
	if think_t > 0.0: return
	think_t = 0.25
	_unstick(0.25)
	if focus and is_instance_valid(focus) and not focus.dead:
		p.target = focus
		if p.in_combat: _fight()
		else: _attack(focus, "duel")
		return
	if p.in_combat or _attacked(): _fight(); return
	fight_t = 0.0
	if p.has_meta("sitting"): return
	if _rest(): return
	if leader and is_instance_valid(leader): _follow(); return
	_quest_step()

func say(t: String) -> void:
	if log_lines: print("[brain %s L%d] %s" % [p.uname, p.level, t])

# ------------------------------------------------------------------ fighting

func _attacked() -> bool:
	for u in p.get_tree().get_nodes_in_group("units"):
		if u is Monster and not u.dead and u.target == p and u.in_combat: return true
	return false

func _enemy_on_me() -> Unit:
	var best: Unit = null; var bd := 1e9
	for u in p.get_tree().get_nodes_in_group("units"):
		if u is Monster and not u.dead and (u.target == p or (leader and u.target == leader)) and u.in_combat:
			var d := p.distance_to(u)
			if d < bd: bd = d; best = u
	return best

func _fight() -> void:
	fight_t += 0.25
	var t := p.target
	if t == null or not is_instance_valid(t) or t.dead or not p.is_enemy(t):
		t = _enemy_on_me()
		if t == null:
			if leader and is_instance_valid(leader) and leader.target and is_instance_valid(leader.target) and not leader.target.dead and p.is_enemy(leader.target): t = leader.target
			else: return
		p.target = t
	match p.cls:
		"warrior": _warrior(t)
		"wizard": _caster(t, ["fireball", "frostbolt"], "fire_blast", "frost_armor")
		"cleric": _cleric(t)

func _can(id: String, t: Unit) -> bool:
	return id in p.known and p.check_use(id, t) == ""

func _use(id: String, t: Unit) -> bool:
	if not (id in p.known): return false
	var why := p.check_use(id, t)
	if why == "Out of range":
		p.chase(t, float(Abilities.LIST[id].get("range", Rules.SPELL_RANGE)) * 0.85); return true
	if why != "": return false
	p.stop_moving()
	return p.use(id, t) == ""

func _warrior(t: Unit) -> void:
	if not p.attacking: p.start_attack(t)
	var d := p.distance_to(t)
	if d > p.swing_range():
		if _can("charge", t): p.use("charge", t); return
		p.chase(t, p.swing_range() * 0.8); return
	if _can("battle_shout", p) and not p.has_aura("battle_shout"): p.use("battle_shout", p); return
	if _can("execute", t): p.use("execute", t); return
	var near := p.enemies_near(p.global_position, 7.0).size()
	if near >= 2 and _can("thunder_clap", t): p.use("thunder_clap", t); return
	if _can("rend", t) and not _has_my_aura(t, "rend") and t.hp > t.max_hp * 0.4: p.use("rend", t); return
	if p.power >= 30 and _can("heroic_strike", t): p.use("heroic_strike", t); return
	if t.hp < t.max_hp * 0.3 and _can("hamstring", t) and not _has_my_aura(t, "hamstring") and t is Monster and t.critter == false: p.use("hamstring", t); return

func _has_my_aura(t: Unit, id: String) -> bool:
	for a in t.auras:
		if a["id"] == id and a["src"] == p: return true
	return false

func _caster(t: Unit, nukes: Array, instant: String, armor: String) -> void:
	if not p.casting.is_empty(): return
	if armor in p.known and not p.has_aura(armor) and _can(armor, p): p.use(armor, p); return
	var d := p.distance_to(t)
	# something in our face: freeze it and step away
	if d < 3.0 and _can("frost_nova", t): p.use("frost_nova", t); return
	if d < 3.0 and t.rooted > 0.0:
		var away := (p.global_position - t.global_position); away.y = 0
		var dest := p.global_position + away.normalized() * 10.0
		if Nav.walkable(dest): p.move_to(dest); return
	if p.is_moving() and d < 26.0: p.stop_moving()
	if _can(instant, t): p.use(instant, t); return
	if p.power < p.max_power * 0.1:
		# out of mana: hit it with the staff
		if not p.attacking: p.start_attack(t)
		if d > p.swing_range(): p.chase(t, p.swing_range() * 0.8)
		return
	if "arcane_missiles" in p.known and rng.randf() < 0.25 and _can("arcane_missiles", t): p.use("arcane_missiles", t); return
	for id in nukes:
		if _use(id, t): return

func _cleric(t: Unit) -> void:
	if not p.casting.is_empty(): return
	var heal_me: Unit = p
	if leader and is_instance_valid(leader) and not leader.dead and leader.hp < leader.max_hp * 0.55: heal_me = leader
	if heal_me.hp < heal_me.max_hp * 0.5:
		if _can("ward_of_light", heal_me) and not heal_me.has_aura("weakened_soul"): p.use("ward_of_light", heal_me); return
		if _can("renewal", heal_me) and not heal_me.has_aura("renewal"): p.use("renewal", heal_me); return
		if _can("mend", heal_me): p.use("mend", heal_me); return
	if not p.has_aura("inner_fire") and _can("inner_fire", p): p.use("inner_fire", p); return
	if fight_t < 1.0 and _can("ward_of_light", p) and not p.has_aura("weakened_soul") and leader == null: p.use("ward_of_light", p); return
	var d := p.distance_to(t)
	if p.is_moving() and d < 26.0: p.stop_moving()
	if _can("shadow_rot", t) and not _has_my_aura(t, "shadow_rot"): p.use("shadow_rot", t); return
	if p.power < p.max_power * 0.15 or d < 2.5:
		if not p.attacking: p.start_attack(t)
		if d > p.swing_range(): p.chase(t, p.swing_range() * 0.8)
		return
	_use("smite", t)

# ------------------------------------------------------------------ between fights

## eat, drink, or just catch our breath
func _rest() -> bool:
	var low_hp := p.hp < p.max_hp * 0.55
	var low_mp := p.power_kind == "mana" and p.power < p.max_power * 0.35
	if not low_hp and not low_mp: return false
	p.stop_moving()
	for i in p.bags.size():
		var it = p.bags[i]
		if it == null: continue
		var d := Items.get_def(it)
		if low_hp and d.get("use", "") == "food": p.use_bag(i); task = "eating"; return true
		if low_mp and d.get("use", "") == "drink": p.use_bag(i); task = "drinking"; return true
	# nothing to eat: wait for health to come back
	task = "resting"
	return p.hp < p.max_hp * 0.8 or (p.power_kind == "mana" and p.power < p.max_power * 0.6)

func _follow() -> void:
	var d := p.global_position.distance_to(leader.global_position)
	if d > 5.0: p.chase(leader, 3.0)
	elif leader.target and is_instance_valid(leader.target) and not leader.target.dead and leader.in_combat and p.is_enemy(leader.target):
		p.target = leader.target; _fight()

# ------------------------------------------------------------------ questing

func _go(pos: Vector3, why: String) -> void:
	task = why
	if goal.distance_to(pos) > 1.5 or not p.is_moving():
		goal = pos
		p.move_to(pos)

func _unstick(dt: float) -> void:
	if not p.is_moving(): stuck_t = 0.0; last_pos = p.global_position; return
	if p.global_position.distance_to(last_pos) < 0.2 * dt * 4.0: stuck_t += dt
	else: stuck_t = 0.0
	last_pos = p.global_position
	if stuck_t > 3.0:
		stuck_t = 0.0
		var side := Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-6, 6))
		p.move_to(Nav.nearest_open(p.global_position + side))

func _npc(id: String) -> Npc:
	for n in p.get_tree().get_nodes_in_group("npcs"):
		if n.npc_id == id: return n
	return null

func _talk_to(id: String, why: String) -> bool:
	var n := _npc(id)
	if n == null: return false
	if p.global_position.distance_to(n.global_position) < 3.0:
		p.stop_moving(); p.on_talk(id); n.face(p)
		return true
	_go(n.global_position, why)
	return false

func _quest_step() -> void:
	# 0. loot what we killed
	for u in p.get_tree().get_nodes_in_group("units"):
		if u is Monster and u.has_loot(p) and p.global_position.distance_to(u.global_position) < 30.0:
			if p.global_position.distance_to(u.global_position) < 3.0:
				p.stop_moving(); p.loot_all(u); _wear_best()
			else: _go(u.global_position, "looting")
			return
	# 1. hand in what's done
	for id in p.quests.keys():
		if p.quest_complete(id):
			var ender := Player.ender_of(id)
			if _npc(ender) == null: continue
			if _talk_to(ender, "handing in " + Quests.LIST[id]["title"]):
				var q: Dictionary = Quests.LIST[id]
				var pick := 0
				if q.has("choice"):
					var best := -1e9
					for i in q["choice"].size():
						var sc := _score({"id": q["choice"][i], "n": 1})
						if sc > best: best = sc; pick = i
				if p.turn_in(id, pick): say("turned in " + id); _wear_best()
			return
	# 2. new abilities from the trainer
	if _trainer_step(): return
	# 3. junk to sell, or bags full
	if p.bags.count(null) <= 2 and _sell_step(): return
	# 4. pick up new quests
	for id in Quests.LIST:
		if skip.has(id): continue
		var q: Dictionary = Quests.LIST[id]
		if p.quest_state(id) != "available": continue
		if q.get("group", false) and p.level < int(q["level"]) + 2 and leader == null: continue
		if _unreachable(id): continue
		if _npc(q["giver"]) == null: continue
		if _talk_to(q["giver"], "picking up " + q["title"]):
			p.accept_quest(id); say("accepted " + id)
		return
	# 5. work on the nearest unfinished objective
	var best_d := 1e9; var best := {}
	for id in p.quests:
		if skip.has(id): continue
		var q: Dictionary = Quests.LIST[id]
		for i in q["obj"].size():
			var o: Dictionary = q["obj"][i]
			if int(p.quests[id]["have"][i]) >= int(o.get("n", 1)): continue
			if o["kind"] == "talk" and o["npc"] == Player.ender_of(id): continue
			var at := _where(o)
			if at == Vector3.INF: continue
			var d := p.global_position.distance_to(at)
			if d < best_d: best_d = d; best = {"id": id, "o": o, "at": at}
	if not best.is_empty():
		_do(best["id"], best["o"], best["at"]); return
	# 6. nothing to do: fight something our level nearby
	var m := _nearest_monster("", p.level - 3, p.level + 1)
	if m: _attack(m, "hunting")
	else: task = "idle"

## quests whose people aren't in the world yet (the next zone)
func _unreachable(id: String) -> bool:
	var q: Dictionary = Quests.LIST[id]
	if _npc(Player.ender_of(id)) == null: return true
	for o in q["obj"]:
		if o["kind"] == "talk" and _npc(o["npc"]) == null: return true
	return false

## where an objective is done
func _where(o: Dictionary) -> Vector3:
	match o["kind"]:
		"talk":
			var n := _npc(o["npc"]); return n.global_position if n else Vector3.INF
		"explore": return Vector3(o["at"][0], 0, o["at"][1])
		"kill":
			var m := _nearest_monster(o["mon"]); return m.global_position if m else _camp_of(o["mon"])
		"collect":
			for k in o["from"]:
				var m2 := _nearest_monster(k)
				if m2: return m2.global_position
			return _camp_of(o["from"][0])
		"gather":
			var pk := _pickup(o["item"]); return pk.global_position if pk else Vector3.INF
	return Vector3.INF

func _do(id: String, o: Dictionary, at: Vector3) -> void:
	var title: String = Quests.LIST[id]["title"]
	match o["kind"]:
		"talk": _talk_to(o["npc"], title)
		"explore": _go(Nav.nearest_open(at), "exploring for " + title)
		"kill", "collect":
			var keys: Array = [o["mon"]] if o["kind"] == "kill" else o["from"]
			for k in keys:
				var m := _nearest_monster(k)
				if m: _attack(m, title); return
			_go(Nav.nearest_open(at), "looking for " + str(keys[0]))
		"gather":
			var pk := _pickup(o["item"])
			if pk == null: return
			if p.global_position.distance_to(pk.global_position) < 2.5: p.stop_moving(); pk.take(p)
			else: _go(pk.global_position, title)

func _attack(m: Monster, why: String) -> void:
	task = why
	p.target = m
	if p.cls == "warrior":
		if p.distance_to(m) > 7.0 and p.distance_to(m) < 24.0 and _can("charge", m): p.use("charge", m); return
		p.start_attack(m)
		if p.distance_to(m) > p.swing_range(): p.chase(m, p.swing_range() * 0.8)
	else:
		var open: String = "fireball" if p.cls == "wizard" else ("shadow_rot" if "shadow_rot" in p.known else "smite")
		if p.distance_to(m) > 26.0: p.chase(m, 24.0)
		else: _use(open, m)

func _key(m: Monster) -> String:
	return Monster.KINDS[m.kind].get("as", m.kind)

func _nearest_monster(kind: String, lo := -99, hi := 99) -> Monster:
	var best: Monster = null; var bd := 1e9
	for u in p.get_tree().get_nodes_in_group("units"):
		if not (u is Monster) or u.dead or not u.visible or u.evading: continue
		if kind != "" and _key(u) != kind: continue
		if kind == "" and (u.critter or u.level < lo or u.level > hi or u.elite): continue
		# don't steal a monster someone else is already fighting
		if u.in_combat and u.target != p and u.target != leader: continue
		var d := p.global_position.distance_to(u.global_position)
		if d < bd: bd = d; best = u
	return best

func _camp_of(kind: String) -> Vector3:
	for c in load("res://src/world/spawns.gd").CAMPS:
		var k: String = Monster.KINDS[c["kind"]].get("as", c["kind"])
		if k == kind: return Vector3(c["at"].x, 0, c["at"].y)
	return Vector3.INF

func _pickup(item: String) -> Pickup:
	var best: Pickup = null; var bd := 1e9
	for pk in p.get_tree().get_nodes_in_group("pickups"):
		if pk.item != item or not pk.visible: continue
		var d := p.global_position.distance_to(pk.global_position)
		if d < bd: bd = d; best = pk
	return best

# ------------------------------------------------------------------ trainers, vendors, gear

func _trainer_step() -> bool:
	var tid := "trainer_" + p.cls
	var want := ""; var cost := 0
	for t in Npcs.TRAINING[p.cls]:
		if not (t[0] in p.known) and p.level >= int(t[1]) and p.gold >= int(t[2]):
			want = t[0]; cost = int(t[2]); break
	if want == "": return false
	if _talk_to(tid, "training"):
		p.train(want, cost)
		_fill_bar()
	return true

## put the best five on the bar
func _fill_bar() -> void:
	var order := {"warrior": ["heroic_strike", "charge", "rend", "thunder_clap", "execute", "battle_shout", "hamstring", "taunt"],
		"wizard": ["fireball", "frostbolt", "fire_blast", "frost_nova", "arcane_missiles", "flamestrike", "blink", "frost_armor"],
		"cleric": ["smite", "mend", "shadow_rot", "renewal", "ward_of_light", "holy_nova", "inner_fire"]}
	var bar := []
	for id in order[p.cls]:
		if id in p.known and bar.size() < 5: bar.append(id)
	while bar.size() < 5: bar.append("")
	p.bar = bar

func _sell_step() -> bool:
	var junk := false
	for it in p.bags:
		if it and int(Items.get_def(it).get("q", 1)) == 0: junk = true
	if not junk: return false
	var v := "bess" if p.global_position.distance_to(Vector3(0, 0, 0)) < 60.0 else "tomas"
	if _talk_to(v, "selling junk"): p.sell_junk()
	return true

## how good an item is for us (a rough WoW-style stat weight)
func _score(it: Dictionary) -> float:
	var d := Items.get_def(it)
	if not Items.can_use(p.cls, d, p.level): return -1e6
	var w: Dictionary = {"warrior": {"str": 2.0, "agi": 1.0, "sta": 1.5, "int": 0.0, "spi": 0.2},
		"wizard": {"str": 0.0, "agi": 0.1, "sta": 1.0, "int": 2.0, "spi": 1.0},
		"cleric": {"str": 0.0, "agi": 0.1, "sta": 1.0, "int": 1.8, "spi": 1.5}}[p.cls]
	var s := float(d.get("armor", 0)) * (0.05 if p.cls == "warrior" else 0.02) + float(d.get("sp", 0)) * (1.2 if p.cls != "warrior" else 0.0)
	for k in d.get("stats", {}): s += float(d["stats"][k]) * float(w.get(k, 0.5))
	if d.has("weapon"):
		var wp: Array = d["weapon"]
		s += (wp[0] + wp[1]) / 2.0 / wp[2] * (3.0 if p.cls == "warrior" else 0.6)
	return s

func _wear_best() -> void:
	for i in p.bags.size():
		var it = p.bags[i]
		if it == null: continue
		var d := Items.get_def(it)
		if not d.has("slot") or not Items.can_use(p.cls, d, p.level): continue
		var slot: String = d["slot"]
		if Items.slot_of(d) in ["finger", "trinket"]:
			slot = Items.slot_of(d) + ("1" if not p.equipped.has(Items.slot_of(d) + "1") else "2")
		var cur = p.equipped.get(slot)
		if cur == null or _score(it) > _score(cur) + 0.1:
			p.equip_from_bag(i)
