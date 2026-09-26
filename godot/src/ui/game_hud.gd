class_name GameHud extends CanvasLayer
## The in-game interface, laid out like World of Warcraft's:
##  top left: your portrait, health and Rage/Mana, with your buffs underneath; next to it the
##  target's frame (name coloured by how dangerous it is, level, health, what it is casting);
##  bottom centre: your cast bar and the five-slot action bar; along the bottom: experience.
##  Floating combat text rises from whoever gets hit or healed; enemies in the fight show a name
##  and health bar over their heads. P opens the spellbook to choose which five abilities to carry.

const GOLD := Color(0.98, 0.84, 0.5)
const INK := Color(0.96, 0.93, 0.86)
const PANEL := Color(0.07, 0.06, 0.05, 0.78)

var player: Player
var cam: Camera3D
var root: Control
var font: Font
var bold: Font

var pf := {}          # player frame parts
var tf := {}          # target frame parts
var slots: Array = []
var castbar := {}
var xpbar := {}
var buffs: HBoxContainer
var err: Label
var err_t := 0.0
var nameplates := {}  # unit -> Control
var fct_layer: Control
var floats: Array = []
var book: PanelContainer
var death: PanelContainer
var clock: Label
var place: Label
var gold_l: Label
var tip: PanelContainer
var tip_l: RichTextLabel
var fps: Label
var help: PanelContainer
var help_t := 30.0
var swap_from := -1
var sel_ring: MeshInstance3D
var sel_mat: StandardMaterial3D
var menu: PanelContainer
var win: GameWindows
var chat: ChatBox
var notices: VBoxContainer
var minimap: Minimap

func _ready() -> void:
	add_to_group("hud"); add_to_group("fct")
	layer = 5
	var f := SystemFont.new(); f.font_names = PackedStringArray(["Georgia", "Palatino Linotype", "Book Antiqua", "serif"]); font = f
	var fb := SystemFont.new(); fb.font_names = f.font_names; fb.font_weight = 700; bold = fb
	var th := Theme.new(); th.default_font = font; th.default_font_size = 18
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.theme = th
	add_child(root)
	fct_layer = Control.new(); fct_layer.set_anchors_preset(Control.PRESET_FULL_RECT); fct_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(fct_layer)
	_player_frame(); _target_frame(); _action_bar(); _cast_bar(); _xp_bar(); _misc()
	chat = ChatBox.new(); root.add_child(chat)
	win = GameWindows.new(); root.add_child(win)
	notices = VBoxContainer.new(); notices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notices.set_anchors_preset(Control.PRESET_CENTER_TOP); notices.offset_left = -400; notices.offset_right = 400; notices.offset_top = 96
	root.add_child(notices)
	root.move_child(tip, -1)

func bind(p: Player, c: Camera3D) -> void:
	player = p; cam = c
	win.bind(self, p); chat.player = p
	minimap = Minimap.new(); root.add_child(minimap); minimap.setup(p, c)
	root.move_child(minimap, 0)
	chat.post("system", "", "Welcome to %s. Press Enter to chat; /who lists who's around." % WorldData.Z.get("name", "Ashvale"))

	p.changed.connect(_refresh_player)
	p.xp_changed.connect(_refresh_xp)
	p.leveled.connect(func(lv): _banner("Level %d!" % lv, "You feel stronger."))
	get_tree().node_added.connect(_on_node_added)
	for u in get_tree().get_nodes_in_group("units"): _watch(u)
	_refresh_player(); _refresh_xp(); _refresh_bar()

func _on_node_added(n: Node) -> void:
	if n is Unit: _watch.call_deferred(n)

func _watch(u: Unit) -> void:
	if not is_instance_valid(u) or u.struck.is_connected(_on_struck): return
	u.struck.connect(_on_struck)

# ------------------------------------------------------------------ building

func _panel(parent: Control, pos: Vector2, size: Vector2, radius := 8) -> Panel:
	var p := Panel.new(); p.position = pos; p.size = size; p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", UiSkin.panel("hud"))
	parent.add_child(p)
	return p

func _label(parent: Control, text: String, size: int, pos: Vector2, col := INK, b := false) -> Label:
	var l := Label.new(); l.text = text; l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if b: l.add_theme_font_override("font", bold)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75)); l.add_theme_constant_override("shadow_offset_x", 1); l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _bar(parent: Control, pos: Vector2, size: Vector2, col: Color) -> Dictionary:
	var bg := ColorRect.new(); bg.color = Color(0.02, 0.02, 0.02, 0.85); bg.position = pos; bg.size = size; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	var fill := ColorRect.new(); fill.color = col; fill.size = size; fill.mouse_filter = Control.MOUSE_FILTER_IGNORE; bg.add_child(fill)
	fill.material = _bar_mat()
	var sheen := ColorRect.new(); sheen.color = Color(1, 1, 1, 0.0); sheen.size = Vector2(size.x, size.y * 0.42); sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE; fill.add_child(sheen)
	var txt := Label.new(); txt.size = size; txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	txt.add_theme_font_size_override("font_size", int(size.y * 0.72)); txt.add_theme_color_override("font_color", Color(1, 1, 1))
	txt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9)); txt.add_theme_constant_override("shadow_offset_y", 1)
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(txt)
	return {"bg": bg, "fill": fill, "text": txt, "w": size.x, "sheen": sheen}

static var _barmat: ShaderMaterial
static func _bar_mat() -> ShaderMaterial:
	if _barmat == null:
		_barmat = ShaderMaterial.new(); _barmat.shader = load("res://shaders/bar.gdshader")
	return _barmat

func _set_bar(b: Dictionary, frac: float, text := "") -> void:
	frac = clampf(frac, 0.0, 1.0)
	b["fill"].size.x = lerpf(b["fill"].size.x, b["w"] * frac, 0.35)
	b["sheen"].size.x = b["fill"].size.x
	b["text"].text = text

