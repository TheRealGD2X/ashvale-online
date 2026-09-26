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
	"straw_bundle": "straw", "rat_tail": "tail", "chicken_egg": "egg", "scratch_claw": "claw", "boar_king_tusk": "tusk_sword",
	"hearthstone": "hearth", "old_tusks_tusk": "tusk"}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_item(it) -> void:
	item = it; queue_redraw()

static func kind_of(d: Dictionary, id: String) -> String:
	if BY_ID.has(id) and not d.has("wtype"): return BY_ID[id]
	if d.has("wtype"): return d["wtype"]
	if d.has("slot"): return Items.slot_of(d)
	return "bag"

## the rendered icon for an item: res://assets/icons/items/<key>.png (made by art/item_icons.py)
const ICON_ID := {"hearthstone": "hearth", "warm_meal": "stew", "hearty_stew": "stew_hearty", "spring_water": "water", "mountain_water": "water",
	"minor_healing_potion": "potion_s", "healing_potion_mid": "potion_m", "major_healing_potion": "potion_l", "hen_feather": "feather",
	"boar_hide": "hide", "grave_token": "token_grave", "old_coin": "coin", "rowans_letter": "letter", "brunnas_letter": "letter",
	"vales_letter": "letter", "roarks_dispatch": "dispatch", "aldrics_dispatch": "dispatch", "greaves_requisition": "dispatch",
	"marens_cargo_note": "dispatch", "neds_notes": "notes", "lamb_bell": "bell", "old_tusks_tusk": "tusk", "cracked_tusk": "tusk",
	"boar_king_tusk": "tusk", "khar_horn_chip": "horn_chip", "highland_bloom": "bloom", "soul_shard": "soul_shard", "sanctum_key": "key_void",
	"skarrs_key": "key_iron", "cultist_robe_scrap": "robe_scrap", "guardian_arrow_scrap": "arrow_broken", "guardian_arrow": "arrow",
	"khar_ledger": "ledger", "moras_seal": "seal", "highland_oats": "oats", "sentinel_core": "core", "goblin_ear": "ear",
	"viper_fang": "fang", "charred_fang": "fang_charred", "frost_fang": "fang_frost", "moth_wing": "moth_wing", "viper_gland": "gland",
	"moth_dust": "dust", "totem_smashed": "totem", "warlords_horn": "war_horn", "elsbeths_map": "map", "grave_blessing": "blessing",
	"maggot_meat": "meat", "bat_wing": "bat_wing", "maggot_goo": "goo", "spider_silk": "silk", "rough_stone": "stone",
	"miners_wages": "purse", "sages_ink": "ink", "matted_fur": "fur", "puglin_trinket": "trinket_shiny", "bone_fragment": "bones",
	"brimstone_chip": "brimstone", "straw_bundle": "straw", "rat_tail": "tail", "chicken_egg": "egg", "crab_shell": "crab_shell",
	"wreckers_trinket": "compass", "sea_glass": "sea_glass", "serpent_scale": "scale_sea", "slag_lump": "slag", "drake_scale": "scale_fire",
	"perfect_drake_scale": "scale_fire", "obsidian_shard": "obsidian", "obsidian_shard_q": "obsidian", "rime_crystal": "rime_crystal",
	"ram_wool": "wool", "void_ichor": "goo_void", "voidstone": "voidstone", "tender_claw": "claw", "scratch_claw": "claw",
	"lamp_oil_cask": "cask", "dry_driftwood": "driftwood", "drowned_locket": "locket", "thick_white_pelt": "pelt_white",
	"ram_horn": "ram_horn", "rune_shard": "rune_shard", "void_ichor_q": "vial_void", "salted_fish": "fish", "gullhaven_chowder": "chowder",
	"black_iron_ore": "m_ore_2"}

## what colour family an item's name suggests (ember rings are red, tide rings are blue...)
static func hue_of(nm: String) -> String:
	for pair in [["fire", ["ember", "cinder", "furnace", "molten", "forge", "fire", "flame", "ashen", "ashfall", "ashworks", "azhul"]],
			["sea", ["tide", "coral", "salt", "lake", "sea", "pearl", "drown", "merrow", "harbo", "ferry", "silt", "bosun"]],
			["void", ["void", "unmade", "hollow", "undying", "barrow", "crown", "lich", "vaal", "silent", "last watch", "cult"]],
			["frost", ["frost", "winter", "ice", "rime", "snow", "white"]],
			["nature", ["wood", "heather", "warden", "marsh", "mire", "witch", "plough", "vale"]]]:
		for w in pair[1]:
			if nm.contains(w): return pair[0]
	return "gold"

