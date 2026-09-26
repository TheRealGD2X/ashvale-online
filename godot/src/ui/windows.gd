class_name GameWindows extends Control
## The windows of the game, laid out as World of Warcraft does:
##   NPC window (left): greeting, their quests, then the quest text with rewards; goods; training
##   B  bags (bottom right)          C  character: the paper doll and your stats (left)
##   L  quest log                    N  talents (centre)
##   loot window beside the corpse you opened, and the quest tracker down the right edge.
## Everything is built from code; the HUD owns this and passes keys in.

const GOLD := Color(0.98, 0.84, 0.5)
const INK := Color(0.96, 0.93, 0.86)
const PARCH := Color(0.93, 0.87, 0.74)
const BROWN := Color(0.24, 0.16, 0.08)

var hud: Node
var player: Player
var font: Font
var bold: Font

var npc_win: PanelContainer
var npc: Npc
var npc_page := "gossip"          # gossip | quest | progress | reward | vendor | trainer
var npc_quest := ""
var choice := -1
var bag_win: PanelContainer
var char_win: PanelContainer
var log_win: PanelContainer
var log_sel := ""
var tal_win: PanelContainer
var loot_win: PanelContainer
var loot_mon: Monster
var tracker: VBoxContainer

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func bind(h: Node, p: Player) -> void:
	hud = h; player = p; font = h.font; bold = h.bold
	p.inventory_changed.connect(_refresh_open)
	p.quests_changed.connect(func(): _refresh_tracker(); _refresh_open())
	p.changed.connect(func(): if char_win and char_win.visible and Engine.get_process_frames() % 10 == 0: _fill_char())
	p.talents_changed.connect(func(): if tal_win and tal_win.visible: _fill_talents())
	p.leveled.connect(func(_l): _refresh_open())
	_make_tracker()
	_refresh_tracker()

func any_open() -> bool:
	for w in [npc_win, bag_win, char_win, log_win, tal_win, loot_win, craft_win, market_win]:
		if w and w.visible: return true
	return false

## Esc closes the top window first
func close_one() -> bool:
	for w in [loot_win, craft_win, market_win, npc_win, tal_win, log_win, char_win, bag_win]:

		if w and w.visible:
			w.visible = false
			if w == npc_win: npc = null
			hud._hide_tip()
			return true
	return false

func _process(_d: float) -> void:
	if player == null: return
	# walking away closes the NPC and loot windows
	if npc_win and npc_win.visible and (npc == null or not is_instance_valid(npc) or npc.global_position.distance_to(player.global_position) > 6.0):
		npc_win.visible = false; npc = null
	if loot_win and loot_win.visible and (loot_mon == null or not is_instance_valid(loot_mon) or not loot_mon.has_loot(player) or loot_mon.global_position.distance_to(player.global_position) > 6.0):
		loot_win.visible = false; loot_mon = null

func _refresh_open() -> void:
	if bag_win and bag_win.visible: _fill_bags()
	if char_win and char_win.visible: _fill_char()
	if npc_win and npc_win.visible and npc_page in ["vendor", "trainer", "gossip"]: _fill_npc()
	if log_win and log_win.visible: _fill_log()

# ------------------------------------------------------------------ building blocks

func _window(title: String, w: float) -> PanelContainer:
	var p := PanelContainer.new(); add_child(p)
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.1, 0.075, 0.05, 0.96); sb.set_corner_radius_all(10)
	sb.border_color = Color(0.78, 0.62, 0.34); sb.set_border_width_all(2)
	sb.shadow_color = Color(0, 0, 0, 0.5); sb.shadow_size = 10
	sb.content_margin_left = 16; sb.content_margin_right = 16; sb.content_margin_top = 10; sb.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(w, 0)
	p.set_meta("title", title)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	return p

## clear a window and give it a fresh body with a title bar and a close button
func _body(p: PanelContainer, title := "") -> VBoxContainer:
	for c in p.get_children(): c.queue_free()
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 8); p.add_child(v)
	var top := HBoxContainer.new(); v.add_child(top)
	var t := _lbl(title if title != "" else p.get_meta("title"), 24, GOLD, true); t.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(t)
	var x := Button.new(); x.text = "✕"; x.flat = true; x.focus_mode = Control.FOCUS_NONE; x.add_theme_font_size_override("font_size", 18)
	x.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
	x.pressed.connect(func(): p.visible = false; hud._hide_tip(); if p == npc_win: npc = null)
	top.add_child(x)
	var line := ColorRect.new(); line.color = Color(0.78, 0.62, 0.34, 0.45); line.custom_minimum_size = Vector2(0, 1); v.add_child(line)
	return v

func _lbl(text: String, size := 17, col := INK, b := false) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	if b: l.add_theme_font_override("font", bold)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6)); l.add_theme_constant_override("shadow_offset_y", 1)
	return l

func _para(text: String, size := 17, col := INK, w := 420.0) -> Label:
	var l := _lbl(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size = Vector2(w, 0)
	return l

func _btn(text: String, f: Callable, w := 0.0) -> Button:
	var b := Button.new(); b.text = text; b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 17)
	if w > 0: b.custom_minimum_size = Vector2(w, 36)
	else: b.custom_minimum_size = Vector2(0, 36)
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.45, 0.12, 0.08); sb.set_corner_radius_all(6); sb.border_color = Color(0.85, 0.65, 0.3); sb.set_border_width_all(1)
	sb.content_margin_left = 14; sb.content_margin_right = 14
	var sh := sb.duplicate(); sh.bg_color = Color(0.6, 0.18, 0.1)
	var sd := sb.duplicate(); sd.bg_color = Color(0.25, 0.2, 0.18); sd.border_color = Color(0.4, 0.35, 0.3)
	b.add_theme_stylebox_override("normal", sb); b.add_theme_stylebox_override("hover", sh); b.add_theme_stylebox_override("pressed", sh); b.add_theme_stylebox_override("disabled", sd)
	b.add_theme_color_override("font_color", Color(1, 0.88, 0.55))
	b.pressed.connect(f)
	return b

