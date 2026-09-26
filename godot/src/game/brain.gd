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
var _last_level := 0


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
	if p.level != _last_level: _last_level = p.level; skip.clear()
	_unstick(0.25)
	if focus and is_instance_valid(focus) and not focus.dead:
		p.target = focus
		if p.in_combat: _fight()
		else: _attack(focus, "duel")
		return
	if p.in_combat or _attacked():
		if _dodge(): return
		_fight(); return

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
		if u is Monster and not u.dead and not u.evading and u.target == p and u.in_combat: return true

	return false

func _enemy_on_me() -> Unit:
	var best: Unit = null; var bd := 1e9
	for u in p.get_tree().get_nodes_in_group("units"):
		if u is Monster and not u.dead and not u.evading and (u.target == p or (leader and u.target == leader)) and u.in_combat:
			var d := p.distance_to(u)
			if d < bd: bd = d; best = u
	return best

func _fight() -> void:
	fight_t += 0.25
	var t := p.target
	if t == null or not is_instance_valid(t) or t.dead or not p.is_enemy(t) or (t is Monster and t.evading):

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
	# in a group, the warrior holds the monsters' attention: taunt whatever is hitting someone else
	if leader and is_instance_valid(leader) and "taunt" in p.known:
		for u in p.get_tree().get_nodes_in_group("units"):
			if u is Monster and not u.dead and u.in_combat and u.target and u.target != p and u.target.faction == "player" and p.check_use("taunt", u) == "":
				p.use("taunt", u); p.target = u; p.start_attack(u); return
	if not p.attacking: p.start_attack(t)

	var d := p.distance_to(t)
	if d > p.swing_range():
		if _can("charge", t): p.use("charge", t); return
		p.chase(t, p.swing_range() * 0.8); return
	if _can("battle_shout", p) and not p.has_aura("battle_shout"): p.use("battle_shout", p); return
	if _can("execute", t): p.use("execute", t); return
	var near := p.enemies_near(p.global_position, 7.0).size()
	if p.hp < p.max_hp * 0.3 and _can("shield_wall", p): p.use("shield_wall", p)
	if p.hp < p.max_hp * 0.35 and _can("rallying_cry", p): p.use("rallying_cry", p)
	if (near >= 2 or (t is Monster and (t.elite or t.boss))) and _can("recklessness", p): p.use("recklessness", p)
	if leader and p.hp < p.max_hp * 0.6 and _can("shield_block", p): p.use("shield_block", p)
	if near >= 2 and _can("cleaving_slam", t): p.use("cleaving_slam", t); return
	if near >= 2 and _can("whirlwind", t): p.use("whirlwind", t); return
	if near >= 2 and _can("thunder_clap", t): p.use("thunder_clap", t); return
	if _can("mortal_strike", t): p.use("mortal_strike", t); return
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
	if p.cls == "wizard":
		if not p.has_aura("ice_barrier") and _can("ice_barrier", p) and fight_t < 2.0: p.use("ice_barrier", p); return
		if p.power < p.max_power * 0.2 and _can("evocation", p): p.use("evocation", p); return
		if (t is Monster and (t.elite or t.boss) or p.enemies_near(t.global_position, 6.0).size() >= 3):
			if _can("arcane_power", p): p.use("arcane_power", p)
			if _can("time_warp", p): p.use("time_warp", p)
		if d < 7.0 and p.enemies_near(p.global_position, 8.0).size() >= 2 and _can("cone_of_cold", t): p.use("cone_of_cold", t); return
		if p.enemies_near(t.global_position, 6.0).size() >= 2 and _can("meteor", t): p.use("meteor", t, t.global_position); return
		if fight_t < 1.0 and d > 10.0 and _can("pyroblast", t): p.use("pyroblast", t); return
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
	# the group's healer: whoever is lowest
	var lowest := p.hp / p.max_hp
	for m in (leader.party_members() if leader and is_instance_valid(leader) else p.party_members()):
		if is_instance_valid(m) and not m.dead and m.hp / m.max_hp < lowest and p.global_position.distance_to(m.global_position) < 28.0:
			lowest = m.hp / m.max_hp; heal_me = m
	if p.hp < p.max_hp * 0.35 and _can("divine_protection", p): p.use("divine_protection", p)
	var hurt := 0
	for m2 in (leader.party_members() if leader and is_instance_valid(leader) else p.party_members()):
		if is_instance_valid(m2) and not m2.dead and m2.hp < m2.max_hp * 0.7 and p.global_position.distance_to(m2.global_position) < 14.0: hurt += 1
	if hurt >= 3 and _can("prayer_of_healing", p): p.use("prayer_of_healing", p); return
	if heal_me.hp < heal_me.max_hp * 0.25 and _can("salvation", heal_me): p.use("salvation", heal_me); return
	if heal_me.hp < heal_me.max_hp * 0.5:
		if _can("ward_of_light", heal_me) and not heal_me.has_aura("weakened_soul"): p.use("ward_of_light", heal_me); return
		if _can("radiance", heal_me) and not heal_me.has_aura("radiance"): p.use("radiance", heal_me); return
		if _can("renewal", heal_me) and not heal_me.has_aura("renewal"): p.use("renewal", heal_me); return
		if heal_me != p and _can("greater_mend", heal_me): p.use("greater_mend", heal_me); return
		if _can("mend", heal_me): p.use("mend", heal_me); return
	if not p.has_aura("inner_fire") and _can("inner_fire", p): p.use("inner_fire", p); return
	if fight_t < 1.0 and _can("ward_of_light", p) and not p.has_aura("weakened_soul") and leader == null: p.use("ward_of_light", p); return
	var d := p.distance_to(t)
	if p.is_moving() and d < 26.0: p.stop_moving()
	if _can("shadow_rot", t) and not _has_my_aura(t, "shadow_rot"): p.use("shadow_rot", t); return
	if _can("holy_fire", t): p.use("holy_fire", t); return
	if _can("mind_blast", t): p.use("mind_blast", t); return
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
	# not in the middle of a monster camp: step back toward safety first
	for u in p.get_tree().get_nodes_in_group("units"):
		if u is Monster and not u.dead and not u.passive and u.global_position.distance_to(p.global_position) < u.aggro_r + 6.0:
			# head back toward the nearest people (a hub is always safe)
			var safe := p.home
			var bd := 1e9
			for n in p.get_tree().get_nodes_in_group("npcs"):
				var dn: float = n.global_position.distance_to(p.global_position)
				if dn < bd: bd = dn; safe = n.global_position
			task = "backing off to rest"
			if not p.is_moving(): p.move_to(Nav.nearest_open(safe + Vector3(4, 0, 4)))
			return true

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