static func key_of(d: Dictionary, id: String) -> String:
	if ICON_ID.has(id): return ICON_ID[id]
	if id.begins_with("token_"): return "tok_" + id.trim_prefix("token_")
	if d.has("mat"): return "m_%s_%d" % [d["mat"], int(d.get("tier", 1))]
	var nm := String(d.get("name", "")).to_lower()
	if d.has("wtype"): return "w_" + String(d.get("model", Items.WTYPE.get(d["wtype"], [0, "sword"])[1]))
	var slot := Items.slot_of(d)
	var look: Array = d.get("look", [])
	if look.size() >= 3 and slot != "neck":
		return "a_%s_%d" % [look[0], clampi(int(look[2]), 1, 3)]
	var h := hue_of(nm)
	match slot:
		"finger": return ("j_signet_" if nm.contains("signet") else "j_band_") + h
		"neck":
			if nm.contains("bell"): return "j_bell"
			if nm.contains("beads"): return "j_beads"
			if nm.contains("pearl"): return "j_pearl"
			if nm.contains("charm") or nm.contains("fletching"): return "j_charm"
			return "j_pendant_" + h
		"trinket":
			for pair in [["lantern", "t_lantern"], ["whistle", "t_whistle"], ["golem", "t_golem"], ["heart", "t_ember_heart"], ["ember", "t_ember_heart"],
					["tome", "t_tome"], ["page", "t_tome"], ["eye", "t_eye"], ["claw", "claw"], ["shard", "t_frost_shard"], ["focus", "t_obsidian"],
					["voidglass", "t_voidglass"], ["bowstring", "t_bowstring"], ["charm", "t_charm"]]:
				if nm.contains(pair[0]): return pair[1]
			return "t_charm"
		"head":
			if nm.contains("cowl") or nm.contains("hood"): return "g_cowl_" + h
			if nm.contains("bell"): return "g_crown_bell"
			if nm.contains("crown") or nm.contains("bone"): return "g_crown_bone"
			return "g_circlet_" + h
		"back":
			if nm.contains("hide") or nm.contains("pelt") or nm.contains("fur"): return "g_cloak_fur" if h == "frost" else "g_cloak_hide"
			return "g_cloak_" + h
		"waist":
			match String(d.get("armor_type", "cloth")):
				"leather": return "g_belt"
				"mail", "plate": return "g_girdle_" + String(d["armor_type"])
			return "g_cord_" + h
		"wrist": return "g_wraps_" + h if d.get("armor_type", "cloth") == "cloth" else "g_bracers"
		"hands": return "g_gloves"
	return ""

static var _tex := {}
static func tex_for(key: String) -> Texture2D:
	if key == "": return null
	if not _tex.has(key):
		var p := "res://assets/icons/items/%s.png" % key
		_tex[key] = load(p) if ResourceLoader.exists(p) else null
	return _tex[key]

static var _frames := {}
static func frame_tex(q: int) -> Texture2D:
	if not _frames.has(q):
		var p := "res://assets/ui/frame_q%d.png" % q
		_frames[q] = load(p) if ResourceLoader.exists(p) else null
	return _frames[q]

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var s := size.x
	var c0 := size * 0.5
	if item == null:
		draw_rect(r, Color(0.06, 0.05, 0.045, 0.85))
		var eg := tex_for("e_" + empty_hint) if empty_hint != "" else null
		if eg: draw_texture_rect(eg, r.grow(-s * 0.08), false, Color(1, 1, 1, 0.55))
		elif empty_hint != "": _symbol(empty_hint, c0, s, Color(0.35, 0.32, 0.28, 0.6), Color(0.3, 0.28, 0.25, 0.4), true)
		var ef := frame_tex(0)
		if ef: draw_texture_rect(ef, r, false, Color(0.7, 0.7, 0.7))
		else: draw_rect(r, Color(0.35, 0.3, 0.22, 0.8), false, 2.0)
		return
	var d := Items.get_def(item)
	var q := Items.color(d)
	var qi := clampi(int(d.get("q", 1)), 0, 5)
	var id := String(item.get("id", ""))
	var t := tex_for(key_of(d, id))
	var fr := frame_tex(qi)
	if t:
		var inset := s * (0.075 if fr else 0.0)
		draw_texture_rect(t, r.grow(-inset), false)
	else:
		for i in 12:
			var k := float(i) / 12.0
			var ins := size * 0.5 * k
			draw_rect(Rect2(ins, size - ins * 2.0), Color(0.07, 0.06, 0.05).lerp(q.darkened(0.72), k * 0.9))
		_symbol(kind_of(d, id), c0, s, Color(0.92, 0.9, 0.84), _accent(d, kind_of(d, id)), false)
	if dim > 0.0: draw_rect(r, Color(0, 0, 0, dim))
	if fr: draw_texture_rect(fr, r, false)
	else:
		var bc := q if qi >= 2 else Color(0.4, 0.36, 0.3)
		draw_rect(r, bc, false, 2.5)
	if hover: draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color(1, 0.95, 0.7, 0.45), false, 2.0)
	var n := int(item.get("n", 1))
	if n > 1:
		var f := ThemeDB.fallback_font
		var fs := int(s * 0.3)
		var txt := str(n)
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2(s - w - s * 0.1, s - s * 0.1)
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
		"hearth":
			_p(_ellipse(v.call(0, 0.04), s * 0.3, s * 0.26), Color(0.45, 0.5, 0.6))
			_p(_ellipse(v.call(-0.04, -0.02), s * 0.18, s * 0.14), Color(0.58, 0.63, 0.72))
			draw_arc(v.call(0, 0.04), s * 0.12, 0, TAU, 16, Color(0.5, 0.85, 1.0), s * 0.05)
			draw_circle(v.call(0, 0.04), s * 0.04, Color(0.8, 0.95, 1.0))
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
