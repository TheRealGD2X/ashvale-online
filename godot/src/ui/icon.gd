class_name AbilityIcon extends Control
## A painted ability icon: a glowing gradient in the ability's school colour with a symbol drawn
## on top (a sword, a flame, a snowflake, a sun...). No image files needed, crisp at any size.

var ability := ""
var dim := 0.0              # 0..1 darkening (not enough power, out of range)
var tint := Color(1, 1, 1, 0)
var cd_frac := 0.0          # 0..1 of a cooldown still to go (drawn as a sweep)

const SYMBOL := {
	"heroic_strike": "sword", "charge": "arrow", "rend": "claws", "thunder_clap": "quake", "execute": "skull",
	"battle_shout": "horn", "hamstring": "boot", "taunt": "eye", "fireball": "flame", "frostbolt": "shard",
	"fire_blast": "burst", "frost_nova": "snow", "flamestrike": "pillar", "arcane_missiles": "orbs", "frost_armor": "shield",
	"blink": "swirl", "smite": "sun", "mend": "cross", "renewal": "leaf", "ward_of_light": "bubble", "shadow_rot": "moon",
	"holy_nova": "star", "inner_fire": "flame",
}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_ability(id: String) -> void:
	ability = id; queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if ability == "" or not Abilities.LIST.has(ability):
		draw_rect(r, Color(0.08, 0.07, 0.06, 0.7))
		return
	var a: Dictionary = Abilities.LIST[ability]
	var col: Color = Fx.SCHOOL.get(a.get("school", "physical"), Color.WHITE)
	if a.has("icon"): col = a["icon"][1]
	# background: dark vignette to a glow in the middle
	var steps := 14
	for i in steps:
		var t := float(i) / steps
		var inset := size * 0.5 * t
		var c := Color(0.05, 0.04, 0.04).lerp(col.darkened(0.25), pow(t, 0.8))
		draw_rect(Rect2(inset, size - inset * 2.0), c)
	var s := size.x
	var c0 := size * 0.5
	var fg := Color(1, 0.98, 0.9)
	var hi := col.lightened(0.55)
	match SYMBOL.get(ability, "star"):
		"sword":
			_poly([c0 + Vector2(-0.3, 0.3) * s, c0 + Vector2(0.22, -0.28) * s, c0 + Vector2(0.3, -0.3) * s, c0 + Vector2(0.28, -0.22) * s, c0 + Vector2(-0.26, 0.34) * s], fg)
			draw_line(c0 + Vector2(-0.34, 0.14) * s, c0 + Vector2(-0.14, 0.34) * s, hi, s * 0.07)
			draw_line(c0 + Vector2(-0.3, 0.3) * s, c0 + Vector2(-0.4, 0.4) * s, Color(0.45, 0.28, 0.15), s * 0.07)
		"arrow":
			for k in 3:
				var y := (k - 1) * 0.18 * s
				draw_line(c0 + Vector2(-0.38 * s, y), c0 + Vector2(0.05 * s, y), Color(fg, 0.5 + 0.2 * k), s * 0.05)
			_poly([c0 + Vector2(0.38, 0) * s, c0 + Vector2(0.05, -0.24) * s, c0 + Vector2(0.1, 0) * s, c0 + Vector2(0.05, 0.24) * s], fg)
		"claws":
			for k in 3:
				var o := Vector2((k - 1) * 0.16, 0) * s
				draw_line(c0 + o + Vector2(0.14, -0.32) * s, c0 + o + Vector2(-0.14, 0.32) * s, Color(1, 0.35, 0.3), s * 0.07)
		"quake":
			draw_arc(c0 + Vector2(0, 0.2 * s), s * 0.36, PI, TAU, 24, fg, s * 0.05)
			draw_arc(c0 + Vector2(0, 0.2 * s), s * 0.22, PI, TAU, 24, hi, s * 0.05)
			_poly([c0 + Vector2(-0.06, -0.4) * s, c0 + Vector2(0.1, -0.12) * s, c0 + Vector2(0.0, -0.1) * s, c0 + Vector2(0.08, 0.12) * s, c0 + Vector2(-0.1, -0.16) * s, c0 + Vector2(0.0, -0.18) * s], Color(1, 1, 0.7))
		"skull":
			draw_circle(c0 + Vector2(0, -0.05 * s), s * 0.26, fg)
			draw_rect(Rect2(c0 + Vector2(-0.15, 0.1) * s, Vector2(0.3, 0.2) * s), fg)
			draw_circle(c0 + Vector2(-0.1, -0.05) * s, s * 0.07, Color(0.2, 0.02, 0.02))
			draw_circle(c0 + Vector2(0.1, -0.05) * s, s * 0.07, Color(0.2, 0.02, 0.02))
			for k in 3: draw_line(c0 + Vector2(-0.08 + k * 0.08, 0.16) * s, c0 + Vector2(-0.08 + k * 0.08, 0.3) * s, Color(0.2, 0.05, 0.05), s * 0.03)
		"horn":
			_poly([c0 + Vector2(-0.34, -0.1) * s, c0 + Vector2(0.3, -0.34) * s, c0 + Vector2(0.34, 0.1) * s, c0 + Vector2(-0.3, 0.06) * s], fg)
			draw_arc(c0 + Vector2(0.32, -0.12) * s, s * 0.22, -PI * 0.5, PI * 0.5, 16, hi, s * 0.05)
		"boot":
			_poly([c0 + Vector2(-0.1, -0.36) * s, c0 + Vector2(0.1, -0.36) * s, c0 + Vector2(0.1, 0.18) * s, c0 + Vector2(0.34, 0.2) * s, c0 + Vector2(0.34, 0.34) * s, c0 + Vector2(-0.12, 0.34) * s], fg)
			draw_line(c0 + Vector2(-0.3, -0.05) * s, c0 + Vector2(0.3, 0.05) * s, Color(1, 0.3, 0.2), s * 0.05)
		"eye":
			draw_circle(c0, s * 0.3, fg)
			draw_circle(c0, s * 0.14, Color(0.8, 0.1, 0.05))
			draw_circle(c0, s * 0.06, Color(0.1, 0, 0))
		"flame":
			_flame(c0 + Vector2(0, 0.06 * s), s * 0.36, Color(1.0, 0.5, 0.08))
			_flame(c0 + Vector2(0, 0.12 * s), s * 0.22, Color(1.0, 0.85, 0.3))
			_flame(c0 + Vector2(0, 0.17 * s), s * 0.1, Color(1, 1, 0.85))
		"shard":
			_poly([c0 + Vector2(0.34, -0.34) * s, c0 + Vector2(0.06, 0.02) * s, c0 + Vector2(-0.34, 0.34) * s, c0 + Vector2(-0.02, -0.06) * s], Color(0.85, 0.95, 1.0))
			draw_line(c0 + Vector2(0.3, -0.3) * s, c0 + Vector2(-0.3, 0.3) * s, Color(1, 1, 1), s * 0.02)
		"burst":
			for k in 10:
				var ang := TAU * k / 10.0
				draw_line(c0, c0 + Vector2(cos(ang), sin(ang)) * s * (0.42 if k % 2 == 0 else 0.28), Color(1.0, 0.8, 0.3), s * 0.08)
			draw_circle(c0, s * 0.14, Color(1, 1, 0.8))
		"snow":
			for k in 6:
				var ang := TAU * k / 6.0
				var tip := c0 + Vector2(cos(ang), sin(ang)) * s * 0.38
				draw_line(c0, tip, fg, s * 0.05)
				var mid := c0 + Vector2(cos(ang), sin(ang)) * s * 0.22
				draw_line(mid, mid + Vector2(cos(ang + 0.8), sin(ang + 0.8)) * s * 0.1, fg, s * 0.04)
				draw_line(mid, mid + Vector2(cos(ang - 0.8), sin(ang - 0.8)) * s * 0.1, fg, s * 0.04)
		"pillar":
			draw_rect(Rect2(c0 + Vector2(-0.12, -0.42) * s, Vector2(0.24, 0.72) * s), Color(1.0, 0.6, 0.2, 0.9))
			draw_rect(Rect2(c0 + Vector2(-0.05, -0.42) * s, Vector2(0.1, 0.72) * s), Color(1, 0.95, 0.7))
			_flame(c0 + Vector2(0, 0.34 * s), s * 0.3, Color(1.0, 0.45, 0.05))
		"orbs":
			for k in 3:
				var o := Vector2(-0.22 + k * 0.22, 0.12 - k * 0.12) * s
				draw_circle(c0 + o, s * 0.11, Color(0.9, 0.7, 1.0))
				draw_circle(c0 + o, s * 0.05, Color(1, 1, 1))
		"shield":
			_poly([c0 + Vector2(-0.3, -0.32) * s, c0 + Vector2(0.3, -0.32) * s, c0 + Vector2(0.28, 0.08) * s, c0 + Vector2(0, 0.38) * s, c0 + Vector2(-0.28, 0.08) * s], hi)
			_poly([c0 + Vector2(-0.18, -0.2) * s, c0 + Vector2(0.18, -0.2) * s, c0 + Vector2(0.16, 0.04) * s, c0 + Vector2(0, 0.22) * s, c0 + Vector2(-0.16, 0.04) * s], fg)
		"swirl":
			for k in 3:
				draw_arc(c0, s * (0.12 + 0.11 * k), k * 1.2, k * 1.2 + 4.2, 20, Color(0.9, 0.75, 1.0, 1.0 - k * 0.2), s * 0.05)
		"sun":
			for k in 12:
				var ang := TAU * k / 12.0
				draw_line(c0 + Vector2(cos(ang), sin(ang)) * s * 0.2, c0 + Vector2(cos(ang), sin(ang)) * s * 0.42, Color(1, 0.9, 0.5), s * 0.05)
			draw_circle(c0, s * 0.18, Color(1, 1, 0.85))
		"cross":
			draw_rect(Rect2(c0 + Vector2(-0.09, -0.34) * s, Vector2(0.18, 0.68) * s), fg)
			draw_rect(Rect2(c0 + Vector2(-0.34, -0.09) * s, Vector2(0.68, 0.18) * s), fg)
		"leaf":
			for k in 5:
				var ang := TAU * k / 5.0 - PI / 2.0
				draw_circle(c0 + Vector2(cos(ang), sin(ang)) * s * 0.19, s * 0.13, Color(0.75, 1.0, 0.65))
			draw_circle(c0, s * 0.1, Color(1, 0.95, 0.6))
		"bubble":
			draw_circle(c0, s * 0.36, Color(1.0, 0.9, 0.55, 0.35))
			draw_arc(c0, s * 0.36, 0, TAU, 32, fg, s * 0.05)
			draw_arc(c0 + Vector2(-0.1, -0.1) * s, s * 0.14, PI, PI * 1.5, 10, Color(1, 1, 1), s * 0.04)
		"moon":
			draw_circle(c0, s * 0.32, Color(0.85, 0.7, 1.0))
			draw_circle(c0 + Vector2(0.14, -0.08) * s, s * 0.28, col.darkened(0.4))
		"star":
			var pts := PackedVector2Array()
			for k in 10:
				var ang := TAU * k / 10.0 - PI / 2.0
				pts.append(c0 + Vector2(cos(ang), sin(ang)) * s * (0.4 if k % 2 == 0 else 0.17))
			draw_colored_polygon(pts, fg)
	# cooldown sweep
	if cd_frac > 0.0:
		var pts2 := PackedVector2Array([c0])
		var n := 32
		for k in n + 1:
			var ang := -PI / 2.0 + TAU * cd_frac * float(k) / n
			var dir := Vector2(cos(ang), sin(ang))
			# project onto the square
			var m := maxf(absf(dir.x), absf(dir.y))
			pts2.append(c0 + dir / m * s * 0.5)
		draw_colored_polygon(pts2, Color(0, 0, 0, 0.62))
	if dim > 0.0: draw_rect(r, Color(0.0, 0.0, 0.08, dim))
	if tint.a > 0.0: draw_rect(r, tint)
	# bevel
	draw_rect(r, Color(0, 0, 0, 0.9), false, 2.0)
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(1, 1, 1, 0.12), false, 1.0)

func _poly(p: Array, c: Color) -> void:
	draw_colored_polygon(PackedVector2Array(p), c)

func _flame(base: Vector2, h: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for k in 17:
		var t := float(k) / 16.0
		var ang := PI * 2.0 * t
		var w := sin(t * PI) * h * 0.55
		var y := -cos(t * PI * 2.0) * 0.0
		pts.append(base + Vector2(sin(ang) * w * 0.9, -h * (0.5 - 0.5 * cos(ang)) * (1.0 if t > 0.25 and t < 0.75 else 0.35) * 1.1 + y))
	# simple teardrop instead (robust)
	pts = PackedVector2Array()
	for k in 24:
		var ang := TAU * k / 24.0
		var r := h * 0.45
		var p := Vector2(sin(ang) * r, cos(ang) * r * 0.9)
		if p.y < 0: p.y *= 2.1; p.x *= 1.0 - (-p.y / (h * 1.1)) * 0.75
		pts.append(base + p)
	draw_colored_polygon(pts, c)
