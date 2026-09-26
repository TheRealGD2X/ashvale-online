class_name Minimap extends Control
## The round map in the top-right corner, turning with the camera so "up" is where you look, and
## the big map on M. Both are painted once from the world's own data (ground height, roads, water,
## houses, fields) and show: you (the arrow), people with quests (! and ?), your group, other
## players, and a golden ring where each of your quest objectives can be done.

const WORLD := 256.0
const RES := 512
const PLACES := {"ashvale": [["Ashvale", Vector2(0, -2)], ["The Mill", Vector2(70, 2)], ["Old Shrine", Vector2(72, -94)], ["Eastern Woods", Vector2(106, -20)],
	["Beetfield", Vector2(74, 48)], ["West Fields", Vector2(-64, 26)], ["Rowan's Fields", Vector2(-28, 34)], ["Millstream Pond", Vector2(-42, 64)],
	["North Road", Vector2(-6, -70)], ["Split Oak", Vector2(94, 30)], ["Hollow Oak", Vector2(108, -46)]],
	"hollow": [["Miners' Camp", Vector2(8, 38)], ["The Scree", Vector2(-56, 24)], ["Upper Tunnels", Vector2(-36, -30)], ["Lantern Row", Vector2(30, -44)],
		["The Hollow Mine", Vector2(24, -96)], ["Skarr's Cut", Vector2(66, -2)], ["Rockjaw's Den", Vector2(76, 60)], ["The Cairn Field", Vector2(-84, -96)],
		["Hollow Road", Vector2(-8, 96)], ["Cliff Road", Vector2(104, 28)]],
	"mine": [["Entrance", Vector2(0, 118)], ["Diggers' Hall", Vector2(-32, 54)], ["The Grub Pit", Vector2(-54, -28)], ["The Deep Rails", Vector2(46, -24)],
		["Foreman's Gallery", Vector2(-2, -32)], ["The Hollow Throne", Vector2(0, -106)]],
	"saltmere": [["Gullhaven", Vector2(-40, 8)], ["The Pier", Vector2(68, 30)], ["Kelp Flats", Vector2(62, 20)], ["Gull Point", Vector2(50, -80)],
		["The Drowned Hold", Vector2(70, -96)], ["Wreck of the Merrow", Vector2(78, 66)], ["Wrecker's Cove", Vector2(52, 102)], ["Serpent Shore", Vector2(82, -20)],
		["Tidecaller Rocks", Vector2(92, -50)], ["The Salt Road", Vector2(-104, 6)], ["The Cinder Stair", Vector2(-14, -106)], ["The Sound", Vector2(104, 36)]],
	"emberreach": [["Forgehold", Vector2(20, 46)], ["The Lava Lake", Vector2(-44, -22)], ["The Ashworks", Vector2(-86, -82)], ["Black Glass Fields", Vector2(18, -50)],
		["The Molten Deep", Vector2(30, -98)], ["The Roost", Vector2(92, -8)], ["Charred Wood", Vector2(-50, 84)], ["Slag Fields", Vector2(-96, 42)],
		["The Frostgate", Vector2(-104, -46)], ["The Cinder Stair", Vector2(-12, 104)]],
	"palereach": [["Wintermere", Vector2(60, -30)], ["The Frozen Lake", Vector2(-20, 40)], ["The Wolfrun", Vector2(30, 62)], ["The Barrows", Vector2(-44, -62)],
		["Frostspire", Vector2(-100, -38)], ["Northern Pass", Vector2(8, -100)], ["East Slopes", Vector2(96, 30)], ["The Frostgate", Vector2(104, -48)]],
	"scar": [["The Last Watch", Vector2(0, 66)], ["The Wastes", Vector2(-64, 26)], ["Hollow Field", Vector2(-84, -52)], ["The Broken Road", Vector2(10, -40)],
		["The Void Pool", Vector2(44, -18)], ["Cult Ring", Vector2(-44, -84)], ["The Broken Crown", Vector2(84, -92)], ["East Rim", Vector2(90, 40)],
		["The Sanctum Gate", Vector2(0, -102)]],
	"drowned_hold": [["The Bilge", Vector2(0, 74)], ["Grell's Deck", Vector2(-34, 16)], ["The Brood Pool", Vector2(34, 16)], ["The Admiral's Hall", Vector2(0, -100)]],
	"molten_deep": [["The Slagworks", Vector2(0, 62)], ["Slagjaw's Pit", Vector2(-50, 4)], ["Tharn's Forge", Vector2(50, 4)], ["The Heart of the Mountain", Vector2(0, -104)]],
	"frostspire": [["The Cold Stair", Vector2(0, 68)], ["Ursoth's Den", Vector2(-40, 14)], ["The Witch's Hall", Vector2(40, 14)], ["The Frozen Throne", Vector2(0, -104)]]}

