extends Node
## Crafting and market, end to end:  --play --crafttest --bots=0 --nomonsters
func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	var p: Player = get_tree().get_first_node_in_group("player")
	p.gold = 50000
	for id in ["ore_1", "hide_1", "linen_1", "herb_1"]: p.add_item({"id": id, "n": 20})
	print("refined bars: ", Crafting.refine(p, "ore_1", 99), " leather: ", Crafting.refine(p, "hide_1", 99), " cloth: ", Crafting.refine(p, "linen_1", 99))
	for r in ["sword", "mail_chest", "robe", "healing_potion", "leather_hands", "staff"]:
		var it := Crafting.craft(p, r, 1)
		print("craft ", r, " -> ", Items.get_def(it).get("name", "(nothing)"), "  q", Items.get_def(it).get("q", "-"), " stats ", Items.get_def(it).get("stats", {}), " weapon ", Items.get_def(it).get("weapon", ""))
	print("skills: ", p.skills)
	# tier 2 is locked at skill ~10
	print("tier 2 sword: ", Crafting.craft(p, "sword", 2))
	var mk: Market = get_tree().get_first_node_in_group("market")
	print("market listings: ", Market.listings.size())
	var l: Dictionary = Market.listings.filter(func(x): return x["seller"] != "you")[0]
	print("buy ", Items.get_def(l["item"])["name"], " for ", Items.money(l["price"]), ": ", mk.buy(p, int(l["key"])))
	var slot := -1
	for i in p.bags.size():
		if p.bags[i] and Items.get_def(p.bags[i]).get("crafted", false) and Items.get_def(p.bags[i]).has("slot"): slot = i; break
	print("list crafted: ", mk.list_item(p, slot, 10), "  mine: ", Market.listings.filter(func(x): return x["seller"] == "you").size())
	var g0 := p.gold
	for k in 40: mk.t = 999.0; mk._process(0.0)
	print("after trading: gold +", p.gold - g0, "  mine left: ", Market.listings.filter(func(x): return x["seller"] == "you").size())
	var nodes := get_tree().get_nodes_in_group("gather").size()
	print("gather nodes: ", nodes, "  stations: ", get_tree().get_nodes_in_group("stations").size())
	get_tree().quit()