func _portrait(parent: Control, pos: Vector2, d: float) -> Dictionary:
	var ring := Panel.new(); ring.position = pos; ring.size = Vector2(d, d); ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.15, 0.12, 0.1); sb.set_corner_radius_all(int(d / 2)); sb.border_color = GOLD; sb.set_border_width_all(3)
	ring.add_theme_stylebox_override("panel", sb); parent.add_child(ring)
	var l := Label.new(); l.size = Vector2(d, d); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", int(d * 0.45)); l.add_theme_font_override("font", bold); l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.add_child(l)
	var lv := Panel.new(); lv.size = Vector2(30, 24); lv.position = Vector2(-4, d - 20); lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb2 := StyleBoxFlat.new(); sb2.bg_color = Color(0.1, 0.08, 0.06); sb2.set_corner_radius_all(10); sb2.border_color = GOLD; sb2.set_border_width_all(2)
	lv.add_theme_stylebox_override("panel", sb2); ring.add_child(lv)
	var lvl := Label.new(); lvl.size = lv.size; lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lvl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lvl.add_theme_font_size_override("font_size", 14); lvl.add_theme_color_override("font_color", GOLD); lvl.mouse_filter = Control.MOUSE_FILTER_IGNORE; lv.add_child(lvl)
	return {"ring": ring, "letter": l, "sb": sb, "level": lvl}

func _player_frame() -> void:
	var p := _panel(root, Vector2(22, 20), Vector2(330, 96), 48)
	pf["panel"] = p
	var por := _portrait(p, Vector2(6, 6), 84); pf["por"] = por
	pf["name"] = _label(p, "", 19, Vector2(100, 8), INK, true)
	pf["hp"] = _bar(p, Vector2(98, 38), Vector2(218, 22), Color(0.2, 0.72, 0.22))
	pf["pw"] = _bar(p, Vector2(98, 64), Vector2(218, 16), Color(0.18, 0.38, 0.9))
	pf["hp"]["bg"].visible = false; pf["pw"]["bg"].visible = false        # the orbs show these now
	p.size = Vector2(230, 96)
	buffs = HBoxContainer.new(); buffs.position = Vector2(30, 122); buffs.add_theme_constant_override("separation", 4); buffs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(buffs)
	gold_l = _label(root, "", 16, Vector2(26, 160), GOLD)

func _target_frame() -> void:
	var p := _panel(root, Vector2(372, 20), Vector2(330, 96), 48)
	tf["panel"] = p; p.visible = false
	var por := _portrait(p, Vector2(240, 6), 84); tf["por"] = por
	tf["name"] = _label(p, "", 19, Vector2(14, 8), INK, true)
	tf["hp"] = _bar(p, Vector2(12, 38), Vector2(220, 22), Color(0.2, 0.72, 0.22))
	tf["pw"] = _bar(p, Vector2(12, 64), Vector2(220, 16), Color(0.18, 0.38, 0.9))
	tf["cast"] = _bar(p, Vector2(12, 104), Vector2(220, 16), Color(0.95, 0.7, 0.15))
	tf["cast"]["bg"].visible = false
	tf["elite"] = _label(p, "", 14, Vector2(200, 8), GOLD)
	# another player: invite them or whisper them
	var social := HBoxContainer.new(); social.position = Vector2(12, 100); social.add_theme_constant_override("separation", 6); p.add_child(social)
	for pair in [["Invite", func(): if player.target is Bot: get_tree().call_group("bots", "invited", player, player.target.uname)],
			["Whisper", func(): if player.target is Bot: chat.last_whisper = player.target.uname; chat.channel = "whisper"; chat.open_input("")],
			["Leave group", func(): get_tree().call_group("bots", "leave_party", player)]]:
		var b := Button.new(); b.text = pair[0]; b.focus_mode = Control.FOCUS_NONE; b.add_theme_font_size_override("font_size", 14); b.pressed.connect(pair[1])
		UiSkin.style_button(b, 8.0); social.add_child(b)
	tf["social"] = social; social.visible = false

## the bottom of the screen, Diablo-style: a health orb on the left, a mana (or rage) orb on the
## right, and between them the five-slot action bar on a bronze-rimmed stone plate, with the cast
## bar and experience above it (art in assets/ui, painted by art/ui_art.py; orbs: shaders/orb.gdshader)
const BAR_W := 580.0
const BAR_H := 110.0
const SLOT_X := [118.0, 204.0, 290.0, 376.0, 462.0]
var orbs := {}