## a gossip-style line you click (a quest, "let me browse your goods")
func _option(icon: String, text: String, col: Color, f: Callable) -> Button:
	var b := Button.new(); b.flat = true; b.focus_mode = Control.FOCUS_NONE; b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = "  %s   %s" % [icon, text]; b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", col); b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.pressed.connect(f)
	return b

## an item square: hover for the tooltip, click (left/right) for f(button)
func _slot(it, size := 48.0, f: Callable = Callable(), hint := "") -> ItemIcon:
	var ic := ItemIcon.new(); ic.custom_minimum_size = Vector2(size, size); ic.size = Vector2(size, size)
	ic.mouse_filter = Control.MOUSE_FILTER_STOP
	ic.empty_hint = hint
	ic.set_item(it)
	ic.mouse_entered.connect(func():
		ic.hover = true; ic.queue_redraw()
		if ic.item != null: _item_tip(ic.item, ic)
		elif hint != "": hud._show_text_tip("[font_size=18]%s[/font_size]" % Items.SLOT_NAMES.get(hint, hint.capitalize()), ic))
	ic.mouse_exited.connect(func(): ic.hover = false; ic.queue_redraw(); hud._hide_tip())
	if f.is_valid():
		ic.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
				f.call(e.button_index); hud._hide_tip())
	return ic

func _item_tip(it, near: Control) -> void:
	var t := Items.tooltip(it, player.cls, player.level)
	var d := Items.get_def(it)
	# compare with what you wear there, like WoW's shift-compare (always on here)
	if d.has("slot") and not (it in player.equipped.values()):
		var cur = player.equipped.get(d["slot"] if not (Items.slot_of(d) in ["finger", "trinket"]) else Items.slot_of(d) + "1")
		if cur: t += "\n\n[color=#9a9a9a]Currently equipped:[/color]\n" + Items.tooltip(cur, player.cls, player.level)
	if npc_page == "vendor" and npc_win and npc_win.visible and it in player.bags: t += "\n[color=#a0e0ff]Right-click to sell[/color]"
	hud._show_text_tip(t, near)

func _money_row(c: int, size := 17) -> HBoxContainer:
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 4)
	var g := c / 10000; var s := (c / 100) % 100; var cc := c % 100
	for pair in [[g, Color(1.0, 0.82, 0.2), "g"], [s, Color(0.8, 0.82, 0.86), "s"], [cc, Color(0.85, 0.5, 0.25), "c"]]:
		if pair[0] == 0 and pair[2] != "c" and (pair[2] == "g" or g == 0): continue
		h.add_child(_lbl(str(pair[0]), size, INK))
		var dot := Panel.new(); dot.custom_minimum_size = Vector2(size * 0.62, size * 0.62); dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var coin := StyleBoxFlat.new(); coin.bg_color = pair[1]; coin.set_corner_radius_all(int(size)); coin.border_color = Color(pair[1]).darkened(0.45); coin.set_border_width_all(1)
		dot.add_theme_stylebox_override("panel", coin)

		var cc2 := CenterContainer.new(); cc2.add_child(dot); h.add_child(cc2)
	return h

# ------------------------------------------------------------------ talking to people

func open_npc(n: Npc) -> void:
	npc = n
	if npc_win == null:
		npc_win = _window("", 480)
		npc_win.position = Vector2(30, 150)
	npc_win.visible = true
	# go straight to the one thing they have, as WoW does when there's only one quest
	var q := player.quests_at(n.npc_id)
	var info: Dictionary = n.info
	var extras := int(info.has("vendor")) + int(info.has("trainer") and info["trainer"] in [player.cls, "all"])
	if q["complete"].size() == 1 and q["available"].is_empty() and extras == 0: _show_quest(q["complete"][0]); return
	if q["available"].size() == 1 and q["complete"].is_empty() and q["active"].is_empty() and extras == 0: _show_quest(q["available"][0]); return
	npc_page = "gossip"
	_fill_npc()

func _fill_npc() -> void:
	if npc == null or not is_instance_valid(npc): return
	match npc_page:
		"gossip": _gossip()
		"vendor": _vendor()
		"trainer": _trainer()
		_: _show_quest(npc_quest)

func _gossip() -> void:
	npc_page = "gossip"
	var info: Dictionary = npc.info
	var v := _body(npc_win, info["name"])
	if info.get("title", "") != "": v.add_child(_lbl("<%s>" % info["title"], 15, Color(0.8, 0.75, 0.65)))
	v.add_child(_para(info.get("greet", "Hello."), 18, PARCH))
	var q := player.quests_at(npc.npc_id)
	if not (q["complete"].is_empty() and q["available"].is_empty() and q["active"].is_empty()):
		v.add_child(_lbl("Quests", 19, GOLD, true))
	for id in q["complete"]: v.add_child(_option("?", Quests.LIST[id]["title"], Color(1, 0.86, 0.1), func(): _show_quest(id)))
	for id in q["available"]: v.add_child(_option("!", Quests.LIST[id]["title"], Color(1, 0.86, 0.1), func(): _show_quest(id)))
	for id in q["active"]: v.add_child(_option("?", Quests.LIST[id]["title"], Color(0.7, 0.7, 0.7), func(): _show_quest(id)))
	if info.has("vendor"): v.add_child(_option("◆", "Let me browse your goods.", INK, func(): npc_page = "vendor"; _vendor(); open_bags(true)))
	if info.get("trainer", "") in [player.cls, "all"]: v.add_child(_option("✦", "I'd like to train.", INK, func(): npc_page = "trainer"; _trainer()))
	elif info.has("trainer"): v.add_child(_para("\"You're no %s. Go and find your own kind.\"" % Rules.CLASSES[info["trainer"]]["name"], 16, Color(0.75, 0.7, 0.6)))
	if info.get("market", false): v.add_child(_option("⚖", "Show me the market board.", INK, func(): open_market()))
	if info.get("inn", false): v.add_child(_option("⌂", "Make this inn your home.", INK, func():
		player.hearth = WorldData.zone_id; hud.notice("%s is now your home." % ("Ashvale Inn" if WorldData.zone_id == "ashvale" else "The Miners' Camp")); npc_win.visible = false))

	if info.get("repair", false) and player.repair_cost() > 0:
		v.add_child(_option("⚒", "Repair my gear (%s)" % Items.money(player.repair_cost()), INK, func(): player.repair(); _gossip()))
	v.add_child(_btn("Goodbye", func(): npc_win.visible = false; npc = null, 140))

