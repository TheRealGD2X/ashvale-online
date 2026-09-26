class_name WorldData
## The shape of Ashvale: ground height, roads, the town square, the pond and the wild edges.
## Everything that places things in the world (terrain, grass, trees, houses, people) asks here,
## so the ground, the paths and what grows on them always agree.
##
## Coordinates: metres, x east, z south, y up. The map runs from -HALF to +HALF on x and z.

static var lite := false          # cheaper settings for slow test machines
const HALF := 128.0              # the map is 256 m across
const TOWN := Vector2(0, 0)      # centre of the town square
const TOWN_H := 2.0              # height of the town plateau
const SQUARE_R := 13.0           # cobbled square radius
const POND := Vector2(-42, 46)
const POND_R := 15.0
const WATER_H := 0.35            # pond surface height

## roads: polylines of [x, z] points, with a half-width and a kind (0 dirt, 1 cobbles)
const ROADS := [
	{"pts": [Vector2(-128, 8), Vector2(-92, 4), Vector2(-56, 7), Vector2(-26, 3), Vector2(0, 0), Vector2(30, -2), Vector2(62, 5), Vector2(96, 2), Vector2(128, 6)], "w": 2.4, "kind": 0},
	{"pts": [Vector2(0, 0), Vector2(-3, -24), Vector2(-9, -52), Vector2(2, -86), Vector2(-4, -128)], "w": 2.0, "kind": 0},
	{"pts": [Vector2(2, 6), Vector2(-8, 22), Vector2(-24, 34), Vector2(-29, 37.5)], "w": 1.4, "kind": 0},
	{"pts": [Vector2(22, -1), Vector2(36, 16), Vector2(46, 34)], "w": 1.5, "kind": 0},
	# the path from the Mill up to the Old Shrine
	{"pts": [Vector2(60, 4), Vector2(64, -20), Vector2(62, -46), Vector2(68, -66), Vector2(72, -77)], "w": 1.2, "kind": 0},
	# town streets: cobbled inside the town
	{"pts": [Vector2(-30, 3), Vector2(-14, 1), Vector2(14, -1), Vector2(30, -2)], "w": 2.6, "kind": 1},
	{"pts": [Vector2(0, 0), Vector2(-2, -22)], "w": 2.2, "kind": 1},
]

static var _noise: FastNoiseLite
static var _detail: FastNoiseLite
static var _warp: FastNoiseLite

static func _init_noise() -> void:
	if _noise: return
	_noise = FastNoiseLite.new(); _noise.seed = 7; _noise.frequency = 1.0 / 90.0; _noise.fractal_octaves = 4
	_detail = FastNoiseLite.new(); _detail.seed = 21; _detail.frequency = 1.0 / 18.0; _detail.fractal_octaves = 2
	_warp = FastNoiseLite.new(); _warp.seed = 3; _warp.frequency = 1.0 / 60.0

## distance (m) from p to the nearest road, and that road's kind
static func road(p: Vector2) -> Vector2:
	var best := 1e9; var kind := 0.0
	for r in ROADS:
		var pts: Array = r["pts"]
		for i in pts.size() - 1:
			var d := _seg_dist(p, pts[i], pts[i + 1]) - float(r["w"])
			if d < best: best = d; kind = r["kind"]
	return Vector2(best, kind)

static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a; var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

## how much of the town plateau covers p (1 in town, 0 in the wild)
static func town_w(p: Vector2) -> float:
	var d := p.distance_to(TOWN)
	return 1.0 - smoothstep(34.0, 58.0, d)

## ground height at (x, z)
static func height(x: float, z: float) -> float:
	_init_noise()
	var p := Vector2(x, z)
	var h := _noise.get_noise_2d(x, z) * 7.0 + _detail.get_noise_2d(x, z) * 0.7 + 3.0
	# rising hills toward the edge of the map: the world's natural walls
	var edge := maxf(absf(x), absf(z)) + _warp.get_noise_2d(x, z) * 10.0
	h += pow(smoothstep(88.0, 128.0, edge), 1.6) * 26.0
	# the town sits on a level plateau
	h = lerpf(h, TOWN_H + _detail.get_noise_2d(x, z) * 0.15, town_w(p))
	# the pond: a soft bowl
	var pd := pond_d(p)
	if pd < 1.9: h = lerpf(h, WATER_H - 2.6 * (1.0 - smoothstep(0.0, 1.1, pd)) + 0.9 * smoothstep(0.75, 1.5, pd), 1.0 - smoothstep(0.8, 1.9, pd))
	# roads are worn a little flatter and lower than the ground around them
	var r := road(p).x
	if r < 3.0: h -= 0.12 * (1.0 - smoothstep(-1.0, 3.0, r))
	return h

static func normal(x: float, z: float) -> Vector3:
	var e := 0.5
	return Vector3(height(x - e, z) - height(x + e, z), 2.0 * e, height(x, z - e) - height(x, z + e)).normalized()

# ---------------------------------------------------------------- baked grid (fast lookups at runtime)
const RES := 513                   # samples per side (0.5 m apart)
const STEP := 2.0 * HALF / (RES - 1)
static var heights := PackedFloat32Array()
static var _mb := PackedByteArray()
static var mask: Image              # R road (1 on the road, soft edge), G cobbles, B town, A shore