func _action_bar() -> void:
	var holder := Control.new(); holder.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)
	var plate := TextureRect.new(); plate.texture = load("res://assets/ui/hotbar.png"); plate.size = Vector2(BAR_W, BAR_H)
	plate.position = Vector2(-BAR_W / 2.0, -BAR_H - 6); plate.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_child(plate)
	var s := 64.0
	for i in SLOT_X.size():
		var b := Button.new(); b.flat = true; b.focus_mode = Control.FOCUS_NONE
		b.position = Vector2(SLOT_X[i] - s / 2.0, 60.0 - s / 2.0); b.size = Vector2(s, s)
		plate.add_child(b)
		var ic := AbilityIcon.new(); ic.size = Vector2(s, s); b.add_child(ic)
		var key := _label(b, str(i + 1), 14, Vector2(6, 3), Color(1, 0.95, 0.8))
		key.add_theme_color_override("font_outline_color", Color(0, 0, 0)); key.add_theme_constant_override("outline_size", 5)
		var cdl := Label.new(); cdl.size = Vector2(s, s); cdl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; cdl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cdl.add_theme_font_size_override("font_size", 24); cdl.add_theme_font_override("font", bold); cdl.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
		cdl.add_theme_color_override("font_outline_color", Color(0, 0, 0)); cdl.add_theme_constant_override("outline_size", 6); cdl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cdl)
		var idx := i
		b.pressed.connect(func(): _slot_pressed(idx))
		b.mouse_entered.connect(func(): _show_tip(player.bar[idx] if player else "", b))
		b.mouse_exited.connect(_hide_tip)
		slots.append({"btn": b, "icon": ic, "cd": cdl, "flash": 0.0})
	# the orbs either side (sized to the screen: big on 1080p, smaller on small windows)
	var od := orb_size(get_viewport().get_visible_rect().size.y)
	for side in [["hp", -1.0], ["mp", 1.0]]:
		var key2: String = side[0]
		var cx: float = side[1] * (BAR_W / 2.0 + od * 0.36)
		var box := Control.new(); box.size = Vector2(od, od); box.position = Vector2(cx - od / 2.0, -od - 2); box.mouse_filter = Control.MOUSE_FILTER_PASS
		holder.add_child(box)
		var liq := ColorRect.new(); var inner := od * 0.772
		liq.size = Vector2(inner, inner); liq.position = Vector2((od - inner) / 2.0, (od - inner) / 2.0); liq.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sm := ShaderMaterial.new(); sm.shader = load("res://shaders/orb.gdshader"); liq.material = sm
		box.add_child(liq)
		var frame := TextureRect.new(); frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.texture = load("res://assets/ui/orb_frame_%s.png" % key2); frame.size = Vector2(od, od)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE; box.add_child(frame)
		var txt := Label.new(); txt.size = Vector2(od, 24); txt.position = Vector2(0, od * 0.5 - 12); txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		txt.add_theme_font_size_override("font_size", 17); txt.add_theme_font_override("font", bold)
		txt.add_theme_color_override("font_outline_color", Color(0, 0, 0)); txt.add_theme_constant_override("outline_size", 6)
		txt.mouse_filter = Control.MOUSE_FILTER_IGNORE; txt.modulate.a = 0.0; box.add_child(txt)
		box.mouse_entered.connect(func(): txt.modulate.a = 1.0)
		box.mouse_exited.connect(func(): txt.modulate.a = 0.0)
		orbs[key2] = {"mat": sm, "text": txt, "shown": 1.0, "last": -1.0, "flash": 0.0}
	_set_orb_colors()

static func orb_size(screen_h: float) -> float:
	return clampf(screen_h * 0.26, 150.0, 230.0)

## where the left orb starts (for the chat box to keep clear of it)
static func orb_left_edge(screen: Vector2) -> float:
	var od := orb_size(screen.y)
	return screen.x / 2.0 - (BAR_W / 2.0 + od * 0.36) - od / 2.0

func _set_orb_colors() -> void:
	(orbs["hp"]["mat"] as ShaderMaterial).set_shader_parameter("deep", Color(0.32, 0.02, 0.03)); orbs["hp"]["mat"].set_shader_parameter("bright", Color(1.0, 0.22, 0.14))
	var rage := player != null and player.power_kind == "rage"
	orbs["mp"]["mat"].set_shader_parameter("deep", Color(0.35, 0.08, 0.0) if rage else Color(0.02, 0.06, 0.32))
	orbs["mp"]["mat"].set_shader_parameter("bright", Color(1.0, 0.55, 0.12) if rage else Color(0.25, 0.55, 1.0))

func _update_orbs(delta: float) -> void:
	for pair in [["hp", player.hp / maxf(1.0, player.max_hp), "%d / %d" % [int(player.hp), int(player.max_hp)]],
			["mp", player.power / maxf(1.0, player.max_power), "%d / %d" % [int(player.power), int(player.max_power)]]]:
		var o: Dictionary = orbs[pair[0]]
		var want: float = pair[1]
		if o["last"] >= 0.0 and absf(want - o["last"]) > 0.02: o["flash"] = 1.0
		o["last"] = want
		o["shown"] = lerpf(o["shown"], want, clampf(delta * 6.0, 0, 1))
		o["flash"] = maxf(0.0, o["flash"] - delta * 3.0)
		o["mat"].set_shader_parameter("fill", o["shown"])
		o["mat"].set_shader_parameter("flash", o["flash"])
		o["text"].text = pair[2]

func _cast_bar() -> void:
	var holder := Control.new(); holder.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); holder.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(holder)
	var p := _panel(holder, Vector2(-170, -BAR_H - 78), Vector2(340, 34), 8)
	castbar["panel"] = p; p.visible = false
	castbar["bar"] = _bar(p, Vector2(8, 7), Vector2(324, 20), Color(0.95, 0.72, 0.2))

func _xp_bar() -> void:
	var holder := Control.new(); holder.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); holder.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(holder)
	var w := BAR_W - 60.0
	var bg := ColorRect.new(); bg.color = Color(0.03, 0.02, 0.04, 0.92); bg.size = Vector2(w, 10); bg.position = Vector2(-w / 2.0, -BAR_H - 20)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS; holder.add_child(bg)
	var edge := ReferenceRect.new(); edge.border_color = Color(0.72, 0.56, 0.32, 0.9); edge.border_width = 1.5; edge.editor_only = false
	edge.size = bg.size + Vector2(2, 2); edge.position = Vector2(-1, -1); edge.mouse_filter = Control.MOUSE_FILTER_IGNORE; bg.add_child(edge)
	var fill := ColorRect.new(); fill.color = Color(0.55, 0.3, 0.85); fill.mouse_filter = Control.MOUSE_FILTER_IGNORE; bg.add_child(fill)
	fill.anchor_bottom = 1.0; fill.material = _bar_mat()
	# ten notches, like the old MMO experience bars
	for k in range(1, 10):
		var tick := ColorRect.new(); tick.color = Color(0, 0, 0, 0.55); tick.size = Vector2(1, 10); tick.position = Vector2(w * k / 10.0, 0)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE; bg.add_child(tick)
	var txt := Label.new(); txt.set_anchors_preset(Control.PRESET_FULL_RECT); txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	txt.add_theme_font_size_override("font_size", 12); txt.mouse_filter = Control.MOUSE_FILTER_IGNORE; txt.position.y = -16
	txt.add_theme_color_override("font_outline_color", Color(0, 0, 0)); txt.add_theme_constant_override("outline_size", 4)
	txt.modulate.a = 0.0; bg.add_child(txt)
	bg.mouse_entered.connect(func(): txt.modulate.a = 1.0)
	bg.mouse_exited.connect(func(): txt.modulate.a = 0.0)
	xpbar = {"fill": fill, "text": txt, "bg": bg}

