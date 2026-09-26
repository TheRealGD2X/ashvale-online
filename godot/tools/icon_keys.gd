extends SceneTree
## Lists every item icon key the game can ask for (for art/item_icons.py):
##   godot --headless --path . -s tools/icon_keys.gd     -> ../art/item_keys.txt ("key<TAB>example item name")
func _init() -> void:
	var keys := {}
	var add := func(d: Dictionary, id: String) -> void:
		var k := ItemIcon.key_of(d, id)
		if k != "" and not keys.has(k): keys[k] = String(d.get("name", id))
	for id in Items.LIST.keys(): add.call(Items.def(id), id)
	var mats := Crafting.materials()
	for id in mats.keys(): add.call(mats[id], id)
	# random drops: every base in every quality look, every prefix colour
	for b in Items.BASES:
		for p in Items.PREFIX:
			var d := {"name": "%s %s" % [p, b[2]], "slot": b[0]}
			if b[1] != "": d["armor_type"] = b[1]
			for v in [2, 3]:
				if b[3].size() == 2: d["look"] = [b[3][0], b[3][1], v]
				add.call(d, "rolled")
	for w in Items.WEAPON_BASES: add.call({"name": w[1], "wtype": w[0], "model": w[3]}, "rolled")
	for s in ["head", "neck", "shoulders", "back", "chest", "wrist", "hands", "waist", "legs", "feet", "finger", "trinket", "main_hand", "off_hand"]:
		keys["e_" + s] = "(empty %s slot)" % s
	var ks := keys.keys(); ks.sort()
	var f := FileAccess.open("res://../art/item_keys.txt", FileAccess.WRITE)
	for k in ks: f.store_line("%s\t%s" % [k, keys[k]])
	f.close()
	print("icon keys: ", ks.size())
	quit()