## compute the whole grid once (all cores); call before building the world
static func bake() -> void:
	if heights.size() == RES * RES: return
	_init_noise()
	heights.resize(RES * RES)
	_mb.resize(RES * RES * 4)
	var rows := func(j: int) -> void:
		var z := -HALF + j * STEP
		for i in RES:
			var x := -HALF + i * STEP
			var p := Vector2(x, z)
			heights[j * RES + i] = height(x, z)
			var r := road(p)
			var o := (j * RES + i) * 4
			var on_road := 1.0 - smoothstep(-0.6, 0.9, r.x)
			var cob := 1.0 if (r.y > 0.5 and on_road > 0.0) else 0.0
			var sq := 1.0 - smoothstep(SQUARE_R - 1.0, SQUARE_R + 0.6, p.distance_to(TOWN))
			_mb[o] = int(maxf(on_road, sq) * 255.0)
			_mb[o + 1] = int(maxf(cob, sq) * 255.0)
			_mb[o + 2] = int(town_w(p) * 255.0)
			_mb[o + 3] = int((1.0 - smoothstep(0.9, 1.3, pond_d(p))) * 255.0)
	var task := WorkerThreadPool.add_group_task(rows, RES, -1, true, "bake world")
	WorkerThreadPool.wait_for_group_task_completion(task)
	mask = Image.create_from_data(RES, RES, false, Image.FORMAT_RGBA8, _mb)

## ground height from the baked grid (bilinear); falls back to the formula before baking
static func h(x: float, z: float) -> float:
	if heights.size() != RES * RES: return height(x, z)
	var fx := clampf((x + HALF) / STEP, 0.0, RES - 1.001); var fz := clampf((z + HALF) / STEP, 0.0, RES - 1.001)
	var i := int(fx); var j := int(fz); var tx := fx - i; var tz := fz - j
	var a := heights[j * RES + i]; var b := heights[j * RES + i + 1]
	var c := heights[(j + 1) * RES + i]; var d := heights[(j + 1) * RES + i + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)

## baked mask at (x, z): r road, g cobbles, b town, a shore
static func m(x: float, z: float) -> Color:
	var i := clampi(int((x + HALF) / STEP + 0.5), 0, RES - 1); var j := clampi(int((z + HALF) / STEP + 0.5), 0, RES - 1)
	return mask.get_pixel(i, j)

static func n(x: float, z: float) -> Vector3:
	var e := 0.5
	return Vector3(h(x - e, z) - h(x + e, z), 2.0 * e, h(x, z - e) - h(x, z + e)).normalized()

# ---------------------------------------------------------------- clearings (where no grass grows)
const CLEAR_RES := 1024            # 0.25 m per pixel
static var clear := Image.create(CLEAR_RES, CLEAR_RES, false, Image.FORMAT_L8)

## mark a rectangle (centre, half size, yaw) as bare ground: under houses, fields, big rocks
static func clear_rect(c: Vector2, half: Vector2, yaw := 0.0, pad := 0.4) -> void:
	var px := CLEAR_RES / (2.0 * HALF)
	var r := (half + Vector2(pad, pad)).length()
	var cs := cos(-yaw); var sn := sin(-yaw)
	for j in range(int((c.y - r + HALF) * px), int((c.y + r + HALF) * px) + 1):
		for i in range(int((c.x - r + HALF) * px), int((c.x + r + HALF) * px) + 1):
			if i < 0 or j < 0 or i >= CLEAR_RES or j >= CLEAR_RES: continue
			var d := Vector2(i / px - HALF, j / px - HALF) - c
			var l := Vector2(d.x * cs - d.y * sn, d.x * sn + d.y * cs)
			var e := maxf(absf(l.x) - half.x, absf(l.y) - half.y)
			var v := 1.0 - smoothstep(0.0, pad, e)
			if v > clear.get_pixel(i, j).r: clear.set_pixel(i, j, Color(v, v, v))

## mark a disc as bare ground
static func clear_disc(c: Vector2, r: float, pad := 0.3) -> void:
	var px := CLEAR_RES / (2.0 * HALF)
	for j in range(int((c.y - r - pad + HALF) * px), int((c.y + r + pad + HALF) * px) + 1):
		for i in range(int((c.x - r - pad + HALF) * px), int((c.x + r + pad + HALF) * px) + 1):
			if i < 0 or j < 0 or i >= CLEAR_RES or j >= CLEAR_RES: continue
			var v := 1.0 - smoothstep(r, r + pad, Vector2(i / px - HALF, j / px - HALF).distance_to(c))
			if v > clear.get_pixel(i, j).r: clear.set_pixel(i, j, Color(v, v, v))

## distance from the pond centre in pond radii, with a wandering (not circular) shoreline
static func pond_d(p: Vector2) -> float:
	_init_noise()
	var a := atan2(p.y - POND.y, p.x - POND.x)
	var wob := sin(a * 2.0 + 0.7) * 0.2 + sin(a * 3.0 + 2.1) * 0.12 + sin(a * 5.0 + 4.0) * 0.05 + _warp.get_noise_2d(p.x * 3.0, p.y * 3.0) * 0.15
	return p.distance_to(POND) / (POND_R * (1.0 + wob))

## true where the pond is
static func in_water(x: float, z: float) -> bool:
	return h(x, z) < WATER_H + 0.05 and Vector2(x, z).distance_to(POND) < POND_R * 1.9

## true on the cobbled town square
static func on_square(p: Vector2) -> bool:
	return p.distance_to(TOWN) < SQUARE_R
