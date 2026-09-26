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
	"old_tusk": {"creature": "boar", "type": "beast", "scale": 2.3, "speed": 2.4, "names": ["Old Tusk"], "loot": ["cracked_tusk"], "named": true, "rare": true, "drop": ["old_tusks_tusk"]},

	"wildcat": {"creature": "wildcat", "type": "beast", "scale": 1.4, "speed": 1.6, "names": ["Wildcat"], "loot": ["matted_fur"]},
	"old_scratch": {"creature": "wildcat", "type": "beast", "scale": 1.9, "speed": 1.5, "names": ["Old Scratch"], "loot": ["matted_fur"], "named": true},
	"wolf": {"creature": "wolf", "type": "beast", "scale": 1.3, "speed": 2.0, "names": ["Timber Wolf"], "loot": ["matted_fur"]},
	"scarecrow": {"scarecrow": true, "type": "elemental", "scale": 1.0, "speed": 2.6, "names": ["Walking Scarecrow"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle",
		"attack": ["Zombie_Scratch", "Punch_Cross"], "loot": ["straw_bundle"]},
	# ---- Hollow Cliffs (10–16)
	"cave_bat": {"creature": "bat", "type": "beast", "scale": 1.4, "speed": 1.5, "names": ["Cave Bat", "Screeching Bat"], "loot": ["bat_wing"]},
	"cave_maggot": {"creature": "maggot", "type": "beast", "scale": 1.6, "speed": 2.0, "names": ["Cave Maggot"], "loot": ["maggot_goo"], "aggro": 6.0},
	"rail_spider": {"creature": "spider", "type": "beast", "scale": 1.3, "speed": 1.7, "names": ["Rail Spider", "Lantern Row Lurker"], "loot": ["spider_silk"]},
	"mountain_bear": {"creature": "bear", "type": "beast", "scale": 1.2, "speed": 2.4, "names": ["Mountain Bear"], "loot": ["matted_fur"]},
	"rockjaw": {"creature": "bear", "type": "beast", "scale": 1.7, "speed": 2.4, "names": ["Rockjaw"], "named": true, "loot": ["matted_fur"], "spells": ["ravage"]},
	"hollow_digger": {"avatar": "peasant", "tool": "pickaxe", "type": "humanoid", "scale": 1.0, "speed": 2.4, "names": ["Hollow Digger", "Hollow Delver", "Tunnel Rat"],
		"attack": ["Sword_Regular_A", "Sword_Regular_B"], "loot": ["rough_stone", "miners_wages"]},
	"skarr": {"avatar": "warrior", "tool": "pickaxe", "type": "humanoid", "scale": 1.15, "speed": 2.6, "names": ["Deep Foreman Skarr"], "named": true,
		"attack": ["Sword_Regular_A", "Sword_Heavy_Combo"], "drop": ["skarrs_key"], "spells": ["ravage"]},
	"brak": {"model": "Tidebreaker", "type": "humanoid", "scale": 0.9, "attack": ["Sword_Attack", "Sword_Regular_C"], "speed": 3.0, "names": ["Brak, Skarr's Enforcer"], "spells": ["tidal_slam"]},
	# ---- the Hollow Mine (dungeon)
	"grub_mother": {"creature": "maggot", "type": "beast", "scale": 3.6, "speed": 2.2, "names": ["The Grub Mother"], "boss": "grub", "loot": ["maggot_goo"], "drop_one": ["grubhide_jerkin", "lantern_row_cord"]},
	"gault": {"avatar": "warrior", "tool": "pickaxe", "type": "humanoid", "scale": 1.12, "speed": 2.4, "names": ["Foreman Gault"], "boss": "gault", "drop_one": ["foremans_maul", "gaults_ledger_staff"],
		"attack": ["Sword_Regular_A", "Sword_Regular_B", "Sword_Heavy_Combo"]},
	"bone_king": {"model": "Skeleton_B", "type": "undead", "scale": 1.7, "attack": ["Sword_Heavy_Combo", "Sword_Regular_C"], "speed": 3.0, "names": ["The Bone King"], "boss": "bone_king", "drop_one": ["bone_kings_circlet", "marrowplate_pauldrons", "hollow_crown_band"],
		"walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "spells": ["hellfire_ring"]},
	"bone_cage": {"cage": true, "type": "undead", "scale": 1.0, "speed": 99.0, "names": ["Bone Prison"]},
	"puglin": {"model": "Puglin", "type": "humanoid", "scale": 1.0, "attack": ["Punch_Jab", "Punch_Cross"], "speed": 2.0,
		"names": ["Puglin Scavenger", "Puglin Snout", "Puglin Tusker"], "walk": "Walk", "loot": ["puglin_trinket"]},
	"imp": {"model": "Imp", "type": "demon", "scale": 1.0, "attack": ["Sword_Regular_A", "Melee_Hook"], "speed": 1.8,
		"names": ["Ember Imp", "Cinder Imp"], "walk": "Walk", "caster": true, "spells": ["ember_bolt"], "loot": ["brimstone_chip"]},
	"skeleton_a": {"model": "Skeleton_A", "type": "undead", "scale": 1.0, "attack": ["Sword_Regular_A", "Sword_Regular_B"], "speed": 2.4,
		"names": ["Restless Bones"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "loot": ["bone_fragment"], "as": "restless_bones", "aggro": 7.0},
	"skeleton_b": {"model": "Skeleton_B", "type": "undead", "scale": 1.0, "attack": ["Sword_Regular_B", "Sword_Regular_C"], "speed": 2.4,
		"names": ["Restless Bones"], "walk": "Zombie_Walk_Fwd", "idle": "Zombie_Idle", "loot": ["bone_fragment"], "as": "restless_bones", "aggro": 7.0},
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
var boss := false
var boss_t := 0.0
var boss_phase := 0
var adds: Array = []

func setup(k: String, lv: int, is_elite := false) -> void:
	kind = k; level = lv; elite = is_elite; cls = "monster"; faction = "hostile"
	var d: Dictionary = KINDS[k]
	var names: Array = d["names"]
	uname = names[rng.randi() % names.size()]
	creature_type = d["type"]
	power_kind = "none"
	passive = d.get("passive", false) or d.get("critter", false) or d.get("cage", false)
	critter = d.get("critter", false)
	if passive: faction = "neutral"
	aggro_r = float(d.get("aggro", 9.0))

func _ready() -> void:
	super._ready()
	rng.randomize()
	var d: Dictionary = KINDS[kind]
	if d.has("creature"):
		model = CreatureBody.new(); model.model = d["creature"]
	elif d.has("avatar"):
		var ava := Avatar.new()
		var r2 := RandomNumberGenerator.new(); r2.randomize()
		ava.look = Avatar.random_look(r2, d["avatar"], "m")
		if kind == "gault": ava.look["beard"] = "Hair_Beard"; ava.look["hair"] = "Hair_Balding"; ava.look["hair_color"] = Avatar.HAIR_COLORS[5]
		model = ava
	elif d.get("cage", false):
		model = _cage_body()
	elif d.get("scarecrow", false):

		var av := Avatar.new()
		av.look = {"sex": "m", "skin": 2, "hair": "", "brows": "", "beard": "", "gear": Avatar.CLASS_GEAR["peasant"].duplicate(), "tint": {"Peasant": rng.randi_range(1, 3)}}
		model = av
	else:
		model = Humanoid.new(); model.model = "res://assets/licensed/monsters/%s.glb" % d["model"]
	model.scale = Vector3.ONE * float(d["scale"]) * (1.15 if elite and not boss else 1.0)
	add_child(model)
	if d.has("tool") and model is Avatar: model.wield.call_deferred("res://assets/weapons/%s.glb" % d["tool"], 0.62, "hand_r", -30.0)
	if kind == "bone_king": _crown()

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
	if boss: max_hp = Rules.mon_hp(level) * 9.0
	if KINDS[kind].get("cage", false): max_hp = 40 * level
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
	if evading or not attacking or target == null or not is_instance_valid(target) or target.dead or stunned > 0.0: return
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

# ------------------------------------------------------------------ dungeon bosses: one mechanic each (DESIGN §7.2)

func _boss_tick(delta: float) -> void:
	boss_t += delta
	match KINDS[kind].get("boss", ""):
		"grub":
			# Burrow: dives under the floor and erupts beneath someone (the ring on the ground warns you)
			if boss_phase == 1:
				if casting.is_empty():
					boss_phase = 0; visible = true; collision_layer = 2
					global_position = Vector3(get_meta("dive").x, WorldData.h(get_meta("dive").x, get_meta("dive").z), get_meta("dive").z)
					get_tree().call_group("fx", "burst", global_position + Vector3(0, 0.3, 0), Color(0.45, 0.38, 0.3), 50, 7.0, 0.7, 1.1, -6.0, Fx.smoke, 70.0, Vector3.UP, false, 1.5)
					get_tree().call_group("fx", "shake", 0.5, global_position)
				return
			if boss_t > 16.0 and not threat.is_empty():
				boss_t = 0.0
				var v := _random_foe()
				if v:
					boss_phase = 1; set_meta("dive", v.global_position)
					visible = false; collision_layer = 0; stop_moving(); attacking = false

					casting.clear()
					use("grub_eruption", v, v.global_position)
					_yell("The ground heaves...")
		"gault":
			# every 30 s he calls two diggers; any still standing 10 s later work him into a fury
			if boss_t > 30.0:
				boss_t = 0.0
				_yell(["Diggers! To me!", "Put your backs into it, lads!", "Nobody leaves till the Hollow's open!"][rng.randi() % 3])
				for i in 2:
					var m := Monster.new(); m.setup("hollow_digger", level - 2)
					get_parent().add_child(m)
					var p := Nav.nearest_open(global_position + Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-6, 6)))
					p.y = WorldData.h(p.x, p.z); m.global_position = p; m.home = p; m.respawn_t = 1e9
					m.died.connect(func(_u): m.get_tree().create_timer(15.0).timeout.connect(m.queue_free))
					adds.append(m)
					if target: m.get_tree().create_timer(0.3).timeout.connect(func(): if is_instance_valid(m) and is_instance_valid(target): m.aggro(target))
				get_tree().create_timer(10.0).timeout.connect(_gault_fury)
		"bone_king":
			# Bone Prison: a cage of bone closes on someone; break it in 6 seconds or it crushes them
			if boss_t > 20.0 and threat.size() >= 1:
				boss_t = 0.0
				var v2 := _random_foe(true)
				if v2: _bone_prison(v2)

func _random_foe(not_tank := false) -> Unit:
	var foes := threat.keys().filter(func(u): return is_instance_valid(u) and not u.dead)
	if not_tank and foes.size() > 1: foes.erase(target)
	return foes[rng.randi() % foes.size()] if not foes.is_empty() else null

func _gault_fury() -> void:
	if dead or not is_instance_valid(self): return
	var alive := adds.filter(func(a): return is_instance_valid(a) and not a.dead).size()
	if alive > 0:
		add_aura("foremans_fury", self, 30.0, {"dmg_pct": 0.2 * alive})
		_yell("That's the spirit!")

func _bone_prison(v: Unit) -> void:
	_yell("Stay a while. Stay forever.")
	var cage := Monster.new(); cage.setup("bone_cage", level)
	get_parent().add_child(cage)
	cage.global_position = v.global_position; cage.home = v.global_position; cage.respawn_t = 1e9
	v.add_aura("bone_prison", self, 6.0, {"root": true, "cage": true, "debuff": true})
	v.stop_moving()
	cage.died.connect(func(_u):
		if is_instance_valid(v): v.remove_aura("bone_prison")
		cage.get_tree().create_timer(2.0).timeout.connect(cage.queue_free))
	get_tree().create_timer(6.0).timeout.connect(func():
		if is_instance_valid(cage) and not cage.dead:
			if is_instance_valid(v) and not v.dead:
				v.take_damage(self, v.max_hp * 0.4, "shadow", false, "spell")
				get_tree().call_group("fx", "burst", v.global_position + Vector3(0, 1, 0), Color(0.9, 0.9, 0.8), 40, 6.0, 0.2, 0.7, -8.0)
			cage.die(null))

func _yell(t: String) -> void:
	get_tree().call_group("chat", "post", "yell", uname, t)
	show_text(t, Color(1.0, 0.3, 0.2))

## a cage of ribs and bone for the Bone Prison
func _cage_body() -> Humanoid:
	var h := PropBody.new(); h.kind = "cage"
	return h


func _crown() -> void:
	if model == null or model.skeleton == null: return
	var ba := BoneAttachment3D.new(); ba.bone_name = "Head"; model.skeleton.add_child(ba)
	var c := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.17; cm.bottom_radius = 0.14; cm.height = 0.12; cm.radial_segments = 8
	var mt := StandardMaterial3D.new(); mt.albedo_color = Color(0.85, 0.65, 0.25); mt.metallic = 0.9; mt.roughness = 0.3
	mt.emission_enabled = true; mt.emission = Color(0.6, 0.35, 0.1); mt.emission_energy_multiplier = 0.4
	cm.material = mt; c.mesh = cm; ba.add_child(c); c.position = Vector3(0, 0.22, 0)
	for k in 5:
		var sp := MeshInstance3D.new(); var sm := CylinderMesh.new(); sm.top_radius = 0.0; sm.bottom_radius = 0.035; sm.height = 0.12; sm.material = mt; sp.mesh = sm
		c.add_child(sp); var a := TAU * k / 5.0; sp.position = Vector3(cos(a) * 0.15, 0.1, sin(a) * 0.15)

func _think(delta: float) -> void:
	if KINDS[kind].get("cage", false): attacking = false; return
	if boss and in_combat and not dead: _boss_tick(delta)
	if boss_phase == 1: return


	if has_meta("taunted"):
		var tt: float = get_meta("taunted") - delta
		if tt <= 0.0: remove_meta("taunted")
		else: set_meta("taunted", tt)
	if evading:
		evade_t += delta
		if path.is_empty() and global_position.distance_to(home) > 1.5:
			path = PackedVector3Array([home])     # no route found: walk straight home
		# stuck on the way home: just be home (as WoW does)
		if evade_t > 8.0: global_position = home; evade_t = 0.0
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
		if is_instance_valid(m) and m != self and not m.dead and not m.in_combat and not m.evading and m.global_position.distance_to(global_position) < 6.0:
			m.add_threat(u, 0.5); m.target = u; m.enter_combat(); m.attacking = true

func enter_combat() -> void:
	var was := in_combat
	super.enter_combat()
	if not was and target and is_instance_valid(target) and not passive:
		for m in camp:
			if is_instance_valid(m) and m != self and not m.dead and not m.in_combat and not m.evading and m.global_position.distance_to(global_position) < 6.0:
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

var evade_t := 0.0

func _evade() -> void:
	evading = true; attacking = false; target = null; evade_t = 0.0

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
	# in your group, you loot (the bots are polite)
	if looter is Bot and looter.party_with and is_instance_valid(looter.party_with): looter = looter.party_with

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
		if d.has("drop_one"):
			var pick: Array = d["drop_one"]
			loot.append({"id": pick[rng.randi() % pick.size()], "n": 1})
		if boss: loot_money = level * 60 + rng.randi_range(0, level * 30)
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