var goal_best := 1e9
var goal_t := 0.0

func _go(pos: Vector3, why: String) -> void:
	# no closer for a long while: this place can't be reached from here; leave it for later
	var d := Vector2(p.global_position.x - pos.x, p.global_position.z - pos.z).length()
	if why != task or goal.distance_to(pos) > 6.0: goal_best = d; goal_t = 0.0
	elif d < goal_best - 1.0: goal_best = d; goal_t = 0.0
	else:
		goal_t += 0.25
		if goal_t > 45.0:
			goal_t = 0.0
			for id in p.quests:
				if why.contains(Quests.LIST[id]["title"]): skip[id] = true; say("giving up on %s for now" % id)
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
		if n.npc_id == id and n.visible: return n
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
	# break a friend out of a Bone Prison, get out of what's about to blow up
	if _dodge(): return
	# 1. hand in what's done
	for id in p.quests.keys():
		if p.quest_complete(id):
			var ender := Player.ender_of(id)
			if _npc(ender) == null:
				if _travel_toward(_zone_of_npc(ender), "handing in " + Quests.LIST[id]["title"]): return
				continue
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
			if o["kind"] == "daily" and int(p.quests[id].get("day", -1)) == Player.today(): continue
			var at := _where(o)
			if at == Vector3.INF: continue
			var d := p.global_position.distance_to(at)
			if d < best_d: best_d = d; best = {"id": id, "o": o, "at": at}
	if not best.is_empty():
		_do(best["id"], best["o"], best["at"]); return
	# 5b. what's left is somewhere else: a group quest needs friends, other things need a road
	for id in p.quests:
		if skip.has(id): continue
		var q2: Dictionary = Quests.LIST[id]
		if q2.get("group", false) and p.party_members().size() < 2:
			if _find_group(id): return
			continue
		for i in q2["obj"].size():
			var o2: Dictionary = q2["obj"][i]
			if int(p.quests[id]["have"][i]) >= int(o2.get("n", 1)): continue
			var z := _zone_of_npc(o2["npc"]) if o2["kind"] == "talk" else (_zone_of_mon(o2.get("mon", "")) if o2["kind"] == "kill" else "")
			if z != "" and _travel_toward(z, "on the road for " + q2["title"]): return

	# 6. nothing to do: fight something our level nearby
	var m := _nearest_monster("", p.level - 3, p.level + 1)
	if m: _attack(m, "hunting")
	else: task = "idle"

## quests whose people aren't in the world yet (a later update), or who have left the story
func _unreachable(id: String) -> bool:
	var q: Dictionary = Quests.LIST[id]
	if _zone_of_npc(Player.ender_of(id)) == "": return true
	for o in q["obj"]:
		if o["kind"] == "talk" and _zone_of_npc(o["npc"]) == "": return true
	return false

func _zone_of_npc(id: String) -> String:
	if not Npcs.LIST.has(id): return ""
	return Npcs.LIST[id].get("zone", "ashvale")

