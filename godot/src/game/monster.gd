class_name Monster extends Unit
## A monster: wanders near its home, notices people who come too close (the higher its level
## compared to yours, the further it notices you), calls its friends, fights whoever it hates
## most (threat), gives up and walks home if dragged too far (leash), and comes back a while
## after it dies.

## body: "bestiary" (a paid-pack monster), "creature" (our animals) or "scarecrow" (a dressed-up
## person with a sack for a head). passive: only fights back. critter: harmless (hens).
const KINDS := {
	"field_rat": {"creature": "rat", "type": "beast", "scale": 1.5, "speed": 1.6, "names": ["Field Rat"], "aggro": 5.0, "loot": ["rat_tail"]},
	"grizzled_rat": {"creature": "rat", "type": "beast", "scale": 2.6, "speed": 1.8, "names": ["Grizzled Rat"], "aggro": 7.0, "named": true, "loot": ["rat_tail"]},
	"hen": {"creature": "hen", "type": "beast", "scale": 1.0, "speed": 2.0, "names": ["Hen"], "critter": true, "loot": ["chicken_egg"]},
	"wild_boar": {"creature": "boar", "type": "beast", "scale": 1.35, "speed": 2.2, "names": ["Wild Boar", "Rooting Boar"], "passive": true, "loot": ["cracked_tusk", "boar_hide"]},
	"hogtooth": {"creature": "boar", "type": "beast", "scale": 2.1, "speed": 2.4, "names": ["Hogtooth, the Boar King"], "loot": ["cracked_tusk"], "named": true},
	"old_tusk": {"creature": "boar", "type": "beast", "scale": 2.3, "speed": 2.4, "names": ["Old Tusk"], "loot": ["cracked_tusk"], "named": true, "rare": true, "drop": ["tusk_blue"]},
	"wildcat": {"creature": "wildcat", "type": "beast", "scale": 1.4, "speed": 1.6, "names": ["Wildcat"], "loot": ["matted_fur"]},
	"old_scratch": {"creature": "wildcat", "type": "beast", "scale": 1.9, "speed": 1.5, "names": ["Old Scratch"], "loot": ["matted_fur"], "named": true},
	"wolf": {"creature": "wolf", "type": "beast", "scale": 1.3, "speed": 2.0, "names": ["Timber Wolf"], "loot": ["matted_fur"]},
	"scarecrow": {"scarecrow": true, "type": "elemental", "scale": 1.0, "speed": 2.6, "names": ["Walking Scarecrow"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle",
		"attack": ["Zombie_Scratch", "Punch_Cross"], "loot": ["straw_bundle"]},
	"puglin": {"model": "Puglin", "type": "humanoid", "scale": 1.0, "attack": ["Punch_Jab", "Punch_Cross"], "speed": 2.0,
		"names": ["Puglin Scavenger", "Puglin Snout", "Puglin Tusker"], "walk": "Walk", "loot": ["puglin_trinket"]},
	"imp": {"model": "Imp", "type": "demon", "scale": 1.0, "attack": ["Sword_Regular_A", "Melee_Hook"], "speed": 1.8,
		"names": ["Ember Imp", "Cinder Imp"], "walk": "Walk", "caster": true, "spells": ["ember_bolt"], "loot": ["brimstone_chip"]},
	"skeleton_a": {"model": "Skeleton_A", "type": "undead", "scale": 1.0, "attack": ["Sword_Regular_A", "Sword_Regular_B"], "speed": 2.4,
		"names": ["Restless Bones"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "loot": ["bone_fragment"], "as": "restless_bones"},
	"skeleton_b": {"model": "Skeleton_B", "type": "undead", "scale": 1.0, "attack": ["Sword_Regular_B", "Sword_Regular_C"], "speed": 2.4,
		"names": ["Restless Bones"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "loot": ["bone_fragment"], "as": "restless_bones"},
	"lycan": {"model": "Lycan", "type": "beast", "scale": 1.05, "attack": ["Zombie_Scratch", "Melee_Hook"], "speed": 2.0,
		"names": ["Moonfang Stalker"], "walk": "Jog_Fwd", "spells": ["ravage"]},
	"hellwarden": {"model": "Hellwarden", "type": "demon", "scale": 1.0, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0,
		"names": ["The Ashen Warden"], "walk": "Walk", "spells": ["hellfire_ring"]},
	"tidebreaker": {"model": "Tidebreaker", "type": "elemental", "scale": 1.0, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.2,
		"names": ["Old Tidebreaker"], "walk": "Walk", "spells": ["tidal_slam"]},
}

var kind := "puglin"
var passive := false
var critter := false
var loot: Array = []                 # what the corpse holds: [{"id":..., "n":...}] and money
var loot_money := 0
var looted := false
var camp: Array = []                 # the other monsters of this camp (social aggro)
var aggro_r := 9.0
var leash := 38.0
var evading := false
var wander_t := 0.0
var respawn_t := 0.0
var corpse_t := 0.0
var rng := RandomNumberGenerator.new()
var loot_gold := 0
var killer: Unit

func setup(k: String, lv: int, is_elite := false) -> void:
	kind = k; level = lv; elite = is_elite; cls = "monster"; faction = "hostile"
	var d: Dictionary = KINDS[k]
	var names: Array = d["names"]
	uname = names[rng.randi() % names.size()]
	creature_type = d["type"]
	power_kind = "none"
	passive = d.get("passive", false) or d.get("critter", false)
	critter = d.get("critter", false)
	if passive: faction = "neutral"
	aggro_r = float(d.get("aggro", 9.0))

func _ready() -> void:
	super._ready()
	rng.randomize()
	var d: Dictionary = KINDS[kind]
	if d.has("creature"):
		model = CreatureBody.new(); model.model = d["creature"]
	elif d.get("scarecrow", false):
		var av := Avatar.new()
		av.look = {"sex": "m", "skin": 2, "hair": "", "brows": "", "beard": "", "gear": Avatar.CLASS_GEAR["peasant"].duplicate(), "tint": {"Peasant": rng.randi_range(1, 3)}}
		model = av
	else:
		model = Humanoid.new(); model.model = "res://assets/licensed/monsters/%s.glb" % d["model"]
	model.scale = Vector3.ONE * float(d["scale"]) * (1.15 if elite else 1.0)
	add_child(model)
	if d.get("scarecrow", false):
		# a sack with a stitched face where the head should be
		var ba := BoneAttachment3D.new(); ba.bone_name = "Head"; model.skeleton.add_child(ba)
		var sack := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.16; sm.height = 0.36
		var mt := StandardMaterial3D.new(); mt.albedo_color = Color(0.72, 0.6, 0.4); mt.roughness = 1.0; sm.material = mt; sack.mesh = sm
		ba.add_child(sack); sack.position = Vector3(0, 0.1, 0.02)
		for ex in [-0.06, 0.06]:
			var e := MeshInstance3D.new(); var em := SphereMesh.new(); em.radius = 0.028; em.height = 0.056
			var emt := StandardMaterial3D.new(); emt.albedo_color = Color(0.05, 0.04, 0.03); emt.emission_enabled = true; emt.emission = Color(1.0, 0.6, 0.2); emt.emission_energy_multiplier = 1.5
			em.material = emt; e.mesh = em; sack.add_child(e); e.position = Vector3(ex, 0.03, 0.14)
		var hat := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.08; cm.bottom_radius = 0.26; cm.height = 0.14
		var hmt := StandardMaterial3D.new(); hmt.albedo_color = Color(0.5, 0.42, 0.25); cm.material = hmt; hat.mesh = cm; sack.add_child(hat); hat.position = Vector3(0, 0.16, 0)
	radius = 0.5 * float(d["scale"]) * (1.2 if elite else 1.0)
	move_speed = Rules.RUN_SPEED * 0.95
	_stats()
	wander_t = rng.randf_range(2.0, 8.0)

func _stats() -> void:
	var named: bool = KINDS[kind].get("named", false)
	max_hp = Rules.mon_hp(level) * (2.5 if elite else (1.8 if named else 1.0))
	if critter: max_hp = 6 + level * 2
	hp = max_hp
	armor = Rules.mon_armor(level)
	var hit := Rules.mon_hit(level) * (1.5 if elite else 1.0)
	var spd: float = KINDS[kind]["speed"]
	weapon = {"min": hit * spd / 2.0 * 0.85, "max": hit * spd / 2.0 * 1.15, "speed": spd}
	loot_gold = int((level * 3 + rng.randi_range(0, level * 4)) * (3 if elite else 1))
	if critter: loot_gold = 0; weapon = {"min": 0.0, "max": 0.0, "speed": 99.0}
	changed.emit()

func attack_power() -> float: return 0.0
func spell_power() -> float: return 0.0
func cost_of(_id: String) -> float: return 0.0
func crit_chance(_spell: bool) -> float: return 0.05
func _armed() -> bool: return false

func _animate(v: float) -> void:
	if model == null or model.anim == null: return
	if busy_anim > 0.0 and v < 0.4: return
	var d: Dictionary = KINDS[kind]
	if v < 0.3: model.play(d.get("idle", "Idle") if not in_combat else d.get("idle", "Idle"))
	elif v < 3.4: model.play(d.get("walk", "Walk"), clampf(v / 1.7, 0.6, 1.4))
	else: model.play("Jog_Fwd", clampf(v / 4.4, 0.8, 1.4))

func _tick_swing(delta: float) -> void:
	swing_t = maxf(0.0, swing_t - delta)
	if not attacking or target == null or not is_instance_valid(target) or target.dead or stunned > 0.0: return
	if distance_to(target) > swing_range() or swing_t > 0.0: return
	swing_t = weapon["speed"] * (1.0 + _aura_sum("slow_attack"))
	var r := randf()
	var t := target
	var atk: Array = KINDS[kind].get("attack", ["Attack"])
	act(atk[rng.randi() % atk.size()], 1.1)
	if r < 0.05: t.show_text("Miss", Color(1, 1, 1), self); _swing_sound(t, "miss"); return
	if r < 0.05 + 0.05 + t.attrs.get("agi", 0) / 2500.0 + t.tmod("dodge"): t.show_text("Dodge", Color(1, 1, 1), self); t._on_dodge(); _swing_sound(t, "miss"); return
	var dmg := randf_range(weapon["min"], weapon["max"])
	var crit := randf() < 0.05
	if crit: dmg *= 1.5
	_swing_sound(t, "crit" if crit else "hit")
	dmg *= 1.0 - Rules.armor_dr(t.armor, level)
	t.take_damage(self, dmg, "physical", crit, "white")

# ------------------------------------------------------------------ thinking

func _think(delta: float) -> void:
	if has_meta("taunted"):
		var tt: float = get_meta("taunted") - delta
		if tt <= 0.0: remove_meta("taunted")
		else: set_meta("taunted", tt)
	if evading:
		if path.is_empty() and global_position.distance_to(home) > 1.5:
			path = PackedVector3Array([home])     # no route found: walk straight home
		if global_position.distance_to(home) < 1.5:
			evading = false; hp = max_hp; auras.clear(); threat.clear(); target = null; attacking = false; in_combat = false
			changed.emit()
		return
	# forget the dead and the gone
	for k in threat.keys():
		if not is_instance_valid(k) or k.dead: threat.erase(k)
	if in_combat:
		if global_position.distance_to(home) > leash or (threat.is_empty() and combat_t > 1.0):
			_evade(); return
		_pick_target()
		if critter:
			# run away from whoever is bothering us
			if target and is_instance_valid(target) and path.is_empty():
				var away := (global_position - target.global_position); away.y = 0
				var p := global_position + away.normalized() * 8.0
				if Nav.walkable(p): path = Nav.path(global_position, p)
			if combat_t > 5.0: threat.clear(); in_combat = false; target = null
			return
		if target and is_instance_valid(target) and not target.dead:
			attacking = true
			if not casting.is_empty(): return
			var caster: bool = KINDS[kind].get("caster", false)
			# special attacks when they are ready
			for sp in KINDS[kind].get("spells", []):
				if check_use(sp, target) == "" and (not caster or distance_to(target) > 4.0 or rng.randf() < 0.3):
					stop_moving(); use(sp, target); return
			if caster and distance_to(target) > 4.0:
				if distance_to(target) > 22.0: chase(target, 20.0)
				else: stop_moving()
				attacking = distance_to(target) <= swing_range()
			elif distance_to(target) > swing_range() * 0.85: chase(target, swing_range() * 0.8)
			else: stop_moving()
		return
	# idle: look around for trouble
	wander_t -= delta
	if not passive and Engine.get_physics_frames() % 8 == get_instance_id() % 8: _look_for_trouble()
	if wander_t <= 0.0 and path.is_empty():
		wander_t = rng.randf_range(5.0, 14.0)
		var p := home + Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-6, 6))
		if Nav.walkable(p): path = Nav.path(global_position, p)

func _look_for_trouble() -> void:
	for u in get_tree().get_nodes_in_group("units"):
		if u.dead or not is_enemy(u) or u.has_meta("ghost"): continue
		var r := clampf(aggro_r + (level - u.level) * 1.2, 3.0, 20.0)
		if global_position.distance_to(u.global_position) < r:
			aggro(u); return

func aggro(u: Unit) -> void:
	if dead or evading: return
	add_threat(u, 1.0); target = u; enter_combat(); attacking = true
	if passive: return
	for m in camp:
		if is_instance_valid(m) and m != self and not m.dead and not m.in_combat and m.global_position.distance_to(global_position) < 6.0:
			m.add_threat(u, 0.5); m.target = u; m.enter_combat(); m.attacking = true

func enter_combat() -> void:
	var was := in_combat
	super.enter_combat()
	if not was and target and is_instance_valid(target) and not passive:
		for m in camp:
			if is_instance_valid(m) and m != self and not m.dead and not m.in_combat and m.global_position.distance_to(global_position) < 6.0:
				m.add_threat(target, 0.5); m.target = target; m.in_combat = true; m.combat_t = 0.0; m.attacking = true

func _pick_target() -> void:
	if has_meta("taunted") and target and is_instance_valid(target) and not target.dead: return
	var best: Unit = null; var bt := -1.0
	for k in threat:
		if threat[k] > bt: bt = threat[k]; best = k
	if best == null: return
	if target == null or not is_instance_valid(target) or target.dead or not threat.has(target):
		target = best; return
	# the 110% / 130% rule: switch only when someone clearly out-threatens the current target
	var cur: float = threat[target]
	var near := distance_to(best) <= swing_range() + 0.5
	if best != target and bt > cur * (1.1 if near else 1.3): target = best

func _evade() -> void:
	evading = true; attacking = false; target = null
	threat.clear(); casting.clear()
	path = Nav.path(global_position, home)
	show_text("Evade", Color(1, 1, 1))

func take_damage(src: Unit, amount: float, school := "physical", crit := false, kind_ := "", threat_mult := 1.0) -> int:
	if evading:
		show_text("Evade", Color(1, 1, 1)); return 0
	if not in_combat and src and is_instance_valid(src): target = src
	return super.take_damage(src, amount, school, crit, kind_, threat_mult)

func _on_death(k: Unit) -> void:
	killer = k
	# experience, quest credit and the loot go to whoever tagged it / did the most
	var best: Unit = k; var bt := -1.0
	for u in threat:
		if is_instance_valid(u) and threat[u] > bt: bt = threat[u]; best = u
	looter = best if best and is_instance_valid(best) and best.has_method("gain_xp") else null
	loot = []; loot_money = 0
	if looter:
		var party: Array = looter.party_members() if looter.has_method("party_members") else [looter]
		for m in party:
			if not is_instance_valid(m) or m.dead or m.global_position.distance_to(global_position) > 60.0: continue
			if not critter: m.gain_xp(int(Rules.kill_xp(m.level, level, elite) / (1.0 if party.size() == 1 else party.size() * 0.75)), self)
			if m.has_method("on_kill"): m.on_kill(self)
		_roll_loot()
	threat.clear()
	corpse_t = 60.0 if not loot.is_empty() or loot_money > 0 else 18.0
	respawn_t = rng.randf_range(40.0, 70.0) * (3.0 if elite else 1.0)

var looter: Unit                     # who may loot this corpse
var sparkle: Node3D

## what the corpse holds: coins, a grey or two, quest items the looter needs, sometimes a green
func _roll_loot() -> void:
	var d: Dictionary = KINDS[kind]
	if critter:
		if rng.randf() < 0.3 and d.has("loot"): loot.append({"id": d["loot"][0], "n": 1})
	else:
		loot_money = loot_gold if rng.randf() < 0.85 or elite or d.get("named", false) else 0
		if d.has("loot") and rng.randf() < 0.55:
			loot.append({"id": d["loot"][rng.randi() % d["loot"].size()], "n": 1})
		if d.has("drop"):
			for it in d["drop"]: loot.append({"id": it, "n": 1})
		var green := 0.05 + (0.9 if d.get("named", false) or elite else 0.0)
		if rng.randf() < green: loot.append(Items.roll(level, rng, 3 if elite and rng.randf() < 0.3 else 2))
		if rng.randf() < 0.04: loot.append({"id": "minor_healing_potion", "n": 1})
	if looter.has_method("quest_drops"): loot.append_array(looter.quest_drops(self))
	if looter.has_method("auto_loot"): looter.auto_loot(self); return
	if not loot.is_empty() or loot_money > 0: _show_sparkle(true)

func has_loot(p: Unit) -> bool:
	return dead and p == looter and (not loot.is_empty() or loot_money > 0)

## after someone took something
func loot_taken() -> void:
	if loot.is_empty() and loot_money <= 0:
		_show_sparkle(false); corpse_t = minf(corpse_t, 6.0)

func _show_sparkle(on: bool) -> void:
	if on and sparkle == null:
		var fx := get_tree().get_first_node_in_group("fx")
		if fx == null: return
		sparkle = fx.twinkle(self, Color(1.0, 0.85, 0.35))
		sparkle.position = Vector3(0, 0.4, 0)
	elif not on and sparkle:
		sparkle.queue_free(); sparkle = null

func _physics_process(delta: float) -> void:
	if dead:
		corpse_t -= delta; respawn_t -= delta
		if corpse_t < 0.0 and visible: visible = false
		if respawn_t <= 0.0: _respawn()
		return
	super._physics_process(delta)

func _respawn() -> void:
	global_position = home; visible = true
	loot = []; loot_money = 0; looter = null; _show_sparkle(false)
	dead = false; collision_layer = 2; busy_anim = 0.0; in_combat = false; evading = false
	auras.clear(); threat.clear(); target = null; attacking = false
	if model: model._once = false; model.current = ""
	_stats()
