extends Node
## Runs the Abyssal Sanctum with a gathered raid and prints how each boss goes:
##   godot --headless --path . --fixed-fps 30 -- --play --raidtest --zone=scar --level=60 --class=warrior --done=scar
## The leader is you, played by a Brain; the other nine are simulated players with raid roles.

static var phase := "gather"         # gather | walk | sanctum | done
static var boss_i := 0
static var tries := 0
static var t_all := 0.0
static var results := []
var p: Player
var brain: Brain
var t := 0.0
var fight_t := 0.0
var report := 0.0
var fighting: Monster
var wait_t := 0.0
var trash: Monster
var trash_t := 0.0

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	p = get_tree().get_first_node_in_group("player")
	var chat = get_tree().get_first_node_in_group("chat")
	if chat: chat.set_meta("print", true)
	brain = Brain.new(p); brain.idle = true; p.add_child(brain)
	get_tree().create_timer(2.0).timeout.connect(_watch_deaths)
	if phase == "gather":
		var r := RandomNumberGenerator.new(); r.seed = 3
		p.equipped.clear(); p.gear_up(59, 3, r); p._gear_changed(); p.refresh_stats(true)
		if p.count_item("sanctum_key") <= 0: p.add_item({"id": "sanctum_key", "n": 1})
		get_tree().call_group("society", "gather_raid", p)
	if WorldData.zone_id == "sanctum" and phase == "walk":
		phase = "sanctum"
		# --raidfrom=N: start at the Nth boss (the ones before are already down)
		boss_i = int(get_parent().args.get("raidfrom", "0"))
		for i in boss_i:
			for u in get_tree().get_nodes_in_group("units"):
				if u is Monster and (u.kind == Raid.ORDER[i] or (Raid.ORDER[i] == "warden_ashur" and u.kind == "warden_seth")):
					u.dead = true; u.visible = false; u.collision_layer = 0; u.respawn_t = 1e9
		# and the rooms before it are clear of trash, for a quick test
		if boss_i > 0:
			for u in get_tree().get_nodes_in_group("units"):
				if u is Monster and Monster.KINDS[u.kind].get("raid_trash", false):
					u.dead = true; u.visible = false; u.collision_layer = 0; u.respawn_t = 1e9
	print("raidtest: phase %s in %s" % [phase, WorldData.zone_id])

func _physics_process(delta: float) -> void:
	if p == null: return
	t += delta; t_all += delta; report += delta
	if t_all > 7200.0: _finish("timeout"); return
	match phase:
		"gather":
			if p.party.size() >= 9 or t > 90.0:
				print("raid gathered: %d  %s" % [p.party.size() + 1, ", ".join(p.party.map(func(m): return "%s (%s %s)" % [m.uname, m.cls, m.raid_role]))])
				phase = "walk"; t = 0.0
		"walk":
			# to the Gate; the raid follows
			if t > 3.0 and not p.is_moving(): p.move_to(Nav.nearest_open(Vector3(0, 0, -85)))
			if t > 200.0: _finish("never reached the gate")
		"sanctum": _sanctum(delta)

func _alive() -> Array:
	return p.party_members().filter(func(m): return is_instance_valid(m) and not m.dead)

func _boss() -> Monster:
	var want: String = Raid.ORDER[boss_i]
	for u in get_tree().get_nodes_in_group("units"):
		if u is Monster and u.kind == want: return u
	return null