func _zone_of_mon(kind: String) -> String:
	var S = load("res://src/world/spawns.gd")
	for z in S.CAMPS:
		for c in S.CAMPS[z]:
			if Monster.KINDS[c["kind"]].get("as", c["kind"]) == kind: return z
	return ""

## walk to the road that leads toward a zone (one step: straight there, or out of a dungeon first)
func _travel_toward(z: String, why: String) -> bool:
	if z == "" or z == WorldData.zone_id: return false
	var exits: Array = WorldData.Z.get("exits", [])
	var best: Dictionary = {}
	for ex in exits:
		if ex["to"] == z: best = ex; break
	if best.is_empty():
		for ex in exits:
			if ex["to"] != "" and (best.is_empty() or ex["to"] == "hollow"): best = ex
	if best.is_empty(): return false
	_go(Vector3(best["at"].x, 0, best["at"].y), why)
	return true

## ask someone nearby to come along (bots accept if they're close in level)
func _find_group(id: String) -> bool:
	if p.is_bot: return false
	for b in p.get_tree().get_nodes_in_group("bots"):
		if b.party_with == null and absi(b.level - p.level) <= 4 and not b.dead:
			if p.global_position.distance_to(b.global_position) < 18.0:
				p.get_tree().call_group("bots", "invited", p, b.uname)
				say("invited %s for %s" % [b.uname, id])
				return true
			_go(b.global_position, "looking for a group for " + Quests.LIST[id]["title"])
			return true
	return false

## dungeon sense: free a caged friend, step out of a marked circle
func _dodge() -> bool:
	for u in p.get_tree().get_nodes_in_group("units"):
		if not (u is Monster) or u.dead: continue
		if Monster.KINDS[u.kind].get("cage", false):
			p.target = u
			if p.cls == "warrior" or p.power < p.max_power * 0.1:
				p.start_attack(u)
				if p.distance_to(u) > p.swing_range(): p.chase(u, p.swing_range() * 0.8)
			else:
				_use("fireball" if p.cls == "wizard" else "smite", u)
			task = "breaking the bone prison"
			return true
		if not u.casting.is_empty() and Abilities.LIST.get(u.casting["id"], {}).get("kind", "") == "telegraph":
			var a: Dictionary = Abilities.LIST[u.casting["id"]]
			var c: Vector3 = u.global_position if a.get("self_center", false) else u.casting["pos"]
			var d := Vector2(p.global_position.x - c.x, p.global_position.z - c.z)
			if d.length() < float(a["radius"]) + 1.0:
				var out := c + Vector3(d.normalized().x, 0, d.normalized().y) * (float(a["radius"]) + 3.0) if d.length() > 0.1 else c + Vector3(float(a["radius"]) + 3.0, 0, 0)
				p.move_to(Nav.nearest_open(out)); task = "getting out of the way"
				return true
	return false


## where an objective is done
func _where(o: Dictionary) -> Vector3:
	match o["kind"]:
		"talk", "daily":
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
		"talk", "daily": _talk_to(o["npc"], title)
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
		# prefer ones standing alone: every friend within pulling distance counts as 10 m further
		if not u.passive:
			for o in u.camp:
				if is_instance_valid(o) and o != u and not o.dead and o.global_position.distance_to(u.global_position) < 7.0: d += 10.0
		if d < bd: bd = d; best = u
	return best

func _camp_of
(kind: String) -> Vector3:
	for c in load("res://src/world/spawns.gd").camps():
		var k: String = Monster.KINDS[c["kind"]].get("as", c["kind"])
		if k == kind: return Vector3(c["at"].x, 0, c["at"].y)
	return Vector3.INF

func _pickup(item: String) -> Pickup:
	var best: Pickup = null; var bd := 1e9
	for pk in p.get_tree().get_nodes_in_group("pickups"):
		if pk.item != item or not pk.available: continue
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
	# the class trainer in Ashvale, or a master of the orders in the bigger camps; none here: later
	if _npc(tid) == null:
		tid = ""
		for n in p.get_tree().get_nodes_in_group("npcs"):
			if n.visible and n.info.get("trainer", "") == "all": tid = n.npc_id
		if tid == "": return false
	if _talk_to(tid, "training"):
		p.train(want, cost)
		_fill_bar()
	return true

## put the best five on the bar
func _fill_bar() -> void:
	var order := {"warrior": ["mortal_strike", "heroic_strike", "charge", "execute", "whirlwind", "rend", "thunder_clap", "battle_shout", "hamstring", "taunt"],
		"wizard": ["fireball", "frostbolt", "fire_blast", "frost_nova", "pyroblast", "arcane_missiles", "flamestrike", "blink", "frost_armor"],
		"cleric": ["smite", "mend", "shadow_rot", "renewal", "ward_of_light", "greater_mend", "holy_nova", "inner_fire"]}
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