func _show_quest(id: String) -> void:
	npc_quest = id
	var q: Dictionary = Quests.LIST[id]
	var st := player.quest_state(id)
	var v := _body(npc_win, q["title"])
	choice = -1
	if st == "available":
		npc_page = "quest"
		v.add_child(_para(q["offer"], 18, PARCH))
		v.add_child(_lbl("Quest Objectives", 19, GOLD, true))
		v.add_child(_para(q["goal"], 17, INK))
		_rewards(v, q, false)
		var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 12); v.add_child(h)
		h.add_child(_btn("Accept", func(): player.accept_quest(id); _after_quest(), 140))
		h.add_child(_btn("Decline", func(): _gossip(), 140))
	elif st == "active" or (st == "complete" and npc_page != "reward" and q.has("progress")):
		npc_page = "progress"
		v.add_child(_para(q.get("progress", "How is it going?"), 18, PARCH))
		if st == "active":
			for i in q["obj"].size():
				var o: Dictionary = q["obj"][i]
				if o["kind"] == "talk" and o["npc"] == npc.npc_id: continue
				v.add_child(_lbl("  •  " + Quests.objective_text(o, int(player.quests[id]["have"][i])), 16, Color(0.85, 0.85, 0.85)))
		var h2 := HBoxContainer.new(); h2.add_theme_constant_override("separation", 12); v.add_child(h2)
		var cont := _btn("Continue", func(): npc_page = "reward"; _show_quest(id), 140)
		cont.disabled = st != "complete"
		h2.add_child(cont)
		h2.add_child(_btn("Goodbye", func(): _gossip(), 140))
	elif st == "complete":
		npc_page = "reward"
		v.add_child(_para(q["done"] if q["done"] != "" else "Well done.", 18, PARCH))
		_rewards(v, q, true)
		var h3 := HBoxContainer.new(); v.add_child(h3)
		h3.add_child(_btn("Complete Quest", func():
			if player.turn_in(id, choice): _after_quest(), 190))
	else:
		_gossip()

## after accepting or finishing: back to the person's other business, or close
func _after_quest() -> void:
	if npc == null: return
	var q := player.quests_at(npc.npc_id)
	if q["complete"].is_empty() and q["available"].is_empty() and not npc.info.has("vendor") and not (npc.info.get("trainer", "") in [player.cls, "all"]):
		npc_win.visible = false; npc = null
	else: _gossip()

func _rewards(v: VBoxContainer, q: Dictionary, picking: bool) -> void:
	var any: bool = q.has("items") or q.has("choice") or q.has("money") or q.has("xp") or q.has("title_reward")
	if not any: return
	v.add_child(_lbl("Rewards", 19, GOLD, true))
	if q.has("choice"):
		v.add_child(_lbl("You will be able to choose one of these rewards:", 15, Color(0.85, 0.82, 0.75)))
		var g := GridContainer.new(); g.columns = 2; g.add_theme_constant_override("h_separation", 12); v.add_child(g)
		var boxes := []
		for i in q["choice"].size():
			var it := {"id": q["choice"][i], "n": 1}
			var row := PanelContainer.new()
			var sb := StyleBoxFlat.new(); sb.bg_color = Color(0, 0, 0, 0.3); sb.set_corner_radius_all(6); sb.content_margin_left = 4; sb.content_margin_right = 8; sb.content_margin_top = 4; sb.content_margin_bottom = 4
			row.add_theme_stylebox_override("panel", sb)
			boxes.append(sb)
			var h := HBoxContainer.new(); row.add_child(h)
			var idx: int = i
			var pick := func(_b):
				if not picking: return
				choice = idx
				for k in boxes.size():
					boxes[k].border_color = GOLD; boxes[k].set_border_width_all(2 if k == idx else 0)
			h.add_child(_slot(it, 44, pick))
			var nl := _lbl(Items.def(it["id"])["name"], 15, Items.color(Items.def(it["id"]))); nl.custom_minimum_size = Vector2(150, 0)
			nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			h.add_child(nl)
			g.add_child(row)
	if q.has("items"):
		v.add_child(_lbl("You will receive:", 15, Color(0.85, 0.82, 0.75)))
		var h2 := HBoxContainer.new(); v.add_child(h2)
		for id in q["items"]:
			var it2 := {"id": id, "n": 1}
			h2.add_child(_slot(it2, 44))
			h2.add_child(_lbl(Items.def(id)["name"] + "   ", 15, Items.color(Items.def(id))))
	var h3 := HBoxContainer.new(); h3.add_theme_constant_override("separation", 16); v.add_child(h3)
	if q.has("money"): h3.add_child(_money_row(int(q["money"])))
	h3.add_child(_lbl("%d experience" % Quests.xp_for(npc_quest, player.level), 16, Color(0.75, 0.6, 1.0)))
	if q.has("title_reward"): v.add_child(_lbl("Title: %s" % q["title_reward"], 16, GOLD))

