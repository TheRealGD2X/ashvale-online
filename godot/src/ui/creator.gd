extends CanvasLayer
## Choose or create a hero. Shown over Ashvale at golden hour: your character stands on the green
## by the square while you pick a class, a body, a face, hair and a name. Drag to turn them.
##
## emits start(character) when you step into the world

signal start(ch: Dictionary)

const GOLD := Color(0.98, 0.84, 0.5)
const INK := Color(0.96, 0.93, 0.86)

var stage_pos := Vector3.ZERO
var cam: Camera3D
var preview: Avatar
var holder: Node3D
var look := {}
var cls := "warrior"
var name_edit: LineEdit
var panel: PanelContainer
var sel_panel: PanelContainer
var desc: Label
var class_btns := {}
var rng := RandomNumberGenerator.new()
var spin := 0.0
var dragging := false
var font: Font
var bold: Font
var rows := {}

func setup(pos: Vector3, camera: Camera3D) -> void:
	stage_pos = pos; cam = camera

func _ready() -> void:
	layer = 8
	rng.randomize()
	var f := SystemFont.new(); f.font_names = PackedStringArray(["Georgia", "Palatino Linotype", "Book Antiqua", "serif"]); font = f
	var fb := SystemFont.new(); fb.font_names = f.font_names; fb.font_weight = 700; bold = fb
	holder = Node3D.new(); get_parent().add_child.call_deferred(holder)
	await get_tree().process_frame
	holder.global_position = stage_pos
	_place_camera()
	var chars := Save.load_all()
	if chars.is_empty(): _open_creator()
	else: _open_select(chars)

func _place_camera() -> void:
	if cam == null: return
	cam.set_process(false)
	var fwd := Vector3(0, 0, 1)
	cam.global_position = stage_pos + Vector3(-1.1, 1.55, 3.6)
	cam.look_at(stage_pos + Vector3(-1.1 + 0.0, 1.05, 0), Vector3.UP)
	cam.fov = 38.0

# ------------------------------------------------------------------ select screen

func _open_select(chars: Array) -> void:
	sel_panel = _box(Vector2(40, 60), Vector2(420, 0))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10); sel_panel.add_child(v)
	v.add_child(_title("Welcome back"))
	for ch in chars:
		var b := _button("%s  ·  level %d %s" % [ch["name"], int(ch.get("level", 1)), Rules.CLASSES[ch.get("cls", "warrior")]["name"]], 20)
		v.add_child(b)
		b.pressed.connect(func(): _show_char(ch))
		b.set_meta("ch", ch)
	v.add_child(HSeparator.new())
	var play := _button("Enter Ashvale", 24, true); v.add_child(play)
	play.pressed.connect(func():
		if sel_panel.has_meta("ch"): _go(sel_panel.get_meta("ch")))
	var nb := _button("Create a new hero", 18); v.add_child(nb)
	nb.pressed.connect(func(): sel_panel.queue_free(); _open_creator())
	var del := _button("Delete this hero", 15); v.add_child(del)
	del.pressed.connect(func():
		if sel_panel.has_meta("ch") and del.text == "Click again to delete":
			Save.remove(sel_panel.get_meta("ch")["name"]); sel_panel.queue_free()
			var rest := Save.load_all()
			if rest.is_empty(): _open_creator()
			else: _open_select(rest)
		else: del.text = "Click again to delete")
	_show_char(chars[0])

func _show_char(ch: Dictionary) -> void:
	sel_panel.set_meta("ch", ch)
	cls = ch.get("cls", "warrior"); look = ch.get("look", {})
	_rebuild()

# ------------------------------------------------------------------ creator

