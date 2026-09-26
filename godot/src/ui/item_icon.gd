class_name ItemIcon extends Control
## A painted item icon, like the ability icons: a small picture of the thing (a sword, a robe, a
## boot, a bowl of stew, a feather...) on a dark tile with a border in the item's quality colour,
## and the stack count in the corner.

var item = null                # a bag item {"id", "n", ...} or null
var empty_hint := ""           # for an empty paper-doll slot: which slot it is ("head", "feet"...)
var dim := 0.0
var hover := false

const BY_ID := {"warm_meal": "stew", "spring_water": "flask", "minor_healing_potion": "potion", "hen_feather": "feather",
	"boar_hide": "hide", "grave_token": "token", "old_coin": "coin", "rowans_letter": "letter", "lamb_bell": "bell", "sages_ink": "ink",
	"cracked_tusk": "tusk", "matted_fur": "hide", "puglin_trinket": "gem", "bone_fragment": "bone", "brimstone_chip": "gem",
	"straw_bundle": "straw", "rat_tail": "tail", "chicken_egg": "egg", "scratch_claw": "claw", "boar_king_tusk": "tusk_sword"}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_item(it) -> void:
	item = it; queue_redraw()

static func kind_of(d: Dictionary, id: String) -> String:
	if BY_ID.has(id) and not d.has("wtype"): return BY_ID[id]
	if d.has("wtype"): return d["wtype"]
	if d.has("slot"): return Items.slot_of(d)
	return "bag"

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var s := size.x
	var c0 := size * 0.5
	if item == null:
		draw_rect(r, Color(0.06, 0.05, 0.045, 0.85))
		if empty_hint != "": _symbol(empty_hint, c0, s, Color(0.35, 0.32, 0.28, 0.6), Color(0.3, 0.28, 0.25, 0.4), true)
		draw_rect(r, Color(0.35, 0.3, 0.22, 0.8), false, 2.0)
		return
	var d := Items.get_def(item)
	var q := Items.color(d)
	# tile: a warm dark gradient with a little of the quality colour in the middle
	for i in 12:
		var t := float(i) / 12.0
		var inset := size * 0.5 * t
		draw_rect(Rect2(inset, size - inset * 2.0), Color(0.07, 0.06, 0.05).lerp(q.darkened(0.72), t * 0.9))
	var fg := Color(0.92, 0.9, 0.84)
	var kind := kind_of(d, String(item.get("id", "")))
	_symbol(kind, c0, s, fg, _accent(d, kind), false)
	if dim > 0.0: draw_rect(r, Color(0, 0, 0, dim))
	# border in the quality colour (grey and white items get a plain border)
	var bc := q if int(d.get("q", 1)) >= 2 else Color(0.4, 0.36, 0.3)
	draw_rect(r, bc, false, 2.5)
	if hover: draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(1, 0.95, 0.7, 0.5), false, 2.0)
	var n := int(item.get("n", 1))
	if n > 1:
		var f := ThemeDB.fallback_font
		var fs := int(s * 0.3)
		var txt := str(n)
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2(s - w - 4, s - 5)
		draw_string_outline(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0))
		draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1))

func _accent(d: Dictionary, kind: String) -> Color:
	match d.get("armor_type", ""):
		"cloth": return Color(0.45, 0.35, 0.7) if d.get("look", ["", "Wizard"])[1] == "Wizard" else Color(0.7, 0.25, 0.25)
		"leather": return Color(0.55, 0.38, 0.22)
		"mail", "plate": return Color(0.7, 0.72, 0.78)
	return Color(0.85, 0.7, 0.35)

func _p(pts: Array, c: Color) -> void:
	draw_colored_polygon(PackedVector2Array(pts), c)