func _vendor() -> void:
	var info: Dictionary = npc.info
	var v := _body(npc_win, info["name"])
	v.add_child(_lbl("Click to buy. Right-click things in your bags to sell them.", 14, Color(0.8, 0.76, 0.68)))
	var g := GridContainer.new(); g.columns = 2; g.add_theme_constant_override("h_separation", 14); g.add_theme_constant_override("v_separation", 8); v.add_child(g)
	for id in info["vendor"]:
		var d: Dictionary = Items.def(id)
		var it := {"id": id, "n": 1 if int(d.get("stack", 1)) == 1 else mini(5, int(d["stack"]))}
		var h := HBoxContainer.new(); h.custom_minimum_size = Vector2(210, 0)
		var ic := _slot(it, 44, func(_b): player.buy(id); _vendor())
		if not Items.can_use(player.cls, d, player.level) and d.has("slot"): ic.dim = 0.35; ic.modulate = Color(1, 0.6, 0.6)
		h.add_child(ic)
		var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 0); h.add_child(vb)
		var nl := _lbl(d["name"], 14, Items.color(d)); nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; nl.custom_minimum_size = Vector2(150, 0); vb.add_child(nl)
		vb.add_child(_money_row(Items.buy_price(d), 14))
		g.add_child(h)
	if not player.buyback.is_empty():
		v.add_child(_lbl("Buy back", 16, GOLD))
		var hb := HBoxContainer.new(); v.add_child(hb)
		for i in player.buyback.size():
			var bb = player.buyback[i]
			var idx: int = i
			hb.add_child(_slot(bb, 40, func(_b):
				var price := int(Items.get_def(bb).get("sell", 0)) * int(bb.get("n", 1))
				if player.gold >= price and player.add_item(bb):
					player.gold -= price; player.buyback.remove_at(idx); player.changed.emit(); _vendor()))
	var h2 := HBoxContainer.new(); h2.add_theme_constant_override("separation", 10); v.add_child(h2)
	h2.add_child(_btn("Sell junk", func(): player.sell_junk(); _vendor()))
	if info.get("repair", false):
		var rb := _btn("Repair (%s)" % Items.money(player.repair_cost()), func(): player.repair(); _vendor())
		rb.disabled = player.repair_cost() <= 0; h2.add_child(rb)
	h2.add_child(_btn("Back", func(): _gossip()))

func _trainer() -> void:
	var info: Dictionary = npc.info
	var v := _body(npc_win, info["name"])
	v.add_child(_lbl("Abilities you can learn", 16, Color(0.85, 0.8, 0.7)))
	var list: Array = Npcs.TRAINING[player.cls]
	for t in list:
		var id: String = t[0]; var lv: int = t[1]; var cost: int = t[2]
		var a: Dictionary = Abilities.LIST[id]
		var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 10); v.add_child(h)
		var ic := AbilityIcon.new(); ic.custom_minimum_size = Vector2(40, 40); ic.set_ability(id); h.add_child(ic)
		ic.mouse_filter = Control.MOUSE_FILTER_STOP
		ic.mouse_entered.connect(func(): hud._show_tip(id, ic)); ic.mouse_exited.connect(hud._hide_tip)
		var known: bool = id in player.known
		var col := Color(0.55, 0.55, 0.55) if known else (INK if player.level >= lv else Color(0.9, 0.35, 0.3))
		var nl := _lbl(a["name"], 17, col); nl.custom_minimum_size = Vector2(170, 0); h.add_child(nl)
		if known: h.add_child(_lbl("Known", 15, Color(0.55, 0.55, 0.55)))
		elif player.level < lv: h.add_child(_lbl("Level %d" % lv, 15, Color(0.9, 0.35, 0.3)))
		else:
			h.add_child(_money_row(cost, 15))
			var b := _btn("Train", func(): player.train(id, cost); _trainer())
			b.disabled = player.gold < cost
			h.add_child(b)
	v.add_child(_btn("Back", func(): _gossip(), 120))

# ------------------------------------------------------------------ loot

func open_loot(m: Monster) -> void:
	loot_mon = m
	if loot_win == null:
		loot_win = _window("Loot", 300)
	loot_win.visible = true
	loot_win.position = get_viewport().get_mouse_position() + Vector2(20, -80)
	loot_win.position.x = clampf(loot_win.position.x, 10, get_viewport_rect().size.x - 320)
	loot_win.position.y = clampf(loot_win.position.y, 10, get_viewport_rect().size.y - 420)
	get_tree().call_group("fx", "sound", "loot_open", m.global_position, -10.0)
	_fill_loot()

func _fill_loot() -> void:
	if loot_mon == null or not is_instance_valid(loot_mon) or not loot_mon.has_loot(player):
		loot_win.visible = false; return
	var v := _body(loot_win, loot_mon.uname)
	if loot_mon.loot_money > 0:
		var h := HBoxContainer.new(); v.add_child(h)
		var coin := {"id": "old_coin", "n": 1}
		var ic := _slot(coin, 40, func(_b): player.loot_take(loot_mon, -1); _fill_loot())
		ic.set_meta("money", true)
		h.add_child(ic)
		h.add_child(_money_row(loot_mon.loot_money))
	for i in loot_mon.loot.size():
		var it: Dictionary = loot_mon.loot[i]
		var d := Items.get_def(it)
		var h2 := HBoxContainer.new(); v.add_child(h2)
		var idx: int = i
		h2.add_child(_slot(it, 40, func(_b): player.loot_take(loot_mon, idx); _fill_loot()))
		var nl := _lbl(d["name"], 16, Items.color(d)); nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; nl.custom_minimum_size = Vector2(200, 0); h2.add_child(nl)
	v.add_child(_btn("Take all", func(): player.loot_all(loot_mon); _fill_loot(), 140))

# ------------------------------------------------------------------ bags

func open_bags(on := true) -> void:
	if bag_win == null:
		bag_win = _window("Backpack", 330)
		bag_win.visible = false
	bag_win.visible = on
	if on:
		_fill_bags()
		bag_win.reset_size()
		var vs := get_viewport_rect().size
		bag_win.position = Vector2(vs.x - bag_win.size.x - 24, vs.y - bag_win.size.y - 130)

func toggle_bags() -> void:
	open_bags(bag_win == null or not bag_win.visible)