func _open_creator() -> void:
	cls = ["warrior", "wizard", "cleric"][rng.randi() % 3]
	look = Avatar.random_look(rng, cls)
	panel = _box(Vector2(40, 40), Vector2(440, 0))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10); panel.add_child(v)
	v.add_child(_title("Create your hero"))
	# class
	var cr := HBoxContainer.new(); cr.add_theme_constant_override("separation", 8); v.add_child(cr)
	for c in ["warrior", "wizard", "cleric"]:
		var b := _button(Rules.CLASSES[c]["name"], 20)
		b.custom_minimum_size = Vector2(128, 46)
		b.add_theme_color_override("font_color", Rules.CLASSES[c]["color"])
		cr.add_child(b); class_btns[c] = b
		b.pressed.connect(func(): _set_class(c))
	desc = Label.new(); desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; desc.custom_minimum_size = Vector2(400, 96)
	desc.add_theme_font_size_override("font_size", 15); desc.add_theme_color_override("font_color", Color(0.88, 0.85, 0.78)); v.add_child(desc)
	# body
	v.add_child(_row("Body", func(d): look["sex"] = "f" if look.get("sex", "m") == "m" else "m"; _fit_sex(); _rebuild(), func(): return "Male" if look.get("sex", "m") == "m" else "Female"))
	v.add_child(_swatches("Skin", Avatar.SKIN, func(i): look["skin"] = i; _rebuild()))
	v.add_child(_row("Hair", func(d): _cycle("hair", _hairs(), d), func(): return _pretty(look.get("hair", ""))))
	v.add_child(_swatches("Hair colour", Avatar.HAIR_COLORS, func(i): look["hair_color"] = Avatar.HAIR_COLORS[i]; _rebuild()))
	v.add_child(_row("Brows", func(d): _cycle("brows", Avatar.BROWS_M if look.get("sex", "m") == "m" else Avatar.BROWS_F, d), func(): return _pretty(look.get("brows", ""))))
	v.add_child(_row("Facial hair", func(d): _cycle("beard", Avatar.BEARDS if look.get("sex", "m") == "m" else [""], d), func(): return _pretty(look.get("beard", ""))))
	v.add_child(_row("Outfit colour", func(d):
		var fam := _family(); var t: Dictionary = look.get("tint", {})
		t[fam] = posmod(int(t.get(fam, 1)) - 1 + d, 3) + 1; look["tint"] = t; _rebuild(), func(): return "Style %d" % int(look.get("tint", {}).get(_family(), 1))))
	# name
	var nr := HBoxContainer.new(); nr.add_theme_constant_override("separation", 8); v.add_child(nr)
	name_edit = LineEdit.new(); name_edit.placeholder_text = "Your name"; name_edit.max_length = 16; name_edit.custom_minimum_size = Vector2(300, 42)
	name_edit.add_theme_font_size_override("font_size", 20); name_edit.text = Save.NAMES[rng.randi() % Save.NAMES.size()]
	nr.add_child(name_edit)
	var rn := _button("?", 20); rn.custom_minimum_size = Vector2(42, 42); nr.add_child(rn)
	rn.pressed.connect(func(): name_edit.text = Save.NAMES[rng.randi() % Save.NAMES.size()])
	var rr := HBoxContainer.new(); rr.add_theme_constant_override("separation", 8); v.add_child(rr)
	var rb := _button("Surprise me", 16); rb.custom_minimum_size = Vector2(140, 42); rr.add_child(rb)
	rb.pressed.connect(func(): look = Avatar.random_look(rng, cls); _rebuild(); _refresh_rows())
	var go := _button("Enter Ashvale", 22, true); go.custom_minimum_size = Vector2(250, 48); rr.add_child(go)
	go.pressed.connect(_create)
	_set_class(cls)

func _family() -> String:
	return {"warrior": "Knight", "wizard": "Wizard", "cleric": "Noble"}[cls]

func _hairs() -> Array:
	return Avatar.HAIR_M if look.get("sex", "m") == "m" else Avatar.HAIR_F