func _misc() -> void:
	err = _label(root, "", 22, Vector2(0, 0), Color(1.0, 0.25, 0.2), true)
	err.set_anchors_preset(Control.PRESET_CENTER_TOP); err.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	err.offset_left = -300; err.offset_right = 300; err.offset_top = 130
	var right := Control.new(); right.set_anchors_preset(Control.PRESET_TOP_RIGHT); right.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(right)
	place = _label(right, WorldData.Z.get("name", "Ashvale"), 22, Vector2(-300, 18), GOLD, true)
	clock = _label(right, "", 16, Vector2(-258, 54))
	fps = _label(right, "", 14, Vector2(-258, 78)); fps.visible = false
	tip = PanelContainer.new(); tip.visible = false; tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_theme_stylebox_override("panel", UiSkin.panel("tooltip", Vector4(14, 10, 14, 10)))
	tip_l = RichTextLabel.new(); tip_l.bbcode_enabled = true; tip_l.fit_content = true; tip_l.custom_minimum_size = Vector2(300, 0); tip_l.scroll_active = false
	tip_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_child(tip_l); root.add_child(tip)
	help = PanelContainer.new(); root.add_child(help)
	help.add_theme_stylebox_override("panel", UiSkin.panel("hud", Vector4(18, 12, 18, 12))); help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := Label.new(); t.add_theme_font_size_override("font_size", 15)
	t.text = "Left-click ground: walk (hold to keep walking)    Left-click an enemy: target, again: attack\n1–5: abilities    Tab: nearest enemy    Esc: clear target    P: spellbook\nClick people with a ! over their heads for quests\nB: bags    C: character    L: quest log    N: talents    M: map    Enter: chat\nZ: ride your stag (40+)    R: Mythic power    /lfm: call for a raid\nRight-drag: turn camera    Wheel: zoom    F1: this card    F3: FPS    F11: fullscreen"
	help.add_child(t)
	t.text = t.text.replace("    Left-click an enemy", "\nLeft-click an enemy").replace("    P: spellbook", "\nP: spellbook").replace("    F1:", "\nF1:")
	help.set_anchors_preset(Control.PRESET_CENTER_LEFT); help.offset_left = 22; help.offset_top = -250


# ------------------------------------------------------------------ updating

func _refresh_player() -> void:
	if player == null: return
	var c: Dictionary = Rules.CLASSES[player.cls]
	pf["name"].text = player.uname
	pf["por"]["letter"].text = player.uname.substr(0, 1).to_upper()
	pf["por"]["letter"].add_theme_color_override("font_color", c["color"])
	pf["por"]["level"].text = str(player.level)
	pf["pw"]["fill"].color = Color(0.85, 0.15, 0.12) if player.power_kind == "rage" else Color(0.18, 0.38, 0.9)
	if not orbs.is_empty(): _set_orb_colors()
	_refresh_bar()
	_refresh_buffs()

func _refresh_buffs() -> void:
	for ch in buffs.get_children(): ch.queue_free()
	for a in player.auras:
		if a["data"].get("debuff", false) and a["id"] != "weakened_soul": pass
		var id: String = a["id"]
		var base := id.trim_suffix("_burn").trim_suffix("_slow")
		var ic := AbilityIcon.new(); ic.custom_minimum_size = Vector2(30, 30); ic.size = Vector2(30, 30)
		var shown := id if ResourceLoader.exists("res://assets/icons/%s.png" % id) else base
		ic.set_ability(shown if (Abilities.LIST.has(shown) or ResourceLoader.exists("res://assets/icons/%s.png" % shown)) else "")
		if a["data"].get("debuff", false): ic.tint = Color(0.35, 0.0, 0.0, 0.25)
		buffs.add_child(ic)

func _refresh_bar() -> void:
	if player == null: return
	for i in slots.size():
		slots[i]["icon"].set_ability(player.bar[i] if i < player.bar.size() else "")

func _refresh_xp() -> void:
	if player == null: return
	var need := Rules.xp_need(player.level)
	var frac := float(player.xp) / maxf(1.0, need)
	xpbar["fill"].anchor_right = frac if need > 0 else 1.0
	xpbar["text"].text = "Level %d   ·   %d / %d experience" % [player.level, player.xp, need] if need > 0 else "Level %d (the cap)" % player.level
	# rested: the bar turns blue while kills give double experience (as in WoW)
	xpbar["fill"].color = Color(0.25, 0.48, 0.95) if player.rested > 0 else Color(0.55, 0.3, 0.85)
	if player.rested > 0: xpbar["text"].text += "   ·   rested (+%d)" % player.rested