func _fill_bags() -> void:
	var v := _body(bag_win)
	var g := GridContainer.new(); g.columns = 5; g.add_theme_constant_override("h_separation", 6); g.add_theme_constant_override("v_separation", 6); v.add_child(g)
	for i in player.bags.size():
		var idx: int = i
		g.add_child(_slot(player.bags[i], 52, func(b):
			if npc_win and npc_win.visible and npc_page == "vendor" and b == MOUSE_BUTTON_RIGHT: player.sell(idx); _vendor()
			else: player.use_bag(idx)))
	var h := HBoxContainer.new(); v.add_child(h)
	h.add_child(_lbl("%d / %d" % [player.bags.size() - player.bags.count(null), player.bags.size()], 15, Color(0.8, 0.76, 0.68)))
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(sp)
	h.add_child(_money_row(player.gold))

# ------------------------------------------------------------------ character sheet

func toggle_char() -> void:
	if char_win == null:
		char_win = _window("", 560); char_win.visible = false
		char_win.position = Vector2(30, 140)
	char_win.visible = not char_win.visible
	if char_win.visible: _fill_char()

func _fill_char() -> void:
	var cls: Dictionary = Rules.CLASSES[player.cls]
	var v := _body(char_win, player.uname + ("  " + player.title if player.title != "" else ""))
	v.add_child(_lbl("Level %d %s" % [player.level, cls["name"]], 17, cls["color"]))
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 14); v.add_child(h)
	var left := VBoxContainer.new(); var right := VBoxContainer.new(); var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(300, 0); mid.add_theme_constant_override("separation", 3)
	h.add_child(left); h.add_child(mid); h.add_child(right)
	for s in ["head", "neck", "shoulders", "back", "chest", "wrist", "main_hand", "off_hand"]: left.add_child(_doll(s))
	for s in ["hands", "waist", "legs", "feet", "finger1", "finger2", "trinket1", "trinket2"]: right.add_child(_doll(s))
	# stats, WoW style
	var a: Dictionary = player.attrs
	var g: Dictionary = player.gear_stats
	var rows := [["Health", "%d" % int(player.max_hp)], ["Rage" if player.power_kind == "rage" else "Mana", "%d" % int(player.max_power)], ["", ""]]
	for k in ["str", "agi", "sta", "int", "spi"]:
		rows.append([Items.STAT_NAMES[k], "%d%s" % [int(a[k]), ("  (+%d)" % int(g.get(k, 0))) if int(g.get(k, 0)) > 0 else ""]])
	rows.append(["", ""])
	rows.append(["Armor", "%d  (%d%% less damage)" % [int(player.armor), int(Rules.armor_dr(player.armor, player.level) * 100)]])
	var w: Dictionary = player.weapon
	rows.append(["Damage", "%d – %d" % [int(w["min"] + player.attack_power() / 14.0 * w["speed"]), int(w["max"] + player.attack_power() / 14.0 * w["speed"])]])
	rows.append(["Attack Power", "%d" % int(player.attack_power())])
	if player.power_kind == "mana": rows.append(["Spell Power", "%d" % int(player.spell_power())])
	rows.append(["Crit (melee / spell)", "%.1f%% / %.1f%%" % [player.crit_chance(false) * 100, player.crit_chance(true) * 100]])
	rows.append(["Durability", "%d%%" % int(player.durability * 100)])
	rows.append(["Ashvale reputation", "%d" % int(player.rep.get("Ashvale", 0))])
	for r in rows:
		var rr := HBoxContainer.new(); mid.add_child(rr)
		var k := _lbl(r[0], 16, Color(1, 0.84, 0.3) if r[0] != "" else INK); k.custom_minimum_size = Vector2(160, 0); rr.add_child(k)
		rr.add_child(_lbl(r[1], 16, INK))
	if not player.titles.is_empty():
		var t := HBoxContainer.new(); mid.add_child(t)
		t.add_child(_lbl("Title  ", 16, Color(1, 0.84, 0.3)))
		var ob := OptionButton.new(); ob.focus_mode = Control.FOCUS_NONE; ob.add_item("None")
		for x in player.titles: ob.add_item(x)
		ob.selected = maxi(0, player.titles.find(player.title) + 1)
		ob.item_selected.connect(func(i): player.title = "" if i == 0 else player.titles[i - 1]; _fill_char())
		t.add_child(ob)

func _doll(slot: String) -> ItemIcon:
	var hint := slot.trim_suffix("1").trim_suffix("2")
	return _slot(player.equipped.get(slot), 50, func(_b): player.unequip(slot), hint)

# ------------------------------------------------------------------ quest log and tracker

func toggle_log() -> void:
	if log_win == null:
		log_win = _window("Quest Log", 720); log_win.visible = false
		log_win.position = Vector2(40, 130)
	log_win.visible = not log_win.visible
	if log_win.visible: _fill_log()