## the little pictures; v() places a point in the tile (-0.5..0.5)
func _symbol(kind: String, c0: Vector2, s: float, fg: Color, ac: Color, ghost: bool) -> void:
	var v := func(x: float, y: float) -> Vector2: return c0 + Vector2(x, y) * s
	var wood := Color(0.5, 0.32, 0.17) if not ghost else fg
	var steel := Color(0.85, 0.87, 0.92) if not ghost else fg
	match kind:
		"sword", "two_hand_sword", "dagger", "tusk_sword":
			_p([v.call(-0.3, 0.3), v.call(0.24, -0.3), v.call(0.32, -0.32), v.call(0.3, -0.24), v.call(-0.26, 0.34)], steel if kind != "tusk_sword" else Color(0.95, 0.9, 0.75))
			draw_line(v.call(-0.36, 0.14), v.call(-0.14, 0.36), ac, s * 0.07)
			draw_line(v.call(-0.3, 0.3), v.call(-0.4, 0.4), wood, s * 0.07)
		"axe", "two_hand_axe":
			draw_line(v.call(-0.3, 0.38), v.call(0.2, -0.3), wood, s * 0.07)
			_p([v.call(0.05, -0.32), v.call(0.36, -0.2), v.call(0.3, 0.08), v.call(0.12, -0.06)], steel)
		"mace":
			draw_line(v.call(-0.3, 0.36), v.call(0.12, -0.1), wood, s * 0.08)
			draw_circle(v.call(0.18, -0.18), s * 0.15, steel)
			for k in 6:
				var a := TAU * k / 6.0
				draw_circle(v.call(0.18 + cos(a) * 0.15, -0.18 + sin(a) * 0.15), s * 0.045, steel.darkened(0.2))
		"staff":
			draw_line(v.call(-0.32, 0.4), v.call(0.22, -0.26), wood, s * 0.07)
			draw_circle(v.call(0.26, -0.3), s * 0.1, Color(0.55, 0.8, 1.0) if not ghost else fg)
			draw_circle(v.call(0.24, -0.32), s * 0.04, Color(1, 1, 1, 0.9))
		"wand":
			draw_line(v.call(-0.26, 0.3), v.call(0.2, -0.2), wood.lightened(0.2), s * 0.06)
			draw_circle(v.call(0.23, -0.23), s * 0.07, Color(1.0, 0.8, 0.4) if not ghost else fg)
		"shield", "offhand":
			_p([v.call(-0.28, -0.32), v.call(0.28, -0.32), v.call(0.26, 0.08), v.call(0, 0.38), v.call(-0.26, 0.08)], ac)
			_p([v.call(-0.16, -0.2), v.call(0.16, -0.2), v.call(0.14, 0.04), v.call(0, 0.22), v.call(-0.14, 0.04)], fg)
		"chest":
			_p([v.call(-0.2, -0.34), v.call(-0.06, -0.3), v.call(0.06, -0.3), v.call(0.2, -0.34), v.call(0.36, -0.14), v.call(0.26, -0.02), v.call(0.2, -0.1),
				v.call(0.2, 0.36), v.call(-0.2, 0.36), v.call(-0.2, -0.1), v.call(-0.26, -0.02), v.call(-0.36, -0.14)], ac)
			draw_line(v.call(0, -0.28), v.call(0, 0.34), ac.darkened(0.35), s * 0.03)
			draw_line(v.call(-0.2, 0.12), v.call(0.2, 0.12), fg.darkened(0.3), s * 0.04)
		"legs":
			_p([v.call(-0.22, -0.34), v.call(0.22, -0.34), v.call(0.24, 0.38), v.call(0.06, 0.38), v.call(0, -0.08), v.call(-0.06, 0.38), v.call(-0.24, 0.38)], ac)
			draw_line(v.call(-0.22, -0.26), v.call(0.22, -0.26), fg.darkened(0.3), s * 0.04)
		"feet":
			_p([v.call(-0.14, -0.34), v.call(0.1, -0.34), v.call(0.1, 0.14), v.call(0.36, 0.2), v.call(0.36, 0.34), v.call(-0.16, 0.34)], ac)
			draw_line(v.call(-0.14, -0.2), v.call(0.1, -0.2), fg.darkened(0.3), s * 0.04)
		"hands":
			_p([v.call(-0.2, 0.36), v.call(-0.2, -0.06), v.call(-0.3, -0.16), v.call(-0.22, -0.24), v.call(-0.1, -0.12), v.call(-0.1, -0.36), v.call(0.2, -0.36), v.call(0.22, 0.36)], ac)
			for k in 3: draw_line(v.call(-0.02 + k * 0.08, -0.36), v.call(-0.02 + k * 0.08, -0.14), ac.darkened(0.35), s * 0.02)
		"head":
			draw_arc(v.call(0, 0.08), s * 0.3, PI, TAU, 20, ac, s * 0.14)
			_p([v.call(-0.36, 0.1), v.call(0.36, 0.1), v.call(0.3, 0.2), v.call(-0.3, 0.2)], ac.darkened(0.2))
		"shoulders":
			draw_arc(v.call(-0.16, 0.1), s * 0.18, PI, TAU, 14, ac, s * 0.14)
			draw_arc(v.call(0.16, 0.1), s * 0.18, PI, TAU, 14, ac, s * 0.14)
		"wrist":
			draw_rect(Rect2(v.call(-0.24, -0.14), Vector2(0.48, 0.28) * s), ac)
			draw_line(v.call(-0.24, 0), v.call(0.24, 0), fg.darkened(0.3), s * 0.03)
		"waist":
			draw_rect(Rect2(v.call(-0.4, -0.08), Vector2(0.8, 0.16) * s), ac)
			draw_rect(Rect2(v.call(-0.09, -0.12), Vector2(0.18, 0.24) * s), Color(0.9, 0.75, 0.35) if not ghost else fg, false, s * 0.04)
		"back":
			_p([v.call(-0.16, -0.34), v.call(0.16, -0.34), v.call(0.32, 0.36), v.call(-0.32, 0.36)], ac)
		"neck":
			draw_arc(v.call(0, -0.12), s * 0.26, 0.1, PI - 0.1, 20, Color(0.9, 0.78, 0.4) if not ghost else fg, s * 0.04)
			draw_circle(v.call(0, 0.2), s * 0.1, Color(0.4, 0.8, 0.95) if not ghost else fg)
		"finger":
			draw_arc(v.call(0, 0.06), s * 0.22, 0, TAU, 24, Color(0.9, 0.78, 0.4) if not ghost else fg, s * 0.07)
			draw_circle(v.call(0, -0.18), s * 0.08, Color(0.85, 0.3, 0.35) if not ghost else fg)
		"trinket", "claw":
			_p([v.call(-0.1, -0.34), v.call(0.14, -0.3), v.call(0.2, 0.0), v.call(0.02, 0.36), v.call(-0.04, 0.0)], Color(0.92, 0.88, 0.75) if not ghost else fg)
		"stew":
			draw_arc(v.call(0, 0.0), s * 0.32, 0.0, PI, 20, Color(0.55, 0.36, 0.2), s * 0.12)
			draw_rect(Rect2(v.call(-0.34, -0.04), Vector2(0.68, 0.08) * s), Color(0.8, 0.45, 0.2))
			for k in 3: draw_arc(v.call(-0.12 + k * 0.12, -0.2), s * 0.06, PI, TAU, 8, Color(1, 1, 1, 0.5), s * 0.02)
		"flask":
			_p([v.call(-0.08, -0.36), v.call(0.08, -0.36), v.call(0.08, -0.14), v.call(0.26, 0.12), v.call(0.22, 0.36), v.call(-0.22, 0.36), v.call(-0.26, 0.12), v.call(-0.08, -0.14)], Color(0.5, 0.75, 1.0, 0.95))
			draw_rect(Rect2(v.call(-0.1, -0.4), Vector2(0.2, 0.08) * s), wood)
		"potion":
			draw_circle(v.call(0, 0.12), s * 0.24, Color(0.9, 0.15, 0.15))
			draw_rect(Rect2(v.call(-0.07, -0.34), Vector2(0.14, 0.24) * s), Color(0.8, 0.8, 0.85, 0.8))
			draw_circle(v.call(-0.08, 0.04), s * 0.06, Color(1, 1, 1, 0.6))
		"feather":
			_p([v.call(0.3, -0.36), v.call(0.12, 0.1), v.call(-0.3, 0.34), v.call(-0.02, -0.08)], Color(0.95, 0.92, 0.85))
			draw_line(v.call(0.3, -0.36), v.call(-0.34, 0.38), Color(0.5, 0.4, 0.3), s * 0.025)
		"hide":
			_p([v.call(-0.3, -0.2), v.call(-0.1, -0.32), v.call(0.2, -0.28), v.call(0.34, -0.06), v.call(0.26, 0.26), v.call(-0.04, 0.34), v.call(-0.32, 0.18)], Color(0.55, 0.38, 0.24))
		"token", "coin":
			draw_circle(c0, s * 0.28, Color(0.8, 0.65, 0.3) if kind == "coin" else Color(0.55, 0.55, 0.58))
			draw_arc(c0, s * 0.22, 0, TAU, 24, Color(0.45, 0.35, 0.15), s * 0.03)
			if kind == "token": draw_line(v.call(-0.1, -0.1), v.call(0.1, 0.1), Color(0.2, 0.2, 0.2), s * 0.04); draw_line(v.call(0.1, -0.1), v.call(-0.1, 0.1), Color(0.2, 0.2, 0.2), s * 0.04)
		"letter":
			draw_rect(Rect2(v.call(-0.34, -0.22), Vector2(0.68, 0.44) * s), Color(0.95, 0.9, 0.78))
			_p([v.call(-0.34, -0.22), v.call(0.34, -0.22), v.call(0, 0.06)], Color(0.85, 0.8, 0.66))
			draw_circle(v.call(0, 0.06), s * 0.07, Color(0.75, 0.1, 0.1))
		"bell":
			_p([v.call(-0.06, -0.3), v.call(0.06, -0.3), v.call(0.26, 0.2), v.call(-0.26, 0.2)], Color(0.85, 0.66, 0.25))
			draw_circle(v.call(0, 0.26), s * 0.06, Color(0.5, 0.4, 0.2))
		"ink":
			_p([v.call(-0.2, -0.1), v.call(0.2, -0.1), v.call(0.24, 0.34), v.call(-0.24, 0.34)], Color(0.15, 0.15, 0.3))
			draw_line(v.call(0.05, -0.08), v.call(0.3, -0.4), Color(0.95, 0.92, 0.85), s * 0.04)
		"tusk":
			draw_arc(v.call(0.1, 0.12), s * 0.3, PI * 0.9, PI * 1.7, 16, Color(0.95, 0.9, 0.75), s * 0.1)
		"bone":
			draw_line(v.call(-0.26, 0.26), v.call(0.26, -0.26), Color(0.92, 0.9, 0.82), s * 0.1)
			for p2 in [v.call(-0.3, 0.2), v.call(-0.2, 0.3), v.call(0.3, -0.2), v.call(0.2, -0.3)]: draw_circle(p2, s * 0.07, Color(0.92, 0.9, 0.82))
		"gem":
			_p([v.call(0, -0.3), v.call(0.26, -0.06), v.call(0, 0.32), v.call(-0.26, -0.06)], Color(0.95, 0.55, 0.2))
			_p([v.call(0, -0.3), v.call(0.1, -0.06), v.call(0, 0.32), v.call(-0.1, -0.06)], Color(1, 0.8, 0.5))
		"straw":
			for k in 7: draw_line(v.call(-0.2 + k * 0.066, 0.36), v.call(-0.1 + k * 0.035, -0.36), Color(0.9, 0.78, 0.4), s * 0.035)
			draw_line(v.call(-0.2, 0.02), v.call(0.2, 0.02), Color(0.5, 0.35, 0.15), s * 0.05)
		"tail":
			draw_arc(v.call(0, 0), s * 0.26, 0.3, TAU - 0.6, 20, Color(0.85, 0.6, 0.6), s * 0.05)
		"egg":
			_p(_ellipse(v.call(0, 0.04), s * 0.22, s * 0.3), Color(0.97, 0.93, 0.82))
		_:
			draw_rect(Rect2(v.call(-0.26, -0.2), Vector2(0.52, 0.5) * s), Color(0.55, 0.4, 0.25))
			draw_arc(v.call(0, -0.2), s * 0.14, PI, TAU, 10, Color(0.45, 0.3, 0.15), s * 0.05)

func _ellipse(c: Vector2, rx: float, ry: float) -> Array:
	var out := []
	for k in 20:
		var a := TAU * k / 20.0
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry * (1.0 if sin(a) > 0 else 1.15)))
	return out