static var map_zone := ""

static var map_tex: Texture2D
var player: Player
var cam: Camera3D
var radius := 105.0
var zoom := 70.0                  # metres from centre to edge
var mat: ShaderMaterial
var tex_rect: TextureRect
var big: Control
var big_open := false

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(p: Player, c: Camera3D) -> void:
	player = p; cam = c
	if map_tex == null or map_zone != WorldData.zone_id: map_tex = _paint(); map_zone = WorldData.zone_id
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -radius * 2 - 26; offset_top = 96; offset_right = -26; offset_bottom = 96 + radius * 2
	tex_rect = TextureRect.new(); tex_rect.texture = map_tex; tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE; tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mat = ShaderMaterial.new(); mat.shader = _shader(); tex_rect.material = mat
	add_child(tex_rect)
	tex_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tex_rect.position = Vector2.ZERO; tex_rect.custom_minimum_size = Vector2(radius * 2, radius * 2); tex_rect.size = Vector2(radius * 2, radius * 2)

	var dots := Control.new(); dots.size = tex_rect.size; dots.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(dots)
	dots.draw.connect(func(): _draw_dots(dots))
	set_meta("dots", dots)

func _process(_d: float) -> void:
	if player == null: return
	var yaw := _cam_yaw()
	mat.set_shader_parameter("center", Vector2(player.global_position.x, player.global_position.z) / WORLD + Vector2(0.5, 0.5))
	mat.set_shader_parameter("span", zoom / WORLD)
	mat.set_shader_parameter("rot", yaw)
	(get_meta("dots") as Control).queue_redraw()
	if big_open and big: big.queue_redraw()

func _cam_yaw() -> float:
	if cam == null: return 0.0
	var f := -cam.global_basis.z; f.y = 0
	if f.length() < 0.01: return 0.0
	# rotation that turns the camera's forward to screen-up
	return atan2(f.x, -f.z)

## world (x, z) -> minimap pixels
func _to_mini(w: Vector2) -> Vector2:
	var d := (w - Vector2(player.global_position.x, player.global_position.z)) / zoom * radius
	return d.rotated(-_cam_yaw()) + Vector2(radius, radius)

func _draw_dots(c: Control) -> void:
	var font := ThemeDB.fallback_font
	# quest areas
	for spot in _quest_spots():
		var p := _to_mini(spot["at"])
		if p.distance_to(Vector2(radius, radius)) > radius - 6:
			# off the edge: a little arrow on the rim pointing at it
			var dir := (p - Vector2(radius, radius)).normalized()
			var rim := Vector2(radius, radius) + dir * (radius - 9)
			c.draw_colored_polygon(PackedVector2Array([rim + dir * 7, rim + dir.orthogonal() * 5, rim - dir.orthogonal() * 5]), Color(1, 0.85, 0.2, 0.95))
		else:
			c.draw_circle(p, maxf(7.0, spot["r"] / zoom * radius), Color(1, 0.82, 0.2, 0.22))
			c.draw_arc(p, maxf(7.0, spot["r"] / zoom * radius), 0, TAU, 24, Color(1, 0.85, 0.3, 0.8), 1.5)
	# other players and the group
	for b in get_tree().get_nodes_in_group("bots"):
		var p2 := _to_mini(Vector2(b.global_position.x, b.global_position.z))
		if p2.distance_to(Vector2(radius, radius)) < radius - 4:
			c.draw_circle(p2, 3.5 if b.party_with == player else 2.5, Color(0.35, 0.65, 1.0) if b.party_with == player else Color(0.45, 0.9, 0.45))
	# people with quests
	for n in get_tree().get_nodes_in_group("npcs"):
		var p3 := _to_mini(Vector2(n.global_position.x, n.global_position.z))
		if p3.distance_to(Vector2(radius, radius)) > radius - 6: continue
		var m: String = n.mark.text if n.mark else ""
		if m != "":
			c.draw_string_outline(font, p3 + Vector2(-4, 6), m, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 4, Color(0, 0, 0))
			c.draw_string(font, p3 + Vector2(-4, 6), m, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, n.mark.modulate)
		elif n.info.has("vendor") or n.info.has("trainer"):
			c.draw_circle(p3, 2.5, Color(1, 1, 0.8, 0.8))
	# you: an arrow pointing where you face
	var fwd := Vector2(sin(player.yaw), cos(player.yaw)).rotated(-_cam_yaw())
	var ctr := Vector2(radius, radius)
	c.draw_colored_polygon(PackedVector2Array([ctr + fwd * 9, ctr + fwd.rotated(2.5) * 6, ctr - fwd * 3, ctr + fwd.rotated(-2.5) * 6]), Color(1, 0.95, 0.6))
	# a gold rim and the compass N
	c.draw_arc(ctr, radius, 0, TAU, 64, Color(0.78, 0.62, 0.34), 3.0)
	var north := Vector2(0, -1).rotated(-_cam_yaw()) * (radius - 2) + ctr
	c.draw_circle(north, 9, Color(0.1, 0.08, 0.06))
	c.draw_string(font, north + Vector2(-5, 5), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.9, 0.6))