func _fill_log() -> void:
	var v := _body(log_win, "Quest Log   (%d / 20)" % player.quests.size())
	if player.quests.is_empty():
		v.add_child(_para("Your quest log is empty. Look for people with a yellow ! over their heads.", 17, PARCH, 600))
		return
	if not player.quests.has(log_sel): log_sel = player.quests.keys()[0]
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 16); v.add_child(h)
	var list := VBoxContainer.new(); list.custom_minimum_size = Vector2(250, 0); h.add_child(list)
	var chains := {}
	for id in player.quests:
		var zone: String = Zones.get_def(Npcs.LIST.get(Quests.LIST[id]["giver"], {}).get("zone", "ashvale"))["name"]

		if not chains.has(zone): chains[zone] = true; list.add_child(_lbl(zone, 16, Color(0.8, 0.75, 0.65), true))
		var q: Dictionary = Quests.LIST[id]
		var col := Rules.con_color(player.level, int(q["level"]))
		var done := player.quest_complete(id)
		var b := _option("", "[%d] %s%s" % [q["level"], q["title"], "  (Complete)" if done else ""], col, func(): log_sel = id; _fill_log())
		if id == log_sel: b.add_theme_color_override("font_color", Color(1, 1, 1))
		list.add_child(b)
	var d := VBoxContainer.new(); d.custom_minimum_size = Vector2(420, 0); h.add_child(d)
	var q2: Dictionary = Quests.LIST[log_sel]
	d.add_child(_lbl(q2["title"], 21, GOLD, true))
	d.add_child(_para(q2["goal"], 17, INK, 420))
	for i in q2["obj"].size():
		var o: Dictionary = q2["obj"][i]
		var have := int(player.quests[log_sel]["have"][i])
		var ok: bool = have >= int(o.get("n", 1))
		if o["kind"] == "talk" and o["npc"] == Player.ender_of(log_sel): continue
		d.add_child(_lbl("  •  " + Quests.objective_text(o, have), 16, Color(0.6, 1.0, 0.6) if ok else Color(0.85, 0.85, 0.85)))
	if q2.has("where"): d.add_child(_para("Where: " + q2["where"], 15, Color(0.8, 0.76, 0.68), 420))
	d.add_child(_lbl("Description", 18, GOLD, true))
	d.add_child(_para(q2["offer"], 16, PARCH, 420))
	var turn: String = Npcs.LIST.get(Player.ender_of(log_sel), {}).get("name", "?")
	d.add_child(_lbl("Hand in to: %s" % turn, 15, Color(0.8, 0.76, 0.68)))
	d.add_child(_btn("Abandon Quest", func(): player.abandon_quest(log_sel); _fill_log(), 170))

func _make_tracker() -> void:
	tracker = VBoxContainer.new(); tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tracker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tracker.offset_left = -330; tracker.offset_top = 330; tracker.offset_right = -20
	tracker.add_theme_constant_override("separation", 1)
	add_child(tracker)

func _refresh_tracker() -> void:
	if tracker == null: return
	for c in tracker.get_children(): c.queue_free()
	var n := 0
	for id in player.quests:
		if n >= 6: break
		n += 1
		var q: Dictionary = Quests.LIST[id]
		var done := player.quest_complete(id)
		var t := _lbl(q["title"], 17, Color(1, 0.82, 0.1) if not done else Color(0.6, 1.0, 0.5), true); t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tracker.add_child(t)
		if done:
			tracker.add_child(_lbl("   Return to %s" % Npcs.LIST.get(Player.ender_of(id), {}).get("name", "?"), 15, INK))
			continue
		for i in q["obj"].size():
			var o: Dictionary = q["obj"][i]
			if o["kind"] == "talk" and o["npc"] == Player.ender_of(id): continue
			var have := int(player.quests[id]["have"][i])
			tracker.add_child(_lbl("   - " + Quests.objective_text(o, have), 15, Color(0.6, 1.0, 0.6) if have >= int(o.get("n", 1)) else INK))
		var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 6); tracker.add_child(sp)

# ------------------------------------------------------------------ talents

func toggle_talents() -> void:
	if tal_win == null:
		tal_win = _window("Talents", 900); tal_win.visible = false
	tal_win.visible = not tal_win.visible
	if tal_win.visible:
		_fill_talents()
		tal_win.reset_size()
		tal_win.position = (get_viewport_rect().size - tal_win.size) / 2.0

func _fill_talents() -> void:
	var left := Talents.points_total(player.level) - Talents.spent(player)
	var v := _body(tal_win, "Talents")
	if player.level < 10:
		v.add_child(_para("Talents open at level 10: from then on you earn one point every level to spend here. Each tree goes deeper the more you put into it.", 17, PARCH, 860))
	var head := HBoxContainer.new(); v.add_child(head)
	head.add_child(_lbl("Points to spend: %d" % left, 18, GOLD if left > 0 else INK, true))
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(sp)
	if Talents.spent(player) > 0: head.add_child(_btn("Reset (free for now)", func(): player.reset_talents()))
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 14); v.add_child(h)
	for tree in Talents.TREES[player.cls]:
		var col := VBoxContainer.new(); col.custom_minimum_size = Vector2(280, 0); h.add_child(col)
		var sb := StyleBoxFlat.new(); sb.bg_color = Color(tree["color"], 0.12); sb.set_corner_radius_all(8); sb.content_margin_left = 8; sb.content_margin_right = 8; sb.content_margin_top = 6; sb.content_margin_bottom = 6
		var pc := PanelContainer.new(); pc.add_theme_stylebox_override("panel", sb); col.add_child(pc)
		var inner := VBoxContainer.new(); inner.add_theme_constant_override("separation", 4); pc.add_child(inner)
		inner.add_child(_lbl("%s   (%d)" % [tree["name"], Talents.spent_in_tree(player, tree)], 19, tree["color"], true))
		var tiers := {}
		for t in tree["talents"]:
			if not tiers.has(t["tier"]): tiers[t["tier"]] = []
			tiers[t["tier"]].append(t)
		var keys := tiers.keys(); keys.sort()
		for tier in keys:
			var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 6); inner.add_child(row)
			row.add_child(_lbl("%d" % ((int(tier) - 1) * 5), 12, Color(0.6, 0.55, 0.5)))
			for t in tiers[tier]: row.add_child(_talent_btn(t, tree))

