extends Node
## A robot player for tests: finds the nearest monster, fights it with the class's abilities,
## rests when low, and reports what happened (kills, deaths, levels, errors) to the log.
##   godot --path . -- --play --autoplay=120 --class=wizard --level=3 --hero=40,-30

var p: Player
var t := 0.0
var limit := 120.0
var kills := 0
var deaths := 0
var start_level := 1
var log_t := 0.0
var casts := {}

func _ready() -> void:
	limit = float(get_parent().args.get("autoplay", "120"))

func _physics_process(delta: float) -> void:
	if p == null:
		p = get_tree().get_first_node_in_group("player")
		if p == null: return
		start_level = p.level
		p.leveled.connect(func(l): print("[auto] reached level %d at %.0fs" % [l, t]))
		for m in get_tree().get_nodes_in_group("units"):
			if m is Monster: m.died.connect(func(_u): kills += 1)
		p.died.connect(func(_u): deaths += 1; print("[auto] died at %.0fs" % t))
	t += delta
	log_t += delta
	if log_t > 10.0:
		log_t = 0.0
		print("[auto] %3.0fs  lv %d  hp %d/%d  %s %d/%d  kills %d  target %s  pos %s" % [t, p.level, p.hp, p.max_hp, p.power_kind, p.power, p.max_power, kills,
			p.target.uname if p.target and is_instance_valid(p.target) else "-", str(Vector2i(int(p.global_position.x), int(p.global_position.z)))])
	if t > limit:
		print("[auto] DONE  %.0fs  level %d -> %d  kills %d  deaths %d  casts %s  gold %d" % [t, start_level, p.level, kills, deaths, str(casts), p.gold])
		get_tree().quit(); return
	if p.dead:
		p.release(); return
	if not p.casting.is_empty(): return
	# rest when hurt and out of combat
	if not p.in_combat and (p.hp < p.max_hp * 0.55 or (p.power_kind == "mana" and p.power < p.max_power * 0.35)):
		p.stop_moving(); return
	var tg := p.target
	if tg == null or not is_instance_valid(tg) or tg.dead:
		tg = _nearest()
		if tg == null: return
		p.target = tg
	var d := p.distance_to(tg)
	# healers heal themselves
	if p.cls == "cleric" and p.hp < p.max_hp * 0.45:
		_try("ward_of_light", p); _try("mend", p); return
	for i in p.bar.size():
		var id: String = p.bar[i]
		if id == "" or not Abilities.LIST.has(id): continue
		var a: Dictionary = Abilities.LIST[id]
		if a.get("helpful", false) or a["kind"] == "buff": continue
		if a["kind"] == "aoe" and d > float(a.get("radius", 5)) - 1.0: continue
		if id == "execute" and tg.hp > tg.max_hp * 0.2: continue
		if a["kind"] in ["dot", "debuff"] and tg.has_aura(id): continue
		var why := p.check_use(id, tg)
		if why == "":
			p.stop_moving(); p.use(id, tg); casts[id] = casts.get(id, 0) + 1
			if p.cls == "warrior": p.start_attack(tg)
			return
	# get into range
	var want := Rules.MELEE_RANGE * 0.8 if p.cls == "warrior" else 24.0
	if d > want:
		if not p.is_moving(): p.chase(tg, want)
	else:
		p.stop_moving()
		p.start_attack(tg)

func _try(id: String, tg: Unit) -> void:
	if p.known.has(id) and p.check_use(id, tg) == "": p.use(id, tg); casts[id] = casts.get(id, 0) + 1

func _nearest() -> Unit:
	var best: Unit = null; var bd := 1e9
	for u in get_tree().get_nodes_in_group("units"):
		if u is Monster and not u.dead and u.visible and u.level <= p.level + 2:
			var d: float = u.global_position.distance_to(p.global_position)
			if d < bd: bd = d; best = u
	return best