func _process(delta: float) -> void:
	if player == null: return
	_update_orbs(delta)
	# player frame
	_set_bar(pf["hp"], player.hp / maxf(1.0, player.max_hp), "%d / %d" % [int(player.hp), int(player.max_hp)])
	_set_bar(pf["pw"], player.power / maxf(1.0, player.max_power), "%d / %d" % [int(player.power), int(player.max_power)])
	pf["por"]["sb"].border_color = Color(0.95, 0.25, 0.2) if player.in_combat else GOLD
	gold_l.text = _money(player.gold)
	# target frame
	var t: Unit = player.target if player.target and is_instance_valid(player.target) else null
	tf["panel"].visible = t != null
	if t:
		var namecol := Color(0.4, 1.0, 0.45) if not player.is_enemy(t) else Rules.con_color(player.level, t.level)
		tf["name"].text = t.uname
		tf["name"].add_theme_color_override("font_color", namecol if player.is_enemy(t) else INK)
		tf["por"]["level"].text = str(t.level) if t.level - player.level < 10 else "??"
		tf["por"]["level"].add_theme_color_override("font_color", Rules.con_color(player.level, t.level) if player.is_enemy(t) else GOLD)
		tf["por"]["letter"].text = t.uname.substr(0, 1)
		tf["por"]["letter"].add_theme_color_override("font_color", Color(1, 0.4, 0.3) if player.is_enemy(t) else Color(0.5, 1, 0.5))
		tf["elite"].text = "Elite" if t.elite else ""
		tf["social"].visible = t is Bot
		if t is Bot:
			var in_group: bool = t.party_with == player
			tf["social"].get_child(0).visible = not in_group
			tf["social"].get_child(2).visible = in_group
			tf["name"].text = "%s  (%s)" % [t.uname, Rules.CLASSES[t.cls]["name"]]

		_set_bar(tf["hp"], t.hp / maxf(1.0, t.max_hp), ("%d%%" % int(round(100.0 * t.hp / maxf(1.0, t.max_hp)))) if t.faction == "hostile" else "%d / %d" % [int(t.hp), int(t.max_hp)])
		tf["hp"]["fill"].color = Color(0.2, 0.72, 0.22) if not t.dead else Color(0.3, 0.3, 0.3)
		tf["pw"]["bg"].visible = t.power_kind != "none"
		if t.power_kind != "none": _set_bar(tf["pw"], t.power / maxf(1.0, t.max_power), "")
		tf["cast"]["bg"].visible = not t.casting.is_empty()
		if not t.casting.is_empty():
			_set_bar(tf["cast"], t.casting["t"] / t.casting["dur"], Abilities.LIST[t.casting["id"]]["name"])
	# action bar
	for i in slots.size():
		var id: String = player.bar[i] if i < player.bar.size() else ""
		var s: Dictionary = slots[i]
		var ic: AbilityIcon = s["icon"]
		if id == "": ic.cd_frac = 0.0; s["cd"].text = ""; continue
		var a: Dictionary = Abilities.LIST[id]
		var left := float(player.cds.get(id, 0.0))
		var cd_total := float(a.get("cd", 0.0))
		var g := player.gcd if a.get("gcd", true) else 0.0
		if left > g and cd_total > 0.0: ic.cd_frac = left / cd_total
		elif g > 0.0: ic.cd_frac = g / Rules.GCD
		else: ic.cd_frac = 0.0
		s["cd"].text = str(int(ceil(left))) if left > 1.6 else ""
		var why := player.check_use(id, player.target if not a.get("helpful", false) else player)
		ic.dim = 0.55 if why.begins_with("Not enough") else 0.0
		ic.tint = Color(0.8, 0.05, 0.05, 0.35) if why in ["Out of range", "Too close"] else Color(0, 0, 0, 0)
		if s["flash"] > 0.0:
			s["flash"] -= delta
			ic.tint = Color(1, 1, 0.8, s["flash"] * 1.5)
		ic.queue_redraw()
	# cast bar
	castbar["panel"].visible = not player.casting.is_empty()
	if not player.casting.is_empty():
		var c: Dictionary = player.casting
		var frac: float = c["t"] / c["dur"]
		if c["channel"]: frac = 1.0 - frac
		_set_bar(castbar["bar"], frac, "%s   %.1f" % [Abilities.LIST[c["id"]]["name"], maxf(0.0, c["dur"] - c["t"])])
		castbar["bar"]["fill"].size.x = castbar["bar"]["w"] * clampf(frac, 0, 1)
	# errors
	if err_t > 0.0:
		err_t -= delta; err.modulate.a = clampf(err_t, 0.0, 1.0)
	# clock
	var h := DayNight.hour
	clock.text = "%02d:%02d" % [int(h), int((h - int(h)) * 60.0)]
	fps.text = "%d fps" % Engine.get_frames_per_second()
	if help_t > 0.0:
		help_t -= delta; help.modulate.a = clampf(help_t / 2.0, 0.0, 1.0)
	_update_party()
	_update_nameplates()
	_update_floats(delta)
	_update_ring(t, delta)
	if Engine.get_process_frames() % 20 == 0: _refresh_buffs()

var party_frames: Array = []

## your group, under your own frame (WoW's party frames)
func _update_party() -> void:
	var members: Array = player.party.filter(func(m): return is_instance_valid(m))
	while party_frames.size() < members.size():
		var i := party_frames.size()
		var p := _panel(root, Vector2(26, 190 + i * 62), Vector2(230, 54), 10)
		var d := {"panel": p, "name": _label(p, "", 15, Vector2(10, 3), INK, true), "hp": _bar(p, Vector2(10, 24), Vector2(210, 13), Color(0.2, 0.72, 0.22)), "pw": _bar(p, Vector2(10, 39), Vector2(210, 8), Color(0.18, 0.38, 0.9))}
		d["hp"]["text"].add_theme_font_size_override("font_size", 10)
		party_frames.append(d)
	# a raid: smaller frames, two columns
	var compact := members.size() > 4
	for i in party_frames.size():
		var f: Dictionary = party_frames[i]
		f["panel"].visible = i < members.size()
		f["panel"].scale = Vector2.ONE * (0.66 if compact else 1.0)
		f["panel"].position = Vector2(26 + (i / 5) * 160, 190 + (i % 5) * 40) if compact else Vector2(26, 190 + i * 62)
		if i >= members.size(): continue
		var m: Unit = members[i]
		f["name"].text = "%s   %d %s" % [m.uname, m.level, Rules.CLASSES[m.cls]["name"]]
		f["name"].add_theme_color_override("font_color", Rules.CLASSES[m.cls]["color"] if not m.dead else Color(0.6, 0.6, 0.6))
		_set_bar(f["hp"], m.hp / maxf(1.0, m.max_hp), "%d / %d" % [int(m.hp), int(m.max_hp)])
		_set_bar(f["pw"], m.power / maxf(1.0, m.max_power), "")
		f["pw"]["fill"].color = Color(0.85, 0.15, 0.12) if m.power_kind == "rage" else Color(0.18, 0.38, 0.9)