func _fit_sex() -> void:
	var m: bool = look.get("sex", "m") == "m"
	if not (look.get("hair", "") in _hairs()): look["hair"] = _hairs()[0]
	look["brows"] = Avatar.BROWS_M[0] if m else Avatar.BROWS_F[0]
	if not m: look["beard"] = ""
	_refresh_rows()

func _cycle(key: String, opts: Array, d: int) -> void:
	var i := opts.find(look.get(key, ""))
	look[key] = opts[posmod(i + d, opts.size())]
	_rebuild(); _refresh_rows()

func _pretty(s: String) -> String:
	if s == "": return "None"
	return s.replace("Hair_", "").replace("Eyebrows_", "").replace("_", " ").replace("BuzzedFemale", "Buzzed").replace("Ponytail 2", "Ponytail (high)").replace("SimpleParted", "Parted").replace("SlickBack", "Slicked back").replace("LongDreads", "Long dreads").replace("MuttonChops", "Mutton chops")

func _set_class(c: String) -> void:
	cls = c
	look["gear"] = Avatar.CLASS_GEAR[c].duplicate()
	desc.text = Rules.CLASSES[c]["blurb"] + "\nTalents: " + ", ".join(Rules.CLASSES[c]["trees"]) + "."
	for k in class_btns:
		var sb := StyleBoxFlat.new(); sb.set_corner_radius_all(8)
		sb.bg_color = Color(0.25, 0.2, 0.12, 0.95) if k == c else Color(0.12, 0.1, 0.08, 0.9)
		sb.border_color = GOLD if k == c else Color(0.5, 0.42, 0.3, 0.6); sb.set_border_width_all(2 if k == c else 1)
		class_btns[k].add_theme_stylebox_override("normal", sb); class_btns[k].add_theme_stylebox_override("hover", sb)
	_rebuild(); _refresh_rows()

func _create() -> void:
	var nm := name_edit.text.strip_edges()
	if nm.length() < 2: name_edit.placeholder_text = "Pick a name first"; return
	for ch in Save.load_all():
		if ch["name"].to_lower() == nm.to_lower(): name_edit.text = ""; name_edit.placeholder_text = "That name is taken"; return
	var ch := {"name": nm, "cls": cls, "level": 1, "look": look.duplicate(true), "xp": 0, "gold": 0, "bar": Abilities.DEFAULT_BAR[cls]}
	var saved := ch.duplicate(true); saved["look"] = Save.encode_look(look)
	Save.upsert(saved)
	_go(ch)

func _go(ch: Dictionary) -> void:
	if ch.get("look", {}).get("hair_color") is Array: Save._fix(ch)
	var tw := create_tween()
	var fade := ColorRect.new(); fade.color = Color(0, 0, 0, 0); fade.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(fade)
	tw.tween_property(fade, "color:a", 1.0, 0.6)
	tw.tween_callback(func():
		if is_instance_valid(holder): holder.queue_free()
		cam.set_process(true); cam.fov = 50.0
		start.emit(ch))
	tw.tween_property(fade, "color:a", 0.0, 0.8)
	tw.tween_callback(queue_free)

# ------------------------------------------------------------------ preview

func _rebuild() -> void:
	if not is_instance_valid(holder): return
	for c in holder.get_children(): c.queue_free()
	preview = Avatar.new(); preview.look = look
	holder.add_child(preview)
	preview.rotation.y = spin
	match cls:
		"warrior": preview.wield("res://assets/weapons/sword.glb", 0.55)
		"wizard": preview.wield("res://assets/weapons/staff.glb", 0.62, "hand_r", 50.0)
		"cleric": preview.wield("res://assets/weapons/club.glb", 0.62, "hand_r", -40.0)
	preview.play("Idle")

func _process(delta: float) -> void:
	if is_instance_valid(preview) and not dragging:
		spin = lerp_angle(spin, 0.35, 1.0 - exp(-delta * 1.5))
		preview.rotation.y = spin

