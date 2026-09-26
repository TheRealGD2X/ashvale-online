class_name ChatBox extends Control
## The chat window, bottom left, as in WoW: General chat for the whole zone, Say for people
## nearby, whispers, your group, and yellow system lines (loot, quests). Press Enter to type.
##   /s  say        /g  general        /p  party        /w Name  whisper        /r  reply
## Simulated players read what you write (the "bots" group gets hear()) and may answer.

const COLORS := {"say": Color(1, 1, 1), "general": Color(1.0, 0.78, 0.6), "whisper": Color(1.0, 0.5, 1.0),
	"party": Color(0.55, 0.75, 1.0), "system": Color(1.0, 0.95, 0.4), "loot": Color(0.2, 0.9, 0.3), "npc": Color(1.0, 1.0, 0.62), "yell": Color(1.0, 0.25, 0.2)}

var log_box: RichTextLabel
var input: LineEdit
var channel := "say"
var last_whisper := ""
var lines: Array = []
var fade_t := 0.0
var player: Player

func _ready() -> void:
	add_to_group("chat")
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 20; offset_top = -330; offset_right = 520; offset_bottom = -40
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := Panel.new(); bg.set_anchors_preset(Control.PRESET_FULL_RECT); bg.offset_bottom = -34; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0, 0, 0, 0.28); sb.set_corner_radius_all(6)
	bg.add_theme_stylebox_override("panel", sb); add_child(bg); bg.name = "Bg"
	log_box = RichTextLabel.new(); log_box.bbcode_enabled = true; log_box.scroll_following = true
	log_box.set_anchors_preset(Control.PRESET_FULL_RECT); log_box.offset_left = 8; log_box.offset_top = 6; log_box.offset_right = -6; log_box.offset_bottom = -38
	log_box.add_theme_font_size_override("normal_font_size", 16); log_box.add_theme_font_size_override("bold_font_size", 16)
	log_box.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9)); log_box.add_theme_constant_override("shadow_offset_y", 1); log_box.add_theme_constant_override("shadow_offset_x", 1)
	log_box.mouse_filter = Control.MOUSE_FILTER_PASS
	log_box.meta_clicked.connect(_on_name)
	add_child(log_box)
	input = LineEdit.new(); input.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); input.offset_top = -32; input.offset_bottom = 0
	input.placeholder_text = "Press Enter to chat"; input.visible = false
	input.add_theme_font_size_override("font_size", 16)
	input.text_submitted.connect(_send)
	add_child(input)

func is_typing() -> bool:
	return input.visible and input.has_focus()

func open_input(prefix := "") -> void:
	input.visible = true; input.text = prefix; input.grab_focus(); input.caret_column = prefix.length()
	_chan_hint()

func _chan_hint() -> void:
	input.placeholder_text = {"say": "Say:", "general": "General:", "party": "Party:", "whisper": "To %s:" % last_whisper}.get(channel, "Say:")

func _unhandled_key_input(e: InputEvent) -> void:
	if e.pressed and not e.echo and e.physical_keycode in [KEY_ENTER, KEY_KP_ENTER] and not input.has_focus():
		open_input(); get_viewport().set_input_as_handled()
	elif e.pressed and e.physical_keycode == KEY_SLASH and not input.has_focus():
		open_input("/"); get_viewport().set_input_as_handled()

func _input(e: InputEvent) -> void:
	if input.has_focus() and e is InputEventKey and e.pressed and e.physical_keycode == KEY_ESCAPE:
		input.text = ""; input.release_focus(); input.visible = false; get_viewport().set_input_as_handled()

func _send(text: String) -> void:
	input.release_focus(); input.visible = false; input.text = ""
	text = text.strip_edges()
	if text == "" or player == null: return
	var ch := channel
	var to := last_whisper
	if text.begins_with("/"):
		var parts := text.split(" ", false, 2)
		var cmd := parts[0].to_lower()
		match cmd:
			"/s", "/say": ch = "say"; text = text.substr(parts[0].length()).strip_edges()
			"/g", "/1", "/general": ch = "general"; text = text.substr(parts[0].length()).strip_edges()
			"/p", "/party": ch = "party"; text = text.substr(parts[0].length()).strip_edges()
			"/w", "/whisper", "/t", "/tell":
				if parts.size() < 3: post("system", "", "Whisper who? /w Name message"); return
				ch = "whisper"; to = parts[1]; text = parts[2]
			"/r", "/reply":
				if last_whisper == "": post("system", "", "Nobody has whispered you yet."); return
				ch = "whisper"; to = last_whisper; text = text.substr(parts[0].length()).strip_edges()
			"/invite", "/inv":
				if parts.size() < 2: return
				get_tree().call_group("bots", "invited", player, parts[1]); return
			"/leave":
				get_tree().call_group("bots", "leave_party", player); return
			"/who":
				var names := []
				for b in get_tree().get_nodes_in_group("bots"): names.append("%s (%d %s)" % [b.uname, b.level, Rules.CLASSES[b.cls]["name"]])
				post("system", "", "%d players in Ashvale: %s" % [names.size(), ", ".join(names)]); return
			_:
				post("system", "", "Unknown command. Try /s /g /p /w Name /r /invite Name /leave /who"); return
		channel = ch
		if ch == "whisper": last_whisper = to
	if text == "": return
	if ch == "whisper":
		post("whisper_out", to, text)
	else:
		post(ch, player.uname, text)
	get_tree().call_group("bots", "hear", ch, player, text, to)

## add a line. channel: say | general | party | whisper (incoming) | whisper_out | system | loot | npc | yell
func post(ch: String, who: String, text: String) -> void:
	var col: Color = COLORS.get(ch if ch != "whisper_out" else "whisper", Color.WHITE)
	var c := col.to_html(false)
	var line := ""
	match ch:
		"say": line = "[color=#%s][url=%s][%s][/url] says: %s[/color]" % [c, who, who, _esc(text)]
		"yell": line = "[color=#%s][url=%s][%s][/url] yells: %s[/color]" % [c, who, who, _esc(text)]
		"general": line = "[color=#%s][1. General] [url=%s][%s][/url]: %s[/color]" % [c, who, who, _esc(text)]
		"party": line = "[color=#%s][Party] [url=%s][%s][/url]: %s[/color]" % [c, who, who, _esc(text)]
		"whisper":
			line = "[color=#%s][url=%s][%s][/url] whispers: %s[/color]" % [c, who, who, _esc(text)]
			last_whisper = who
			get_tree().call_group("fx", "sound", "whisper", null, -10.0, 0.0)
		"whisper_out": line = "[color=#%s]To [url=%s][%s][/url]: %s[/color]" % [c, who, who, _esc(text)]
		"npc": line = "[color=#%s]%s says: %s[/color]" % [c, who, _esc(text)]
		_: line = "[color=#%s]%s[/color]" % [c, _esc(text) if ch != "loot" else text]
	log_box.append_text(line + "\n")
	lines.append(line)
	if lines.size() > 200:
		lines = lines.slice(100)
		log_box.clear()
		for l in lines: log_box.append_text(l + "\n")
	fade_t = 12.0

func _esc(t: String) -> String:
	return t.replace("[", "(").replace("]", ")")

func _on_name(meta) -> void:
	last_whisper = str(meta); channel = "whisper"
	open_input("")

func _process(delta: float) -> void:
	# the chat fades when nothing has happened for a while
	fade_t -= delta
	var a := 1.0 if fade_t > 0.0 or input.visible else clampf(1.0 + fade_t / 3.0, 0.35, 1.0)
	log_box.modulate.a = a
	get_node("Bg").modulate.a = a
