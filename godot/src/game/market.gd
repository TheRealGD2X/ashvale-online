class_name Market extends Node
## The market, Albion-style: one shared board of things for sale. Other players (the bots) put up
## what they gather, craft and find, and buy what's worth buying, including what you list. Prices
## drift around what things are worth. The board is kept between sessions (user://market.json).
##
## A listing: {"key": unique id, "item": {...}, "price": copper, "seller": name, "age": seconds}

const PATH := "user://market.json"
const FEE := 0.05                 # the market's cut when your listing sells

static var listings: Array = []
static var loaded := false
var t := 0.0
var rng := RandomNumberGenerator.new()
var next_key := 1

func _ready() -> void:
	add_to_group("market")
	rng.randomize()
	if not loaded: _load()
	if listings.size() < 25:
		for i in 30: _bot_post()

static func fair(it: Dictionary) -> int:
	var d := Items.get_def(it)
	return maxi(5, int(d.get("sell", 1)) * (6 if d.has("mat") else 4) * int(it.get("n", 1)))

func _process(delta: float) -> void:
	t += delta
	if t < 45.0: return
	t = 0.0
	# the board moves: people post, people buy, old things are taken down
	for i in rng.randi_range(1, 3): _bot_post()
	for l in listings: l["age"] = float(l.get("age", 0.0)) + 45.0
	listings = listings.filter(func(l): return l["seller"] == "you" or float(l["age"]) < 3600.0)
	var p: Player = get_tree().get_first_node_in_group("player")
	for l in listings.duplicate():
		if l["seller"] != "you":
			if rng.randf() < 0.04: listings.erase(l)          # someone else bought it
			continue
		var ratio := float(l["price"]) / float(fair(l["item"]))
		var chance := 0.35 if ratio <= 0.9 else (0.18 if ratio <= 1.2 else (0.06 if ratio <= 1.6 else 0.0))
		if rng.randf() < chance and p:
			listings.erase(l)
			var got := int(l["price"] * (1.0 - FEE))
			p.gold += got; p.changed.emit()
			var d := Items.get_def(l["item"])
			get_tree().call_group("hud", "notice", "Your %s sold on the market for %s." % [d.get("name", "item"), Items.money(got)])
			get_tree().call_group("fx", "sound", "coins", null, -8.0)
	_save()

func _bot_post() -> void:
	var names := ["Thornwick", "Lirael", "Brannoc", "Elspeth", "Kaelen", "Mossfoot", "Grimble", "Tamsin", "Oswin", "Vessa", "Rookwood", "Pipkin"]
	var it: Dictionary
	var r := rng.randf()
	var tier := 1 if rng.randf() < 0.6 else 2
	if r < 0.55:
		var mats := ["ore", "bar", "hide", "leather", "linen", "cloth", "herb"]
		it = {"id": "%s_%d" % [mats[rng.randi() % mats.size()], tier], "n": rng.randi_range(3, 12)}
	elif r < 0.8:
		it = Items.roll(rng.randi_range(4, 16), rng)
	elif r < 0.92:
		var rec: Array = Crafting.RECIPES[rng.randi() % Crafting.RECIPES.size()]
		it = Crafting.make(rec, tier, rng.randi_range(0, 2) if rng.randf() < 0.9 else 3, rng)
	else:
		it = {"id": ["minor_healing_potion", "warm_meal", "spring_water"][rng.randi() % 3], "n": rng.randi_range(2, 5)}
	var price := int(fair(it) * rng.randf_range(0.8, 1.6))
	listings.append({"key": _key(), "item": it, "price": price, "seller": names[rng.randi() % names.size()], "age": rng.randf_range(0, 1200)})

func _key() -> int:
	next_key += 1
	return int(Time.get_unix_time_from_system()) % 1000000 * 100 + next_key

func buy(p: Player, key: int) -> bool:
	for l in listings:
		if int(l["key"]) != key: continue
		if l["seller"] == "you": get_tree().call_group("hud", "error", "That's yours"); return false
		if p.gold < int(l["price"]): get_tree().call_group("hud", "error", "You don't have enough money"); return false
		if not p.add_item(l["item"].duplicate(true)): return false
		p.gold -= int(l["price"]); p.changed.emit()
		listings.erase(l)
		get_tree().call_group("fx", "sound", "coins", null, -8.0)
		_save()
		return true
	return false

func list_item(p: Player, bag_i: int, price: int) -> bool:
	var it = p.bags[bag_i]
	if it == null: return false
	var d := Items.get_def(it)
	if d.get("quest", false) or d.get("bind", "") in ["bop", "quest"]: get_tree().call_group("hud", "error", "You can't sell that on the market"); return false
	p.bags[bag_i] = null; p.inventory_changed.emit()
	listings.append({"key": _key(), "item": it, "price": maxi(1, price), "seller": "you", "age": 0.0})
	_save()
	return true

func cancel(p: Player, key: int) -> void:
	for l in listings:
		if int(l["key"]) == key and l["seller"] == "you":
			if p.add_item(l["item"]): listings.erase(l); _save()
			return

func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null: return
	var out := []
	for l in listings:
		var c: Dictionary = l.duplicate(true)
		out.append(c)
	f.store_string(JSON.stringify({"listings": out})); f.close()

func _load() -> void:
	loaded = true
	if not FileAccess.file_exists(PATH): return
	var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if d is Dictionary: listings = d.get("listings", [])
	for l in listings:
		# JSON turns numbers into floats; make item counts whole again
		l["item"]["n"] = int(l["item"].get("n", 1)); l["price"] = int(l["price"])
