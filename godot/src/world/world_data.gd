class_name WorldData
## The shape of the current zone (see Zones): ground height, roads, a town square, a pond, cliffs,
## the wild edges, or a cave's halls. Everything that places things in the world (terrain, grass,
## trees, houses, people) asks here, so the ground, the paths and what grows on them always agree.
##
## Coordinates: metres, x east, z south, y up. The map runs from -HALF to +HALF on x and z.

static var lite := false          # cheaper settings for slow test machines
const HALF := 128.0              # every zone is 256 m across
const WATER_H := 0.35            # pond surface height
static var zone_id := "ashvale"
static var Z: Dictionary = {}
static var TOWN := Vector2(0, 0)         # centre of the town square (or camp)
static var TOWN_H := 2.0
static var SQUARE_R := 13.0              # cobbled square radius (0: none)
static var POND := Vector2(-42, 46)
static var POND_R := 15.0                # 0: no pond
static var ROADS: Array = []
static var CAVE := false

## switch every lookup to a zone (before baking)
static func use_zone(id: String) -> void:
	zone_id = id if Zones.DEFS.has(id) else "ashvale"
	Z = Zones.get_def(zone_id)
	ROADS = Z.get("roads", [])
	var pl: Array = Z.get("plateaus", [])
	TOWN = pl[0]["at"] if pl.size() else Vector2(0, 0)
	TOWN_H = float(pl[0]["h"]) if pl.size() else 0.0
	var sq = Z.get("square")
	SQUARE_R = float(sq["r"]) if sq else 0.0
	var pd = Z.get("pond")
	POND = pd["at"] if pd else Vector2(9999, 9999)
	POND_R = float(pd["r"]) if pd else 0.0
	CAVE = Z.has("cave")
	_noise = null
	heights = PackedFloat32Array()
	clear = Image.create(CLEAR_RES, CLEAR_RES, false, Image.FORMAT_L8)

static var _noise: FastNoiseLite
static var _detail: FastNoiseLite
static var _warp: FastNoiseLite

static func _init_noise() -> void:
	if _noise: return
	if Z.is_empty(): use_zone(zone_id)
	var sd := int(Z.get("seed", 7))
	_noise = FastNoiseLite.new(); _noise.seed = sd; _noise.frequency = 1.0 / 90.0; _noise.fractal_octaves = 4
	_detail = FastNoiseLite.new(); _detail.seed = sd + 14; _detail.frequency = 1.0 / 18.0; _detail.fractal_octaves = 2
	_warp = FastNoiseLite.new(); _warp.seed = sd - 4; _warp.frequency = 1.0 / 60.0

## distance (m) from p to the nearest road, and that road's kind
static func road(p: Vector2) -> Vector2:
	var best := 1e9; var kind := 0.0
	for r in ROADS:
		var pts: Array = r["pts"]
		for i in pts.size() - 1:
			var d := _seg_dist(p, pts[i], pts[i + 1]) - float(r["w"])
			if d < best: best = d; kind = r["kind"]
	return Vector2(best, kind)

## distance to the nearest road that cuts a pass through the rim
static func _cut_road(p: Vector2) -> float:
	var best := 1e9
	for r in ROADS:
		if not r.get("cut", false): continue
		var pts: Array = r["pts"]
		for i in pts.size() - 1: best = minf(best, _seg_dist(p, pts[i], pts[i + 1]) - float(r["w"]))
	return best

static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a; var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

static func _line_dist(p: Vector2, pts: Array) -> float:
	var best := 1e9
	for i in pts.size() - 1: best = minf(best, _seg_dist(p, pts[i], pts[i + 1]))
	return best

## how much of the town (or camp) plateau covers p (1 in town, 0 in the wild)
static func town_w(p: Vector2) -> float:
	if Z.is_empty(): use_zone(zone_id)
	var pl: Array = Z.get("plateaus", [])
	if pl.is_empty(): return 0.0
	var t: Dictionary = pl[0]
	return 1.0 - smoothstep(float(t["r0"]), float(t["r1"]), p.distance_to(t["at"]))

## a cave: 0 on the floor of a hall or room, 1 inside the rock
static func rock_w(p: Vector2) -> float:
	var c: Dictionary = Z["cave"]
	var d := 1e9
	for hl in c["halls"]: d = minf(d, _line_dist(p, hl["pts"]) - float(hl["w"]))
	for rm in c["rooms"]: d = minf(d, p.distance_to(rm["at"]) - float(rm["r"]))
	d += (_warp.get_noise_2d(p.x * 2.0, p.y * 2.0)) * 1.6
	return smoothstep(-0.2, 1.6, d)

## ground height at (x, z)
static func height(x: float, z: float) -> float:
	_init_noise()
	var p := Vector2(x, z)
	if CAVE:
		var w := rock_w(p)
		return _detail.get_noise_2d(x, z) * float(Z.get("relief", 0.6)) + w * float(Z["cave"]["wall"]) * (0.85 + 0.3 * (_noise.get_noise_2d(x * 3.0, z * 3.0) * 0.5 + 0.5))
	var h := _noise.get_noise_2d(x, z) * float(Z.get("relief", 7.0)) + _detail.get_noise_2d(x, z) * 0.7 + 3.0
	# rising hills toward the edge of the map: the world's natural walls, with a pass where a road leaves
	var edge := maxf(absf(x), absf(z)) + _warp.get_noise_2d(x, z) * 10.0
	var rim := pow(smoothstep(88.0, 128.0, edge), 1.6) * float(Z.get("edge", 26.0))
	var cr := _cut_road(p)
	if cr < 30.0: rim *= smoothstep(4.0, 30.0, cr)
	h += rim
	# cliffs and rock spines
	for rg in Z.get("ridges", []):
		var d := _line_dist(p, rg["pts"]) + _warp.get_noise_2d(x * 1.7, z * 1.7) * 3.0
		var w := float(rg["w"])
		h += float(rg["h"]) * (1.0 - smoothstep(w * 0.35, w, d)) * (0.8 + 0.4 * (_detail.get_noise_2d(x * 0.5, z * 0.5) * 0.5 + 0.5))
	# level ground for towns and camps
	for pl in Z.get("plateaus", []):
		var k := 1.0 - smoothstep(float(pl["r0"]), float(pl["r1"]), p.distance_to(pl["at"]))
		if k > 0.0: h = lerpf(h, float(pl["h"]) + _detail.get_noise_2d(x, z) * 0.15, k)
	# the pond: a soft bowl
	if POND_R > 0.0:
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
			var sq := (1.0 - smoothstep(SQUARE_R - 1.0, SQUARE_R + 0.6, p.distance_to(TOWN))) if SQUARE_R > 0.0 else 0.0

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
	if POND_R <= 0.0: return 99.0
	var a := atan2(p.y - POND.y, p.x - POND.x)
	var wob := sin(a * 2.0 + 0.7) * 0.2 + sin(a * 3.0 + 2.1) * 0.12 + sin(a * 5.0 + 4.0) * 0.05 + _warp.get_noise_2d(p.x * 3.0, p.y * 3.0) * 0.15
	return p.distance_to(POND) / (POND_R * (1.0 + wob))

## true where the pond is
static func in_water(x: float, z: float) -> bool:
	if POND_R <= 0.0: return false
	return h(x, z) < WATER_H + 0.05 and Vector2(x, z).distance_to(POND) < POND_R * 1.9

## true on the cobbled town square
static func on_square(p: Vector2) -> bool:
	return SQUARE_R > 0.0 and p.distance_to(TOWN) < SQUARE_R
