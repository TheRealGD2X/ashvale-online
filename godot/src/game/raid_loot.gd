class_name RaidLoot extends Node
## Rolling for raid loot, WoW-style: each item comes up in turn; everyone picks Need, Greed or Pass
## (the other players decide in a moment, you get a window and 30 seconds), the highest Need wins,
## else the highest Greed. Results go in chat. Set tokens: everyone can Need them.

signal rolled(choice: String)

var items: Array = []           # [{"id", "from"}]
var busy := false
var rng := RandomNumberGenerator.new()
var cur_tok := 0
var waiting := false

## the roll window calls this
func choose(c: String) -> void:
	if not waiting: return
	waiting = false
	get_tree().call_group("hud", "close_roll")
	rolled.emit(c)

static func get_or_make(tree: SceneTree) -> RaidLoot:
	var n := tree.get_first_node_in_group("raid_loot")
	if n: return n
	var r := RaidLoot.new(); r.add_to_group("raid_loot"); r.rng.randomize()
	tree.current_scene.add_child(r)
	return r

func queue(ids: Array, from: String) -> void:
	for id in ids: items.append({"id": id, "from": from})
	if not busy: _next()

func _chat(t: String) -> void:
	get_tree().call_group("chat", "post", "loot", "", t)
	if not get_tree().get_nodes_in_group("chat").is_empty(): return
	print("LOOT ", t)

func _link(d: Dictionary) -> String:
	return "[color=#%s][%s][/color]" % [Items.color(d).to_html(false), d.get("name", "?")]

func _next() -> void:
	if items.is_empty(): busy = false; return
	busy = true
	var it: Dictionary = items.pop_front()
	var item := {"id": it["id"], "n": 1}
	var d := Items.get_def(item)
	var p: Player = get_tree().get_first_node_in_group("player")
	if p == null: _next(); return
	await get_tree().create_timer(1.0).timeout
	_chat("%s drops %s." % [it["from"], _link(d)])
	# everyone in the raid chooses
	var choices := {}
	for m in p.party_members():
		if not is_instance_valid(m) or m == p: continue
		choices[m] = _bot_choice(m, item, d)
	var mine := "pass"
	if p.has_node("Brain") or _auto(p):
		mine = _bot_choice(p, item, d)
	else:
		cur_tok += 1
		var tok := cur_tok
		get_tree().call_group("hud", "open_roll", item, self)
		get_tree().create_timer(30.0).timeout.connect(func(): if tok == cur_tok and waiting: choose("pass"))
		waiting = true
		mine = await rolled
	choices[p] = mine
	# roll the dice
	var best: Unit = null; var best_roll := -1; var best_kind := ""
	for kind in ["need", "greed"]:
		for m in choices:
			if choices[m] != kind or not is_instance_valid(m): continue
			var r := rng.randi_range(1, 100)
			_chat("%s rolls %s: %d" % [m.uname, kind.capitalize(), r])
			if r > best_roll: best_roll = r; best = m; best_kind = kind
		if best: break
	if best == null:
		_chat("Everyone passed on %s." % _link(d))
	else:
		_chat("%s won %s (%s %d)." % [best.uname, _link(d), best_kind.capitalize(), best_roll])
		best.add_item(item)
		if Items.get_def(item).get("q", 1) == 5: get_tree().call_group("chat", "post", "raid_warning", "", "%s has won a Mythic: %s!" % [best.uname, d["name"]])
		if best is Bot:
			exchange_tokens(best)
			best.brain._wear_best()
			get_tree().create_timer(rng.randf_range(1.5, 4.0)).timeout.connect(func():
				if is_instance_valid(best): best.voice_event("loot_win", {"item": d["name"]}))
		if best == p and int(d.get("q", 1)) == 5: p.pity.erase(_boss_of(item["id"]))
	_next()

func _auto(p: Player) -> bool:
	return DisplayServer.get_name() == "headless" or p.is_bot

func _boss_of(id: String) -> String:
	for k in Monster.KINDS:
		if Monster.KINDS[k].get("mythic", "") == id: return k
	return ""

## what a simulated player would pick: Need what it would wear (or its set token), Greed the rest it can use
func _bot_choice(m: Player, item: Dictionary, d: Dictionary) -> String:
	if d.has("token"): return "need"
	if not Items.can_use(m.cls, d, m.level): return "pass"
	if m.cls == "warrior" and (d.get("armor_type", "") == "cloth" or d.get("wtype", "") in ["staff", "wand"]): return "greed" if rng.randf() < 0.5 else "pass"
	if m.cls != "warrior" and d.get("stats", {}).has("str") and not d.get("stats", {}).has("int"): return "greed" if rng.randf() < 0.5 else "pass"
	var slot := Items.slot_of(d)
	if slot == "finger" or slot == "trinket": slot += "1"
	var cur = m.equipped.get(slot)
	var score := _score(m, item)
	var had := _score(m, cur) if cur else -1.0
	if score > had * 1.02: return "need" if rng.randf() < 0.95 else "greed"
	return "greed" if rng.randf() < 0.6 else "pass"

func _score(m: Player, it: Dictionary) -> float:
	var brain = m.get_node_or_null("Brain")
	if brain == null:
		for c in m.get_children():
			if c is Brain: brain = c
	if brain: return brain._score(it)
	var d := Items.get_def(it)
	return float(d.get("ilvl", 1))

## set tokens become the right piece for your class (the Keeper of the Vault does this; bots do it at once)
static func exchange_tokens(p: Player) -> int:
	var n := 0
	for i in p.bags.size():
		var it = p.bags[i]
		if it == null: continue
		var d := Items.get_def(it)
		if not d.has("token"): continue
		p.bags[i] = {"id": "set_%s_%s" % [p.cls, d["token"]], "n": 1}; n += 1
	if n > 0: p.inventory_changed.emit()
	return n