func _money(c: int) -> String:

	var g := c / 10000; var s := (c / 100) % 100; var cc := c % 100
	var out := ""
	if g > 0: out += "%dg " % g
	if g > 0 or s > 0: out += "%ds " % s
	return out + "%dc" % cc

# ------------------------------------------------------------------ the selection circle under your target

func _update_ring(t: Unit, delta: float) -> void:
	if sel_ring == null:
		sel_ring = MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(2, 2); q.orientation = PlaneMesh.FACE_Y
		sel_mat = StandardMaterial3D.new(); sel_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; sel_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sel_mat.albedo_texture = Fx.ring_tex; sel_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		q.material = sel_mat; sel_ring.mesh = q; sel_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_tree().current_scene.add_child(sel_ring)
	sel_ring.visible = t != null and not t.dead and t.visible
	if not sel_ring.visible: return
	var r: float = maxf(0.7, t.radius * 1.9)
	sel_ring.global_position = t.global_position + Vector3(0, 0.09, 0)
	sel_ring.scale = Vector3.ONE * r * (1.0 + 0.04 * sin(Time.get_ticks_msec() / 250.0))
	sel_ring.rotate_y(delta * 0.6)
	var c := Color(1.0, 0.25, 0.15) if player.is_enemy(t) else Color(0.35, 1.0, 0.35)
	if t.faction == "neutral": c = Color(1.0, 0.9, 0.3)
	sel_mat.albedo_color = Color(c.r * 1.6, c.g * 1.6, c.b * 1.6, 0.95)

# ------------------------------------------------------------------ game menu (Esc with nothing targeted)

func toggle_menu() -> void:
	if menu and is_instance_valid(menu):
		menu.queue_free(); menu = null; return
	menu = PanelContainer.new(); root.add_child(menu)
	menu.add_theme_stylebox_override("panel", UiSkin.panel("window", Vector4(30, 22, 30, 22)))
	menu.set_anchors_preset(Control.PRESET_CENTER); menu.offset_left = -150; menu.offset_top = -140
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10); menu.add_child(v)
	var t := Label.new(); t.text = "Ashvale"; t.add_theme_font_size_override("font_size", 28); t.add_theme_color_override("font_color", GOLD); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(t)
	for pair in [["Return to the game", func(): toggle_menu()], ["Spellbook (P)", func(): toggle_menu(); toggle_book()],
			["Fullscreen (F11)", func(): _fullscreen()], ["Music: on / off", func(): Soundscape.music_on = not Soundscape.music_on; notice("Music on" if Soundscape.music_on else "Music off")], ["Save and quit", func(): get_tree().current_scene._save(); get_tree().quit()]]:
		var b := Button.new(); b.text = pair[0]; b.custom_minimum_size = Vector2(260, 42); b.add_theme_font_size_override("font_size", 18); b.focus_mode = Control.FOCUS_NONE
		UiSkin.style_button(b); b.pressed.connect(pair[1]); v.add_child(b)

func _fullscreen() -> void:
	var w := get_window()
	w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN or w.mode == Window.MODE_EXCLUSIVE_FULLSCREEN else Window.MODE_FULLSCREEN

# ------------------------------------------------------------------ nameplates

func _update_nameplates() -> void:
	if cam == null: return
	var seen := {}
	for u in get_tree().get_nodes_in_group("units"):
		if u == player or not u.visible: continue
		var show: bool = not u.dead and u.global_position.distance_to(player.global_position) < (38.0 if u.faction != "npc" else 22.0) and (u.faction in ["hostile", "friendly", "npc"])
		if not show: continue
		var head: Vector3 = u.global_position + Vector3(0, 2.25 * (u.model.scale.y if u.model else 1.0), 0)
		if cam.is_position_behind(head): continue
		seen[u] = true
		var np: Control = nameplates.get(u)
		if np == null or not is_instance_valid(np):
			np = _make_plate(u); nameplates[u] = np
		np.position = cam.unproject_position(head) - Vector2(60, 26)
		var hb: Dictionary = np.get_meta("hp")
		var enemy: bool = player.is_enemy(u)
		np.get_node("Name").add_theme_color_override("font_color", Rules.con_color(player.level, u.level) if enemy else Color(0.55, 1.0, 0.55))
		var nm: String = u.uname
		if u is Npc and u.info.get("title", "") != "": nm += "\n<%s>" % u.info["title"]
		(np.get_node("Name") as Label).text = nm if u == player.target or not enemy or u.in_combat else ""
		hb["bg"].visible = enemy and (u.in_combat or u == player.target or u.hp < u.max_hp)
		_set_bar(hb, u.hp / maxf(1.0, u.max_hp), "")
		np.modulate.a = 1.0 if u == player.target else 0.85
		var sel := np.get_node("Sel") as ColorRect
		sel.visible = u == player.target
	for u in nameplates.keys():
		if not seen.has(u):
			if is_instance_valid(nameplates[u]): nameplates[u].queue_free()
			nameplates.erase(u)

