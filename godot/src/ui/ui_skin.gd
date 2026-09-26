class_name UiSkin
## The painted panels, buttons and tooltips (art/ui_art.py, "panels"): dark tooled leather in a
## bevelled bronze rim, Albion-style. Each is a 9-slice StyleBoxTexture; the soft drop shadow lives in
## the texture's outer margin and is drawn outside the control with expand margins.

const UI := "res://assets/ui/"
static var _cache := {}

## kind: "window", "hud", "tooltip", "inset"
static func panel(kind := "window", pad := Vector4(16, 10, 16, 14)) -> StyleBox:
	var key := "%s%s" % [kind, pad]
	if _cache.has(key): return _cache[key]
	var spec: Dictionary = {"window": [14, 30], "hud": [8, 20], "tooltip": [8, 14], "inset": [0, 10]}[kind]
	var tex: Texture2D = load(UI + "panel_%s.png" % kind) if ResourceLoader.exists(UI + "panel_%s.png" % kind) else null
	var sb: StyleBox
	if tex:
		var t := StyleBoxTexture.new(); t.texture = tex
		var m: float = spec[1]
		t.texture_margin_left = m; t.texture_margin_right = m; t.texture_margin_top = m; t.texture_margin_bottom = m
		var sh: float = spec[0]
		t.expand_margin_left = sh; t.expand_margin_right = sh; t.expand_margin_top = sh; t.expand_margin_bottom = sh
		sb = t
	else:
		var f := StyleBoxFlat.new(); f.bg_color = Color(0.1, 0.075, 0.05, 0.96); f.set_corner_radius_all(10)
		f.border_color = Color(0.78, 0.62, 0.34); f.set_border_width_all(2); sb = f
	sb.content_margin_left = pad.x; sb.content_margin_top = pad.y; sb.content_margin_right = pad.z; sb.content_margin_bottom = pad.w
	_cache[key] = sb
	return sb

## "normal", "hover", "pressed", "disabled"
static func button(state := "normal", pad_x := 14.0) -> StyleBox:
	var key := "btn_%s%d" % [state, int(pad_x)]
	if _cache.has(key): return _cache[key]
	var p := UI + "btn_%s.png" % state
	var sb: StyleBox
	if ResourceLoader.exists(p):
		var t := StyleBoxTexture.new(); t.texture = load(p)
		t.texture_margin_left = 12; t.texture_margin_right = 12; t.texture_margin_top = 12; t.texture_margin_bottom = 12
		sb = t
	else:
		var f := StyleBoxFlat.new(); f.bg_color = Color(0.45, 0.12, 0.08); f.set_corner_radius_all(6); sb = f
	sb.content_margin_left = pad_x; sb.content_margin_right = pad_x; sb.content_margin_top = 4; sb.content_margin_bottom = 4
	_cache[key] = sb
	return sb

static func style_button(b: Button, pad_x := 14.0) -> void:
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, button(st, pad_x))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color(1, 0.88, 0.6))
	b.add_theme_color_override("font_hover_color", Color(1, 0.96, 0.8))
	b.add_theme_color_override("font_pressed_color", Color(0.95, 0.82, 0.55))
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.56, 0.5))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8)); b.add_theme_constant_override("outline_size", 3)

## the ornamental line under a window title
static func divider() -> Control:
	var p := UI + "divider.png"
	if ResourceLoader.exists(p):
		var t := TextureRect.new(); t.texture = load(p); t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; t.stretch_mode = TextureRect.STRETCH_SCALE
		t.custom_minimum_size = Vector2(0, 14); t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return t
	var line := ColorRect.new(); line.color = Color(0.78, 0.62, 0.34, 0.45); line.custom_minimum_size = Vector2(0, 1)
	return line