func _talent_btn(t: Dictionary, tree: Dictionary) -> Control:
	var rank := int(player.talents.get(t["id"], 0))
	var open := Talents.spent_in_tree(player, tree) >= (int(t["tier"]) - 1) * 5
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(80, 54)
	b.text = "%s  %d/%d" % [_short(t["name"]), rank, t["max"]]
	b.add_theme_font_size_override("font_size", 12)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var sb := StyleBoxFlat.new(); sb.set_corner_radius_all(6); sb.set_border_width_all(2)
	sb.bg_color = Color(tree["color"], 0.35 if open else 0.08)
	sb.border_color = Color(0.3, 1.0, 0.3) if rank > 0 and rank < int(t["max"]) else (GOLD if rank == int(t["max"]) else (Color(0.6, 0.6, 0.6) if open else Color(0.3, 0.3, 0.3)))
	b.add_theme_stylebox_override("normal", sb); b.add_theme_stylebox_override("hover", sb); b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_color_override("font_color", INK if open else Color(0.5, 0.5, 0.5))
	b.pressed.connect(func(): if player.learn_talent(t["id"]): _fill_talents())
	b.mouse_entered.connect(func():
		var per = t.get("per", 0)
		var desc: String = t["desc"]
		if desc.contains("%s"): desc = desc % str(per * maxi(1, rank))
		var tip := "[font_size=18][b]%s[/b][/font_size]\nRank %d/%d\n[color=#ffd479]%s[/color]" % [t["name"], rank, t["max"], desc]
		if rank > 0 and rank < int(t["max"]) and t["desc"].contains("%s"): tip += "\n\nNext rank:\n[color=#ffd479]%s[/color]" % (t["desc"] % str(per * (rank + 1)))
		if not open: tip += "\n[color=#ff4040]Requires %d points in %s[/color]" % [(int(t["tier"]) - 1) * 5, tree["name"]]
		hud._show_text_tip(tip, b))
	b.mouse_exited.connect(hud._hide_tip)
	return b

func _short(n: String) -> String:
	return n

# ------------------------------------------------------------------ crafting stations

var craft_win: PanelContainer
var station := ""
var craft_tier := 1

func open_station(kind: String) -> void:
	station = kind
	if craft_win == null:
		craft_win = _window("", 620); craft_win.position = Vector2(30, 130)
	craft_win.visible = true
	craft_tier = clampi(int(WorldData.Z.get("tier", 1)), 1, 6)
	_fill_station()
	open_bags(true)
	get_tree().call_group("fx", "sound", "anvil" if kind == "forge" else "page", null, -10.0)

func _fill_station() -> void:
	var v := _body(craft_win, Crafting.STATIONS[station])
	# the skills this station uses
	var used := {}
	for r in Crafting.RECIPES:
		if r[3] == station: used[r[2]] = true
	var head := HBoxContainer.new(); head.add_theme_constant_override("separation", 18); v.add_child(head)
	for s in used: head.add_child(_lbl("%s %d / %d" % [Crafting.SKILLS[s], player.skill(s), Crafting.MAX_SKILL], 16, Color(0.6, 0.85, 1.0)))
	for s in ["mining", "herbalism"]: head.add_child(_lbl("%s %d" % [Crafting.SKILLS[s], player.skill(s)], 14, Color(0.7, 0.7, 0.7)))
	# tier picker
	var tiers := HBoxContainer.new(); v.add_child(tiers)
	tiers.add_child(_lbl("Tier  ", 16, GOLD))
	for t in range(1, 7):
		var b := _btn("T%d" % t, func(): craft_tier = t; _fill_station(), 50)
		if t == craft_tier: b.add_theme_color_override("font_color", Color(1, 1, 1)); b.add_theme_stylebox_override("normal", b.get_theme_stylebox("hover"))
		tiers.add_child(b)
	tiers.add_child(_lbl("   needs %d skill" % Crafting.skill_needed(craft_tier), 14, Color(0.8, 0.76, 0.68)))
	# refining
	for raw in Crafting.REFINE:
		var info: Array = Crafting.REFINE[raw]
		if info[1] != station: continue
		var rid := "%s_%d" % [raw, craft_tier]
		var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 10); v.add_child(h)
		h.add_child(_slot({"id": rid, "n": maxi(1, player.count_item(rid))}, 40))
		h.add_child(_lbl("2 × %s → 1 × %s   (you have %d)" % [Items.get_def({"id": rid})["name"], Items.get_def({"id": "%s_%d" % [info[0], craft_tier]})["name"], player.count_item(rid)], 15, INK))
		var rb := _btn("Refine all", func():
			var n := Crafting.refine(player, rid, 99)
			if n > 0: get_tree().call_group("fx", "sound", "anvil", null, -12.0)
			_fill_station())
		rb.disabled = player.count_item(rid) < 2
		h.add_child(rb)
	# recipes
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size = Vector2(580, 380); v.add_child(scroll)
	var list := VBoxContainer.new(); list.add_theme_constant_override("separation", 6); scroll.add_child(list)
	for r in Crafting.RECIPES:
		if r[3] != station: continue
		var need := Crafting.needs(r, craft_tier)
		var ok := Crafting.has_all(player, need) and player.skill(r[2]) >= Crafting.skill_needed(craft_tier)
		var h2 := HBoxContainer.new(); h2.add_theme_constant_override("separation", 8); list.add_child(h2)
		var rng := RandomNumberGenerator.new(); rng.seed = 1
		var preview := Crafting.make(r, craft_tier, 0, rng)
		h2.add_child(_slot(preview, 42))
		var nm := _lbl(r[1], 16, INK if ok else Color(0.6, 0.6, 0.6)); nm.custom_minimum_size = Vector2(140, 0); h2.add_child(nm)
		var parts := []
		for m in need: parts.append("%d/%d %s" % [player.count_item(m), need[m], Items.get_def({"id": m})["name"]])
		var nl := _lbl(", ".join(parts), 13, Color(0.8, 0.8, 0.75) if ok else Color(0.85, 0.5, 0.45)); nl.custom_minimum_size = Vector2(300, 0); nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h2.add_child(nl)
		var id: String = r[0]
		var cb := _btn("Craft", func():
			var it := Crafting.craft(player, id, craft_tier)
			if not it.is_empty():
				var d := Items.get_def(it)
				hud.notice("You create %s%s." % [d["name"], (" (%s)" % Crafting.QUALITY_NAMES[[0, 0, 2, 3][clampi(int(d.get("q", 2)), 0, 3)] if d.has("slot") else 0]) if d.get("q", 1) >= 3 else ""])
				get_tree().call_group("fx", "sound", "learn" if d.get("q", 1) >= 3 else "anvil", null, -8.0)
			_fill_station())
		cb.disabled = not ok
		h2.add_child(cb)