func _make_plate(u: Unit) -> Control:
	var c := Control.new(); c.mouse_filter = Control.MOUSE_FILTER_IGNORE; c.size = Vector2(120, 30)
	fct_layer.add_child(c)
	var sel := ColorRect.new(); sel.name = "Sel"; sel.color = Color(1, 0.9, 0.5, 0.9); sel.position = Vector2(-2, 17); sel.size = Vector2(124, 12); c.add_child(sel)
	var l := Label.new(); l.name = "Name"; l.size = Vector2(120, 18); l.position = Vector2(0, -2); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 14); l.add_theme_color_override("font_outline_color", Color(0, 0, 0)); l.add_theme_constant_override("outline_size", 4)
	c.add_child(l)
	var hb := _bar(c, Vector2(0, 19), Vector2(120, 8), Color(0.85, 0.18, 0.12))
	hb["text"].visible = false
	c.set_meta("hp", hb)
	return c

# ------------------------------------------------------------------ floating combat text

func _on_struck(u: Unit, amount: int, crit: bool, school: String, kind: String) -> void:
	if amount <= 0: return
	var col := Color(1, 1, 1)
	if kind == "heal": col = Color(0.35, 1.0, 0.35)
	elif u == player: col = Color(1.0, 0.25, 0.2)
	elif school != "physical": col = Fx.SCHOOL.get(school, Color(1, 1, 0.4)).lightened(0.3)
	else: col = Color(1, 1, 1) if kind == "white" else Color(1, 0.95, 0.45)
	var txt := ("+%d" % amount) if kind == "heal" else str(amount)
	float_text(u, txt, col, crit)

func float_text(u: Node3D, text: String, col: Color, big := false) -> void:
	if not is_instance_valid(u): return
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", 34 if big else 22)
	l.add_theme_font_override("font", bold)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9)); l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fct_layer.add_child(l)
	var side := randf_range(-40, 40)
	floats.append({"l": l, "u": u, "t": 0.0, "side": side, "big": big, "at": u.global_position + Vector3(0, 2.0, 0)})

func _update_floats(delta: float) -> void:
	for i in range(floats.size() - 1, -1, -1):
		var f: Dictionary = floats[i]
		f["t"] += delta
		var l: Label = f["l"]
		var life := 1.3 if f["big"] else 1.0
		if f["t"] > life or cam == null:
			l.queue_free(); floats.remove_at(i); continue
		var at: Vector3 = f["at"]
		if is_instance_valid(f["u"]): at = f["u"].global_position + Vector3(0, 2.0, 0)
		if cam.is_position_behind(at): l.visible = false; continue
		l.visible = true
		var p := cam.unproject_position(at)
		var k: float = f["t"] / life
		l.position = p + Vector2(f["side"] * k - l.size.x / 2.0, -k * 70.0 - 10.0)
		var pop: float = 1.0 + (0.6 * (1.0 - clampf(f["t"] * 6.0, 0, 1)) if f["big"] else 0.0)
		l.scale = Vector2(pop, pop); l.pivot_offset = l.size / 2.0
		l.modulate.a = 1.0 - pow(k, 3.0)

# ------------------------------------------------------------------ messages

func error(msg: String) -> void:
	err.text = msg; err_t = 2.0; err.modulate.a = 1.0

func banner(title: String, sub: String) -> void:
	_banner(title, sub)
	get_tree().call_group("fx", "sound", "page", null, -8.0, 0.0)

func _banner(title: String, sub: String) -> void:

	var l := _label(root, title, 54, Vector2.ZERO, GOLD, true)
	l.set_anchors_preset(Control.PRESET_CENTER_TOP); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.offset_left = -400; l.offset_right = 400; l.offset_top = 170
	l.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.02)); l.add_theme_constant_override("outline_size", 8)
	var s := _label(root, sub, 22, Vector2.ZERO, INK)
	s.set_anchors_preset(Control.PRESET_CENTER_TOP); s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.offset_left = -400; s.offset_right = 400; s.offset_top = 240
	for n in [l, s]:
		var tw: Tween = n.create_tween(); tw.tween_interval(2.5); tw.tween_property(n, "modulate:a", 0.0, 1.0); tw.tween_callback(n.queue_free)

func player_died() -> void:
	if death and is_instance_valid(death): return
	death = PanelContainer.new(); root.add_child(death)
	death.add_theme_stylebox_override("panel", UiSkin.panel("window", Vector4(32, 22, 32, 22)))
	death.set_anchors_preset(Control.PRESET_CENTER); death.offset_left = -180; death.offset_right = 180; death.offset_top = -90
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 12); death.add_child(v)
	var l := Label.new(); l.text = "You have died."; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.add_theme_font_size_override("font_size", 28); v.add_child(l)
	var b := Button.new(); b.text = "Release to the graveyard"; b.add_theme_font_size_override("font_size", 20); UiSkin.style_button(b); b.custom_minimum_size = Vector2(0, 44); v.add_child(b)
	b.pressed.connect(func(): player.release(); death.queue_free(); death = null)

# ------------------------------------------------------------------ action bar clicks, tooltips, spellbook

func _slot_pressed(i: int) -> void:
	if book and book.visible and swap_from != -2:
		pass
	if book and book.visible and book.has_meta("pick"):
		player.bar[i] = book.get_meta("pick"); book.remove_meta("pick")
		_refresh_bar(); _refresh_book(); return
	player.press_slot(i)
	slots[i]["flash"] = 0.2

func flash_slot(i: int) -> void:
	if i >= 0 and i < slots.size(): slots[i]["flash"] = 0.2