func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		dragging = e.pressed and e.position.x > 520
	elif e is InputEventMouseMotion and dragging and is_instance_valid(preview):
		spin += e.relative.x * 0.01; preview.rotation.y = spin

# ------------------------------------------------------------------ widgets

func _box(pos: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new(); p.position = pos; p.custom_minimum_size = size
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.08, 0.065, 0.05, 0.9); sb.set_corner_radius_all(14)
	sb.border_color = Color(0.85, 0.7, 0.42, 0.7); sb.set_border_width_all(2)
	sb.content_margin_left = 22; sb.content_margin_right = 22; sb.content_margin_top = 18; sb.content_margin_bottom = 20
	sb.shadow_color = Color(0, 0, 0, 0.4); sb.shadow_size = 12
	p.add_theme_stylebox_override("panel", sb)
	var th := Theme.new(); th.default_font = font; th.default_font_size = 18; p.theme = th
	add_child(p)
	return p

func _title(t: String) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_font_size_override("font_size", 32); l.add_theme_color_override("font_color", GOLD); l.add_theme_font_override("font", bold)
	return l

func _button(t: String, size := 18, primary := false) -> Button:
	var b := Button.new(); b.text = t; b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	var sb := StyleBoxFlat.new(); sb.set_corner_radius_all(8); sb.content_margin_left = 12; sb.content_margin_right = 12; sb.content_margin_top = 6; sb.content_margin_bottom = 6
	sb.bg_color = Color(0.55, 0.36, 0.12, 0.95) if primary else Color(0.14, 0.11, 0.08, 0.9)
	sb.border_color = GOLD if primary else Color(0.55, 0.45, 0.3, 0.7); sb.set_border_width_all(2 if primary else 1)
	var hv := sb.duplicate(); hv.bg_color = sb.bg_color.lightened(0.15)
	b.add_theme_stylebox_override("normal", sb); b.add_theme_stylebox_override("hover", hv); b.add_theme_stylebox_override("pressed", hv)
	b.add_theme_color_override("font_color", Color(1, 0.95, 0.85) if primary else INK)
	return b

func _row(label: String, on_change: Callable, value: Callable) -> Control:
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 8)
	var l := Label.new(); l.text = label; l.custom_minimum_size = Vector2(120, 0); l.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7)); h.add_child(l)
	var lb := _button("‹", 20); lb.custom_minimum_size = Vector2(38, 36); h.add_child(lb)
	var vl := Label.new(); vl.custom_minimum_size = Vector2(160, 0); vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; h.add_child(vl)
	var rb := _button("›", 20); rb.custom_minimum_size = Vector2(38, 36); h.add_child(rb)
	lb.pressed.connect(func(): on_change.call(-1); vl.text = value.call())
	rb.pressed.connect(func(): on_change.call(1); vl.text = value.call())
	vl.text = value.call()
	rows[label] = [vl, value]
	return h

func _refresh_rows() -> void:
	for k in rows:
		var r: Array = rows[k]
		if is_instance_valid(r[0]): r[0].text = r[1].call()

func _swatches(label: String, cols: Array, on_pick: Callable) -> Control:
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 6)
	var l := Label.new(); l.text = label; l.custom_minimum_size = Vector2(120, 0); l.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7)); h.add_child(l)
	for i in cols.size():
		var b := Button.new(); b.custom_minimum_size = Vector2(32, 32); b.focus_mode = Control.FOCUS_NONE
		var sb := StyleBoxFlat.new(); sb.bg_color = cols[i]; sb.set_corner_radius_all(16); sb.border_color = Color(0, 0, 0, 0.6); sb.set_border_width_all(2)
		var hv := sb.duplicate(); hv.border_color = GOLD
		b.add_theme_stylebox_override("normal", sb); b.add_theme_stylebox_override("hover", hv); b.add_theme_stylebox_override("pressed", hv)
		var idx := i
		b.pressed.connect(func(): on_pick.call(idx))
		h.add_child(b)
	return h
