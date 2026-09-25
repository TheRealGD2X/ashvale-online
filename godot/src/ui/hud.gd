extends CanvasLayer
## A light touch on screen: the place and time of day (top left), a controls card that fades
## after a while (F1 brings it back), frames per second on F3, F11 for fullscreen, Esc to quit.

var clock: Label
var place: Label
var help: PanelContainer
var fps: Label
var help_t := 25.0

func _ready() -> void:
	var font := SystemFont.new(); font.font_names = PackedStringArray(["Georgia", "Palatino Linotype", "Book Antiqua", "serif"])
	var th := Theme.new(); th.default_font = font; th.default_font_size = 20
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.theme = th
	add_child(root)
	place = _label(root, "Ashvale", 30, Vector2(28, 20)); place.add_theme_color_override("font_color", Color(0.98, 0.9, 0.7))
	clock = _label(root, "", 18, Vector2(30, 60))
	fps = _label(root, "", 16, Vector2(30, 88)); fps.visible = false
	help = PanelContainer.new(); root.add_child(help)
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.08, 0.07, 0.06, 0.62); sb.set_corner_radius_all(10); sb.content_margin_left = 18; sb.content_margin_right = 18; sb.content_margin_top = 12; sb.content_margin_bottom = 12
	sb.border_color = Color(0.89, 0.76, 0.5, 0.5); sb.set_border_width_all(1)
	help.add_theme_stylebox_override("panel", sb)
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); help.position = Vector2(26, -200); help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var t := Label.new(); t.add_theme_font_size_override("font_size", 17); t.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	t.text = "WASD  move      Shift  run      Ctrl  walk      Space  jump\nLeft-click the ground  walk there\nRight-drag  turn the camera      Wheel  zoom      Q / E  turn\nHold T  speed up time      F1  this card      F3  FPS      F11  fullscreen      Esc  quit"
	help.add_child(t)
	help.anchor_top = 1.0; help.anchor_bottom = 1.0; help.offset_top = -150; help.offset_bottom = -26; help.offset_left = 26

func _label(parent: Control, text: String, size: int, pos: Vector2) -> Label:
	var l := Label.new(); l.text = text; l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6)); l.add_theme_constant_override("shadow_offset_x", 1); l.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(l)
	return l

func _process(delta: float) -> void:
	var h := DayNight.hour
	var hh := int(h); var mm := int((h - hh) * 60.0)
	var part := "Night"
	if h >= 5.0 and h < 7.5: part = "Dawn"
	elif h >= 7.5 and h < 12.0: part = "Morning"
	elif h >= 12.0 and h < 17.0: part = "Afternoon"
	elif h >= 17.0 and h < 20.5: part = "Evening"
	clock.text = "%s  ·  %02d:%02d" % [part, hh, mm]
	if help_t > 0.0:
		help_t -= delta
		help.modulate.a = clampf(help_t / 2.0, 0.0, 1.0)
	fps.text = "%d fps" % Engine.get_frames_per_second()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_F1: help_t = 25.0 if help.modulate.a < 0.5 else 0.0; help.modulate.a = 1.0 if help_t > 0 else 0.0
			KEY_F3: fps.visible = not fps.visible
			KEY_F11:
				var w := get_window()
				w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN or w.mode == Window.MODE_EXCLUSIVE_FULLSCREEN else Window.MODE_FULLSCREEN
			KEY_ESCAPE: get_tree().quit()
