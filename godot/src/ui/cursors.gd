class_name Cursors
## Painted mouse pointers, WoW style: a gilded arrow normally, a sword over enemies, a speech
## hand over friendly people. Drawn into images at start-up, no files needed.

static func install() -> void:
	Input.set_custom_mouse_cursor(_arrow(), Input.CURSOR_ARROW, Vector2(2, 2))
	Input.set_custom_mouse_cursor(_sword(), Input.CURSOR_CROSS, Vector2(3, 3))
	Input.set_custom_mouse_cursor(_talk(), Input.CURSOR_POINTING_HAND, Vector2(4, 3))

static func _img() -> Image:
	return Image.create(32, 32, false, Image.FORMAT_RGBA8)

## fill a polygon with an outline, by testing every pixel (32×32 is tiny)
static func _poly(img: Image, pts: PackedVector2Array, fill: Color, edge: Color, grad := Color(0, 0, 0, 0)) -> void:
	for y in 32:
		for x in 32:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				var c := fill
				if grad.a > 0.0: c = fill.lerp(grad, clampf((x + y) / 44.0, 0.0, 1.0))
				img.set_pixel(x, y, c)
	# outline: any empty pixel next to a filled one
	var copy := img.duplicate()
	for y in 32:
		for x in 32:
			if copy.get_pixel(x, y).a > 0.0: continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < 32 and q.y < 32 and copy.get_pixel(q.x, q.y).a > 0.5 and copy.get_pixel(q.x, q.y) != edge:
					img.set_pixel(x, y, edge); break

static func _arrow() -> Image:
	var img := _img()
	_poly(img, PackedVector2Array([Vector2(2, 2), Vector2(22, 12), Vector2(13, 14), Vector2(19, 26), Vector2(15, 28), Vector2(10, 16), Vector2(3, 22)]),
		Color(1.0, 0.88, 0.55), Color(0.2, 0.12, 0.04), Color(0.72, 0.5, 0.2))
	return img

static func _sword() -> Image:
	var img := _img()
	_poly(img, PackedVector2Array([Vector2(2, 2), Vector2(7, 3), Vector2(22, 18), Vector2(18, 22), Vector2(3, 7)]), Color(0.92, 0.94, 1.0), Color(0.15, 0.15, 0.2), Color(0.6, 0.65, 0.75))
	_poly(img, PackedVector2Array([Vector2(16, 24), Vector2(24, 16), Vector2(26, 18), Vector2(18, 26)]), Color(0.9, 0.7, 0.3), Color(0.25, 0.15, 0.05))
	_poly(img, PackedVector2Array([Vector2(21, 23), Vector2(23, 21), Vector2(30, 28), Vector2(28, 30)]), Color(0.5, 0.3, 0.15), Color(0.2, 0.1, 0.05))
	return img

static func _talk() -> Image:
	var img := _img()
	_poly(img, PackedVector2Array([Vector2(3, 4), Vector2(28, 4), Vector2(28, 19), Vector2(14, 19), Vector2(8, 26), Vector2(9, 19), Vector2(3, 19)]),
		Color(1.0, 0.97, 0.88), Color(0.25, 0.18, 0.08), Color(0.85, 0.78, 0.6))
	for x in [10, 15, 20]:
		for dy in 2:
			for dx in 2: img.set_pixel(x + dx, 11 + dy, Color(0.35, 0.25, 0.1))
	return img