## where each unfinished objective of your quests can be done
func _quest_spots() -> Array:
	var out := []
	if player == null: return out
	for id in player.quests:
		var q: Dictionary = Quests.LIST[id]
		if player.quest_complete(id):
			var n := _npc(Player.ender_of(id))
			if n: out.append({"at": Vector2(n.global_position.x, n.global_position.z), "r": 3.0})
			continue
		for i in q["obj"].size():
			var o: Dictionary = q["obj"][i]
			if int(player.quests[id]["have"][i]) >= int(o.get("n", 1)): continue
			match o["kind"]:
				"talk":
					var n2 := _npc(o["npc"])
					if n2: out.append({"at": Vector2(n2.global_position.x, n2.global_position.z), "r": 3.0})
				"explore": out.append({"at": Vector2(o["at"][0], o["at"][1]), "r": float(o.get("r", 10.0))})
				"kill", "collect":
					var kinds: Array = [o["mon"]] if o["kind"] == "kill" else o["from"]
					for c in load("res://src/world/spawns.gd").camps():
						if Monster.KINDS[c["kind"]].get("as", c["kind"]) in kinds: out.append({"at": c["at"], "r": maxf(6.0, float(c["r"]) + 3.0)})
				"gather":
					for pk in load("res://src/world/spawns.gd").pickups():
						if pk["item"] == o["item"]: out.append({"at": pk["at"], "r": 6.0}); break
	return out

func _npc(id: String) -> Node3D:
	for n in get_tree().get_nodes_in_group("npcs"):
		if n.npc_id == id: return n
	return null

# ------------------------------------------------------------------ the big map (M)

func toggle_big(parent: Control) -> void:
	if big == null:
		big = Control.new(); big.set_anchors_preset(Control.PRESET_CENTER)
		var s := 720.0
		big.offset_left = -s / 2; big.offset_top = -s / 2; big.offset_right = s / 2; big.offset_bottom = s / 2
		big.mouse_filter = Control.MOUSE_FILTER_STOP
		big.draw.connect(func(): _draw_big(s))
		parent.add_child(big)
	big_open = not big_open
	big.visible = big_open

func _big_pos(w: Vector2, s: float) -> Vector2:
	return (w / WORLD + Vector2(0.5, 0.5)) * s