# ------------------------------------------------------------------ the market

var market_win: PanelContainer
var market_tab := "buy"
var market_filter := "all"
var sell_pick := -1
var sell_price := 0

func open_market() -> void:
	if npc_win: npc_win.visible = false
	if market_win == null:
		market_win = _window("Market", 720); market_win.position = Vector2(30, 110)
	market_win.visible = true
	open_bags(true)
	_fill_market()

func _market() -> Market:
	return get_tree().get_first_node_in_group("market")

func _fill_market() -> void:
	var mk := _market()
	if mk == null: return
	var v := _body(market_win, "Market")
	var tabs := HBoxContainer.new(); tabs.add_theme_constant_override("separation", 8); v.add_child(tabs)
	for tb in [["buy", "Buy"], ["sell", "Sell"], ["mine", "Your listings"]]:
		var tid: String = tb[0]
		var b := _btn(tb[1], func(): market_tab = tid; _fill_market(), 140)
		if tid == market_tab: b.add_theme_stylebox_override("normal", b.get_theme_stylebox("hover"))
		tabs.add_child(b)
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tabs.add_child(sp)
	tabs.add_child(_money_row(player.gold))
	match market_tab:
		"buy":
			var fl := HBoxContainer.new(); v.add_child(fl)
			for f in [["all", "All"], ["mat", "Materials"], ["gear", "Gear"], ["use", "Food and potions"]]:
				var fid: String = f[0]
				fl.add_child(_option("", f[1], GOLD if market_filter == fid else INK, func(): market_filter = fid; _fill_market()))
			var scroll := ScrollContainer.new(); scroll.custom_minimum_size = Vector2(690, 420); v.add_child(scroll)
			var list := VBoxContainer.new(); scroll.add_child(list)
			var shown := Market.listings.filter(func(l):
				var d := Items.get_def(l["item"])
				if l["seller"] == "you": return false
				match market_filter:
					"mat": return d.has("mat")
					"gear": return d.has("slot")
					"use": return d.has("use")
				return true)
			shown.sort_custom(func(a, b): return Items.get_def(a["item"]).get("name", "") < Items.get_def(b["item"]).get("name", ""))
			for l in shown.slice(0, 60):
				var d := Items.get_def(l["item"])
				var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 10); list.add_child(h)
				h.add_child(_slot(l["item"], 38))
				var nm := _lbl(d.get("name", "?"), 15, Items.color(d)); nm.custom_minimum_size = Vector2(270, 0); h.add_child(nm)
				var sl := _lbl(l["seller"], 13, Color(0.7, 0.7, 0.7)); sl.custom_minimum_size = Vector2(100, 0); h.add_child(sl)
				var mr := _money_row(int(l["price"]), 15); mr.custom_minimum_size = Vector2(130, 0); h.add_child(mr)
				var key := int(l["key"])
				var bb := _btn("Buy", func(): if mk.buy(player, key): _fill_market(), 70)
				bb.disabled = player.gold < int(l["price"])
				h.add_child(bb)
			if shown.is_empty(): list.add_child(_lbl("Nothing like that for sale right now. Check back later.", 16, PARCH))
		"sell":
			v.add_child(_para("Click something in your bags below to put it up for sale. Other players buy things that are fairly priced; the market keeps 5%.", 15, PARCH, 690))
			var g := GridContainer.new(); g.columns = 10; g.add_theme_constant_override("h_separation", 5); g.add_theme_constant_override("v_separation", 5); v.add_child(g)
			for i in player.bags.size():
				var idx: int = i
				var ic := _slot(player.bags[i], 44, func(_b):
					if player.bags[idx] == null: return
					sell_pick = idx; sell_price = Market.fair(player.bags[idx]); _fill_market())
				if i == sell_pick: ic.modulate = Color(1.3, 1.2, 0.8)
				g.add_child(ic)
			if sell_pick >= 0 and sell_pick < player.bags.size() and player.bags[sell_pick] != null:
				var it = player.bags[sell_pick]
				var d2 := Items.get_def(it)
				var h2 := HBoxContainer.new(); h2.add_theme_constant_override("separation", 8); v.add_child(h2)
				h2.add_child(_lbl(d2["name"] + ("  ×%d" % int(it.get("n", 1)) if int(it.get("n", 1)) > 1 else ""), 17, Items.color(d2)))
				h2.add_child(_lbl("   price:", 16, INK))
				for step in [[-1000, "−10s"], [-100, "−1s"], [-10, "−10c"], [10, "+10c"], [100, "+1s"], [1000, "+10s"]]:
					var dv: int = step[0]
					h2.add_child(_btn(step[1], func(): sell_price = maxi(1, sell_price + dv); _fill_market()))
				var h3 := HBoxContainer.new(); h3.add_theme_constant_override("separation", 12); v.add_child(h3)
				h3.add_child(_money_row(sell_price, 18))
				h3.add_child(_lbl("(worth about %s)" % Items.money(Market.fair(it)), 14, Color(0.7, 0.7, 0.7)))
				h3.add_child(_btn("List it", func():
					if mk.list_item(player, sell_pick, sell_price): sell_pick = -1; hud.notice("Listed on the market.")
					_fill_market(), 120))
		"mine":
			var mine := Market.listings.filter(func(l): return l["seller"] == "you")
			if mine.is_empty(): v.add_child(_lbl("You have nothing listed.", 16, PARCH))
			for l in mine:
				var d3 := Items.get_def(l["item"])
				var h4 := HBoxContainer.new(); h4.add_theme_constant_override("separation", 10); v.add_child(h4)
				h4.add_child(_slot(l["item"], 38))
				var nm2 := _lbl(d3.get("name", "?"), 15, Items.color(d3)); nm2.custom_minimum_size = Vector2(300, 0); h4.add_child(nm2)
				h4.add_child(_money_row(int(l["price"]), 15))
				var k2 := int(l["key"])
				h4.add_child(_btn("Take down", func(): mk.cancel(player, k2); _fill_market()))