func _sanctum(delta: float) -> void:
	if boss_i >= Raid.ORDER.size(): _finish("cleared"); return
	var b := _boss()
	if b == null: print("no boss %s" % Raid.ORDER[boss_i]); boss_i += 1; return
	if b.dead and fighting == null:
		boss_i += 1; return
	if fighting:
		fight_t += delta
		if report >= 10.0:
			report = 0.0
			var twin := ""
			if b.kind == "warden_ashur":
				for u in get_tree().get_nodes_in_group("units"):
					if u is Monster and u.kind == "warden_seth": twin = "  seth %d%%" % int(100.0 * u.hp / u.max_hp)
			var hs := []
			for m in p.party:
				if is_instance_valid(m) and m.raid_role in ["heal", "tank"]:
					hs.append("%s:%s %s mp%d%% hp%d%% %s d%.0f" % [m.uname, m.raid_role, m.casting.get("id", "-"), int(100.0 * m.power / maxf(1.0, m.max_power)), int(100.0 * m.hp / m.max_hp), m.brain.task, m.global_position.distance_to(b.global_position)])
			print("    ", " | ".join(hs))
			print("  %s  t=%3d  boss %3d%%%s  raid alive %d/10  adds %d" % [b.uname, int(fight_t), int(100.0 * b.hp / b.max_hp), twin, _alive().size(), b.adds.filter(func(a): return is_instance_valid(a) and not a.dead).size()])
		var done := b.dead
		if b.kind == "warden_ashur":
			for u in get_tree().get_nodes_in_group("units"):
				if u is Monster and u.kind == "warden_seth" and not u.dead: done = false
		if done:
			results.append("%s: killed in %ds (try %d, %d alive)" % [b.uname, int(fight_t), tries + 1, _alive().size()])
			print("KILLED %s in %ds on try %d" % [b.uname, int(fight_t), tries + 1]); _meter(b.uname, fight_t)
			get_tree().call_group("bots", "voice_event", "raid_kill")
			fighting = null; tries = 0; boss_i += 1; brain.focus = null; brain.idle = true; wait_t = 0.0
			return
		if _alive().is_empty() or b.evading or (p.dead and _alive().size() <= 1):
			results.append("%s: wipe at %d%% after %ds" % [b.uname, int(100.0 * b.hp / b.max_hp), int(fight_t)])
			print("WIPE on %s at %d%% after %ds (evading %s, %.0f m from home, threat %d, leader dead %s)" % [b.uname, int(100.0 * b.hp / b.max_hp), int(fight_t), b.evading, b.global_position.distance_to(b.home), b.threat.size(), p.dead])
			get_tree().call_group("bots", "voice_event", "raid_wipe"); _meter(b.uname, fight_t)
			fighting = null; tries += 1; brain.focus = null; brain.idle = true; wait_t = 0.0
			if tries >= 5: results.append("%s: gave up" % b.uname); boss_i = 99
		return
	# between pulls: gather, rest, clear the trash on the way, then go
	if p.dead: return
	if trash and is_instance_valid(trash) and not trash.dead:
		if not p.in_combat and not trash.in_combat:
			if p.distance_to(trash) > 20.0: p.move_to(Nav.nearest_open(trash.global_position)); return
			for m in p.party:
				if is_instance_valid(m) and m.raid_role == "tank": trash.add_threat(m, 30.0)
			trash.aggro(p); brain.idle = false; brain.focus = trash; trash_t = 0.0
		trash_t += get_physics_process_delta_time()
		return
	if trash: _meter(trash.uname, trash_t)
	trash = null; brain.focus = null
	for u in get_tree().get_nodes_in_group("units"):
		if u is Monster and not u.dead and Monster.KINDS[u.kind].get("raid_trash", false) and u.adds.is_empty() and not u.has_meta("add") \
				and u.global_position.distance_to(p.global_position) < 34.0 and u.global_position.distance_to(b.global_position) > 18.0 \
				and u.global_position.z > b.global_position.z - 5.0:
			trash = u; print("  clearing %s" % u.uname); return
	brain.idle = true
	var ready := true
	for m in p.party_members():
		if not is_instance_valid(m): continue
		if m.dead or m.hp < m.max_hp * 0.9 or (m.power_kind == "mana" and m.power < m.max_power * 0.8): ready = false
	wait_t += delta
	var d := p.global_position.distance_to(b.global_position)
	if d > 26.0:
		if not p.is_moving() or Engine.get_physics_frames() % 60 == 0: p.move_to(Nav.nearest_open(b.global_position + (p.global_position - b.global_position).normalized() * 22.0))
		return
	p.stop_moving()
	if (ready and wait_t > 8.0) or wait_t > 60.0:
		print("PULL %s (try %d)" % [b.uname, tries + 1])
		fighting = b; fight_t = 0.0; report = 0.0
		brain.idle = false; brain.focus = b
		if b.kind == "warden_ashur": brain.focus = null      # the leader fights like the others: keep them even
		# the tank goes first
		for m in p.party:
			if is_instance_valid(m) and m.raid_role == "tank":
				b.add_threat(m, 50.0)
		b.aggro(p)

func _finish(why: String) -> void:
	if phase == "done": return
	phase = "done"
	print("RAIDTEST END (%s) after %ds" % [why, int(t_all)])
	for r in results: print("  ", r)
	print("  locks: ", p.raid_locks, "  pity: ", p.pity)
	var bags := []
	for it in p.bags:
		if it: bags.append(Items.get_def(it).get("name", "?"))
	print("  bags: ", ", ".join(bags))
	get_tree().quit()

var watched := {}
func _watch_deaths() -> void:
	for m in p.party_members():
		if is_instance_valid(m) and not watched.has(m):
			watched[m] = true
			m.struck.connect(func(u, amount, _crit, school, kind): if u.hp <= 0 and kind != "heal": _last_hit(u, amount, school, kind))
	get_tree().create_timer(5.0).timeout.connect(_watch_deaths)

func _last_hit(u: Unit, amount: int, school: String, kind: String) -> void:
	var who := []
	for m in get_tree().get_nodes_in_group("units"):
		if m is Monster and not m.dead and m.in_combat and (m.target == u or m.casting.get("target") == u): who.append(m.uname)
	var role: String = u.raid_role if u is Bot else "leader"
	print("    DEATH %s (%s %s, %d max hp): %d %s %s; on them: %s" % [u.uname, u.cls, role, int(u.max_hp), amount, school, kind, ", ".join(who)])

func _meter(label: String, secs: float) -> void:
	var rows := []
	for m in p.party_members():
		if not is_instance_valid(m): continue
		rows.append("%s %s: %d dps %d hps" % [m.uname, m.raid_role if m is Bot else "you", int(m.dmg_done / maxf(1.0, secs)), int(m.heal_done / maxf(1.0, secs))])
		m.dmg_done = 0; m.heal_done = 0
	print("  METER %s (%ds): %s" % [label, int(secs), "; ".join(rows)])