func _draw_big(s: float) -> void:
	big.draw_rect(Rect2(-12, -46, s + 24, s + 58), Color(0.1, 0.075, 0.05, 0.96))
	big.draw_rect(Rect2(-12, -46, s + 24, s + 58), Color(0.78, 0.62, 0.34), false, 2.0)
	var font := ThemeDB.fallback_font
	big.draw_string(font, Vector2(0, -16), WorldData.Z.get("name", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.98, 0.84, 0.5))
	big.draw_texture_rect(map_tex, Rect2(0, 0, s, s), false)
	for spot in _quest_spots():
		var p := _big_pos(spot["at"], s)
		big.draw_circle(p, maxf(6.0, spot["r"] / WORLD * s), Color(1, 0.82, 0.2, 0.25))
		big.draw_arc(p, maxf(6.0, spot["r"] / WORLD * s), 0, TAU, 24, Color(1, 0.85, 0.3, 0.9), 2.0)
	for pl in PLACES.get(WorldData.zone_id, []):
		var p2 := _big_pos(pl[1], s)
		var w := font.get_string_size(pl[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		big.draw_string_outline(font, p2 - Vector2(w / 2, 0), pl[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 5, Color(0.1, 0.07, 0.03, 0.9))
		big.draw_string(font, p2 - Vector2(w / 2, 0), pl[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 0.93, 0.75))
	for n in get_tree().get_nodes_in_group("npcs"):
		var m: String = n.mark.text if n.mark else ""
		if m == "": continue
		var p3 := _big_pos(Vector2(n.global_position.x, n.global_position.z), s)
		big.draw_string_outline(font, p3 + Vector2(-4, 6), m, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Color(0, 0, 0))
		big.draw_string(font, p3 + Vector2(-4, 6), m, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, n.mark.modulate)
	for b in get_tree().get_nodes_in_group("bots"):
		big.draw_circle(_big_pos(Vector2(b.global_position.x, b.global_position.z), s), 3.0, Color(0.45, 0.9, 0.45))
	var pp := _big_pos(Vector2(player.global_position.x, player.global_position.z), s)
	var fwd := Vector2(sin(player.yaw), cos(player.yaw))
	big.draw_colored_polygon(PackedVector2Array([pp + fwd * 12, pp + fwd.rotated(2.5) * 8, pp - fwd * 4, pp + fwd.rotated(-2.5) * 8]), Color(1, 0.95, 0.6))
	big.draw_arc(pp, 14, 0, TAU, 24, Color(1, 0.95, 0.6, 0.6), 2.0)
	big.draw_string(font, Vector2(s - 200, s + 4), "M closes the map", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.76, 0.68))

# ------------------------------------------------------------------ painting the map

static func _paint() -> Texture2D:
	var img := Image.create(RES, RES, false, Image.FORMAT_RGBA8)
	var step := WORLD / RES
	var houses: Array = []
	var v := load("res://src/world/village.gd")
	if WorldData.zone_id == "ashvale":
		for h in v.HOUSES: houses.append(h)
	for j in RES:
		for i in RES:
			var x := -WORLD / 2 + (i + 0.5) * step; var z := -WORLD / 2 + (j + 0.5) * step
			var hgt := WorldData.h(x, z)
			var n := WorldData.n(x, z)
			var shade := clampf(0.9 + (n.x * -0.8 + n.z * -0.6) * 0.9, 0.65, 1.12)

			var c := Color(0.36, 0.52, 0.25).lerp(Color(0.52, 0.5, 0.36), smoothstep(8.0, 20.0, hgt)).lerp(Color(0.6, 0.58, 0.55), smoothstep(18.0, 28.0, hgt))
			var m := WorldData.m(x, z) if WorldData.mask else Color(0, 0, 0, 0)
			if m.r > 0.4: c = Color(0.72, 0.6, 0.42) if m.g < 0.5 else Color(0.6, 0.58, 0.55)
			var cl := WorldData.clear.get_pixel(clampi(int((x + 128.0) * 4.0), 0, 1023), clampi(int((z + 128.0) * 4.0), 0, 1023)).r
			if cl > 0.5 and m.r < 0.4: c = c.lerp(Color(0.55, 0.43, 0.3), 0.55)
			if WorldData.in_water(x, z): c = Color(0.25, 0.45, 0.6)
			if WorldData.CAVE: c = Color(0.42, 0.36, 0.3).lerp(Color(0.05, 0.04, 0.04), WorldData.rock_w(Vector2(x, z)))
			c = c * shade; c.a = 1.0
			img.set_pixel(i, j, c)
	# houses as little roofs
	for h in houses:
		var cx: float = h[0]; var cz: float = h[1]
		var hw: float = h[2] / 2.0 + 0.5; var hd: float = h[3] / 2.0 + 0.5
		for j in range(int((cz - hd + 128.0) / step), int((cz + hd + 128.0) / step)):
			for i in range(int((cx - hw + 128.0) / step), int((cx + hw + 128.0) / step)):
				if i >= 0 and j >= 0 and i < RES and j < RES: img.set_pixel(i, j, Color(0.55, 0.3, 0.22))
	return ImageTexture.create_from_image(img)

static func _shader() -> Shader:
	var s := Shader.new()
	s.code = """
shader_type canvas_item;
uniform vec2 center = vec2(0.5);
uniform float span = 0.25;
uniform float rot = 0.0;
void fragment() {
	vec2 d = UV - vec2(0.5);
	float r = length(d);
	if (r > 0.5) discard;
	float c = cos(rot), s = sin(rot);
	vec2 w = vec2(c * d.x - s * d.y, s * d.x + c * d.y);
	vec2 uv = center + w * 2.0 * span;
	vec4 col = texture(TEXTURE, uv);
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) col = vec4(0.1, 0.1, 0.08, 1.0);
	col.rgb *= 1.0 - smoothstep(0.42, 0.5, r) * 0.35;
	COLOR = col;
}
"""
	return s