func _show_tip(id: String, near: Control) -> void:
	if id == "" or not Abilities.LIST.has(id) or player == null: return
	var a: Dictionary = Abilities.LIST[id]
	var lines := "[font_size=19][b]%s[/b][/font_size]\n" % a["name"]
	var cost := Abilities.cost_text(id, player.power_kind, player.base_mana())
	var rng := ""
	if a.has("range") and not a.get("self", false): rng = "%d m range" % int(a["range"])
	lines += "[color=#cfcfcf]%s%s%s[/color]\n" % [cost, "      " if cost != "" and rng != "" else "", rng]
	var ct := "Instant" if float(a.get("cast", 0)) == 0.0 and float(a.get("channel", 0)) == 0.0 else ("%.1f sec cast" % a["cast"] if a.has("cast") else "Channeled")
	var cd := ("      %d sec cooldown" % int(a["cd"])) if a.has("cd") else ""
	lines += "[color=#cfcfcf]%s%s[/color]\n" % [ct, cd]
	var pw := player.spell_power() if a.get("school", "physical") != "physical" else 0.0
	lines += "[color=#ffd479]%s[/color]" % Abilities.describe(id, player.level, pw)
	tip_l.text = lines
	tip.visible = true
	tip.reset_size()
	var r := near.get_global_rect()
	tip.position = Vector2(clampf(r.position.x + r.size.x / 2.0 - 160, 8, get_viewport().get_visible_rect().size.x - 340), r.position.y - tip.size.y - 16)

func _hide_tip() -> void:
	tip.visible = false

## a tooltip with any text, beside a control (items, talents)
func _show_text_tip(bb: String, near: Control) -> void:
	tip_l.text = bb
	tip.visible = true
	tip.reset_size()
	var r := near.get_global_rect()
	var vs := get_viewport().get_visible_rect().size
	var x := r.position.x + r.size.x + 10
	if x + tip.size.x > vs.x - 8: x = r.position.x - tip.size.x - 10
	tip.position = Vector2(clampf(x, 8, vs.x - tip.size.x - 8), clampf(r.position.y, 8, vs.y - tip.size.y - 8))

# ------------------------------------------------------------------ messages the game sends us

## a yellow line in the middle of the screen (and the chat)
func notice(msg: String) -> void:
	_center_line(msg, Color(1.0, 0.92, 0.35))
	chat.post("system", "", msg)

## quest progress: "Field Rats slain: 3/8"
func quest_progress(msg: String) -> void:
	_center_line(msg, Color(1.0, 0.92, 0.35))

func _center_line(msg: String, col: Color) -> void:
	var l := _label(notices, msg, 21, Vector2.ZERO, col, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8)); l.add_theme_constant_override("outline_size", 5)
	while notices.get_child_count() > 4: notices.get_child(0).free()
	var tw := l.create_tween(); tw.tween_interval(3.0); tw.tween_property(l, "modulate:a", 0.0, 1.0); tw.tween_callback(l.queue_free)

func loot_line(d: Dictionary, n: int) -> void:
	var c := Items.color(d).to_html(false)
	chat.post("loot", "", "You receive loot: [color=#%s][%s][/color]%s" % [c, d["name"], ("x%d" % n) if n > 1 else ""])

func open_npc(n: Npc) -> void:
	win.open_npc(n)

func open_loot(m: Monster) -> void:
	win.open_loot(m)

func open_station(kind: String) -> void:
	win.open_station(kind)

func open_roll(it: Dictionary, loot: RaidLoot) -> void:
	win.open_roll(it, loot)

func close_roll() -> void:
	win.close_roll()


func toggle_book() -> void:
	if book == null:
		book = PanelContainer.new(); root.add_child(book)
		book.add_theme_stylebox_override("panel", UiSkin.panel("window", Vector4(24, 18, 24, 18)))
		book.set_anchors_preset(Control.PRESET_CENTER_LEFT); book.offset_left = 30; book.offset_top = -300
		book.visible = false
	book.visible = not book.visible
	if book.visible: _refresh_book()

func _refresh_book() -> void:
	for c in book.get_children(): c.queue_free()
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 6); book.add_child(v)
	var title := Label.new(); title.text = "Spellbook"; title.add_theme_font_size_override("font_size", 26); title.add_theme_color_override("font_color", GOLD); v.add_child(title)
	var hint := Label.new(); hint.text = "Click an ability, then click a slot on your bar to carry it.\nYou can carry five at a time."
	hint.add_theme_font_size_override("font_size", 14); hint.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75)); v.add_child(hint)
	for id in player.known:
		var a: Dictionary = Abilities.LIST[id]
		var row := Button.new(); row.custom_minimum_size = Vector2(360, 52); row.focus_mode = Control.FOCUS_NONE
		row.flat = not (book.has_meta("pick") and book.get_meta("pick") == id)
		v.add_child(row)
		var ic := AbilityIcon.new(); ic.size = Vector2(44, 44); ic.position = Vector2(4, 4); ic.set_ability(id); row.add_child(ic)
		var nm := Label.new(); nm.text = a["name"] + ("   (on your bar)" if id in player.bar else ""); nm.position = Vector2(58, 13)
		nm.add_theme_font_size_override("font_size", 18); nm.add_theme_color_override("font_color", INK if not (id in player.bar) else Color(0.7, 0.9, 0.6)); row.add_child(nm)
		row.pressed.connect(func(): book.set_meta("pick", id); _refresh_book())
		row.mouse_entered.connect(func(): _show_tip(id, row))
		row.mouse_exited.connect(_hide_tip)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if chat.is_typing(): return
		match e.physical_keycode:
			KEY_P: toggle_book()
			KEY_B: win.toggle_bags()
			KEY_C: win.toggle_char()
			KEY_L: win.toggle_log()
			KEY_N: win.toggle_talents()
			KEY_M: minimap.toggle_big(root)
			KEY_ESCAPE:
				if book and book.visible: book.visible = false
				elif win.close_one(): pass
				elif player and player.target == null: toggle_menu()
			KEY_F1: help_t = 30.0 if help.modulate.a < 0.5 else 0.0; help.modulate.a = 1.0 if help_t > 0 else 0.0
			KEY_F3: fps.visible = not fps.visible
			KEY_F11: _fullscreen()
		if e.physical_keycode >= KEY_1 and e.physical_keycode <= KEY_5: flash_slot(e.physical_keycode - KEY_1)
