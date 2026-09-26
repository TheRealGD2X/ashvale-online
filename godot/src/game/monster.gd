class_name Monster extends Unit
## A monster: wanders near its home, notices people who come too close (the higher its level
## compared to yours, the further it notices you), calls its friends, fights whoever it hates
## most (threat), gives up and walks home if dragged too far (leash), and comes back a while
## after it dies.

const KINDS := {
	"puglin": {"model": "Puglin", "type": "humanoid", "scale": 1.0, "attack": ["Punch_Jab", "Punch_Cross"], "speed": 2.0,
		"names": ["Puglin Scavenger", "Puglin Snout", "Puglin Tusker"], "walk": "Walk"},
	"imp": {"model": "Imp", "type": "demon", "scale": 1.0, "attack": ["Sword_Regular_A", "Melee_Hook"], "speed": 1.8,
		"names": ["Ember Imp", "Cinder Imp"], "walk": "Walk", "caster": true},
	"skeleton_a": {"model": "Skeleton_A", "type": "undead", "scale": 1.0, "attack": ["Sword_Regular_A", "Sword_Regular_B"], "speed": 2.4,
		"names": ["Restless Bones", "Varn Deadguard"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle"},
	"skeleton_b": {"model": "Skeleton_B", "type": "undead", "scale": 1.0, "attack": ["Sword_Regular_B", "Sword_Regular_C"], "speed": 2.4,
		"names": ["Rattling Footman", "Varn Deadguard"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle"},
	"lycan": {"model": "Lycan", "type": "beast", "scale": 1.05, "attack": ["Zombie_Scratch", "Melee_Hook"], "speed": 2.0,
		"names": ["Moonfang Stalker"], "walk": "Jog_Fwd"},
	"hellwarden": {"model": "Hellwarden", "type": "demon", "scale": 1.0, "attack": ["Sword_Heavy_Combo", "Sword_Attack"], "speed": 3.0,
		"names": ["The Ashen Warden"], "walk": "Walk"},
	"tidebreaker": {"model": "Tidebreaker", "type": "elemental", "scale": 1.0, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.2,
		"names": ["Old Tidebreaker"], "walk": "Walk"},
}

var kind := "puglin"
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

func _ready() -> void:
	super._ready()
	rng.randomize()
	var d: Dictionary = KINDS[kind]
	model = Humanoid.new(); model.model = "res://assets/licensed/monsters/%s.glb" % d["model"]
	model.scale = Vector3.ONE * float(d["scale"]) * (1.15 if elite else 1.0)
	add_child(model)
	radius = 0.5 * float(d["scale"]) * (1.2 if elite else 1.0)
	move_speed = Rules.RUN_SPEED * 0.95
	_stats()
	wander_t = rng.randf_range(2.0, 8.0)

func _stats() -> void:
	max_hp = Rules.mon_hp(level) * (2.5 if elite else 1.0)
	hp = max_hp
	armor = Rules.mon_armor(level)
	var hit := Rules.mon_hit(level) * (1.5 if elite else 1.0)
	var spd: float = KINDS[kind]["speed"]
	weapon = {"min": hit * spd / 2.0 * 0.85, "max": hit * spd / 2.0 * 1.15, "speed": spd}
	loot_gold = int((level * 3 + rng.randi_range(0, level * 4)) * (3 if elite else 1))
	changed.emit()

func attack_power() -> float: return 0.0
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
	var atk: Array = KINDS[kind]["attack"]
	act(atk[rng.randi() % atk.size()], 1.1)
	if r < 0.05: t.show_text("Miss", Color(1, 1, 1), self); _swing_sound(t, "miss"); return
	if r < 0.05 + 0.05 + t.attrs.get("agi", 0) / 2500.0: t.show_text("Dodge", Color(1, 1, 1), self); t._on_dodge(); _swing_sound(t, "miss"); return
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
		if target and is_instance_valid(target) and not target.dead:
			attacking = true
			if distance_to(target) > swing_range() * 0.85: chase(target, swing_range() * 0.8)
			else: stop_moving()
		return
	# idle: look around for trouble
	wander_t -= delta
	if Engine.get_physics_frames() % 8 == get_instance_id() % 8: _look_for_trouble()
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
	for m in camp:
		if is_instance_valid(m) and m != self and not m.dead and not m.in_combat and m.global_position.distance_to(global_position) < 6.0:
			m.add_threat(u, 0.5); m.target = u; m.enter_combat(); m.attacking = true

func enter_combat() -> void:
	var was := in_combat
	super.enter_combat()
	if not was and target and is_instance_valid(target):
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
	# experience and a little gold to whoever did the most (the player's group later)
	var best: Unit = k; var bt := -1.0
	for u in threat:
		if is_instance_valid(u) and threat[u] > bt: bt = threat[u]; best = u
	if best and is_instance_valid(best) and best.has_method("gain_xp"):
		best.gain_xp(Rules.kill_xp(best.level, level, elite), self)
		if best.has_method("gain_gold"): best.gain_gold(loot_gold)
	threat.clear()
	corpse_t = 18.0
	respawn_t = rng.randf_range(40.0, 70.0) * (3.0 if elite else 1.0)

func _physics_process(delta: float) -> void:
	if dead:
		corpse_t -= delta; respawn_t -= delta
		if corpse_t < 0.0 and visible: visible = false
		if respawn_t <= 0.0: _respawn()
		return
	super._physics_process(delta)

func _respawn() -> void:
	global_position = home; visible = true
	dead = false; collision_layer = 2; busy_anim = 0.0; in_combat = false; evading = false
	auras.clear(); threat.clear(); target = null; attacking = false
	if model: model._once = false; model.current = ""
	_stats()
